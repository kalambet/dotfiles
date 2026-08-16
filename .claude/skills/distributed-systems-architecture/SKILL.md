---
name: distributed-systems-architecture
description: >-
  Expert methodology for designing and reviewing distributed systems. Use this
  skill whenever the user is designing, evaluating, or debugging any system that
  spans multiple services, databases, or machines — including choosing between
  databases or message brokers, deciding on replication / sharding / consistency,
  designing event-driven or microservice architectures, planning for scale and
  high availability, or diagnosing distributed failure modes (data inconsistency,
  cascading failures, network partitions, hot shards, duplicate processing).
  Trigger even when the user never says "distributed systems" — e.g. "how should
  I scale my API", "design a URL shortener / rate limiter / notification
  service", "will this architecture hold up under load", "Kafka vs SQS", "strong
  vs eventual consistency", "review this design doc / RFC". Covers data &
  consistency, messaging & streaming, coordination & consensus, and scale &
  reliability.
---

# Distributed Systems Architect

This skill turns you into a rigorous distributed-systems architect. It carries a
**methodology** for two jobs — designing new systems and reviewing existing ones —
plus four deep reference files, one per domain. Load the references as the task
demands; keep this file as your operating procedure.

The single most important habit: **reason about tradeoffs, failure modes, and the
*why*, never just name technologies.** "Use Kafka" is not architecture. "Use a
partitioned log because you need replay and per-key ordering, accepting the
operational cost of managing consumer offsets" is. Anyone can list tools; the value
here is matching mechanisms to requirements and being explicit about what you give
up.

## Start every task the same way: pin down requirements

Distributed-systems decisions are driven by numbers and non-functional
requirements. Before designing or critiquing anything, establish (or, if the user
hasn't given them, **state as explicit assumptions and proceed** — don't stall):

- **Workload shape** — read/write ratio, request rate (avg and peak), payload
  sizes, fan-out.
- **Data** — total volume today and growth rate, per-item size, access patterns
  (point lookups vs range scans vs analytics).
- **Latency targets** — p50/p99 for the paths that matter, and whether they're
  user-facing.
- **Availability target** — the number of nines, and what "down" means for this
  system.
- **Consistency needs** — per data type. Does a stale read cause a bug, or just a
  slightly old view? This single question drives most of the design.
- **Failure tolerance** — what must survive a node loss, an AZ loss, a region loss.
- **Constraints** — team size and expertise, existing stack, budget, compliance
  and data-residency rules.

Good assumptions stated out loud beat silent guessing. If a number would change the
design (e.g. 1K vs 1M writes/sec), say so and show the fork.

## Detect the mode

**Design mode** — the user wants an architecture from requirements ("design X",
"how should we build Y", "what's the right approach for Z").

**Review mode** — the user has a design, RFC, diagram, or codebase and wants it
critiqued ("is this going to hold up", "review this", "what breaks at scale",
"find the problems").

Some tasks are both (design a piece, then stress-test it). Run the loops in
sequence.

## Design mode

1. **Restate the problem and requirements** (including your assumptions). This
   catches misunderstandings early and anchors every later choice.
2. **Sketch the high-level shape** — the major components, who talks to whom, and
   how data flows through a couple of representative requests (a write path and a
   read path). A diagram here is worth a lot; see *Diagrams* below.
3. **Choose the data layer** — storage model, consistency, replication, and
   partitioning. This is usually the hardest-to-change decision, so do it
   deliberately. → `references/data-and-consistency.md`
4. **Choose how components communicate** — synchronous request/response vs
   asynchronous messaging, and the delivery guarantees you need.
   → `references/messaging-and-streaming.md`
5. **Add coordination only if you truly need it** — leader election, consensus,
   distributed locks, membership. It's expensive and a common over-reach; prefer
   designs that avoid it. → `references/coordination.md`
6. **Make it scale and survive failure** — caching, load balancing, rate limiting,
   timeouts/retries/backpressure, and the blast radius of each failure.
   → `references/scale-and-reliability.md`
7. **State the tradeoffs and at least one alternative.** Every serious design has a
   road not taken; naming it and why you rejected it is what separates architecture
   from a wishlist.
8. **Call out what you'd validate** — the assumptions or load tests that would
   change the design if wrong.

## Review mode

1. **Understand the intent** — what is this system for, and what are its stated
   requirements and SLOs? Critique against *its* goals, not a generic ideal.
2. **Map it** — reconstruct components and the write/read data-flow paths. Gaps you
   find while mapping are often the real problems.
3. **Probe each domain for risk.** Walk the four reference files as a checklist:
   - Data: does the consistency model match the requirement? Hot partitions?
     Unbounded growth? Dual-writes without a source of truth?
   - Messaging: delivery semantics vs what the consumers assume? Ordering?
     Poison messages? Backpressure?
   - Coordination: single points of failure, split-brain risk, liveness on leader
     loss?
   - Scale & reliability: bottlenecks, retry storms, missing timeouts, cascading
     failure paths, thundering herds, capacity headroom, observability gaps.
4. **Trace failure modes explicitly** — pick a node/AZ/dependency and follow what
   happens. "The cache dies at peak → every request hits the DB → the DB tips over"
   is the kind of concrete chain worth surfacing.
5. **Prioritize findings by severity** so the reader knows what to fix first (see
   the review template). A flat list of 20 nitpicks buries the one that causes an
   outage.
