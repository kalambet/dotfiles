# Artifact templates

These are required fields, not mandatory prose length. Keep artifacts proportional
to the task.

## `design/brief.md`

1. System purpose and users.
2. Mode and artifact under review, including exact paths or commit when applicable.
3. Functional requirements and decision-driving numbers.
4. Constraints: stack, chain, team, timeline, budget, privacy, and regulation.
5. Explicit assumptions, marking those that would fork the recommendation.
6. Selected roster, rationale, and skipped architects.
7. Cross-domain interfaces when in design mode.

## Interface contract

| Interface | Producer | Consumer | Payload | Sync/async | Consistency guarantee | Failure semantics | Owner |
|---|---|---|---|---|---|---|---|

## Review finding

Every finding includes:

- Severity: Critical, Major, or Minor.
- Concrete triggering condition.
- Evidence using `file:line` or a quoted design passage.
- Specific corrective action.
- Confidence and evidence that would change it.

## `design/consensus.md`

1. Agreed findings, severity-ordered, with surviving fixes and originators.
2. Amended findings, showing the original claim, amendment, and rationale.
3. Open decisions using the table below.
4. Withdrawn claims and why they were withdrawn.
5. Consolidated strengths.

## Open decisions

| ID | Decision | Position A: owner and rationale | Position B: owner and rationale | Evidence needed | Cost of choosing wrong |
|---|---|---|---|---|---|

## `design/conflicts.md`

| ID | Claim | Raised by | Positions | Status | Round opened |
|---|---|---|---|---|---|

Status must be `AGREED`, `AMENDED`, or `CONTESTED`.

## `design/plan.md`

Include:

- One system diagram with edges labeled by meaning, such as sync, async,
  publishes, settles, or retrieves.
- The agreed interface-contract table.
- A coherent design for each domain slice.
- A decision log: decision, proposer, rejected alternative, and accepted trade-off.
- Open decisions from the debate.
- Cross-system failure modes.
- Evaluation, monitoring, and audit plans.
- A granular implementation checklist before approval.
