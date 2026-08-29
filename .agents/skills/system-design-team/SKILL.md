---
name: system-design-team
description: Convene Web3, distributed-systems, and LLM architects to review an existing architecture or design a system spanning at least two of those domains, then reconcile their positions. Use for cross-domain architecture reviews, RFCs, design documents, or new system designs where one specialist would have meaningful blind spots. Use a single specialist for a single-domain question.
---

# System Design Team

Convene senior architects for the domains a system crosses, then make disagreements
at those boundaries explicit. The result must be one coherent design or review, not
three opinions concatenated together.

## Roster

| Teammate | Agent definition | Companion skill | Owns |
|---|---|---|---|
| `web3` | `web3-architect` | `web3-architecture` | EVM contracts, custody, access control, upgradeability, oracles, MEV, and on-chain/off-chain boundaries |
| `distributed` | `distributed-systems-architect` | `distributed-systems-architecture` | Services, data, consistency, messaging, coordination, scale, availability, and failure modes |
| `llm` | `llm-system-architect` | `llm-system-architecture` | LLM system shape, RAG, agents, context assembly, guardrails, evaluations, and observability |

Each architect must invoke its companion skill and read the references relevant to
its assignment. Agent names end in `-architect`; companion skill names end in
`-architecture`.

## Facilitate; do not arbitrate

The main agent assembles the brief, selects the roster, dispatches rounds, maintains
the conflict ledger, detects convergence, and reports the result. It must not settle
a contested technical question, soften findings, or add its own architecture claims
to the consensus. After the final round, preserve unresolved positions as decisions
for the user.

## Select mode and roster

- **Review mode:** an architecture, RFC, diagram, design document, or running system
  already exists and needs stress-testing. Engage all three architects. If a domain
  is absent, give that architect an outside-lens brief: assess reasoning,
  assumptions, failure handling, and operations without manufacturing domain
  findings.
- **Design mode:** the system or a substantial part of it does not yet exist. Engage
  only architects whose domains the system touches, and state who was skipped and
  why. If exactly one architect is relevant, delegate directly instead of running a
  team debate.

Ask only when the mode is genuinely ambiguous and the choice changes the work;
otherwise select it and state the choice.

## Load the mode instructions

After selecting the mode, read these references completely before proceeding:

- **Review:** [review-mode.md](references/review-mode.md),
  [debate-protocol.md](references/debate-protocol.md), and
  [templates.md](references/templates.md).
- **Design:** [design-mode.md](references/design-mode.md),
  [debate-protocol.md](references/debate-protocol.md), and
  [templates.md](references/templates.md).

Do not load the unused mode file.

## Shared intake

Before dispatching architects, write `design/brief.md` using the schema in
`templates.md`. Give every architect the same brief and artifacts. Check for
`ARCHITECTURE.md` and `LIBRARIAN.md` in the repository root and `docs/`, and read
them when present.

Requirements should include the numbers that drive the design: workload, data
volume and growth, latency and cost budgets, availability, consistency per data
type, value at risk on-chain, and the quality bar for incorrect LLM output. Record
constraints and explicit assumptions. Ask the user only for facts that would
materially fork the recommendation; otherwise state assumptions and proceed.

## Shared execution rules

- Run independent work concurrently when possible.
- Continue with the same architects in later rounds so their context survives.
- Use the shared debate protocol and maintain `design/conflicts.md`.
- Stop early when nothing remains contested; never exceed three debate rounds.
- Show the conflict-ledger status after each round.
- Keep unresolved decisions intact, with the evidence needed to settle them.
- Architects design; builders or the main thread implement approved production
  changes.

Right-size the process. A focused question does not justify three architects and
three rounds. Run reconciliation only while substantive conflicts remain.
