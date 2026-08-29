---
name: web3-architecture
description: >-
  Use when designing, evaluating, or documenting the architecture of Ethereum/EVM
  smart-contract systems and dApps, producing an Architecture Decision Record (ADR)
  as the output. Trigger whenever the user is weighing smart-contract or protocol
  design trade-offs — upgradeable proxy vs. immutable, monolith vs. modular/Diamond,
  custody and access-control models, oracle choice, on-chain vs. off-chain split,
  L1 vs. L2, token standards — or asks to design, review, or "write up the decision"
  for a protocol, contract, or Web3 system on EVM chains. Use it even when the user
  never says "ADR" or "architecture": any request to decide how to structure an EVM
  smart-contract system, or to security-review a proposed design, is in scope.
  Security threat-modeling is built into the workflow, so also reach for this when
  choosing a pattern that must resist reentrancy, oracle manipulation, flash-loan
  attacks, or privileged-key compromise.
---

# Web3 Architecture (EVM) — Decision Records

## What this is for

Turn an open-ended Web3 design question ("should our lending core be upgradeable?", "how do we split this dApp on-chain vs off-chain?", "which oracle for LP-token collateral?") into a clear, defensible **Architecture Decision Record (ADR)**: a document that states the problem and threat model, lays out the realistic options, weighs them against the forces that matter on EVM chains, and commits to a recommendation with its consequences.

The output is a decision *record*, not a tutorial. Its readers are the team that has to build and defend the system — and, later, the auditors who need to understand why it looks the way it does. So the value is in honest trade-off analysis and a security-aware recommendation, not in restating what a proxy is.

Why a record and not just an answer: on-chain systems are adversarial and largely irreversible. Once value is at stake, a rejected option can't be casually revisited, and "why didn't we just do X?" comes up in every audit and incident review. Writing down what was rejected and why is what makes the decision durable.

## Workflow

Work through these five steps. They are deliberately front-loaded on framing and security, because in Web3 the threat model *is* part of the requirements — an attacker is a first-class user of your system.

### 1. Frame the problem and the threat model

Before comparing anything, establish:

- **What the system does** and who the actors are (users, LPs, admins, keepers, attackers).
- **Assets and value at risk** — what an attacker gains by breaking each component. This ranks everything that follows.
- **Trust assumptions** — who must be trusted (admins, oracles, sequencers, bridges, multisig signers) and what breaks if they misbehave or are compromised.
- **Hard constraints** — target chain(s), gas/cost budget, timeline, team size and audit budget, regulatory or custody requirements.
- **Success and "secure" defined for this system** — e.g. "user funds are never withdrawable by anyone but the owner, even if the price feed is wrong."

If the user hasn't supplied all of this, don't stall. Make reasonable assumptions **explicit** in the Context section and proceed; ask the user only for the one or two facts that would actually change the recommendation.

### 2. Name the real decision(s)

State the specific architectural choice(s) at stake, in the user's terms. Most EVM designs turn on a small set of recurring decisions — upgradeability, modularity, custody/access control, oracle/data source, on-chain vs off-chain split, chain/L2, token standard. `references/evm-patterns.md` catalogs each of these with the standard options and their trade-offs; consult it to make sure you're enumerating the real alternatives and not missing a common one.

### 3. Enumerate 2–4 viable options

For each option describe **how it works** and its **consequences** across the decision drivers:

security · cost/gas · upgradeability & agility · decentralization/trust · complexity · UX · composability · time-to-market

Only list options a competent team might actually choose — no strawmen there to make the winner look good. If an option is a non-starter, say so in one line rather than dressing it up as a contender. Reference concrete, battle-tested implementations where they exist (OpenZeppelin, Chainlink, Safe, Solady, ERC standards) and distinguish them from novel/unaudited approaches.

### 4. Run the security pass

Take the leading option(s) through `references/security-checklist.md`. A design that is elegant but opens a reentrancy path, relies on a spot price a flash loan can move, or puts an upgrade key behind a single EOA is not a good design regardless of how clean it looks. For the recommended direction, record: the top applicable threats, whether the design structurally mitigates them (not just "we'll be careful"), and the residual risk that remains for auditors to focus on.

Prefer designs that make classes of bug *impossible* over designs that require every future developer to remember a rule. Checks-effects-interactions, pull-over-push payments, immutability, and least-privilege access control are load-bearing here.

### 5. Decide and document as an ADR

Produce the ADR using `assets/adr-template.md`. Make a **clear recommendation** — an ADR that lists options without choosing one has failed at its only job. Capture the consequences honestly, including what gets worse under the chosen option and how you'll mitigate it, plus concrete follow-ups (what needs an audit, what invariants to test, what to monitor).

## Principles that should shape every recommendation

- **Security and irreversibility first.** Mainnet deployments hold real value and can't be patched like a web app. When value-at-risk is high, bias toward simplicity and immutability unless there's a concrete reason agility is worth the added attack surface.
- **Minimize trust, but be honest about it.** Every admin key, oracle, sequencer, and bridge is a trust assumption and an attack target. Reducing them is usually good — but say so out loud when a "decentralized" option trades away safety rails (e.g. no pause, no upgrade path if a bug is found). Name the trade; don't pretend it away.
- **Upgradeability is a loaded gun.** A proxy that can fix a bug can also rug users or brick the system via a bad storage layout. If you recommend upgradeability, pair it with governance controls (timelock, multisig/Safe, guardian roles) and call out the storage-collision and initialization risks.
- **Cite standards and prior art.** Prefer ERC standards and audited libraries over bespoke mechanisms; novelty is a cost that must be justified and audited.
- **Never call a design "safe."** Say it *reduces* or *mitigates* a specific risk, and always note that any non-trivial system needs an independent audit and thorough invariant testing before it holds real value. This isn't a disclaimer to bury — it's part of the recommendation.
- **Right-size the analysis.** A small, low-value contract doesn't need a ten-option epic; a protocol holding nine figures deserves real rigor. Match the depth of the ADR to the value and complexity at stake.

## Output

The deliverable is an ADR following `assets/adr-template.md`. Default to Markdown so it drops into a repo's `docs/adr/` folder. Include a Mermaid diagram in the Decision or Options section when it clarifies the on-chain/off-chain split or contract topology — a picture of what calls what is worth a paragraph. If the user asks for a Word or PDF version instead, produce the ADR content first, then convert.

## Reference files

- `references/evm-patterns.md` — catalog of the recurring EVM architecture decisions (upgradeability, modularity, access control, oracles, on/off-chain split, L2s, token standards, account abstraction) with the standard options and their trade-offs. Read the sections relevant to the decision at hand.
- `references/security-checklist.md` — threat-modeling prompts and a vulnerability checklist (reentrancy, access control, oracle/price manipulation, MEV/front-running, upgrade and initialization risks, external-call handling, DoS, signature replay). Run the recommended design against it in step 4.
- `assets/adr-template.md` — the ADR template to fill in. Copy its structure exactly.
