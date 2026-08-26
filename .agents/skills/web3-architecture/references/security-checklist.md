# Smart-Contract Security Checklist (EVM)

Run the *recommended* design through this in step 4 of the workflow. The goal isn't
to grep for keywords — it's to threat-model: for each item, ask "does this apply to
our design, does the architecture structurally prevent it, and what residual risk
remains for an auditor?" Record only what actually applies.

## Threat-modeling prompts (do this first)

- **Who profits from breaking each component, and how much?** Rank by value-at-risk.
- **What can an attacker do atomically in one transaction?** Assume unlimited capital via flash loans — anything priced off manipulable state within a tx is suspect.
- **What happens if each trusted party is compromised or malicious?** Admin key, oracle, sequencer, keeper, bridge, multisig signer.
- **What if off-chain components vanish or lie?** Can users still withdraw? Is on-chain state still safe?
- **What's irreversible?** Where a mistake can't be undone, the bar for that path is highest.

## Vulnerability checklist

### Reentrancy
- External calls (token transfers, ETH sends, callbacks/hooks like ERC-721/1155 `onReceived`, ERC-777) before state updates.
- Defenses: **Checks-Effects-Interactions**, `nonReentrant` guards, pull-over-push. Watch **cross-function** and **cross-contract/read-only** reentrancy, not just single-function.

### Access control & privilege
- Every state-changing function has an intended caller — is it enforced? Missing/incorrect modifiers are a top cause of loss.
- Least privilege via roles; no single EOA controlling value; timelock on the most dangerous actions.
- Initializers on proxies protected (`initializer`, disabled on implementation) so they can't be front-run or re-run.
- `delegatecall` targets and library storage are trusted and can't be swapped.

### Oracle & price manipulation
- No pricing off a spot AMM reserve that a flash loan can move within a tx.
- Price feeds checked for **staleness** (`updatedAt`), zero/negative, and sane bounds; L2 sequencer-uptime feed consulted.
- TWAP windows sized against manipulation cost; low-liquidity pairs flagged.

### Flash loans & atomic composability
- Assume any external price/balance an attacker can influence *will* be influenced within one tx.
- Governance that reads token balances must use **snapshots**, not live balances (flash-loan voting).

### Arithmetic & accounting
- Solidity ≥0.8 checked math (or explicit `unchecked` justified); watch casting/truncation.
- Rounding always in the protocol's favor; ERC-4626 first-depositor/inflation attack mitigated (virtual shares/offset).
- Fee-on-transfer / rebasing tokens handled via balance-delta accounting, not assumed `amount`.

### MEV / front-running / ordering
- Sandwichable actions (swaps, liquidations) protected with slippage limits / deadlines / min-out.
- Commit-reveal or private mempools where ordering leaks value.
- Don't rely on transaction ordering for correctness.

### Upgrade & storage risks (if upgradeable)
- Storage layout preserved across upgrades (append-only, storage gaps, or Diamond storage discipline).
- Upgrade authority behind timelock + multisig; upgrade path itself audited.
- New implementation can't brick the proxy (UUPS must retain upgrade capability).

### External calls & DoS
- Return values of low-level `call`/token transfers checked (SafeERC20).
- No unbounded loops over user-controlled arrays (gas-limit DoS); one reverting recipient can't block everyone (pull payments).
- Reasonable behavior if an external dependency (oracle, bridge, DEX) reverts or pauses.

### Signatures & replay
- EIP-712 typed data with domain separator incl. `chainId`; nonces + deadlines; guard against signature malleability; reject `ecrecover` returning `address(0)`.
- Cross-chain replay considered where the same contract lives on multiple chains.

### Chain & environment assumptions
- No reliance on `block.timestamp`/`blockhash` for randomness (use a VRF).
- L2 sequencer downtime, reorgs, and finality/withdrawal delays accounted for.
- `tx.origin` not used for auth.

## Resilience & operations

- **Pause / circuit breaker** for emergencies (and the centralization trade-off it implies — note it).
- **Invariants** worth fuzzing/formally verifying stated explicitly (e.g. `sum(userBalances) == token.balanceOf(this)`; no non-owner withdrawal path; total shares ↔ total assets monotonicity).
- **Monitoring & incident response:** what to watch (large withdrawals, oracle deviation, admin actions), and the key-management / upgrade runbook.
- **Audit posture:** what an independent audit should focus on, and confirmation that the system won't hold real value before audit + thorough testing.

## How to report this in the ADR

For the recommended option, capture in the "Security analysis" section: the **top applicable threats**, the **structural mitigations** actually present in the design (not intentions), the **residual risk** for auditors, and the **key invariants** to test. Keep it specific to the system — a generic checklist dump is not useful to the team.
