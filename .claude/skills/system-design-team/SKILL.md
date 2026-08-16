---
name: system-design-team
description: System Design Team — convenes web3-architect, distributed-systems-architect, and llm-system-architect to review an existing architecture or design a new system, then makes them argue to consensus. Use when the user asks to review/critique a system architecture, RFC, design doc, or ARCHITECTURE.md, or to design a system that spans more than one of on-chain/EVM, distributed backend, and LLM/AI domains. Trigger on "review this architecture", "design this system", "get the architects on this", "does this design hold up", or any cross-domain architecture question where a single specialist would have blind spots. Runs in review mode or design mode.
---

# System Design Team

Three senior architects, each blind to the others' domain, review or design a system
and then **argue to consensus**. The value is not three opinions stapled together —
it is the disagreements they surface at the boundaries between their domains, which
is exactly where cross-domain systems fail.

## The roster

| Teammate | Agent definition | Companion skill | Owns |
|---|---|---|---|
| `web3` | `web3-architect` | `web3-architecture` | On-chain/EVM: contracts, upgradeability, custody & access control, oracles, on-chain/off-chain split, L1/L2, MEV, adversarial economics |
| `distributed` | `distributed-systems-architect` | `distributed-systems-architecture` | Services, data & consistency, messaging & streaming, coordination, scale, failure modes, availability |
| `llm` | `llm-system-architect` | `llm-system-architecture` | LLM system shape, retrieval/RAG, agentic workflows, context assembly, guardrails, evals & observability |

Each teammate **must invoke its companion skill** at the start of its task and pull
the relevant reference files. Working from memory is what makes architecture output
generic; the specifics live in those references.

Naming is uniform across all three: the **agent** is `*-architect` (the teammate you
dispatch), the **skill** is `*-architecture` (the methodology that teammate invokes
for itself). So `Agent(subagent_type: "llm-system-architect")` is the teammate and
`Skill(skill: "llm-system-architecture")` is its method — never the same string.

## Your role: facilitator, not arbiter

You run the protocol. You do **not** settle technical disputes.

You: assemble the brief, select the roster, dispatch rounds, maintain the conflict
ledger, detect convergence, and escalate what's left to the user.

You do not: pick a winner on a contested design question, soften a finding to make
the doc read cleanly, or write architecture content of your own into the consensus
document. If two architects disagree after the final round, that disagreement ships
to the user as an open decision — an unresolved conflict honestly reported is a
better outcome than one you quietly resolved.

## Roster selection

**Review mode — always engage all three.** An outside lens catches what a domain
expert has stopped seeing. An architect whose domain the system doesn't touch gets
the *outside-lens brief*: don't manufacture findings in your domain; review the
design's reasoning, stated assumptions, failure handling, and operational story as
an experienced architect from outside, and say plainly where your domain is absent.

**Design mode — engage only the architects whose domain the system actually
touches.** Name any architect you skip and why, in one line, in the brief. If the
user disagrees they'll say so.

If exactly one architect is relevant in design mode, say so and delegate to that
agent directly instead of running this protocol — a debate needs at least two
positions.

## Mode selection

- **Review mode** — an architecture already exists (design doc, RFC, ARCHITECTURE.md,
  diagram, running code) and the user wants it stress-tested.
- **Design mode** — the system does not exist yet, or a substantial new piece of it
  doesn't, and the user wants it designed.

If the request is genuinely ambiguous, ask. Otherwise pick and state which mode
you're running in one line.

---

# Round 0 — Intake (both modes)

Do this yourself, before dispatching anyone. All architects must review or design
against the *same* stated problem, or the debate is noise.

Write `design/brief.md`:

1. **What the system does** and who uses it.
2. **The artifact under review** (review mode): exact paths, commit, or pasted doc.
   Check for `ARCHITECTURE.md` and `LIBRARIAN.md` in the root or `docs/`, and read
   them if present.
3. **Requirements and numbers.** Request rate (avg/peak), data volume and growth,
   latency and cost budgets, availability target, consistency needs per data type,
   value-at-risk on-chain, quality bar and stakes of a wrong LLM output.
4. **Constraints**: chain and stack, team, timeline, audit budget, privacy and
   regulatory limits.
5. **Assumptions.** Anything above that the user didn't give, you state as an
   explicit assumption and flag which ones would fork the design if wrong. State
   assumptions and proceed — don't stall on intake. Ask the user only for the one or
   two facts that would actually change the recommendation.
