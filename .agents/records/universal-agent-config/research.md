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

## Junie and OpenCode live-validation research (2026-08-27)

- Neither `junie` nor `opencode` is currently installed, and neither is declared
  in the current `Brewfile`.
- Installation is not required to identify schema errors: current official docs
  are sufficient to show that the generated adapters have drifted. Installation
  is required to close the limitation with evidence that the actual released
  binaries discover, list, and invoke the generated definitions.
- Junie's current subagent schema uses case-sensitive built-in tool groups such
  as `Read`, `Bash`, `Glob`, `Grep`, `Write`, `Edit`, and `WebSearch`. The
  generated lowercase `read`, `search`, `web`, `write`, and `shell` values do not
  match that documented vocabulary. `model` is optional and supported names
  depend on the installed environment, so emitting the literal `default` without
  live evidence is unnecessary risk. Commands use `~/.junie/commands`,
  `description`, `allowPromptArgument`, and `$prompt` as currently documented.
  <https://junie.jetbrains.com/docs/junie-cli-subagents.html>
  <https://junie.jetbrains.com/docs/custom-slash-commands.html>
- Junie's stable CLI is installed by its official shell installer. `--version`
  and `--help` do not require authentication, but a genuine headless task does.
  The CLI supports explicit agent and command locations, which can isolate
  discovery tests. Authentication can use a JetBrains account/token or BYOK and
  must remain a user-controlled step.
  <https://junie.jetbrains.com/docs/junie-cli.html>
  <https://junie.jetbrains.com/docs/parameters.html>
- OpenCode's current Markdown agent schema uses singular `permission`; the
  permission key for shell execution is `bash`, not `shell`. Its documented
  `model` values use `provider/model`, so the generated literal `default` should
  be omitted. `mode: subagent` is valid. Its command directory, `description`,
  and `$ARGUMENTS` usage match current documentation.
  <https://opencode.ai/docs/agents/>
  <https://opencode.ai/v2/docs/commands>
- OpenCode can be installed through its maintained Homebrew tap and exposes
  `opencode agent list`, allowing discovery validation without invoking a model.
  An authenticated `opencode run` is only needed for an end-to-end command or
  agent execution smoke test.
  <https://github.com/anomalyco/opencode>
  <https://dev.opencode.ai/docs/cli/>
- Durable `research.md` and `plan.md` records already contain decisions,
  limitations, and verification history that are not recoverable from generated
  configuration alone. Retaining them is justified; the removed one-use PR body
  remains the correct boundary between durable records and delivery scratch.

## Operator decision — 2026-08-27

Junie and OpenCode installation, schema remediation, and live validation are
deferred. Their adapters in PR #1 provide initial, experimental support only;
they are not a compatibility claim. Preserve the source-backed findings and
validation checklist as future work, and retain this research together with
`plan.md` as the durable decision record.

## Third-review minor findings (2026-08-28)

Claude's third pass reports no blockers and six minor items. Inspection of the
applied generator, wrappers, hooks, configuration, and behavioral tests confirms
the following dispositions.

### 1. Collision validation is absent from pre-push

Confirmed. `~/.config/yadm/hooks/pre_push` invokes
`sync-adapters.sh --check`, while collision detection runs only in the separate
`--validate-skills` mode. A tracked `~/.claude/commands/<skill>.md` can therefore
pass pre-push. The narrow fix is to make ordinary generator checks validate
skills and collisions before rendering, so every caller of `--check` receives
the same safety property. Keep the explicit validation mode for focused setup
diagnostics.

The behavioral test must demonstrate the actual gate: create a colliding command
and observe `--check` fail, not merely call the dedicated validator.

### 2. Human-facing generated/experimental labels

Confirmed as a discoverability trade-off, but the proposed arbitrary
`generated: true` frontmatter is not safe. The sidecar was introduced precisely
to avoid adding generator-only data to harness inputs, and Junie/OpenCode schema
compatibility is already explicitly deferred. Unknown frontmatter could be
ignored, rejected, or enter model context depending on the harness.

Do not restore per-file markers or add undocumented metadata. Keep ownership in
`generated-adapters.yaml`; retain experimental-status disclosure in the durable
records and PR limitations. A point-of-edit signpost should wait for a verified
harness-native metadata or filesystem mechanism.

### 3. Crash window between file and manifest writes

The narrow window is real, but the suggested condition
`current_hash in {ownership.get(key), desired}` does not close the described
case. If generation A writes a file and crashes before its manifest update, then
the canonical source changes to generation B, the on-disk hash is A, the
manifest hash is older, and `desired` is B; the current hash matches neither.

