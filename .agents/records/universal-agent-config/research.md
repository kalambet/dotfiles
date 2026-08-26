# Research: Claude and universal agent configuration

Date: 2026-08-26

## Scope

This document inventories the current user-level instruction, skill, agent, and
workflow configuration and identifies what can be shared across Claude Code and
other agent harnesses. It does not prescribe file changes; those belong in the
next `plan.md` phase after review.

## Current configuration

### Instructions

- `~/.claude/CLAUDE.md` is the maintained Claude Code instruction file and is
  tracked by `yadm`.
- `~/.codex/AGENTS.md` is a separate copy with older content. It is not the same
  document as `~/.claude/CLAUDE.md` and is not tracked by `yadm`.
- There is no `~/.agents/AGENTS.md` and no project-independent canonical
  `AGENTS.md` shared by harnesses.
- The two existing instruction files have already drifted:
  `~/.claude/CLAUDE.md` has the expanded language, architecture, process, team,
  and agent catalog, while `~/.codex/AGENTS.md` still advertises the absent
  `shell-scripting` skill and has the shorter catalog.
- Both files require Oracle and Librarian, but neither an Oracle/Librarian agent
  nor a corresponding skill is installed. Those instructions cannot currently
  be fulfilled by Claude or universal harnesses.
- Both files refer to phase commands in `.config/agents/`. Only
  `~/.config/agents/research-plan-implement.md` exists. This is a workflow prompt,
  not an Agent Skill or a portable subagent definition.

### Skills

- `~/.claude/skills/` and `~/.agents/skills/` are separate real directories,
  not symlinks.
- Both contain the same 29 named skill directories. Most mirrored `SKILL.md`
  files are byte-identical.
- Seven mirrored skills have divergent `SKILL.md` files:
  `apple-dev`, `apple-reviewer`, `ml-reviewer`, `pickup`,
  `research-plan-implement`, `system-design-team`, and `warp`.
- The first three divergences are wording/metadata edits. `pickup`,
  `research-plan-implement`, and `warp` contain explicit harness names or paths
  (`CLAUDE.md` versus `AGENTS.md`, Claude versus Codex transcript locations).
  They are therefore not currently safe to collapse blindly.
- `system-design-team` is a substantial structural divergence. The Claude copy
  is the newer split-reference implementation and has four reference files;
  the universal copy is an older monolithic implementation without those
  references.
- Claude's tree contains additional non-skill content: `.venv` and
  `research-plan-implement.skill`.
- Only the `.claude/skills` tree is tracked by `yadm`; `.agents/skills` is not.
  As a result, the purported universal tree is neither the source of truth nor
  reproducible from the dotfile repository.
- The Agent Skills specification standardizes the contents of a skill directory
  (`SKILL.md`, optional `scripts/`, `references/`, and `assets/`). It does not
  mandate an installation path. Its client guidance identifies
  `~/.agents/skills/` as the cross-client interoperability convention and
  client-specific directories such as `~/.claude/skills/` as adapters.
- Project-level `.agents/skills/` overrides user-level skills in compatible
  clients. Duplicate user-level copies with the same `name` can have
  client-dependent precedence, so leaving both populated invites silent drift.

### Agents and teams

- Twenty Claude-specific subagent definitions exist in `~/.claude/agents/` and
  are tracked by `yadm`.
- Their frontmatter uses Claude Code concepts such as Claude tool names,
  `skills:`, and model aliases such as `sonnet`. This format is not defined by
  either the AGENTS.md standard or the Agent Skills specification.
- There is no `~/.agents/agents/` universal mirror.
- There is no cross-harness standard for executable subagent definitions
  equivalent to the standards for AGENTS.md and SKILL.md. Each harness needs an
  adapter or generated definition using its own tools, model names, and
  delegation mechanism.
- Team skills are more portable than subagent files because they are plain Agent
  Skills, but their instructions currently assume named subagents exist and that
  the harness exposes compatible delegation primitives. Their compatibility
  requirements should be explicit.

## Standards boundary

### Portable

- Repository instructions in `AGENTS.md`. The open AGENTS.md convention uses
  ordinary Markdown and supports nested files, with the closest applicable file
  taking precedence.
- Skill packages conforming to the Agent Skills `SKILL.md` specification.
- Domain knowledge, review checklists, templates, and scripts that do not name a
  harness-specific tool or state path.

### Not inherently portable

- User-global instruction discovery. Harnesses differ on global paths even when
  they support repository-level `AGENTS.md`.
- Subagent definition formats, model selectors, tool allowlists, delegation APIs,
  and lifecycle behavior.
- Slash-command discovery under `~/.config/agents/`.
- Transcript/session paths used by `warp` and `pickup`.
- Instructions that require unavailable named capabilities such as Oracle and
  Librarian.

## Source-of-truth implications

- Making `AGENTS.md` a symlink to `CLAUDE.md` would make Claude-specific content
  the universal contract and propagate unsupported agent names and paths.
- Making the whole `~/.claude/skills` directory a symlink to
  `~/.agents/skills` now would hide the newer Claude `system-design-team`, lose
  Claude-only auxiliary content from that path, and select older variants for
  several skills.
- The stable direction is a universal core with thin harness adapters:
  `AGENTS.md` for shared behavior, Agent Skills under `~/.agents/skills/` for
  shared capabilities, and Claude-specific instruction/agent layers that refer
  to the shared core without duplicating it.
- Harness-specific behavior inside otherwise shared skills should be isolated in
  small adapters or selected dynamically from documented compatibility rules;
  maintaining full duplicate skill trees is the current source of drift.

## Decisions needed before planning

1. Whether `~/.agents/` becomes the tracked canonical source or whether a new
   neutral source directory is tracked and materialized into each harness.
2. Whether Claude should consume shared skills directly from `~/.agents/skills`
   (if its installed version discovers that location) or through per-skill
   symlinks in `~/.claude/skills`.
3. Which side of each of the seven divergent skills is authoritative, especially
   `system-design-team`, `warp`, and `pickup`.
4. Whether Oracle and Librarian should be implemented, mapped to available
   agents/tools, or removed from the shared instructions.
5. Which non-Claude harnesses must be supported beyond Codex; agent adapters
   cannot be designed correctly without a target list.
6. Whether slash commands are required in both harnesses or whether the
   `research-plan-implement` skill alone should be the portable workflow surface.

### Answers

1. Yes, it should be part of the portable workflow surface and sits in yadm dotfiles repo.
2. I do not have preferences, I would rather think about most optimial solution with as less repetitive work and copypasting.
3. Can we convert `system-design-team`, `warp`, and `pickup` to a Clodex cmaptible format?
4. Yes please, let's implement them.
5. Amp, Jetbrains Juni, Open Code, Hermes Agent
6. Slash commands are required in all harnesses.
7. About `research-plan-implement`. This is the most important skill to have in the portable workflow surface.I want for any harness to create a research, plan docs and then execute the plan issue by issue.

## Evidence and references

- Local inventory: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.claude/skills/`, `~/.agents/skills/`, `~/.claude/agents/`,
  `~/.config/agents/`, and `yadm ls-files` as inspected on 2026-08-26.
- AGENTS.md open convention: <https://agents.md/>
- Agent Skills specification: <https://agentskills.io/specification>
- Agent Skills client path guidance:
  <https://agentskills.io/client-implementation/adding-skills-support>
- Official OpenAI documentation was checked for Codex configuration; it did not
  establish a universal subagent-definition format. The portable conclusion is
  therefore limited to AGENTS.md and Agent Skills rather than inferred from a
  Codex-specific mechanism.