6. **Roster and rationale**, including who was skipped and why.

---

# Review mode

## Round 1 — Independent review (parallel)

Dispatch all three architects **in a single message** so they run concurrently.
Each reads `design/brief.md` and the artifact, invokes its companion skill, and
writes `design/review.<domain>.md`:

- **Findings by severity** (Critical / Major / Minor). Each finding carries: the
  concrete condition that triggers the problem, evidence (`file:line`, or the quoted
  passage from the doc), a specific fix, and a confidence level.
- **Boundary concerns** — problems the architect can see the edge of but cannot
  resolve alone, named as questions for a specific other architect. These are the
  most valuable output of this round; require at least one, or an explicit statement
  that the design has no interface with the other domains.
- **What's genuinely working well.** Not padding — a reviewer who finds nothing good
  hasn't understood the design well enough to be trusted on the bad parts.

## Round 2 — Cross-examination

Continue **the same agents** (via `SendMessage`, so their context survives) rather
than spawning fresh ones. Give each the other two reviews. Each responds in
`design/rebuttal.<domain>.md`, taking a position on every finding that touches its
domain or the boundary:

- `AGREE` — and anything the original finding understated.
- `AGREE-WITH-AMENDMENT` — the problem is real, the proposed fix isn't; say why and
  propose a different one.
- `DISAGREE` — with the mechanism or evidence that makes the finding wrong or
  inapplicable, not merely a preference.
- `OUT OF MY DOMAIN` — say so and defer. Deferring is a legitimate answer; faking
  competence is not.

Each architect must also answer every boundary question addressed to it by name.

## Round 3 — Reconciliation

Only for items still contested. Each holdout states its final position, what it
would take to change its mind, and the one thing it could concede. Then stop —
three rounds is the cap.

## Output — `design/consensus.md`

1. **Agreed findings**, severity-ordered, each with the surviving fix and who
   raised it.
2. **Amended findings** — original claim, the amendment, and why it's better.
3. **Open decisions** — one row per still-contested item:

   | # | The decision | Position A (who, why) | Position B (who, why) | What evidence would settle it | Cost of choosing wrong |

4. **Withdrawn claims** — findings an architect dropped, with the reason. Keeping
   these visible is what keeps concessions honest.
5. **What's working well**, consolidated.

---

# Design mode

Each engaged architect follows the **`research-plan-implement`** skill for its own
slice, and the team's debate rounds sit between that skill's plan and implement
phases. The human annotation cycle is preserved — it is not replaced by the debate.

```
Intake → Research → [CHECKPOINT A] → Individual plans → Debate → Merge → [CHECKPOINT B] → Implement
```

## Phase 1 — Decomposition

You split the system into domain slices and, critically, **name the interfaces
between them** before anyone designs anything. Every interface goes in the brief as
a row that the owning architects must later fill in and agree on:

| Interface | Producer | Consumer | Payload | Sync/async | Consistency guarantee | Failure semantics | Owner |

Cross-domain systems fail at these seams — an LLM agent that assumes it can read
chain state synchronously, a settlement path that assumes exactly-once delivery, a
retrieval index that silently lags the source of truth. Getting the seams onto paper
early is most of this skill's value.

## Phase 2 — Research (parallel)

Each architect runs `research-plan-implement` Phase 1 on its slice and writes
`design/research.<domain>.md`: how the existing code and systems actually work,
existing patterns and conventions to reuse, prior art and battle-tested reference
implementations, and the domain-specific numbers and threats that constrain the
design. Then it **stops** — no planning yet.

You merge the three into `design/research.md`: a short synthesis, contradictions
between the three accounts, and the open questions.

## CHECKPOINT A — Human annotation of research

Stop. Present `design/research.md` and wait. The user annotates inline: wrong
assumptions, missing constraints, domain knowledge, sections to drop.

A wrong shared assumption caught here costs one round; caught after three plans and
a debate it costs everything downstream. Do not proceed until the user responds.
Feed every annotation back to the architects it affects.

## Phase 3 — Individual plans (parallel)

Each architect runs `research-plan-implement` Phase 2 for its slice and writes
`design/plan.<domain>.md` in its own native output format — ADR for `web3`, design
doc for `distributed`, decision-first design doc for `llm` — plus, for this team:

