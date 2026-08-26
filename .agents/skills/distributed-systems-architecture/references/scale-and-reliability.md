# Scale & Reliability

This file covers keeping a system fast and available as load grows and parts fail:
caching, load balancing, rate limiting, the resilience patterns that stop small
failures from becoming outages, capacity math, multi-region, and observability.

## Contents
- [Scaling: vertical, horizontal, and stateless](#scaling-vertical-horizontal-and-stateless)
- [Caching](#caching)
- [Load balancing](#load-balancing)
- [Rate limiting and load shedding](#rate-limiting-and-load-shedding)
- [Resilience patterns](#resilience-patterns)
- [Capacity and back-of-the-envelope math](#capacity-and-back-of-the-envelope-math)
- [Multi-region and geo](#multi-region-and-geo)
- [Observability](#observability)
- [Common failure modes](#common-failure-modes)

## Scaling: vertical, horizontal, and stateless

- **Vertical (bigger box)** — simplest; do it first. It buys real headroom with zero
  architectural change. The ceiling is a single machine and it's a single failure
  domain.
- **Horizontal (more boxes)** — required past the vertical ceiling and for fault
  tolerance. Easy for **stateless** services (any instance handles any request —
  just add instances behind a balancer); hard for **stateful** ones (that's the
  replication/partitioning problem — see `data-and-consistency.md`).
- **Push state to the edges.** Keep application tiers stateless and put state in
  datastores/caches. Session affinity ("sticky sessions") is a smell that state
  leaked into the app tier; prefer a shared session store.

## Caching

Caching is the highest-leverage performance tool and a rich source of bugs.

- **Where:** client → CDN → reverse proxy → application (in-process) → distributed
  cache (Redis/Memcached) → database's own cache. Each layer cuts load on the next.
- **Patterns:**
  - **Cache-aside (lazy)** — app checks cache, on miss reads DB and populates. Most
    common; cache only holds what's used. Risk: stale entries and the miss path.
  - **Read-through / write-through** — the cache sits inline; write-through keeps
    cache and DB in sync on write at the cost of write latency.
  - **Write-behind** — write to cache, flush to DB async; fast but risks data loss
    and complexity.
- **Invalidation** is the hard part ("one of the two hard things"). TTLs are the
  blunt, reliable default; event/CDC-driven invalidation is precise but more work.
  Accept that cached data is a derived copy and can be briefly stale — make sure
  that's acceptable for each cached item.
- **Hazards:**
  - **Thundering herd / cache stampede** — a hot key expires and thousands of
    requests hit the DB at once. Mitigate with request coalescing (single-flight),
    staggered/jittered TTLs, or serving stale while one worker refreshes.
  - **Cache penetration** — requests for keys that don't exist bypass the cache to
    the DB every time; cache negative results.
  - **Hot key** — one key overloads a single cache node; replicate or local-cache
    it.
  - **Cache as a crutch** — if the DB *cannot* survive a cold cache, the cache is
    load-bearing for availability, not just speed. Know whether you can survive a
    cache flush; many outages are "cache restarted → DB melted."

## Load balancing

- **L4 (transport)** vs **L7 (application)** — L7 can route on path/header/cookie,
  do retries, and terminate TLS; L4 is faster and simpler. Most API traffic wants
  L7.
- **Algorithms:** round-robin (simple), least-connections (better under uneven
  request cost), consistent hashing (when you want a key to prefer the same backend,
  e.g. for cache locality).
- **Health checks** remove bad instances — but make them meaningful (check
  dependencies where appropriate) and beware checks so aggressive they evict healthy-
  but-busy nodes and cascade load onto the rest.
- **Anti-pattern:** the load balancer or its config as an unmonitored single point
  of failure; run redundant LBs.

## Rate limiting and load shedding

Protecting a system from overload is as important as scaling it.

- **Algorithms:** **token bucket** (allows bursts up to a cap, refills steadily —
  the usual choice), **leaky bucket** (smooths to a constant rate), **fixed/sliding
  window** (simpler counting; fixed windows allow 2x bursts at boundaries).
- **Where:** at the edge/gateway for coarse protection, per-tenant/per-key for
  fairness (stop one client starving others), and per-dependency internally.
- **Load shedding** — when overloaded, *deliberately* reject or degrade low-priority
  work fast so high-priority work survives. A fast 429/503 is far better than a slow
  timeout that ties up resources. Shedding preserves goodput under overload.

## Resilience patterns

The core idea: **contain failures so they don't cascade.**

- **Timeouts on every remote call.** No timeout = one stuck dependency exhausts your
  threads/connections and takes you down. This is the most common cause of cascading
  failure.
- **Retries with exponential backoff *and jitter*.** Retries without backoff/jitter
  synchronize clients into a **retry storm** that hammers a recovering service to
  death. Cap attempts; only retry idempotent operations; consider a retry budget.
- **Circuit breaker** — after a threshold of failures to a dependency, "open" the
  circuit and fail fast (or fall back) instead of piling on; periodically probe to
  see if it recovered. Stops you from waiting on something that's down.
- **Bulkheads** — isolate resources (separate thread pools/connection pools per
  dependency or tenant) so one saturated dependency can't consume all capacity.
- **Graceful degradation / fallbacks** — serve stale cache, a default, or reduced
  functionality instead of a hard error when a non-critical dependency is down.
- **Idempotency** — the precondition that makes retries safe (see
  `data-and-consistency.md`).

## Capacity and back-of-the-envelope math

Rough numbers prevent designs that can't possibly work. A quick method:

1. **Convert to per-second.** ~86,400 s/day ≈ 1e5. So 1M/day ≈ 12/s; 1B/day ≈
   ~11.5K/s. Estimate peak as 2–10x average.
2. **QPS × per-request cost** = load. Multiply by payload size for bandwidth, by
   working-set size for memory, by rows for storage/IOPS.
3. **Storage** = items × size × replication factor × growth-over-retention. Add
   indexes and overhead.
4. **Sanity-check against single-machine limits** — a modern box does ~10s of Gbps
   network, ~GB/s NVMe, ~100K+ simple ops/s on a good DB, memory in the 100s of GB.
   If one path needs 1M writes/s, you know immediately you must partition.

Latency numbers worth internalizing (orders of magnitude): memory reference ~100 ns,
SSD read ~100 µs, intra-region network round-trip ~0.5 ms, cross-continent RTT
~50–150 ms. Coordination and replication pay these round-trips repeatedly — which is
why cross-region strong consistency is slow.

## Multi-region and geo

- **Why:** lower latency to users, disaster recovery, data residency. **Cost:**
  cross-region latency and the consistency problem of replicating writes far away.
- **Read-local, write-home** (single write region + read replicas elsewhere) is the
  simplest and covers many cases; writes still pay the trip home.
- **Active-active** (writes in multiple regions) needs conflict resolution (see
  multi-leader in `data-and-consistency.md`) — real complexity; adopt only with a
  concrete need.
- **DR posture** — know your **RPO** (how much data you can afford to lose) and
  **RTO** (how fast you must recover); they dictate replication and failover design.
  Test failover; an untested DR plan is a hope, not a plan.

## Observability

You cannot operate or evolve what you can't see; build this in from day one, not
after the first outage.

- **The four golden signals:** latency, traffic, errors, saturation. Alert on these
  and on **SLO burn rate**, not on every CPU blip.
- **Three pillars:** **metrics** (cheap aggregates, dashboards, alerts — use
  **percentiles**, never averages, for latency), **logs** (structured, correlated by
  request/trace id), **traces** (follow one request across services — essential once
  you have more than a couple of hops).
- **Track the leading indicators** this skill keeps flagging: consumer/replication
  lag, queue depth, cache hit rate, connection-pool saturation, error budgets.
- **Health/readiness endpoints** so orchestrators and balancers route only to
  instances that can actually serve.

## Common failure modes

- **Missing timeouts** → one slow dependency exhausts threads → cascading outage.
  The number one culprit.
- **Retry storms** → un-jittered retries synchronize and DDoS a recovering service.
- **Cache stampede** → hot key expiry floods the DB.
- **Cold-cache collapse** → cache restart takes the DB down because it was silently
  load-bearing.
- **No load shedding** → overload turns into total collapse instead of graceful
  goodput loss.
- **Averages hiding pain** → mean latency looks fine while p99 is terrible for a real
  slice of users. Always look at tails.
- **Unbounded resource** → a pool/queue/table with no limit fails catastrophically
  instead of degrading.
- **Untested failover / DR** → the one time you need it, it doesn't work.
- **Health checks too aggressive** → healthy-but-busy nodes evicted, load cascades
  onto survivors.
