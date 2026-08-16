# Design Document Template

Produce the design using this structure. It is decision-first: the reader grasps
*what* you're recommending and *why* from the top, then drills into detail. Lead
with conclusions, not process. Cut sections that don't apply (say so briefly
rather than padding), and never present a menu of undifferentiated options where
a recommendation is expected — take a position and defend it.

Adapt depth to the ask. A quick design review needs the summary, the key
decisions, and the risks; a full greenfield design uses everything.

---

```markdown
# [System name] — LLM System Design

## 1. Summary
- **What we're building:** one or two sentences on the system and the job it does.
- **Recommended shape:** the chosen architecture in a phrase (e.g. "RAG over the
  policy corpus with a reranker, single generation call, LLM-judge eval gate").
- **Why this and not more:** the one-line reason this is the simplest shape that
  fits, and the main thing it deliberately does NOT do.
- **Top risks:** the 2–3 things most likely to bite, named up front.

## 2. Problem & requirements
- **Job to be done** and who it's for.
- **What "good" looks like** in the user's words (made measurable in §6).
- **Inputs & knowledge sources:** what the system must know and where that lives.
- **Constraints:** latency budget (p50/p95), cost ceiling, scale (req/day),
  privacy/compliance/residency, who operates it.
- **Stakes:** cost of a wrong answer or wrong action — this sets the rigor level.
- **Current state:** greenfield, or what's failing today.

## 3. Recommended architecture
- **Overall shape and why** (reference the ladder: why this rung, why not one
  lower, why not one higher).
- **Component diagram / data flow.** Describe the flow from input to output; a
  simple text or Mermaid diagram is fine. Show where knowledge enters and where
  actions happen.
- **Components.** For each: what it does, why it's here, and the main alternative
  rejected. Cover whichever apply:
  - Model(s) and tiers (per step), and any routing.
  - Retrieval design (chunking, embeddings, hybrid search, reranking, query
    transformation) — if RAG.
  - Agent/orchestration design (tools, loop control, memory, human gates) — if
    agentic.
  - Prompting strategy and context assembly (what goes in the window, in what
    order, history handling, caching).
  - Structured output / contracts with downstream systems.

## 4. Key decisions & trade-offs
A short table or list of the decisions that actually mattered. For each:
**decision → alternative considered → why chosen → what it costs.**
This is the heart of the doc — a reader should be able to challenge any decision
here and see the reasoning. Don't hide the costs.

## 5. Guardrails & the unhappy path
- Input, output, and action guardrails appropriate to the stakes.
- Failure-mode table: for each relevant failure (hallucination, retrieval miss,
  prompt injection, malformed output, cost/latency blowup, data leakage, silent
  regression, dependency outage) → what the design does about it.

## 6. Evaluation & observability plan
- **Measurable definition of "good"** (from §2, now concrete).
- **Eval dataset:** sources, size, how ground truth is set, held-out slice.
- **Offline metrics & graders** per component (retrieval vs. generation, or
  trajectory vs. outcome, where relevant).
- **Regression gate:** what runs on changes and what blocks a ship.
- **Production monitoring:** what's logged, which live signals are scored, key
  operational metrics, alert thresholds.
- **Budgets:** target latency (p50/p95) and cost per request.

## 7. Cost & latency estimate
Rough per-request and at-scale numbers based on the chosen models/steps, so the
constraints in §2 are actually checked, not just stated.

## 8. Phasing / what to build first
The smallest version that delivers value and can be measured (often simpler than
the full design), then what to add once evals and production data justify it.
Resist shipping the whole complex design at once.

## 9. Open questions
Decisions that depend on information not yet available, and what you'd need to
resolve each.
```

---

## Style notes for writing the doc

- **Recommend, don't enumerate.** The reader is paying you for judgment. Where
  you genuinely can't decide without more info, put it in Open Questions with what
  you'd need — don't punt the whole decision to a menu.
- **Every "why" earns its component.** If you can't state the problem a component
  solves, delete it from the design.
- **Name the cost of every decision.** A trade-off with no downside listed is a
  trade-off you haven't finished thinking through.
- **Keep it vendor-neutral** unless the user gave you a stack; name tools as
  examples of a category and say so.
- **Match length to stakes.** Don't inflate a small design; don't thin out a
  high-stakes one.
