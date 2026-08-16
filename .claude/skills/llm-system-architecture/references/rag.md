# Retrieval-Augmented Generation (RAG) Design

Read this when the system needs knowledge that's too large, too fresh, or too
private to sit in the prompt. RAG grounds a model in external knowledge; it does
not make a model reason better. Keep that boundary in mind — if the user's
problem is reasoning quality, RAG is the wrong tool.

## The mental model

RAG has two halves that fail for different reasons:

1. **Retrieval** — given a query, find the right knowledge. Failures here are
   *"we didn't fetch the right thing."*
2. **Generation** — given the query + fetched knowledge, produce a grounded
   answer. Failures here are *"we had the right thing and still answered wrong."*

Most RAG quality problems are retrieval problems wearing a generation costume.
When someone says "our RAG hallucinates," the first question is almost always
"did the right chunk make it into context?" Design and eval the two halves
*separately* (see the retrieval-specific evals below and in `evals.md`).

## Design decisions, in order

### 1. What is a "document" and what is a "chunk"?

Chunking is the highest-leverage and most-underestimated decision. You're
splitting source knowledge into retrievable units. Get this wrong and no amount
of model quality saves you.

- **Chunk around meaning, not arbitrary length.** Split on natural boundaries —
  sections, paragraphs, headings, list items, function/class for code — so each
  chunk is a self-contained idea. Fixed-size character splits that cut sentences
  in half are a classic quality killer.
- **Size trade-off.** Small chunks give precise retrieval but may lack context to
  be useful; large chunks carry context but dilute relevance and waste the window.
  There's no universal number — it depends on the content. Pick a starting point,
  then *let retrieval evals tune it*.
- **Overlap** between adjacent chunks preserves context across boundaries at the
  cost of duplication. Modest overlap is a reasonable default.
- **Preserve metadata** on each chunk: source, title, section, date, permissions.
  You'll need it for filtering, citation, and access control.
- **Consider context enrichment.** Prepending a short summary of the parent
  document/section to each chunk ("contextual retrieval") often improves recall
  because the chunk no longer relies on ambient context to be findable.

### 2. How is knowledge represented for search?

- **Dense (embedding) search** captures semantic similarity — it finds things
  that *mean* the same even with different words. Great for paraphrase and
  concept matching. Weak on exact terms, rare identifiers, codes, and names.
- **Sparse / keyword search (e.g. BM25-style)** nails exact terms, IDs, acronyms,
  and rare tokens dense search glosses over.
- **Hybrid search** combines both and is the pragmatic default for most corpora,
  because real queries mix conceptual and exact-match needs. Recommend hybrid
  unless the corpus is clearly one-sided, and name the fusion approach (e.g.
  weighted or rank-fusion).
- **Embedding model choice** matters: domain fit (general vs. code vs.
  biomedical), dimensionality vs. cost, and max input length. Keep the embedding
  model consistent between indexing and querying — mismatches silently wreck
  retrieval.

### 3. Where does it live? (the vector store / index)

Choose the store by *requirements*, stated as a category not a brand: scale
(thousands vs. billions of vectors), filtering needs (metadata/permission
filters at query time), latency, update pattern (batch reindex vs. streaming
upserts), and operational ownership (managed service vs. self-hosted, or a
capability bolted onto a database you already run). For many systems, a vector
capability inside an existing datastore beats introducing a new dependency.

### 4. Retrieval quality boosters (add only if evals show you need them)

- **Reranking.** Retrieve a generous candidate set with fast search, then use a
  (more expensive) cross-encoder reranker to reorder by true relevance and keep
  the top few. This is one of the most reliable quality wins — precision goes up
  without hurting recall. Add it when the right chunk is being retrieved but
  ranked too low to survive the context cut.
- **Query transformation.** The user's raw query is often a poor search query.
  Options: rewrite/expand it, generate multiple query variants and merge results,
  or (for multi-part questions) decompose into sub-queries. Helps most when
  queries are terse, conversational, or compound.
- **Metadata filtering.** Constrain retrieval by date, source, type, or —
  critically — *permissions/tenant*, so users only retrieve what they're allowed
  to see. Access control at retrieval time is a security requirement, not a
  feature.
- **Multi-hop / iterative retrieval.** For questions that require chaining facts,
  retrieve, reason, then retrieve again. Powerful but adds latency and
  complexity; reach for it only when single-shot retrieval demonstrably can't
  answer the questions.

### 5. Generation on top of retrieval

- **Ground hard.** Instruct the model to answer *only* from the provided context
  and to say it doesn't know when the context doesn't support an answer. This is
  the primary defense against confident hallucination.
- **Cite.** Have the model attribute claims to the chunks it used. Citations make
  answers verifiable and make retrieval failures visible.
- **Handle "no good context".** Define what happens when retrieval returns
  nothing relevant — a graceful "I couldn't find this" beats a fabricated answer.
- **Guard the context.** Retrieved documents are untrusted input; they can carry
  prompt-injection payloads. See guardrails in `architecture.md`.

## Evaluating RAG (summary — details in evals.md)

Eval the two halves separately or you'll chase the wrong fix:

- **Retrieval metrics:** did the right chunk make it into the retrieved set, and
  how highly ranked? Use recall@k and precision@k, plus a rank-aware measure like
  MRR or nDCG. Build this from query→relevant-chunk pairs.
- **Generation metrics (given retrieved context):** faithfulness/groundedness (is
  every claim supported by the context?), answer relevance (does it address the
  question?), and citation correctness.
- **End-to-end:** correctness against known answers, plus "no-answer" behavior on
  questions the corpus can't answer (the system should decline, not invent).

## Common RAG failure modes and their real fixes

- **"It hallucinates."** Usually retrieval missed → improve chunking, add hybrid
  search, add reranking, transform the query. Grounding instructions help but
  can't fix missing evidence.
- **"It retrieves irrelevant stuff."** Precision problem → reranking, better
  chunk boundaries, metadata filters, tighter query.
- **"It can't find things it should."** Recall problem → chunking, hybrid search,
  contextual enrichment, embedding-model fit.
- **"Answers are stale."** Index freshness → reindexing/upsert strategy and
  document TTLs.
- **"It's slow/expensive."** Retrieve fewer, rerank fewer, cache embeddings and
  frequent queries, right-size the generation model.
