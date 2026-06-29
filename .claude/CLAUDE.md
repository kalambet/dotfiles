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
- **ai-dev**: Use for all AI/LLM development tasks — model integration, inference optimization, RAG, agents, Go/Swift AI tooling
- **apple-dev**: Use for all Apple platform development — iOS, macOS, watchOS, tvOS, visionOS. Always use this skill when writing Swift, building SwiftUI interfaces, working with SwiftData, debugging Xcode projects, or making any UI/UX design decision for Apple platforms. Swift-first, Objective-C only when unavoidable.
- **ml-reviewer**: Use for all AI/ML/LLM code reviews — hyper-critical, production-hardened reviewer with 20 years ML experience. Triggers on review, audit, and "what's wrong" requests for AI code.
- **apple-reviewer**: Use for all Apple UI/UX code reviews — hyper-critical, pessimistic reviewer obsessed with accessibility, HIG compliance, and performance on real devices. Triggers on review, audit, and "what's wrong" requests for SwiftUI/Apple code.
- **feature-team**: Use to assemble a multi-agent team for end-to-end feature work that spans both Apple (iOS/macOS) and AI/ML components and needs a full review cycle. Orchestrates the other skills — pairs builders (apple-dev, ai-dev) with their reviewers (apple-reviewer, ml-reviewer) through implement-then-review loops.
- **shell-scripting**: Use when writing, editing, or reviewing shell scripts — jq/cast conventions, YAML config parsing, dry-run + mainnet-confirmation safety, colored output helpers — and for Git/GitHub CLI workflows like crawling PR review comments via the API.
- **research-plan-implement**: Use for non-trivial coding work in an existing codebase — features, refactors, cross-cutting bug fixes, or any substantial multi-file change. Enforces a Research → Plan → Annotate → Implement pipeline (research.md → plan.md → human annotation → mechanical implementation). Skip it for trivial one-line fixes.
