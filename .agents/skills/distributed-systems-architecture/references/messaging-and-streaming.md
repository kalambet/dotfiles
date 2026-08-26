# Messaging & Streaming

Asynchronous messaging decouples services in time, absorbs load spikes, and enables
event-driven architectures — but it introduces its own hard problems: delivery
guarantees, ordering, duplicates, and backpressure. This file helps you pick the
right tool and avoid the classic traps.

## Contents
- [Why (and when) async](#why-and-when-async)
- [Queue vs log](#queue-vs-log)
- [Broker selection](#broker-selection)
- [Delivery semantics](#delivery-semantics)
- [Ordering](#ordering)
- [Consumers, groups, and offsets](#consumers-groups-and-offsets)
- [Backpressure and flow control](#backpressure-and-flow-control)
- [Event-driven patterns](#event-driven-patterns)
- [Common failure modes](#common-failure-modes)

## Why (and when) async

Use asynchronous messaging when the caller doesn't need the result immediately, when
you want to smooth spikes (a queue as a shock absorber), when multiple consumers
need the same event, or to decouple deployment and availability of producer and
consumer. Keep things **synchronous** when the caller needs an answer to proceed and
the work is fast — don't add a broker just to feel modern; it's real operational
surface and it turns simple debugging into distributed tracing.

## Queue vs log

This is the fundamental fork, and people conflate them constantly:

- **Message queue (RabbitMQ, SQS, activeMQ, Google Pub/Sub)** — a message is
  delivered to *one* consumer and removed after acknowledgment. The queue is
  work to be done; competing consumers share the load. Little/no history. Great for
  task distribution and RPC-like work dispatch.
- **Log / stream (Kafka, Pulsar, Kinesis, Redpanda)** — an append-only, partitioned,
  *retained* sequence. Consumers read at their own offset and can **replay**.
  Multiple independent consumer groups each read the whole stream. The log is the
  source of events over time. Great for event sourcing, CDC, fan-out to many
  subsystems, stream processing, and anything needing replay or audit.

Pick a **queue** when the semantics are "hand this job to a worker." Pick a **log**
when the semantics are "record that this happened, and let anyone react now or
later." Needing replay, multiple independent consumers, or ordered history is the
tell for a log.

## Broker selection

- **SQS** — fully managed, dead simple, effectively infinite scale, at-least-once,
  no ordering (standard) or limited-throughput FIFO. Best default queue on AWS when
  you don't need a log.
- **RabbitMQ** — flexible routing (exchanges, topics), low latency, mature. You run
  it; scaling and HA take care. Great for complex routing and RPC patterns.
- **Kafka** — the default log. High throughput, durable retention, partitioned
  ordering, huge ecosystem (Connect, Streams). Operationally heavy (though managed
  options exist); overkill for simple task queues.
- **Pulsar** — log + queue semantics, tiered storage, multi-tenancy. Compelling but
  smaller ecosystem.
- **Kinesis / Pub/Sub** — managed log/stream on AWS/GCP; less to run than Kafka,
  fewer knobs.
- **NATS / Redis Streams** — lightweight, low-latency; good for simpler needs where
  Kafka is too much.

Bias toward **managed** unless you have a strong reason and the ops muscle; a broker
is a stateful, availability-critical component.

## Delivery semantics

Be precise here — most bugs come from a consumer assuming stronger semantics than
the broker provides:

- **At-most-once** — fire and forget; messages can be lost, never duplicated.
  Acceptable only for data you can afford to drop (some metrics/telemetry).
- **At-least-once** — the realistic default. Messages are never lost but **can be
  delivered more than once** (a consumer crash after processing but before ack
  causes redelivery). Therefore **consumers must be idempotent** — this is not
  optional.
- **Exactly-once** — genuinely-once *delivery* across a network is impossible in the
  general case. What systems actually offer is **effectively-once processing**:
  at-least-once delivery + idempotent consumers or transactional
  read-process-write (Kafka transactions within Kafka). Treat any "exactly-once"
  claim as "at-least-once plus dedup" and design accordingly.

The takeaway: assume at-least-once, make consumers idempotent (dedup keys,
conditional writes, upserts), and you've defused the whole class.

## Ordering

Global total ordering across a distributed broker is expensive and usually
unnecessary. What you almost always want is **per-key ordering**: events for the
same entity (user, order, account) arrive in order, while different entities proceed
in parallel.

- In a log, this comes from **partitioning by key** — all events for a key go to one
  partition, which is ordered. Order holds *within* a partition, not across.
- Beware anything that breaks per-key order: consumer-side parallelism that
  processes one partition's messages concurrently, retries that reorder, or
  re-keying mid-stream.
- If you need strict ordering, you pay with reduced parallelism (a partition is
  processed serially). Size partitions accordingly.

## Consumers, groups, and offsets

- **Consumer groups** let a set of consumers share partitions of a log for
  horizontal scale; each partition is consumed by one member at a time. Max useful
  parallelism = number of partitions, so choose partition count with future scale in
  mind (increasing it later can disturb keyed ordering).
- **Offset management** — commit offsets *after* successful processing for
  at-least-once; committing before processing gives at-most-once. Auto-commit is a
  common source of silent message loss or duplication — know its timing.
- **Rebalancing** happens when members join/leave; it briefly pauses consumption and
  can cause duplicate processing around the handoff. Idempotency covers you.
- **Dead-letter queues (DLQ)** — after N failed attempts, route a message aside
  rather than blocking the queue or looping forever. Essential; without a DLQ a
  single **poison message** (one that always fails) can stall a whole partition.
  Always plan for reprocessing/alerting on the DLQ.

## Backpressure and flow control

An unbounded queue that grows faster than consumers drain it is a latency bomb and
an outage in slow motion — end-to-end latency climbs without any error until memory/
disk runs out. Design flow control:

- **Bound queues** and decide what happens when full: block the producer, shed load,
  or reject with a clear signal.
- **Let consumers pull** at their own rate (logs do this naturally; consumers read
  when ready) rather than being pushed past capacity.
- **Monitor consumer lag** (offset behind head, or queue depth) as a first-class
  health signal — rising lag is the earliest warning of trouble.
- **Scale consumers** (up to partition count) or shed load upstream when lag grows.

## Event-driven patterns

- **Event notification** — a thin "something happened, go look" event; consumers
  fetch details. Low coupling, more read traffic.
- **Event-carried state transfer** — the event carries the data consumers need, so
  they don't call back. Reduces coupling and read load; risks larger events and
  stale copies.
- **Event sourcing** — persist the *sequence of events* as the source of truth and
  derive current state by folding them. Gives audit, replay, and temporal queries;
  costs complexity (versioning events, rebuilding projections, snapshotting).
  Powerful but don't adopt it reflexively.
- **CQRS** — separate the write model from one or more read models optimized for
  queries, kept in sync via events. Often paired with event sourcing but independent
  of it. Justified when read and write shapes diverge sharply.
- **Outbox** — see `data-and-consistency.md`; the reliable way to publish events
  without dual-write drift.

## Common failure modes

- **Assuming exactly-once** and skipping idempotency → duplicate side effects
  (double charges, double emails) under normal retry conditions.
- **Poison messages with no DLQ** → one bad message blocks a partition forever.
- **Unbounded queue / ignored consumer lag** → silent latency growth, then collapse.
- **Ordering assumptions that don't hold** → processing events for an entity out of
  order (e.g. "delete" before "create").
- **Using a log as a queue (or vice versa)** → e.g. expecting per-message ack/redrive
  semantics from Kafka, or replay from SQS.
- **Too few partitions** → hard ceiling on consumer parallelism discovered under
  load.
- **Synchronous chains disguised as async** → a request that fans out through five
  brokers but the user is still waiting; you got the latency of sync with the
  debuggability of async.
