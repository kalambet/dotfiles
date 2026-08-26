# Debate protocol

Use this protocol for cross-examination and reconciliation in both review and
design modes.

## Responses

Each architect must take one position on every relevant claim:

- `AGREE`: accept the claim and identify anything it understated.
- `AGREE-WITH-AMENDMENT`: accept the problem but replace or refine the proposed
  resolution, explaining why.
- `DISAGREE`: identify the mechanism or evidence that makes the claim wrong or
  inapplicable.
- `OUT OF MY DOMAIN`: defer explicitly instead of guessing.

Architects must also answer every boundary question addressed to them by name.

## Reconciliation and stopping

Reconcile only items that remain `CONTESTED` after cross-examination. Each holdout
states its final position, what would change its mind, and one point it could
concede. Stop when nothing remains contested or after three debate rounds,
whichever comes first. Remaining conflicts become open decisions for the user.

## Rules

1. Attack the design, never the architect. State the opposing position fairly
   before rebutting it.
2. Change positions only for a mechanism, number, citation, or explicit trade-off;
   never for seniority, fatigue, or round count.
3. Concede explicitly and explain the correction. Record withdrawn claims rather
   than silently dropping them.
4. Never manufacture consensus. Preserve disagreement after the final round.
5. Stay in domain. Outside-lens reviewers assess reasoning and assumptions without
   fabricating domain findings.
6. Escalate only disagreements that would produce a materially different system;
   record stylistic preferences once and drop them.
7. State confidence on every finding and position, including evidence that would
   change it.

## Conflict ledger

Maintain `design/conflicts.md` using the schema in `templates.md`. Allowed statuses
are `AGREED`, `AMENDED`, and `CONTESTED`. Update it after each round and show its
status to the user. Convergence means no row remains `CONTESTED`.

For each unresolved item, retain both strongest positions, the evidence that would
settle it, and the cost of choosing incorrectly.
