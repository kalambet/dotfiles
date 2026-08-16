# Architecture: Model, Prompting, Context, Guardrails, Failure Modes

This file covers the cross-cutting decisions every LLM system makes regardless of
shape: which model, how to prompt it, how to assemble what it sees, how to keep
it safe, and how it fails. Read it for any design.

## Table of contents

- Model selection
- Prompting strategy
- Context assembly (the context window is a budget)
- Structured output and contracts
- Guardrails and safety
- Latency and cost engineering
- Failure-mode checklist

## Model selection

Choose models by *capability tier and constraints*, not by brand loyalty.
Reason about these axes and let the requirements pick the tier:

- **Capability needed.** Does the task need frontier reasoning (multi-step logic,
  ambiguous instructions, code), or is it a well-defined transformation
  (classification, extraction, formatting) a smaller/cheaper model nails? Don't
  pay frontier prices for a routing task.
- **Latency budget.** Interactive chat, an autocomplete, and an overnight batch
  job have wildly different tolerances. Smaller models and shorter outputs are
  the biggest levers.
- **Context length.** How much must the model see at once? This can rule tiers
  in or out.
- **Modality.** Text only, or images / audio / structured inputs?
- **Deployment constraints.** Data residency, on-prem/self-hosted requirements,
  or the ability to fine-tune may force open-weight models.
- **Cost at scale.** Per-token price × expected volume. Often the deciding factor
  once quality is "good enough".

**Routing pattern:** it's common and cheap to use a small model to triage/route
and escalate only hard cases to a frontier model. Design this in when volume is
high and most requests are easy. State it as a decision with its trade-off
(added complexity, a routing-error failure mode) rather than assuming it.

**When to fine-tune vs. prompt/retrieve.** Prefer prompting and retrieval first —
they're faster to iterate and easier to debug. Reach for fine-tuning only when
you need a *behavior or format* that prompting can't reliably produce, you have
good training data, and the task is stable. Fine-tuning teaches *how to behave*;
retrieval supplies *what to know*. Don't fine-tune to inject knowledge that
changes often — that's retrieval's job.

## Prompting strategy

The prompt is architecture. Specify it deliberately:

- **System prompt** defines role, task, constraints, tone, and output contract.
  Keep it stable across requests so it's cacheable and testable.
- **Few-shot examples** are the highest-leverage quality lever for format and
  edge-case behavior. Include them when the task has a specific shape or the
  model keeps making the same mistake. Curate them; a few sharp examples beat
  many mediocre ones.
- **Decomposition.** If a single prompt juggles too many objectives, split it
  (see the pipeline rung in `decision-guide.md`). Each call should have one clear
  job you can eval independently.
- **Reasoning space.** For hard tasks, let the model reason before it answers
  (or use a reasoning-capable model). Don't force a terse answer on a task that
  needs thinking; don't pay for reasoning on a task that doesn't.

## Context assembly (the context window is a budget)

Everything the model sees each turn competes for the same finite window and every
token costs latency and money. Treat context as a curated budget, not a dumping
ground:

- **Relevance over volume.** More context is not better. Irrelevant or
  contradictory context degrades quality ("context rot") and buries the signal.
  Retrieve/assemble the *smallest* set that answers the task.
- **Position matters.** Models attend unevenly across a long context; critical
  instructions and the most relevant evidence should be placed where they're
  reliably used (typically the system prompt and near the query), not buried in
  the middle of a huge dump.
- **Order of assembly.** A typical assembly is: system prompt (role + contract) →
  durable context (relevant retrieved knowledge, tool definitions) → conversation
  history (possibly summarized) → the current user query. Be explicit about what
  goes where and why.
- **History management.** Long conversations overflow the window. Decide the
  strategy up front: sliding window, running summary, or retrieval over past
  turns. Each loses something; name it.
- **Caching.** Keep the stable prefix (system prompt, tool defs, static context)
  constant so it can be cached — a large latency and cost win at scale. Design
  the prompt so the volatile part is at the end.

## Structured output and contracts

If a downstream system consumes the model's output, define a **contract**
(schema) and enforce it. Prefer constrained/structured output where available.
Always design for contract violation: the model will occasionally emit malformed
output, so specify validation and a retry/repair or fallback path. A system that
assumes perfectly-formed output is a system with a latent outage.

## Guardrails and safety

Scale guardrails to the stakes you identified in discovery. A brainstorming toy
and an agent that can issue refunds need very different rigor.

- **Input guardrails.** Validate/scope inputs; detect and defang **prompt
  injection**, especially when the model consumes untrusted content (retrieved
  documents, web pages, user files, tool outputs). Treat all such content as
  potentially adversarial — it may contain instructions aimed at your model.
- **Output guardrails.** Check outputs before they reach users or act on the
  world: policy/safety filters, PII checks, factuality/grounding checks for
  knowledge systems, and schema validation.
- **Action guardrails.** For any tool that writes, spends, deletes, or sends:
  require confirmation for high-impact actions, enforce least-privilege scopes,
  make destructive operations reversible or dry-runnable, and rate-limit. Never
  let an autonomous loop take irreversible high-stakes actions without a human
  gate.
- **Grounding.** For knowledge systems, require the model to answer *only* from
  retrieved context and to say "I don't know" when the context doesn't support an
  answer. This is your main lever against confident hallucination.

## Latency and cost engineering

Design these in; they're not afterthoughts:

- **Streaming** improves *perceived* latency dramatically for interactive uses.
- **Parallelize** independent calls (e.g. fan-out retrieval, independent
  sub-tasks) instead of serializing them.
- **Cache** at multiple levels: prompt-prefix caching, semantic caching of
  repeated queries, and embedding caches.
- **Right-size models per step.** The cheapest model that passes eval for a step
  is the right one for that step.
- **Bound the loop.** Agentic loops need hard caps on steps/tokens/cost, or a
  single bad run can be arbitrarily expensive.
- **Budget explicitly.** State a target p50/p95 latency and a cost-per-request
  ceiling in the design so trade-offs are anchored to real numbers.

## Failure-mode checklist

Walk this list for every design and say what happens for each. Naming these is
the difference between a junior and a senior design.

- **Hallucination / ungrounded answer** — mitigation: grounding, citation, "I
  don't know", output factuality check.
- **Retrieval miss** (nothing relevant found, or the right doc isn't retrieved) —
  mitigation: fallback behavior, "no answer" path, retrieval evals, hybrid search
  (see `rag.md`).
- **Prompt injection / data exfiltration** via untrusted content — mitigation:
  treat retrieved/tool content as untrusted, input guardrails, least-privilege
  tools.
- **Malformed / contract-violating output** — mitigation: schema validation,
  repair/retry, fallback.
- **Cost or latency blowup** (runaway loop, huge context, retry storms) —
  mitigation: hard caps, budgets, circuit breakers, timeouts.
- **Silent quality regression** (a model/prompt/data change quietly degrades
  quality) — mitigation: offline eval gate in CI, production monitoring (see
  `evals.md`).
- **Data leakage / privacy** (PII in prompts, logs, or outputs; wrong-tenant
  retrieval) — mitigation: PII handling policy, per-tenant isolation in
  retrieval, log scrubbing.
- **Dependency/tool outage** — mitigation: timeouts, graceful degradation, cached
  or default responses.