Closing this fully requires recoverable transaction state (for example a
pending manifest/journal written before target replacement), not a one-line
authorization relaxation. The present fail-closed behavior prevents data loss,
and an unchanged canonical source self-heals on the next apply. Defer the more
complex journal design unless this rare manual-recovery case proves costly.

### 4. Pre-manifest orphans

Confirmed and accepted. Unrecorded files that are not desired targets remain
untouched. Automatically scanning adapter directories would risk deleting or
rejecting legitimate harness-local files because those directories are not
declared generator-exclusive. Yadm still exposes tracked removals. Preserve the
safe rule that only manifest-owned stale files may be reaped.

### 5. Dead Claude command rendering

Confirmed. `render_commands()` constructs a Claude value that cannot be selected
because `command_directories` intentionally omits Claude. Remove the dead entry;
this reduces confusion and prevents accidental reactivation beside the collision
guard. Add a behavioral assertion that no Claude command adapter is emitted.

### 6. Duplicate hardcoded skills-link verification

Confirmed. `verify-setup.sh` checks the Claude skills symlink directly and then
runs the generator check, which already validates the configured
`skill_adapters` target. The direct check also uses `$HOME` rather than
`ADAPTER_HOME`, weakening isolated verification. Remove both hardcoded symlink
checks and rely on the configured generator preflight. Existing behavioral tests
continue to assert the resolved link target.

### Python review note

The planned Python edit is small and typed, with no new public API, dependency,
async, resource, or exception surface. This repository has no `pyproject.toml`
or configured Python type checker, so the Python-reviewer policy cannot provide
type-review sign-off. Ruff, Python compilation, and behavioral tests remain the
available gates; absence of a type checker should be reported rather than hidden.

## Harness-maintainer guide research (2026-08-28)

### Intended artifact and audience

The requested `~/.agents/harness-instructions.md` should be a human- and
agent-maintainer guide, not another automatically loaded instruction source.
Its lowercase name is intentional: the canonical always-loaded instructions
remain `~/.agents/AGENTS.md`, while this document explains how to maintain the
adapter system without adding context to every harness session.

The guide should answer five questions for each harness:

1. Which canonical files are edited?
2. Which native locations consume generated or linked adapters?
3. Which capabilities are native, adapted, partial, or unverified?
4. How is discovery and behavior verified?
5. Which official documentation must be rechecked before changing schemas?

### Current repository contract

- `~/.agents/AGENTS.md`, `skills/`, `prompts/`, and `commands/` are canonical.
- `~/.agents/adapters.yaml` declares native instruction, skill, agent, and
  command destinations. `generate_adapters.py` translates canonical metadata to
  harness-specific frontmatter and owns generated regular files through the
  SHA-256 `generated-adapters.yaml` sidecar.
- The generator refuses unmanaged-file overwrite, modified stale-file deletion,
  paths outside `ADAPTER_HOME`, malformed manifests, invalid skills, and
  configured skill/command collisions. Ordinary `--check` and `--apply` both
  validate skills first.
- Maintainers edit canonical sources, never generated adapters. The supported
  sequence is generator `--check`, canonical edit, `--apply`, setup and
  behavioral verification, then review both generated diff and manifest diff.
- Current locally installed versions are Claude Code 2.1.250, Codex CLI 0.149.1,
  and Amp build `0.0.1775636421-g1ea6b1`. Junie and OpenCode are not installed.

### Claude Code

- Global instructions are discovered at `~/.claude/CLAUDE.md`; Claude reads
  `CLAUDE.md`, not `AGENTS.md`, and official docs explicitly allow a symlink when
  no Claude-specific suffix is needed. The current repository links this path to
  `~/.agents/AGENTS.md`.
- Personal skills live under `~/.claude/skills/<name>/SKILL.md`; the repository
  links the whole skills directory to `~/.agents/skills`. Personal subagents live
  at `~/.claude/agents/*.md` and are rendered from canonical prompts.
- Current official docs say skills take precedence over same-name legacy command
  files. The installed setup previously observed the inverse and therefore keeps
  the conservative collision guard. This must be described as version-sensitive
  evidence, not a universal rule. Use `/context`, skill listing/invocation,
  delegated-agent smoke tests, and `claude --version` when revalidating.
- Official sources:
  <https://code.claude.com/docs/en/memory>,
  <https://code.claude.com/docs/en/skills>, and
  <https://code.claude.com/docs/en/sub-agents>.

