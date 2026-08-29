---
name: typescript-team
description: >-
  TypeScript Team — architect designs the issue's implementation, developer judges the design from the code standpoint and implements after consensus, reviewer judges the result as a pair of fresh eyes with no design context. Use when the user asks to build, implement, or fix something non-trivial in TypeScript with the team, e.g. "get the typescript team on this", "ts team: implement X", or any substantial TS change that deserves a design-consensus-review cycle. Not for trivial one-line TS fixes — delegate those to typescript-developer directly.
---

# TypeScript Team

Three roles, three phases, one deliberate blindness: the reviewer never sees the
design or the debate. If the code needs the design doc to look correct, that is a
finding, not a formality.

## The roster

| Teammate | Agent definition | Phase |
|---|---|---|
| `architect` | `typescript-architect` | Designs the implementation for this issue |
| `developer` | `typescript-developer` | Critiques the design from the code standpoint, then implements the consensus |
| `reviewer` | `typescript-reviewer` | Reviews the diff cold — fresh eyes, no design context |

**Dispatch every agent with an explicit instruction to load its skill and confirm it
did** — a first `Skill` call for `typescript-architect` / `typescript-developer` / `typescript-reviewer`, and one
line back saying so. Do **not** rely on the agent definition's `skills:` declaration, and do not
accept "my instructions say it is loaded" as confirmation. It costs one tool call per agent and
converts an assumption into an observation.

Measured 2026-08-22: an architect and a developer both ran most of a cycle having made **zero**
`Skill` calls, each working from a persona prompt that asserted the skill was already loaded.
Loading it changed **no convention** — both already complied — but the architect was missing the
ADR template's four required dimensions, and the developer had run **two of the skill's six
verification commands**. Running the other four surfaced a CI failure waiting on a file nobody
had considered.

So the cost of the gap is not wrong conventions; it is **missing evidence**. These skills carry
the checklist of what counts as having *checked*, which is precisely what a confident agent
skips.

## Your role: facilitator, not arbiter

You assemble the brief, dispatch phases, carry messages between architect and
developer, enforce the reviewer's context blindness, and escalate unresolved
disagreements to the user. You do not settle technical disputes, soften findings,
or write design or implementation content yourself.

## Phase 0 — Brief

Write `team/brief.md` before dispatching anyone: the issue in one paragraph, the
relevant packages/modules (paths), acceptance criteria, and constraints (Node and
browser targets, ESM/CJS, public-API stability, published-types surface,
package-manager and test-framework already in use). State assumptions explicitly
rather than stalling; flag the ones that would fork the design if wrong.

## Phase 0.5 — Measure first, when the design turns on facts nobody has run

**The `architect` has no shell.** It can read, grep and reason; it cannot compile, run a
test, or observe a tool's actual output. So when the shape of the design depends on a fact
nobody has measured — what a linter really reports, what a limit really is, why a flake
really fires, what a dependency's source really does — dispatch `developer` **first**, with
a measurement-only task and an explicit instruction not to implement.

The test for whether you need this: *would a wrong answer here change the design, rather
than change a detail inside it?* If yes, measure.

Fold the results into `team/brief.md` as measured facts, attributed and dated, and tell the
architect to **re-verify rather than trust** them. Then run Phase 1 normally.

Skip it when the facts are already in hand or the change is mechanical. It is not a licence
to explore — a measurement task names what it must establish and what would falsify it, and
returns numbers, not a design.

## Phase 1 — Design

Dispatch `architect` with `team/brief.md`. It reads the affected code and writes
`team/design.md`: the recommended implementation shape — package/module placement,
public surface (exact exported signatures), type strategy (unions, brands, guards
at boundaries), error contract, async/cancellation commitments, and the test plan
(including type-level tests if the published type surface changes) — plus rejected
alternatives with reasons. Design only; no implementation code beyond type
signatures and skeletons.

## Phase 2 — Code-standpoint critique → consensus

Dispatch `developer` with the brief and `team/design.md`. Its job here is to judge,
not to build: read the actual code the design touches and take a position on every
design decision —

