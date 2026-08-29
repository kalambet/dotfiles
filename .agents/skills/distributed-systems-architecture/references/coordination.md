# Coordination & Consensus

Coordination is how independent nodes agree on something — who's the leader, who
holds a lock, who's a member, what order events happened in. It's powerful and
necessary for a handful of problems, and it's also the most over-reached-for tool in
distributed systems. The first job of this file is to help you **avoid** coordination
where you can, and get it right where you can't.

## Contents
- [First, try to avoid it](#first-try-to-avoid-it)
- [Consensus, at a working level](#consensus-at-a-working-level)
- [Leader election](#leader-election)
- [Distributed locks and fencing](#distributed-locks-and-fencing)
- [Service discovery and membership](#service-discovery-and-membership)
- [Time, clocks, and ordering](#time-clocks-and-ordering)
- [Common failure modes](#common-failure-modes)

## First, try to avoid it

Coordination costs latency (round-trips to reach agreement), availability (a quorum
must be reachable), and operational complexity. Before adding it, ask whether the
problem dissolves under a different design:

- **Partition ownership instead of locking.** If each key/shard has a single owner
  (consistent hashing, partition assignment), you get serialized access per key
  without a distributed lock.
- **Idempotency instead of exactly-once coordination.** If duplicate work is
  harmless, you don't need to coordinate to prevent it.
- **Let the database do it.** A unique constraint, conditional update, or
  `SELECT ... FOR UPDATE` in a single strongly-consistent store solves many "we need
  a lock" problems without a separate coordination system.
- **CRDTs instead of agreement.** For some data (counters, sets), conflict-free
  replicated data types converge without coordination at all.

When you *do* need agreement — a single leader, a globally unique decision, cluster
membership — reach for a proven system rather than rolling your own.

## Consensus, at a working level

Consensus lets a group of nodes agree on a value (or an ordered log of values) even
as some fail. You rarely implement it; you *use* it (via etcd, ZooKeeper, Consul, or
a database built on it). But understanding it prevents misuse.

- **Raft** — the one to understand, because it's designed to be understandable. A
  single elected leader accepts writes, replicates an append-only log to followers,
  and a write commits once a **majority (quorum)** acknowledges it. On leader
  failure, followers hold an election (randomized timeouts avoid split votes). Key
  consequences: you need an odd number of nodes (3 or 5) to tolerate 1 or 2 failures;
  the system needs a majority reachable to make progress (a minority partition goes
  read-only or unavailable — this is CAP choosing C).
- **Paxos / Multi-Paxos** — the older, foundational family; harder to reason about,
  same guarantees. Multi-Paxos underlies systems like Spanner and Chubby.
- **Quorums** — the shared idea: require overlapping majorities so any two decisions
  intersect. Note that a *read/write quorum* in a Dynamo-style store (R+W>N) is not
  the same as consensus and does **not** give linearizability on its own.

Consensus systems (etcd/ZooKeeper/Consul) are the right home for small amounts of
critical metadata: leader locks, configuration, membership, feature flags. They are
**not** databases — don't put high-volume application data in them.

## Leader election

Many designs need exactly one node doing something at a time: a scheduler, a
sequence generator, the writer to a partition, a cron that must not double-fire.

- **Do it via a consensus store**, not homegrown heartbeats. etcd/ZooKeeper/Consul
  provide election primitives (leases, ephemeral nodes) with the correctness already
  worked out.
- **A leader can become a bottleneck and a single point of failure** — make failover
  fast and make sure a single leader has enough capacity, or partition the work so
  there are many leaders (one per shard).
- **The dangerous window** is after a leader is presumed dead but might still be
  alive (a GC pause or network blip, not a real death). Two nodes both think they're
  leader — **split brain**. Leases with timeouts reduce it; fencing tokens (below)
  make the stale leader's actions safe to reject.

## Distributed locks and fencing

Distributed locks are trickier than they look, because the lock holder can pause
(GC, VM freeze) or get partitioned *after* acquiring the lock and *before* finishing
its work; the lock expires, someone else acquires it, and now two workers act at
once.

- **Always use a fencing token.** The lock service hands out a monotonically
  increasing number with each grant; the protected resource records the highest
  token it has seen and **rejects any write with a lower token**. This makes a
  stale lock holder's late write harmless even if it still thinks it holds the lock.
  A lock without fencing is not safe against pauses.
- **Prefer a lock service with proper semantics** (etcd/ZooKeeper leases) over a
  single Redis key. Single-instance Redis locks (SETNX) are fine for best-effort/
  efficiency ("avoid duplicate work usually") but not for correctness. Redlock is
  contested; don't rely on it for anything where a double-execution is unacceptable.
- **Ask if you need the lock at all** — see "avoid it" above. Often a conditional DB
  write with the same fencing idea (a version column) is simpler and safer.

## Service discovery and membership

- **Service discovery** — how services find each other's current endpoints as
  instances come and go. Client-side (query a registry like Consul/etcd, or DNS) or
  server-side (a load balancer / mesh sidecar owns it). In Kubernetes this is mostly
  handled for you (Services + DNS).
- **Membership & failure detection** — knowing which nodes are alive. Heartbeats and
  gossip protocols (SWIM, used by Serf/Consul) scale this. The hard part is that you
  **cannot distinguish a slow node from a dead one** — a node that's just slow or
  partitioned looks dead. Tune failure detectors to trade false positives (evicting
  healthy nodes, causing churn) against slow detection, and design so a mistaken
  eviction is recoverable.

## Time, clocks, and ordering

Wall-clock time is not a reliable ordering mechanism across machines — clocks drift,
NTP corrects in jumps, and "later timestamp" does not mean "happened after."

- **Don't order events across nodes by wall-clock timestamps.** It causes subtle,
  data-losing bugs (e.g. last-write-wins picking the wrong write).
- **Logical clocks** — **Lamport clocks** give a total order consistent with
  causality (if A caused B, A's counter < B's); **vector clocks** can also *detect*
  concurrency (whether two events are causally related or truly concurrent), at the
  cost of size-O(nodes) metadata.
- **Hybrid logical clocks (HLC)** combine physical time with a logical counter so
  timestamps are both roughly wall-clock-meaningful and causally ordered — a good
  default for ordering in modern systems.
- **Bounded-uncertainty clocks** — Google Spanner's TrueTime exposes a time
  *interval* and waits out the uncertainty to give globally consistent commit
  ordering; this is what buys Spanner external consistency, at the cost of specialized
  infrastructure and commit-wait latency.

## Common failure modes

- **Reinventing consensus** with heartbeats and timeouts → subtle split-brain bugs.
  Use etcd/ZooKeeper/Consul.
- **Locks without fencing tokens** → a paused/partitioned holder's late write
  corrupts state after the lock expired.
- **Even number of consensus nodes** → no fault-tolerance gain and worse split-vote
  behavior; use 3 or 5.
- **Treating a coordination store as a database** → overloading etcd/ZooKeeper with
  high-volume data starves the critical metadata it's meant to hold.
- **Ordering by wall clock** → clock skew silently reorders or drops events.
- **Aggressive failure detectors** → healthy-but-slow nodes evicted, causing
  rebalancing churn and cascading load.
- **Single leader with no capacity plan** → the elected leader is the bottleneck;
  nothing scales past it.
