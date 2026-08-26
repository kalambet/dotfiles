## Summary

- make `~/.agents` the canonical source for shared instructions, skills, agent prompts, and workflow commands
- add generated Claude, Codex, Amp, Junie, and OpenCode adapters
- add portable Oracle, Librarian, and Research → Plan → Implement capabilities

## Verification

- validated all 34 Agent Skills
- verified adapter generation is idempotent and detects drift
- verified symlinks and generated-file ownership
- verified Amp discovers the canonical Oracle, Librarian, and workflow skills
- ran Ruff, Python compilation, and shell syntax checks plus a staged secret-pattern scan

## Limitations

- Junie, OpenCode, and Hermes were not installed; their adapters are statically verified only
- Codex custom prompt discovery needs confirmation in a fresh interactive session
