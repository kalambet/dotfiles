## General

1. Ask, don't assume. If something is unclear, ask before writing a single line. Never make silent assumptions about intent, architecture, or requirements. When running unattended, pick the most reasonable interpretation, proceed, and record the assumption rather than blocking.

2. Implement the simplest solution for simple problems, better solutions for harder problems. Do not over-engineer or add flexibility that isn't needed yet.

3. Don't touch unrelated code but please do surface bad code or design smells you discover with me so we can address them as a separate issue.

4. Flag uncertainty explicitly. If you're unsure about something, see point 1 above. If it makes sense to do so, conduct a small, localised and low-risk experiment and bring the hypothesis and results to me to discuss. Confidence without certainty causes more damage than admitting a gap.

5. I'm always open to ideas on better ways to do things. Please don't hesitate to suggest a better way, or one that has long lasting impact over a tactical change.

## Communication Style

- Be concise and direct
- Skip explanations unless asked
- Use Oracle frequently for planning, debugging, and architecture reviews
- When asked to update/fix code, just do it - don't ask for confirmation

## Workflow For A New Project

For features, refactors, cross-cutting bug fixes, and other substantial work, follow the Research → Plan → Annotate → Implement pipeline — never implement without an approved `plan.md`. The full workflow lives in the **research-plan-implement** skill. Phase-specific slash commands are in `.config/agents/`.

## Workflow Preferences

- **Always consult Oracle** for: bug fixes, architecture decisions, security audits, complex implementations
- **Always consult Librarian** for: documentation investigation, code reviews, and best practices
- When writing scripts, prefer reading config from YAML files (e.g., `config.yaml`, `config.environment.yaml`)
- Use environment variables as overrides, not primary config source
- Generate PR descriptions in markdown files when asked (e.g., `pr_description.md`)
- Write release notes concisely
- Check ARCHITECTURE.md in the root directory or in the `docs` directory
- Check LIBRARIAN.md in the root directory or in the `docs` directory

## Skills

I have the following custom skills installed:

### Domain skills
- **ai-dev**: Use for all AI/LLM development tasks — model integration, inference optimization, RAG, agents, Go/Swift AI tooling
- **apple-dev**: Use for all Apple platform development — iOS, macOS, watchOS, tvOS, visionOS. Always use this skill when writing Swift, building SwiftUI interfaces, working with SwiftData, debugging Xcode projects, or making any UI/UX design decision for Apple platforms. Swift-first, Objective-C only when unavoidable.
- **ml-reviewer**: Use for all AI/ML/LLM code reviews — hyper-critical, production-hardened reviewer. Triggers on review, audit, and "what's wrong" requests for AI code.
- **apple-reviewer**: Use for all Apple UI/UX code reviews — hyper-critical, pessimistic reviewer obsessed with accessibility, HIG compliance, and performance on real devices. Triggers on review, audit, and "what's wrong" requests for SwiftUI/Apple code.

### Language suites
Each language has an architect (design/ADRs), a developer (idiomatic implementation), and a reviewer (convention-enforcing PR review) skill:
- **python-architect / python-developer / python-reviewer**: Python — layout, typing baseline, asyncio, pytest; reviewer emits SOFT WARNING findings
- **rust-architect / rust-developer / rust-reviewer**: Rust — workspaces, error models, Tokio, unsafe discipline; reviewer gives `unsafe` near-HARD-FAIL scrutiny
- **typescript-architect / typescript-developer / typescript-reviewer**: TypeScript — monorepos, ESM/CJS, branded types, strict tsconfig; reviewer emits SOFT WARNING findings
- **solidity-architect / solidity-developer / solidity-reviewer**: Solidity/EVM — every decision is a security decision; reviewer is HARD FAIL tier (reentrancy, upgrade safety, access control)

### Architecture skills
- **distributed-systems-architecture**: Design/review of anything spanning multiple services, databases, or machines — consistency, messaging, coordination, scale & reliability
- **llm-system-architecture**: End-to-end design of production LLM systems — RAG, agentic workflows, guardrails, evals & observability. Produces decision-first design docs
- **web3-architecture**: EVM smart-contract system design with built-in threat modeling. Produces ADRs

### Process skills
- **research-plan-implement**: Use for non-trivial coding work in an existing codebase — features, refactors, cross-cutting bug fixes, or any substantial multi-file change. Enforces a Research → Plan → Annotate → Implement pipeline (research.md → plan.md → human annotation → mechanical implementation). Skip it for trivial one-line fixes.
- **pr-review**: Universal, language-agnostic code-review framework; pair it with the matching language reviewer skill
- **warp** / **pickup**: Session continuity — warp writes a handoff record (records/handoffs/) before stopping or compacting; pickup resumes from the latest handoff in a fresh session

## Teams

Multi-agent team skills that orchestrate the skills above:
- **feature-team**: End-to-end feature work spanning Apple (iOS/macOS) and AI/ML components — pairs builders (apple-dev, ai-dev) with their reviewers (apple-reviewer, ml-reviewer) through implement-then-review loops
- **python-team / rust-team / typescript-team / solidity-team**: Architect designs, developer judges the design and implements after consensus, reviewer judges the result with fresh eyes. Use for non-trivial work in that language; solidity-team reviews at HARD FAIL tier
- **system-design-team**: Convenes web3-architect, distributed-systems-architect, and llm-system-architect to review or design a system, then makes them argue to consensus. Use for cross-domain architecture questions

## Agents

Subagents in `~/.claude/agents/`, mirroring the skills for delegated/parallel work:
- **Builders**: apple-engineer, ai-architect, ai-apple-engineer (AI + Apple combined), python-developer, rust-developer, typescript-developer, solidity-developer
- **Architects**: distributed-systems-architect, llm-system-architect, web3-architect, python-architect, rust-architect, typescript-architect, solidity-architect
- **Reviewers**: apple-reviewer, ml-reviewer, full-reviewer (AI + Apple combined), python-reviewer, rust-reviewer, typescript-reviewer, solidity-reviewer