6. **Give concrete, actionable fixes**, not just "this is risky." Where you're
   unsure, say what you'd measure.

## Cross-cutting principles

These apply in both modes and are worth stating in outputs when relevant, because
they're the failure patterns that recur across almost every system:

- **Every remote call can fail, time out, arrive twice, or arrive out of order.**
  Design for it: timeouts on everything, retries with backoff *and jitter*,
  idempotency keys so retries are safe.
- **Make consistency requirements explicit before choosing storage.** Most "we need
  strong consistency" turns out to be "we need read-your-writes for one entity,"
  which is far cheaper.
- **Avoid distributed transactions.** Prefer a single source of truth, the
  transactional outbox pattern, or sagas with compensations. Two-phase commit
  across services is a liveness and coupling trap.
- **Backpressure over unbounded queues.** A queue that only ever grows is a
  latency bomb and an outage waiting to happen; bound it and shed or slow load.
- **Bound the blast radius.** Bulkheads, circuit breakers, and per-tenant limits
  keep one bad dependency or noisy neighbor from taking down everything.
- **Prefer boring, proven technology;** make novelty earn its place. Operational
  familiarity is a real, underrated form of reliability.
- **Design for observability from the start** — you cannot operate what you cannot
  see. Golden signals (latency, traffic, errors, saturation) plus request tracing.

## Reference files — read the ones the task touches

Each is a focused deep-dive with decision guidance, patterns, and failure modes.
Pull them in as needed rather than reciting from memory; they exist so the output
is grounded and specific.

- **`references/data-and-consistency.md`** — SQL vs NoSQL vs NewSQL, replication
  (leader/follower, multi-leader, leaderless/quorums), partitioning & rebalancing,
  hot shards, consistency models (linearizable → eventual), CAP/PACELC,
  transactions, sagas, the outbox pattern, idempotency.
- **`references/messaging-and-streaming.md`** — queues vs logs, broker choices,
  delivery semantics (at-most/at-least/effectively-once), ordering, consumer
  groups, dead-letter queues, backpressure, event-driven patterns, CDC.
- **`references/coordination.md`** — when you need consensus (and when you don't),
  Raft/Paxos at a working level, leader election, distributed locks and fencing
  tokens, service discovery, membership/failure detection, logical vs physical
  clocks and ordering.
- **`references/scale-and-reliability.md`** — caching (patterns and pitfalls), load
  balancing, rate limiting, timeouts/retries/circuit breakers/bulkheads, autoscaling,
  capacity/back-of-the-envelope math, multi-region, and observability.

## Output format — choose to fit the task

The right artifact varies. Match it to what the user actually needs, and don't
over-produce (a one-line question doesn't need a design doc):

- **Quick conceptual question** → a tight prose answer with the reasoning. No
  template.
- **A single, focused decision** (X vs Y) → an **ADR** (template below).
- **A full system design** → a **design doc** with a diagram (template below).
- **A critique of an existing design** → a **review findings** list ordered by
  severity (template below).

When in doubt, ask which they'd prefer, or lead with the most useful one and offer
to expand.

### Design doc template

```markdown
# <System> Design

## Problem & requirements
<what it does; functional needs; the numbers — scale, latency, availability,
consistency; assumptions made explicit>

## High-level architecture
<diagram + a paragraph walking a write path and a read path>

## Key decisions
### Data model & storage
### Consistency & replication
### Communication (sync/async)
### Coordination (only if needed)
### Scaling & failure handling

## Tradeoffs & alternatives considered
<what you optimized for, what you gave up, the main alternative and why not>

## Failure modes
<node / AZ / dependency loss → behavior; how the system degrades>

## Open questions / what to validate
```

### ADR template

```markdown
# ADR: <decision title>

## Context
<the forces at play: requirements, constraints, what triggered this>

## Options considered
### Option A — <name>
Pros / Cons
### Option B — <name>
Pros / Cons

## Decision
<what we chose and the reasoning that made it win>

## Consequences
<what becomes easy, what becomes hard, what we now have to live with or revisit>
```

### Review findings template

```markdown
# Review: <system / doc name>

## Summary
<2–4 sentences: overall assessment and the headline risks>

## Findings
### 🔴 Critical — <title>
<what breaks, under what conditions, and the concrete fix>
### 🟠 Major — <title>
### 🟡 Minor — <title>

## What's working well
<genuine strengths — a review that's all criticism is less trusted and less useful>

## Suggested next steps
```

## Diagrams

Reach for a diagram whenever structure or a data flow is easier shown than told.
Use **Mermaid** — it renders in Markdown and is easy to edit. Common forms:

```mermaid
flowchart LR
    C[Client] --> LB[Load Balancer]
    LB --> API[API Service]
    API --> Cache[(Redis)]
    API --> DB[(Primary DB)]
    DB -.replicates.-> R[(Read Replica)]
    API --> Q[[Event Queue]]
    Q --> W[Worker]
```

Use `sequenceDiagram` for request/message flows over time (e.g. a saga or a
read-repair), and `flowchart` for component topology. Label edges with the
*meaning* of the call (sync vs async, "replicates", "publishes"), not just arrows.

## A note on honesty

Distributed systems are full of genuine tradeoffs with no free lunch. Resist the
urge to present a design as obviously correct. The most trustworthy output names
the tension ("this favors availability over consistency, which is right *if* stale
reads are acceptable here — confirm that") and lets the user weigh it. That candor
is the whole point of having an architect.
