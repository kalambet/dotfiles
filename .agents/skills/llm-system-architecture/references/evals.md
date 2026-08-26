# Evaluation & Observability

Read this for every design. A system you can't measure is a system you can't
improve, can't safely change, and can't prove is good enough to ship. Evals are a
first-class architectural component, not a phase bolted on at the end. The eval
plan should exist *before* the system ships.

## The core idea

An eval loop is what turns "vibes-based" LLM development into engineering. It
lets you change a prompt, model, or retrieval setting and *know* whether quality
went up or down instead of guessing. Every design this skill produces must answer:
**how will the team know this is good enough, and know when it regresses?**

There are two arenas, and you need both:
- **Offline evals** — run against a fixed dataset before shipping and in CI. They
  gate changes and catch regressions.
- **Online / production monitoring** — measure real traffic after shipping. They
  catch what offline evals miss and track drift over time.

## Step 1: Define "good" as measurable criteria

Vague goals ("high quality," "helpful") can't be measured. Translate the job-to-
be-done into concrete, checkable criteria. Ask: *what would make a domain expert
say this specific output is correct/wrong?* Examples of turning fuzzy into
measurable:

- "Accurate" → "every factual claim is supported by a retrieved source" +
  "matches the known answer on our labeled set."
- "Helpful support reply" → "addresses the customer's actual question,"
  "reflects current policy," "correct tone," "includes next step."
- "Good extraction" → "all required fields present," "values match ground truth,"
  "valid schema."

Write these criteria down; they become your assertions and rubrics.

## Step 2: Build the eval dataset

The dataset is the foundation — a mediocre model with a great eval set beats a
great model flying blind.

- **Sources.** Real production/user queries (best), historical logs, expert-
  written cases, and synthetic/LLM-generated cases to cover rare situations.
  Blend them; anchor on real usage.
- **Coverage.** Include the common "happy path," known hard cases, edge cases,
  and adversarial inputs (prompt injection, out-of-scope questions, empty/garbage
  input). For RAG, include questions the corpus *cannot* answer to test the
  decline-to-answer behavior.
- **Ground truth.** Where an objective answer exists, label it. Where it doesn't
  (open-ended generation), define a rubric instead of a single gold answer.
- **Size.** Start small enough to iterate fast (dozens of cases), grow toward
  broad coverage (hundreds+) as the system matures. A small sharp set beats a
  large sloppy one.
- **Keep a held-out slice** you don't tune against, so you can detect
  overfitting to the eval set.

## Step 3: Choose graders (how each output is scored)

Match the grader to the output type. Most systems use a mix.

- **Code / exact / programmatic.** Deterministic checks: exact match, schema
  validity, numeric tolerance, regex, contains/not-contains, latency and cost
  thresholds. Cheap, fast, reliable — use these wherever the criterion is
  objective. Always prefer a code check over a model judgment when both are
  possible.
- **Human review.** The gold standard for subjective quality, and how you
  *calibrate* automated graders. Expensive, so reserve it for a sample and for
  validating your LLM-judge.
- **LLM-as-judge.** A model scores outputs against a rubric. Scales human-like
  judgment to subjective criteria (faithfulness, tone, helpfulness). Powerful but
  needs care:
  - Give it a **clear, specific rubric** with a defined scale and what each level
    means; vague rubrics give noisy scores.
  - Prefer **binary/low-cardinality judgments** ("is this claim supported: yes/
    no") over fine-grained 1–10 scores, which are noisier and less reproducible.
  - **Pairwise comparison** ("is A or B better?") is often more reliable than
    absolute scoring when comparing two versions.
  - **Validate the judge against human labels** before trusting it, and re-check
    periodically. An un-calibrated judge is just another unmeasured component.
  - Watch for judge biases (position, length, self-preference) and control for
    them.

## Step 4: Metrics by system type

Measure the sub-components, not just the end-to-end output — end-to-end scores
hide *where* the failure is.

**Classification / extraction / routing:** accuracy, precision/recall/F1 per
class, confusion matrix. Schema validity for extraction.

**Generation / summarization / chat:** faithfulness/groundedness, relevance to
the request, completeness, tone/format adherence, and safety. Usually rubric +
LLM-judge, calibrated by human review.

**RAG:** evaluate retrieval and generation *separately* (see `rag.md`).
- Retrieval: recall@k, precision@k, and a rank-aware measure (MRR, nDCG) from
  query→relevant-chunk labels.
- Generation: faithfulness (every claim supported by context), answer relevance,
  citation correctness.
- End-to-end: answer correctness vs. ground truth, and correct decline behavior
  on unanswerable questions.

**Agents:** evaluate the trajectory, not only the endpoint (see `agents.md`).
- Task success rate on a fixed task set.
- Trajectory quality: sensible tool choices, no needless loops, step/cost within
  budget.
- Tool-call correctness (valid args, right tool, right time).
- Safety: respected gates, no unauthorized high-impact actions.
- Robustness on tool errors and junk observations.

## Step 5: Operationalize — make evals part of the workflow

An eval that runs once is a report; an eval that runs on every change is a
safety net.

- **Regression gate.** Run the offline suite automatically on prompt/model/
  retrieval/code changes (in CI). Block merges that drop key metrics. This is how
  you change things without fear.
- **Track over time.** Store scores per version so you can see trends and attribute
  regressions to specific changes.
- **Compare fairly.** When comparing versions, hold the dataset and grader fixed
  and account for run-to-run variance (LLMs are stochastic — average multiple
  runs, report spread).

## Step 6: Production observability

Offline evals can't see everything real users do. After shipping, monitor:

- **Log the full interaction** — inputs, retrieved context, prompts, tool calls,
  outputs, latency, tokens, cost — enough to reconstruct and debug any request.
  (Scrub/handle PII per your privacy policy.)
- **Automated quality signals on live traffic** — sample real outputs and score
  them with your graders (e.g. LLM-judge for groundedness) to catch quality drift
  the offline set doesn't cover.
- **Operational metrics** — p50/p95 latency, cost per request, error/timeout
  rates, tool failure rates, guardrail trigger rates.
- **User feedback signals** — thumbs up/down, edits, escalations, abandonment,
  regeneration rate. Cheap, high-signal, and a source of new eval cases.
- **Alerting and drift detection** — alert on metric drops, cost/latency spikes,
  and shifts in input distribution (users asking new kinds of questions your
  evals don't cover).
- **Close the loop** — feed real failures and interesting production cases back
  into the eval dataset so it keeps reflecting reality.

## What to put in the design doc

For any design, the eval section should name, concretely:
1. The measurable definition of "good" for this system.
2. The eval dataset: where cases come from, how many, how ground truth is set.
3. Offline metrics and graders per component (with the retrieval/generation or
   trajectory/outcome split where relevant).
4. The regression gate: what runs on changes and what blocks a ship.
5. Production monitoring: what's logged, which live signals are scored, key
   operational metrics, and alert thresholds.
6. Latency and cost budgets (p50/p95 and cost-per-request ceilings).
