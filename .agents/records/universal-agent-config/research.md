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
## Generated-marker research (2026-08-27)

### Current behavior

- `generate_adapters.py` inserts the same HTML comment into every generated
  agent and command body. For agents, the comment follows YAML frontmatter and
  is therefore part of the system prompt. For Codex prompts it is the first
  line of the submitted prompt.
- Ownership is currently inferred solely by searching the existing file for
  that marker. This refuses clearly unmanaged files, but any unrelated file
  containing the string is treated as generator-owned, and removing the marker
  from generated output would remove the only ownership evidence.
- Symlink ownership already uses a stronger mechanism: the generator compares
  the link target rather than embedding metadata in consumed content.

### Harness format evidence

- Claude Code documents a fixed set of supported subagent frontmatter fields
  and states that the Markdown body becomes the subagent system prompt. It does
  not document an ignored ownership/comment field. Adding a private frontmatter
  key would therefore depend on undocumented parser behavior.
  <https://code.claude.com/docs/en/sub-agents>
- Claude now treats legacy `.claude/commands/*.md` and skills as the same prompt
  mechanism; the full Markdown instructions are loaded when invoked. There is
  no documented out-of-band generated-file metadata field.
  <https://code.claude.com/docs/en/slash-commands>
- Junie documents supported subagent and command frontmatter fields and states
  that the body is the system prompt or command prompt. It does not document a
  generator-ownership field.
  <https://junie.jetbrains.com/docs/junie-cli-subagents.html>
  <https://junie.jetbrains.com/docs/custom-slash-commands.html>
- OpenCode likewise defines agent and command frontmatter as runtime
  configuration and the Markdown body as the system prompt/template. Its
  documented field sets do not provide generator ownership metadata.
  <https://opencode.ai/docs/agents/>
  <https://opencode.ai/v2/docs/commands>

Applicable documentation was checked on 2026-08-27. Junie and OpenCode evolve
quickly, but relying on undocumented ignored keys would remain less portable
even if a particular current parser tolerated them.

### Design implications

- Moving the HTML comment into frontmatter is not a safe universal solution:
  it either invents unsupported keys or overloads user-visible fields.
- Removing ownership checks would regress the generator's central collision
  guarantee.
- A sidecar ownership manifest is harness-neutral. It can record each generated
  regular file's path and cryptographic digest while leaving consumed Markdown
  clean. Before overwriting, the generator can require the current file digest
  to match the manifest's recorded digest. A user-edited generated file then
  refuses safely; an unchanged prior generation can be replaced when canonical
  input changes.
- The manifest itself should be canonical generator state under `~/.agents`,
  tracked by yadm, deterministic, and updated atomically after all output files
  are written. It must not authorize a path merely because the path is listed:
  the recorded digest must match the current bytes.
- Symlinks should remain target-validated and need not enter the file-digest
  manifest.
- Migration needs one explicit trust bridge for files produced by the current
  marker-based version. The narrow safe bridge is: accept a current file only
  when it contains the exact legacy marker and otherwise refuse; after the first
  successful apply, write clean content plus its digest to the manifest. Future
  ownership checks use only the manifest. The legacy marker must not remain an
  evergreen authorization path after migration.

### Verification requirements

- Assert no generated Markdown contains the legacy marker.
- Assert agent bodies and Codex prompt bodies begin with canonical content, not
  generator instructions.
- Deliberately edit a manifest-owned file and observe both `--check` and
  `--apply` refuse without changing any other target or the manifest.
- Change canonical input while leaving generated output untouched; confirm
  `--apply` accepts the old recorded digest, regenerates the file, and updates
  the digest.
- Delete the manifest and confirm ordinary marker-free files are treated as
  unmanaged. Separately exercise the one-time legacy migration fixture.
- Generate two isolated homes and byte-compare both outputs and manifests.

### Research conclusion

Use a deterministic sidecar digest manifest rather than harness-specific
frontmatter. This removes generator text from model context while preserving
and strengthening collision refusal across all adapter formats. The next phase
should specify manifest schema, migration lifecycle, write ordering, and failure
recovery in `plan.md` before implementation.
