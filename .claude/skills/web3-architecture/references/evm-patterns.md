# EVM Architecture Patterns — decision catalog

The recurring decisions that shape an EVM smart-contract system, with the standard
options and their trade-offs. Use it in step 2/3 of the workflow to make sure you're
enumerating the real alternatives. Read only the sections relevant to the decision
at hand.

## Table of contents

1. Upgradeability
2. Modularity & code organization
3. Access control & custody
4. Oracles & external data
5. On-chain vs off-chain split
6. Chain / L1 vs L2
7. Token standards
8. Account abstraction & UX
9. Value handling & accounting

---

## 1. Upgradeability

The central question: can contract logic change after deployment, and who controls that?

- **Immutable (no upgrade path).** Deploy once, code is frozen. Maximum trust-minimization and smallest attack surface; users can verify exactly what they're interacting with forever. Downside: bugs can't be patched — you migrate to a new deployment and move liquidity/users. Best when logic is simple and stable, or trust-minimization is the product (e.g. Uniswap-style cores).
- **Transparent proxy (EIP-1967 storage slots).** Proxy delegatecalls to an implementation; an admin can swap the implementation. Admin/user call routing separated to avoid selector clashes. Well-trodden (OpenZeppelin). Heavier than UUPS.
- **UUPS proxy (EIP-1822).** Upgrade logic lives in the implementation itself, cheaper to deploy. Risk: if an implementation omits the upgrade function, the proxy is frozen forever. Common modern default.
- **Beacon proxy.** Many proxies point at one beacon; upgrade the beacon to upgrade all instances at once. Good for factory-deployed fleets (e.g. per-user vaults).
- **Diamond / multi-facet (EIP-2535).** One proxy routes function selectors to many "facet" implementations; upgrade per-facet. Escapes the 24 KB contract-size limit and enables modular upgrades, but adds real complexity (selector routing, shared storage discipline) and is harder to audit. Justify it with genuine size/modularity needs, not novelty.

Cross-cutting risks for any proxy: **storage-layout collisions** on upgrade, **initializer** functions that can be front-run or re-run (use `initializer`/`reinitializer` guards, disable initializers on the implementation), and **who holds the upgrade key** (see §3). An upgrade key is the single most powerful privilege in the system — treat it accordingly.

Decision heuristic: default to immutable when value-at-risk is high and logic is stable; choose a proxy when you genuinely expect to iterate, and always pair it with a timelock + multisig and a storage-gap discipline.

## 2. Modularity & code organization

- **Monolith.** One (or few) contracts hold most logic. Simplest to reason about and audit, cheapest cross-function calls (no external-call overhead), but bumps the 24 KB size limit and couples everything.
- **Modular / hub-and-spoke.** A core contract plus peripheral modules (e.g. a router, periphery, satellite contracts). Uniswap's core/periphery split is the canonical example. Cleaner upgrade/permission boundaries; more inter-contract calls to secure.
- **Diamond (EIP-2535).** See §1 — modularity + upgradeability via facets, at the cost of complexity.
- **Libraries (`library` / `using for`).** Share stateless logic without redeploying; `delegatecall` libraries can operate on caller storage (powerful and dangerous).
- **Factory + clones (EIP-1167 minimal proxy).** Cheaply deploy many identical instances (per-user vaults, per-market pools). Pair with a beacon (§1) for upgradeable fleets.

## 3. Access control & custody

Who can call privileged functions, and who holds assets.

- **`Ownable` / single owner.** Simple; one address controls admin functions. That address is a single point of failure — never a bare EOA for anything valuable.
- **Role-based (`AccessControl`).** Granular roles (MINTER, PAUSER, UPGRADER). Least-privilege: give each actor only what it needs, so one compromised key isn't game over.
- **Multisig (Safe).** Require m-of-n signers for privileged actions. The baseline for admin control of real value; document signer set and threshold.
- **Timelock.** Enforce a delay between proposing and executing privileged actions, so users can exit if they dislike a change. Standard for upgrades and parameter changes on protocols holding user funds.
- **Governance (Governor / token voting).** Decentralize control to token holders. Powerful but slow, and introduces governance-attack surface (vote buying, flash-loan voting — snapshot balances).
- **Custody models:** *non-custodial* (contract never has unilateral control of user funds; user can always withdraw) vs *custodial/pooled* (protocol holds pooled funds). Non-custodial is the stronger default; if pooling is required, the security bar rises sharply.

Guiding rule: least privilege + no single EOA controlling value + a delay (timelock) on the most dangerous actions.

## 4. Oracles & external data

How the contract learns off-chain facts (mostly prices). This is one of the most exploited areas in DeFi.

- **Spot price from an AMM pool (`getReserves`).** Cheap and permissionless but **manipulable within a single transaction by a flash loan** — generally unsafe as a pricing source for anything that pays out. Avoid for collateral valuation.
- **TWAP (time-weighted average, e.g. Uniswap v3 oracle).** Averages price over a window, raising manipulation cost to sustaining a price across many blocks. Better, but has lag (bad during fast moves) and can still be attacked on low-liquidity pairs or with enough capital.
- **Push oracle / price feed (Chainlink Data Feeds).** Decentralized reporters push signed prices on-chain; you read the latest answer. Battle-tested for major assets. Must-checks: **staleness** (`updatedAt` age), **min/max sane bounds**, sequencer-uptime feed on L2s, and handling of a feed that reverts or returns zero.
- **Pull / signed price (Pyth, RedStone).** Caller submits a fresh signed price the contract verifies; lower latency, wider asset coverage, but you must validate signature, freshness, and confidence interval.
- **Custom / committee / optimistic (UMA).** For facts with no price feed. Higher latency and trust assumptions.