### Codex

- The repository links `~/.codex/AGENTS.md` to the canonical instructions and
  exposes portable skills directly from `~/.agents/skills` in the active Codex
  environment. Workflow adapters are generated into `~/.codex/prompts`.
- Skills are supported by the current OpenAI skill format, and Codex has native
  AGENTS.md and subagent documentation. The guide should link official OpenAI
  documentation rather than restating volatile UI or precedence details.
- Instruction and skill discovery are working in the current setup. Custom
  prompt discovery still needs confirmation in a fresh interactive session and
  must remain labeled partial until observed.
- Official sources:
  <https://learn.chatgpt.com/docs/agent-configuration/agents-md>,
  <https://learn.chatgpt.com/docs/agent-configuration/subagents>, and
  <https://learn.chatgpt.com/docs/build-skills>.

### Amp

- Amp automatically includes both `~/.config/amp/AGENTS.md` and
  `~/.config/AGENTS.md`; the repository uses the latter as a link to the
  canonical instructions. Amp skill discovery from `~/.agents/skills` has been
  live-verified for Oracle, Librarian, and the workflow skills.
- Amp provides native subagents but no generated role-agent files are maintained
  in this repository. Workflow parity is skill-based, not a claim that Amp has
  the same custom Markdown command surface as other harnesses.
- Revalidation should use the command-palette `agents-md list`, skill listing and
  invocation, and a minimal subagent task.
- Official sources:
  <https://ampcode.com/docs/customize/agents-md> and
  <https://ampcode.com/docs/models-and-subagents>.

### JetBrains Junie

- The repository links `~/.junie/AGENTS.md` to canonical instructions, generates
  subagents under `~/.junie/agents`, and generates workflow commands under
  `~/.junie/commands`. Junie now also documents direct discovery of
  `~/.agents/skills` and user-scope `~/.agents` subagents.
- Current Junie documentation uses case-sensitive tool groups and supports
  command frontmatter with `allowPromptArgument` plus `$prompt`. The current
  generated agent tool/model metadata is known to have schema drift and remains
  initial, experimental support. Do not present generated Junie agents as
  compatible until the deferred schema plan is implemented and tested with an
  installed CLI.
- Revalidation should record the installed version, inspect `/skills` and
  `/commands`, confirm instruction and subagent discovery, then run isolated
  permission/delegation smoke tests only with operator authorization for any
  authenticated or paid call.
- Official sources:
  <https://junie.jetbrains.com/docs/guidelines-and-memory.html>,
  <https://junie.jetbrains.com/docs/agent-skills.html>,
  <https://junie.jetbrains.com/docs/junie-cli-subagents.html>, and
  <https://junie.jetbrains.com/docs/custom-slash-commands.html>.

### OpenCode

- The repository links `~/.config/opencode/AGENTS.md` to canonical instructions,
  generates agents under `~/.config/opencode/agents`, and generates commands
  under `~/.config/opencode/commands`. OpenCode directly discovers global
  `~/.agents/skills/<name>/SKILL.md`.
- Current official agent metadata uses singular `permission` and the `bash` key;
  the generated plural `permissions`, `shell`, and literal `model: default` are
  known schema drift. Support remains initial and experimental until the
  deferred correction and installed-CLI validation are completed.
- Revalidation should use rule/skill discovery, `opencode agent list`, command
  discovery, and isolated permission smoke tests. Authentication or paid model
  calls require explicit operator authorization.
- Official sources: <https://opencode.ai/docs/rules>,
  <https://opencode.ai/docs/skills>, <https://opencode.ai/docs/agents/>, and
  <https://opencode.ai/docs/commands>.

### Required maintenance shape

The future guide should contain:

- a canonical-to-native mapping table;
- per-harness capability/status sections;
- an edit/regenerate/verify checklist;
- rules for adding a skill, prompt/agent, command, or new harness;
- ownership, stale cleanup, collision, and symlink safety notes;
- a versioned validation-evidence table with `verified`, `partial`, and
  `experimental` labels;
- primary-documentation links and a reminder to recheck them before schema work;
- troubleshooting for drift, unmanaged files, command collisions, and newly
  created discovery directories that may require a session restart.

The guide should not duplicate all schemas or list every generated file. Those
details would drift. It should point to `adapters.yaml`, generator rendering
functions, tests, and official docs as the live sources of truth.

## Fourth-review regression research (2026-08-28)

Claude's fourth pass compares the branch against `origin/master` specifically
for lost Claude Code behavior. Direct comparison confirms two functional
regressions and one description-quality regression.