- **Interfaces provided** and **interfaces consumed**, filled into the table shape
  above with concrete guarantees, not aspirations.
- **What I need from the other domains**, addressed by name.
- **Rejected alternative** and why. A plan with only upside is hiding the parts that
  hurt later.
- **Failure modes and the unhappy path**, including what happens when the other
  domains' components are down, slow, lying, or adversarial.

Then stop — no implementation.

## Phase 4 — Debate

Same three-round protocol as review mode (cross-examination → reconciliation),
scoped to what actually matters here:

1. **Interface contracts** — every row where producer and consumer disagree on
   payload, ordering, consistency, or failure semantics. Resolve these first; they
   block everything else.
2. **Conflicting requirements** — where one domain's optimum is another's problem
   (an on-chain guarantee that demands latency the LLM path can't absorb; a
   throughput target that forces eventual consistency the settlement logic can't
   accept). These are real trade-offs, not misunderstandings — the output is a
   stated trade-off with its cost, not a compromise that pretends there's no loss.
3. **Duplicated or unnecessary components** — two architects solving the same
   problem separately, or a component that can't name the problem it solves. The
   strongest move in a design review is deleting something.

## Phase 5 — Merge → `design/plan.md`

One coherent plan, not three concatenated. It must contain: the system in one
diagram (Mermaid, with edges labelled by *meaning* — sync/async, "publishes",
"settles", "retrieves" — not bare arrows); the agreed interface contract table; the
per-slice design; a **decision log** (decision, who proposed it, what was rejected,
the trade-off accepted); the **open decisions** table from the debate; failure modes
across the whole system; and the eval, monitoring, and audit plan.

## CHECKPOINT B — Human annotation of the plan

Stop. The user annotates `design/plan.md`. Repeat 1–6 times per
`research-plan-implement`. On each round, re-run the debate **only over the annotated
sections** — a full re-debate of settled material burns tokens and re-opens
questions the user already closed. Before implementation, add the granular todo list
the skill requires.

## Phase 6 — Implementation

Only after explicit approval, and per `research-plan-implement` Phase 4: implement it
all, mark tasks complete in `design/plan.md`, don't stop mid-flow for confirmation,
typecheck continuously.

These three architects **design; they do not write production code.** Hand
implementation to the appropriate builder agents or to the main thread, with
`design/plan.md` as the contract. On-chain code holding real value goes through an
independent audit — that is part of the recommendation, not a disclaimer.

---

# Debate rules (both modes)

Enforce these when dispatching each round. They exist because the failure mode of a
multi-agent review is not conflict — it's premature, polite agreement.

1. **Attack the design, never the architect.** No strawmen: state the other
   position in its strongest form before arguing against it.
2. **Evidence or trade-off, nothing else.** A position changes because of a
   mechanism, a number, a citation, or an explicitly accepted trade-off. Never
   because of seniority, round count, or fatigue.
3. **Concede explicitly, with the reason.** "You're right, and here's what I got
   wrong" is a strong move. Silently dropping a claim is not — dropped claims go in
   the withdrawn section.
4. **No consensus by capitulation.** Do not agree to close a round. An architect
   that still disagrees after round 3 must say so; that's what the open-decisions
   table is for.
5. **Stay in your lane, out loud.** Outside your domain, defer explicitly rather
   than guessing. The outside-lens brief is about reasoning quality and assumptions,
   not fabricated domain findings.
6. **Preference is not conflict.** Only escalate a disagreement to CONTESTED if the
   two positions produce a *different system*. Style and taste get recorded once
   and dropped.
7. **State confidence** on every finding and position, and say what would change
   your mind.

## Conflict ledger

Maintain this yourself across rounds, in `design/conflicts.md`, and show the user
the status line after each round:

| ID | Claim | Raised by | Positions | Status | Round opened |

Status is `AGREED`, `AMENDED`, or `CONTESTED`. Convergence is reached when nothing
is `CONTESTED` — or after round 3, whichever comes first. Everything still contested
at the cap goes to the user as an open decision with both positions intact.

## Cost discipline

Three architect agents over three rounds is expensive. Right-size it: a single
focused question doesn't need the full protocol — say so and delegate to one
architect. Run the full three rounds only when round 2 leaves real conflicts on the
table; if the ledger is clean after cross-examination, skip round 3 and say why.
