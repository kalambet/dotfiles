# Design mode

Use this procedure after the shared brief is complete. Engage only relevant
architects; a single-domain design should go directly to its specialist.

Each architect follows `research-plan-implement` for its slice. The team debate
sits between planning and implementation and does not replace either human
checkpoint:

```text
Intake -> Research -> Checkpoint A -> Individual plans -> Debate -> Merge -> Checkpoint B -> Implement
```

## 1. Decompose by domain and interface

Split the system into owned domain slices. Name every cross-domain interface in
`design/brief.md` using the interface table in `templates.md`. The producing and
consuming architects must later agree on payload, sync or async behavior,
consistency, failure semantics, and ownership.

## 2. Research in parallel

Each architect runs the research phase for its slice and writes
`design/research.<domain>.md`, covering the existing system, reusable conventions,
relevant prior art, constraints, numbers, and threats. It must stop before planning.

The facilitator merges these into `design/research.md`, summarizing shared facts,
contradictions, and open questions.

## Checkpoint A: research annotation

Stop for the user to review and annotate `design/research.md`. Do not plan until the
user responds. Feed each annotation to the affected architects and update the
research before continuing.

## 3. Individual plans

After research approval, each architect writes `design/plan.<domain>.md` in its
native format: ADR for Web3, design document for distributed systems, and
decision-first design document for LLM systems.

Every plan must also state:

- Interfaces provided and consumed, with concrete guarantees.
- Requirements imposed on named domains.
- At least one rejected alternative and its trade-off.
- Failure behavior when other components are unavailable, slow, incorrect, or
  adversarial.

Architects stop before production implementation.

## 4. Debate

Run the shared debate protocol, prioritizing:

1. Interface disagreements about payload, ordering, consistency, or failure
   semantics.
2. Conflicting requirements where one domain's guarantee imposes cost or risk on
   another.
3. Duplicated or unnecessary components.

Resolve interface contracts first because they block the rest of the design. A real
trade-off must retain its cost; do not disguise it as a cost-free compromise.

## 5. Merge

Produce one coherent `design/plan.md` using the requirements in `templates.md`.
Merge the plans rather than concatenating them. Preserve contested choices as open
decisions with both positions intact.

## Checkpoint B: plan annotation and approval

Stop for user annotation. Repeat only over annotated or still-contested sections;
do not reopen settled material. Add the granular implementation checklist required
by `research-plan-implement`. Do not implement until the user explicitly approves
the plan.

## 6. Implementation handoff

After approval, hand production work to suitable builder agents or the main thread,
using `design/plan.md` as the contract. Track completion in that plan and follow the
implementation phase of `research-plan-implement`.

Architecture agents do not write production code. Recommend an independent audit
for on-chain code that holds or controls real value.