- `AGREE` — implementable as specified.
- `AMEND` — the goal is right, the shape fights the existing code; propose the
  concrete alternative (with `file:line` evidence of what it collides with —
  tsconfig settings, existing error classes, module boundaries, circular-import
  risk).
- `OBJECT` — the decision creates a real implementation problem: names the
  mechanism (a type that can't be narrowed at the stated boundary, an API that
  forces `as` casts on callers, a cancellation path with nowhere to thread the
  `AbortSignal`, an ESM/CJS conflict with a dependency), not a taste complaint.

Relay the critique to the **same** `architect` (SendMessage — its context must
survive). The architect answers each `AMEND`/`OBJECT` with evidence or concession.
**Two rounds maximum.** Consensus = no open `OBJECT`. Record the agreed changes in
`team/design.md` with a short decision log. Anything still contested after round 2
goes to the user with both positions intact — do not break the tie yourself.

Preference is not conflict: an `AMEND` the architect accepts costs one line in the
log, not a round.

## Phase 3 — Implementation

The **same** `developer` (context preserved) implements the consensus design:
matches the surrounding code, writes tests with the change (behavior-level, plus
type-level tests for published types), runs the project's gates — typically
`yarn lint`, `yarn tsc --noEmit`, `yarn test` (or npm/pnpm equivalents from
package.json scripts) — and reports results honestly. Deviations from the
consensus that the code forces get recorded in `team/design.md`'s decision log —
silent drift is what Phase 4 exists to catch.

## Phase 4 — Fresh-eyes review

Spawn a **new** `reviewer` whose prompt contains only: the repo path, the list of
changed files (or the diff), and the instruction to review. **Never** pass it
`team/brief.md`, `team/design.md`, the debate, or any rationale. This blindness is
the point: the reviewer judges whether the code stands on its own — types, naming,
error handling, async discipline, tests — exactly as a stranger reading the PR
would.

The reviewer works its checklist, runs the same gates, and returns findings with a
verdict: LGTM / LGTM-with-nits / request-changes (or refuses to review if the
project lacks `strict: true`).

## Phase 5 — Fix loop

Findings go back to `developer` (same one). It fixes or, where it disagrees,
states why. Send the updated diff and the developer's responses back to the same
`reviewer` for re-review. **Three review rounds maximum.**

- Reviewer satisfied → proceed to sign-off.
- Still contested at the cap → present both positions to the user as open
  decisions. Findings are SOFT WARNING tier — the operator (user) decides on
  merge, but the disagreement ships to them explicitly, never silently dropped.

## Phase 6 — Team sign-off

The issue is not finished when the code lands — it is finished when the team
agrees it is. Send the final diff and the decision log to the **same**
`architect`, which verifies the implementation against the consensus design and
answers `DESIGN-CONFORMS` or raises specific deviations. Deviations go back to
the fix loop (or, if the architect and developer disagree about whether a
deviation is justified, to the user).

## Definition of done

All of these, explicitly, or the issue is still open:

1. Every acceptance criterion from `team/brief.md` is met, with evidence.
2. Tests are implemented and green (lint / `tsc --noEmit` / test gates pass).
3. **Consensus among all three members:** architect — `DESIGN-CONFORMS`;
   developer — implementation complete, gates green; reviewer — LGTM (nits
   allowed). Any standing objection from any member means not done; it either
   resolves inside the loops above or ships to the user as an open decision,
   never gets quietly dropped.

## Output

Report to the user: what shipped (files + summary), the decision log from
`team/design.md`, gate results (lint/typecheck/test), the reviewer's final
verdict, and any open decisions with both positions.

## Cost discipline

**State a round budget at consensus, and hold yourself to it.** When Phase 2 closes, say how
many fix-loop rounds you expect. If the work exceeds it, stop and put the position to the
user — what is done, what is open, what another round would buy — rather than continuing
because the cap technically allows it. Three review rounds is a ceiling, not a plan.

Rounds are the unit that runs away, not hours. An issue whose review keeps finding real
defects is not failing, but it is also not the issue that was scoped, and the user is the
one who decides whether to keep paying for it.

If the issue turns out to be trivial once briefed (single obvious change, no
design decisions), say so and delegate straight to `typescript-developer` with a
follow-up `typescript-reviewer` pass — don't run the full protocol for a rename.