Heuristic: never price collateral or trigger payouts off a spot AMM price. Prefer a decentralized feed (Chainlink) with staleness + bounds checks; use a TWAP or cross-check when a feed doesn't exist. For anything holding funds, assume an attacker will try to move your price with borrowed capital and design so that's not enough.

## 5. On-chain vs off-chain split

Put on-chain only what needs consensus, trust-minimization, or custody of value; push everything else off-chain for cost and UX.

- **On-chain (settlement layer):** custody of funds, final settlement, access control, anything that must be trustless or censorship-resistant, canonical state.
- **Off-chain (compute/data layer):** order matching, heavy computation, indexing/search, large data, notifications, most UI state.
- **Bridging patterns:**
  - *Signed messages (EIP-712).* Users sign intents/orders off-chain; the contract verifies the signature and settles on-chain (0x, Seaport, Permit2). Cheap, great UX — watch replay (nonces, deadlines, chainId, domain separator) and signature malleability.
  - *Indexers (The Graph / custom subgraph).* Read-side scaling: index events off-chain for fast queries; never a source of truth for on-chain logic.
  - *Keepers / relayers (Gelato, Chainlink Automation).* Off-chain actors trigger on-chain functions (liquidations, upkeep). The contract must stay safe even if the keeper is malicious, offline, or front-run.
  - *Meta-transactions / relayers (ERC-2771).* Gasless UX by trusting a forwarder; validate the forwarder and preserve `_msgSender()`.

The key discipline: the off-chain layer can be adversarial or unavailable. On-chain logic must be safe and, ideally, funds must remain user-withdrawable even if every off-chain component disappears.

## 6. Chain / L1 vs L2

- **Ethereum L1.** Maximum security and composability, highest gas. For high-value settlement and blue-chip composability.
- **Rollups (Optimistic — Optimism, Arbitrum, Base; ZK — zkSync, Starknet, Linea, Scroll).** Much cheaper, inherit L1 security to varying degrees. Considerations: **sequencer** is typically centralized (censorship/liveness risk; use the sequencer-uptime oracle feed), withdrawal/finality delays (7-day challenge window on optimistic rollups), and per-chain quirks. EVM-equivalent rollups run Solidity as-is; ZK "EVM-compatible" ones may differ in edge cases.
- **Sidechains / alt-L1 EVM (Polygon PoS, BNB, Avalanche C-Chain).** Cheaper still, but security is the chain's own, not Ethereum's.
- **Cross-chain / multi-chain.** Bridges are the single most exploited component in the space — minimize reliance, prefer canonical/native bridges over third-party, and treat any bridged message as untrusted input.

Heuristic: pick the L2 by where liquidity/users are and the cost budget; then explicitly handle its sequencer and finality properties in the design (especially oracle staleness and withdrawal timing).

## 7. Token standards

- **ERC-20** fungible. Watch: fee-on-transfer and rebasing tokens break naive accounting (measure balance deltas, don't assume `amount` received); non-standard returns (use SafeERC20); infinite-approval risk (prefer Permit2 / EIP-2612 permit).
- **ERC-721** NFTs; **ERC-1155** multi-token (batch, semi-fungible, gaming). Use `safeTransfer` receiver hooks carefully — they're a reentrancy vector.
- **ERC-4626** tokenized vault standard — use it for yield-bearing vaults instead of a bespoke share interface; be aware of the inflation/first-depositor share-price attack and its mitigations (virtual shares/offset).
- **ERC-2612 / Permit2** signature approvals for better UX and fewer approval-management footguns.
- **ERC-4337 / smart accounts** — see §8.

## 8. Account abstraction & UX

- **ERC-4337 (account abstraction via alt-mempool).** Smart-contract wallets with UserOperations, bundlers, paymasters (sponsored/gasless tx), session keys, batched actions, social recovery — no consensus change required. Adds a bundler/paymaster trust and infra dimension.
- **EIP-7702 (set EOA code).** Lets existing EOAs temporarily take on smart-account behavior; relevant to modern onboarding/UX designs.
- **Meta-transactions (ERC-2771)** — simpler gasless pattern via a trusted forwarder (see §5).

Reach for AA when UX (gasless, batching, recovery) is a product requirement; price in the extra infrastructure and trust surface.

## 9. Value handling & accounting

- **Pull over push payments.** Let users withdraw what they're owed rather than the contract pushing funds to them — pushing to arbitrary addresses invites reentrancy and griefing (a reverting receiver can DoS a batch).
- **Checks-Effects-Interactions.** Update state before external calls; the cheapest structural defense against reentrancy.
- **Balance-delta accounting** for tokens that may take fees or rebase (see §7).
- **Precision & rounding.** Round in the protocol's favor; be deliberate about share/asset conversions (ERC-4626) to avoid draining via rounding.
- **Native ETH vs WETH.** Handling raw ETH (`call` with gas, receive/fallback) differs from ERC-20 flows; many designs wrap to WETH internally for uniformity.