### R1: `ai-apple-engineer` lost web tools — confirmed

On `origin/master`, the role had `WebFetch` and `WebSearch`. The generated branch
agent has neither because canonical metadata classifies it as `developer`, and
`claude_tools()` uses a fixed developer bundle with no additive web capability.
The role's cloud APIs and Apple/AI framework remit makes current documentation
access intentional, not incidental.

The narrow correction is a canonical `web: true` capability on
`~/.agents/prompts/ai-apple-engineer.md`, parsed as a required boolean with a
default of `false`. Extend `claude_tools()` with a keyword-only `web` argument
that adds `WebSearch` and `WebFetch` without changing model class, write/edit,
or shell semantics. Other harness output must remain unchanged in this pass;
Junie/OpenCode schema remediation is still deferred.

A behavioral test must assert the regenerated Claude agent contains both web
tools and that an ordinary developer without `web: true` does not gain them.

### R2: three reviewers gained Bash — confirmed

`apple-reviewer`, `ml-reviewer`, and `full-reviewer` had only `Read, Glob, Grep`
on `origin/master`; each generated branch agent also has `Bash` and `Skill`.
The canonical prompt schema already has two independent axes:

- `read_only` controls direct `Write`/`Edit` tools;
- `shell` controls Bash availability.

Therefore, globally stripping Bash whenever `read_only` is true would be a new
regression. `python-reviewer`, `rust-reviewer`, `solidity-reviewer`, and
`typescript-reviewer` are also `read_only: true`, but intentionally had Bash on
master and still have it on the branch so they can run checks. The precise fix
is to add `shell: false` to only the three affected canonical prompts. The
existing renderer already honors that flag.

The term `read_only` remains imperfect because shell can mutate, but within the
current two-axis schema it means no direct edit tools rather than a security
sandbox. `shell: false` expresses strict no-shell roles. The maintainer guide
should document this distinction so future changes do not infer enforcement
from the name alone.

Behavioral tests must assert the three restored agents omit Bash while a
language reviewer such as `python-reviewer` retains Bash.

### N1: three skill descriptions lost literal syntax — confirmed

The canonical branch descriptions changed meaningful retrieval tokens:

- `rust-architect`: `Arc<Mutex<T>> or channel` became `Arc plus Mutex or channel`;
- `rust-developer`: `Arc<Mutex>` became `Arc plus Mutex`;
- `solidity-reviewer`: `<id>` / `<reason>` placeholders became plain `ID` /
  `reason`.

Folded block scalars solve the YAML colon-space problem without requiring these
text substitutions. Restore the exact literal syntax inside the existing `>-`
descriptions and validate all 34 skill frontmatter documents with PyYAML. This
is a retrieval and documentation correction, not a schema change.

### N2: capability catalogue removal — no restoration planned

The removed Claude-only catalogue duplicated generated discovery and created a
drift surface. Current universal instructions already require Oracle/Librarian
consultation, and each team/reviewer skill declares its own composition. A
single portable pairing rule may be useful later if observed invocation behavior
shows agents failing to combine `pr-review` with language reviewers, but the old
catalogue should not be restored merely for parity.

### N3: orphaned legacy file — deferred

`~/.config/agents/research-plan-implement.md` remains tracked but unused. Its
cleanup belongs with the post-merge record/legacy cleanup the operator already
deferred, not this regression fix.

### Python-review boundary

The generator change is small and typed, but the repository still has no
configured Python type checker, so the Python-reviewer policy cannot provide
type-review sign-off. Required evidence remains Ruff, Python compilation,
PyYAML parsing, behavioral tests, generator/setup checks, and explicit
master-versus-generated capability assertions.

### Operator annotation: portable shell semantics (2026-08-29)

The operator accepted cross-harness propagation of `shell: false`. The three
reviewer roles must lose shell capability in Claude, Junie, and OpenCode rather
than introducing a Claude-only metadata flag. Junie/OpenCode remain
experimental because their broader schemas are unverified; this change only
keeps the canonical no-shell intent consistent across generated adapters.

### Additional parity finding: `ai-architect` Bash (2026-08-29)

The implementation plan's all-agent semantic comparison found that
`ai-architect` lost Bash relative to `origin/master`; the external review had
incorrectly categorized its tool difference as ordering only. Other architect
roles did not have Bash on master. The operator approved tri-state `shell`
metadata: omitted preserves the bundle, explicit true adds shell, and explicit
false removes it. `ai-architect` alone receives `shell: true`.
