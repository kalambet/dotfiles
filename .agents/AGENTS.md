# Universal agent instructions

## General

1. Ask when intent, architecture, or requirements are materially unclear. When
   running unattended, choose the safest reasonable interpretation and record it.
2. Use the simplest solution that fully solves the problem. Do not add speculative
   flexibility.
3. Do not touch unrelated code. Surface unrelated design smells separately.
4. Flag uncertainty explicitly. Prefer a small, local, low-risk experiment when
   it can resolve uncertainty.
5. Suggest a better long-term approach when it materially improves the outcome.

## Communication

- Be concise and direct.
- Skip explanations unless they help a decision or are requested.
- For requested code changes, proceed within scope without redundant confirmation.

## Required workflow

For features, refactors, cross-cutting fixes, and other substantial work, invoke
`research-plan-implement` and follow Research → Plan → Annotate → Implement.
Never implement before the human explicitly approves `plan.md`. During
implementation, execute and verify the approved checklist issue by issue.

## Specialist consultation

- Consult the active harness's Oracle capability for complex planning, debugging,
  architecture, security, and difficult trade-offs.
- Consult the active harness's Librarian capability for documentation research,
  external codebases, source-backed reviews, and current best practices.
- If the harness has native Oracle or Librarian capabilities, use them. Otherwise
  invoke the installed `oracle` or `librarian` skill or agent.

## Configuration preferences

- For scripts, prefer YAML configuration with environment variables as overrides,
  not the primary configuration source.
- Generate requested PR descriptions as Markdown files.
- Keep release notes concise.
- Check `ARCHITECTURE.md` and `LIBRARIAN.md` in the repository root or `docs/`
  when present.

## Portable capabilities

Shared skills live under `~/.agents/skills/`. Harness-specific agents and command
adapters may expose those skills through native paths, but the shared skill is the
source of truth.

- Before changing shared harness instructions, skills, agents, commands,
  adapters, or validation tooling, read `~/.agents/harness-instructions.md`.
