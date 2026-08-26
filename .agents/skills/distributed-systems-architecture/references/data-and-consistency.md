# Data & Consistency

Storage and consistency are usually the hardest-to-change decisions in a system, so
they deserve the most care. This file covers picking a data store, replicating and
partitioning data, the consistency models you're choosing between, and how to keep
data correct across services without distributed transactions.

## Contents
- [Choosing a data store](#choosing-a-data-store)
- [Replication](#replication)
- [Partitioning (sharding)](#partitioning-sharding)
- [Consistency models](#consistency-models)
- [CAP and PACELC](#cap-and-pacelc)
- [Transactions across services](#transactions-across-services)
- [Idempotency](#idempotency)
- [Common failure modes](#common-failure-modes)

## Choosing a data store

Start from access patterns, not from a favorite database. The question is "what
shapes of read and write does this workload make, and at what scale?"

- **Relational (Postgres, MySQL)** — the right default. Strong single-node
  consistency, flexible queries, transactions, mature ops. Scales vertically a long
  way and horizontally with read replicas and, eventually, sharding. Reach for
  something else only when you have a concrete reason.
- **Document (MongoDB, DynamoDB)** — good when data is naturally hierarchical and
  accessed by key, and when you want horizontal scale and a flexible schema. You
  trade rich cross-entity queries and (often) multi-document transactions.
- **Wide-column (Cassandra, ScyllaDB, Bigtable)** — very high write throughput,
  linear horizontal scale, tunable consistency. You must design tables around
  queries up front; ad-hoc queries are painful. Great for time-series, event logs,
  large-scale writes.
- **Key-value (Redis, DynamoDB)** — fastest point access; use as a cache, session
  store, or for simple lookups.
- **NewSQL / distributed SQL (Spanner, CockroachDB, TiDB, Yugabyte)** — SQL and
  transactions *with* horizontal scale and strong consistency. The cost is
  operational complexity and, for cross-region strong consistency, write latency
  (commit waits). Choose when you genuinely need both relational semantics and
  scale-out.
- **Search (Elasticsearch, OpenSearch)** — full-text and complex filtering. Treat as
  a derived index fed from your source of truth, not the source of truth itself.
- **Analytics / OLAP (ClickHouse, BigQuery, Snowflake, Druid)** — columnar, for
  aggregations over huge datasets. Keep OLTP and OLAP separate; don't run analytics
  on your primary transactional DB.

Rule of thumb: **one source of truth per piece of data.** Everything else
(caches, search indexes, read models) is derived and must be treated as such.

## Replication

Replication buys availability and read scaling, and it's where consistency
questions get real.

- **Single-leader (primary/replica)** — all writes go to the leader, which streams
  a replication log to followers. Simple and the most common. Reads from followers
  scale reads but are *stale* (replication lag). Failover requires promoting a
  follower and risks losing unreplicated writes (with async replication) or split
  brain (if the old leader returns).
  - *Sync vs async replication:* sync guarantees a write survives leader loss but
    blocks on the slowest replica; async is fast but can lose recent writes on
    failover. Semi-sync (ack from at least one replica) is a common middle ground.
  - *Read-your-writes:* a user who just wrote must not read a stale follower. Fix by
    reading from the leader for a short window after a write, or by tracking the
    write position and only reading replicas caught up past it.
- **Multi-leader** — writes accepted at multiple leaders (e.g. per region), replicated
  to each other. Improves write availability and local write latency, but introduces
  **write conflicts** you must resolve (last-write-wins loses data; CRDTs or
  application merge logic preserve it). Use sparingly and only with a conflict story.
- **Leaderless / quorum (Dynamo-style: Cassandra, DynamoDB)** — clients (or a
  coordinator) write to and read from multiple replicas. Tunable consistency via
  quorums: if R + W > N, a read overlaps the latest write. Uses read-repair and
  anti-entropy to converge. Great availability; you manage staleness and conflicts.
  Note quorums don't give you linearizability by themselves.

## Partitioning (sharding)

When data or write throughput outgrows one node, split it across shards. The
partitioning key choice is critical and hard to change later.

- **Hash partitioning** — spreads load evenly, kills range queries. Good default for
  even distribution.
- **Range partitioning** — keeps ranges together (good for scans, time ranges) but
  risks hot spots (e.g. all "today" writes hit one shard).
- **Consistent hashing** — minimizes data movement when nodes are added/removed;
  standard for leaderless stores and caches.

**Hot partitions / hot keys** are the classic sharding failure: one celebrity user,
one popular product, or a monotonic key (timestamp, auto-increment ID) concentrates
load on a single shard. Mitigate by choosing a high-cardinality key, salting/
compositing the key, or splitting hot keys. Watch for keys that *become* hot.

**Rebalancing** as you add capacity should move as little data as possible and stay
online. Fixed-number-of-partitions (many more partitions than nodes, moving whole
partitions) and consistent hashing are the usual approaches. Avoid schemes that
reshuffle everything on every change.

Secondary indexes over partitioned data are either **local** (per-partition; scatter-
gather reads) or **global** (partitioned by the index key; more expensive writes).
Know which you're getting.

## Consistency models

This is the vocabulary that prevents hand-waving. From strongest to weakest:

- **Linearizable (strong)** — the system behaves as if there's one copy and every
  operation takes effect atomically at a point in time. A read sees the latest
  completed write. Easiest to reason about; costs latency and availability (needs
  coordination). Required for things like distributed locks, leader election, unique
  constraints.
- **Sequential / causal** — weaker but often enough. **Causal consistency**
  preserves cause-and-effect ordering (you won't see a reply before the message it
  answers) without the full cost of linearizability. A sweet spot for many apps.
- **Read-your-writes / monotonic reads** — session guarantees: you always see your
  own writes; you never see time go backwards. Cheap to provide and fixes the most
  common user-visible anomalies from replication lag.
- **Eventual consistency** — replicas converge *eventually* if writes stop. Maximum
  availability and performance; you must ensure the temporary anomalies are
  acceptable for that data (a like count can be eventual; an account balance
  usually can't).

The practical move: **assign a consistency requirement per data type**, then pick
the cheapest model that satisfies it. Most systems mix strong consistency for a few
entities with eventual/causal for the rest.

## CAP and PACELC

CAP: during a **network partition (P)**, a distributed system must choose between
**consistency (C)** and **availability (A)**. It's a statement about the partition
case only — not a license to call a system "AP" or "CP" in general.

**PACELC** is more useful day to day: *if Partition, choose A or C; Else (normal
operation) choose Latency or Consistency.* Even with no partition, stronger
consistency costs latency (coordination round-trips). This "L vs C in the common
case" tradeoff is what you actually tune most of the time.

## Transactions across services

Single-node transactions (ACID) are great — use them within one service's database.
The trouble is atomic changes that span **services or data stores**. Do not reach
for two-phase commit (2PC): it blocks on the coordinator, holds locks across the
network, and couples availability of all participants. Prefer:

- **Keep the transaction inside one service.** The best distributed transaction is
  the one you avoided by putting related data behind one owner.
- **Transactional outbox** — write your state change *and* an "event to publish" row
  in the **same** local transaction; a relay reads the outbox and publishes to the
  broker. This solves the dual-write problem (DB updated but event lost, or vice
  versa) and gives at-least-once delivery. Pair with idempotent consumers.
- **Saga** — model a cross-service workflow as a sequence of local transactions,
  each with a **compensating action** to undo it. *Orchestrated* (a coordinator
  drives steps) is easier to reason about and observe; *choreographed* (services
  react to each other's events) is more decoupled but harder to follow. Sagas give
  you eventual consistency with well-defined rollback, not isolation — design for
  intermediate states being visible.
- **CDC (change data capture)** — stream the DB's commit log (e.g. Debezium) to
  derive events, indexes, and read models from a single source of truth without
  dual writes.

## Idempotency

Because retries and at-least-once delivery are unavoidable, operations that change
state should be **idempotent** — applying them twice has the same effect as once.
Techniques: idempotency keys (client sends a unique key; server dedupes),
conditional writes / compare-and-set, upserts keyed by a natural id, and dedup
tables with TTLs. This is the single most effective defense against the duplicate-
message and double-charge class of bugs.

## Common failure modes

- **Dual writes** — writing to two stores (DB + cache, DB + search, DB + broker)
  without a single source of truth; they drift. Fix with outbox/CDC and derive.
- **Replication lag surprises** — reading a stale follower right after a write.
  Fix with read-your-writes routing.
- **Hot shard** — skewed key concentrates load. Fix the key.
- **Unbounded growth** — a table/partition that only grows (events, logs) with no
  TTL or archival plan eventually degrades everything.
- **Last-write-wins data loss** — silent conflict resolution dropping concurrent
  updates. Know when LWW is in play.
- **"Strong consistency" cargo-culting** — paying linearizability's latency/
  availability cost for data that only needed read-your-writes.
