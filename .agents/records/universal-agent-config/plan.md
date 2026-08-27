# Plan: Universal agent configuration with Claude adapters

Date: 2026-08-26
Status: Revised after annotation; awaiting explicit implementation approval


## Implementation status

- Completed: canonical instructions, 34 validated skills, 23 canonical agent prompts, Claude/Codex/Amp/Junie/OpenCode adapters, YAML-driven generation, idempotence and negative drift checks, secret scan, and Amp discovery.
- Live verified: Claude filesystem discovery contract and Amp skill discovery.
- Statically verified only: Junie and OpenCode adapters (CLIs unavailable).
- Partially verified: Codex instructions and skills; custom prompt UI requires a fresh interactive session.
- Not configured or live-tested: Hermes (CLI unavailable; canonical skills remain compatible and ready for external-skill configuration).
- Delivery: dedicated `refactor/universal-agent-config` branch; PR required and must not be merged by the agent.

## Goal

Create one `yadm`-tracked, portable source of truth for instructions, Agent
Skills, workflow commands, and reusable agent prompts. Claude Code, Codex, Amp,
JetBrains Junie, OpenCode, and Hermes Agent will consume that source through the
smallest native adapter each harness requires.

The migration must preserve current skill content, eliminate duplicate editable
copies, implement Oracle and Librarian where the harness does not already provide
them, and make Research → Plan → Annotate → Implement available in every target
harness. Implementation remains blocked until this plan is approved.

## Architecture

```text
~/.agents/                         # canonical, portable, yadm-tracked
├── AGENTS.md                      # shared behavioral instructions
├── skills/                        # canonical Agent Skills
│   ├── research-plan-implement/
│   ├── oracle/
│   ├── librarian/
│   └── ...
├── prompts/                       # canonical role bodies, not discovered directly
│   ├── oracle.md
│   ├── librarian.md
│   └── existing-agent-prompts...
├── commands/                      # canonical workflow prompt bodies
│   ├── research.md
│   ├── plan.md
│   └── implement.md
├── adapters.yaml                  # harness path/model/tool mapping
└── scripts/
    ├── sync-adapters.sh           # deterministic adapter materialization
    └── verify-setup.sh            # drift/discovery validation

Harness-native adapters
├── ~/.claude/CLAUDE.md
├── ~/.claude/skills -> ~/.agents/skills
├── ~/.claude/agents/*.md
├── ~/.claude/commands/*.md
├── ~/.codex/AGENTS.md
├── ~/.codex/prompts/*.md
├── ~/.config/AGENTS.md            # Amp global instructions
├── ~/.junie/AGENTS.md
├── ~/.junie/agents/*.md
├── ~/.junie/commands/*.md
├── ~/.config/opencode/AGENTS.md
├── ~/.config/opencode/agents/*.md
├── ~/.config/opencode/commands/*.md
└── ~/.hermes/...                  # profile/skill adapter; no fake Markdown-agent format
```

`~/.agents/` is the only editable source. Generated adapter files carry a header
stating their source and are overwritten only by `sync-adapters.sh`. Directories
that a harness can consume natively are symlinked instead of copied.

## Phase 1: Establish the canonical instruction layer

### Files

- Add `~/.agents/AGENTS.md` to `yadm`.
- Replace `~/.claude/CLAUDE.md` with a thin Claude-specific adapter.
- Materialize or link global adapters for Codex, Amp, Junie, and OpenCode.
- Add a documented Hermes instruction adapter only after verifying its installed
  version/profile discovery behavior locally.

### Shared content

Move harness-neutral material from the current `~/.claude/CLAUDE.md` into
`~/.agents/AGENTS.md`:

## General

## Required workflow

For substantial work, invoke `research-plan-implement` and do not implement
until the user approves `plan.md`.

## Specialist consultation

- Consult Oracle for complex planning, debugging, architecture, and security.
- Consult Librarian for documentation, external-source research, code review
  references, and current best practices.
```

Remove the nonexistent `shell-scripting` declaration unless that skill is added
as a separately approved follow-up. Replace hard-coded `.config/agents/` claims
with portable skill/command language.

### Claude adapter

Keep Claude-only facts out of the universal file:

```md
@../.agents/AGENTS.md

## Claude Code adapter

- Claude subagent definitions live in `~/.claude/agents/`.
- Use Claude's Oracle and Librarian adapters when the shared instructions require
  those roles.
```

If Claude's global import syntax does not resolve a parent-relative file in the
installed version, generate the shared content into `CLAUDE.md` with clearly
delimited managed blocks instead of using an unsupported symlink/import.

### Other global adapters

- Codex: `~/.codex/AGENTS.md`
- Amp: `~/.config/AGENTS.md` (documented global path)
- Junie: `~/.junie/AGENTS.md` (documented global path)
- OpenCode: `~/.config/opencode/AGENTS.md` (documented global path)
- Hermes: use the installed profile's supported global/context mechanism; retain
  repository `AGENTS.md` discovery for project rules.

Prefer relative symlinks to `~/.agents/AGENTS.md` where the harness follows
symlinks and needs no extra content. Use generated adapters when harness-specific
content is required.

## Phase 2: Reconcile and canonicalize Agent Skills

### Canonical tree

1. Treat the current Claude skill tree as the base because it is tracked and has
   the newer `system-design-team` split-reference implementation.
2. Merge intentional universal wording from `~/.agents/skills` into that base.
3. Move the reconciled result to `~/.agents/skills` under `yadm`.
4. Remove duplicate tracked files under `~/.claude/skills` and replace that
   directory with a relative symlink to `../.agents/skills` only after verifying
   Claude discovers symlinked skill directories.
5. Move `.venv` out of the skills root or recreate it as untracked cache data;
   remove the obsolete `research-plan-implement.skill` package from the live
   discovery tree after preserving it if still needed as a release artifact.

### Divergence decisions

- `apple-dev`, `apple-reviewer`, `ml-reviewer`: retain the newer concise Claude
  wording unless validation shows lost trigger coverage.
- `system-design-team`: retain the newer split-reference implementation and move
  all four references into the canonical skill.
- `research-plan-implement`: remove Claude/Codex branding and cite the workflow
  generically.
- `pickup` and `warp`: make the main procedure harness-neutral and route session
  discovery through a small harness table/reference rather than embedding one
  transcript path in `SKILL.md`.

Example portable session reference:

```md
## Resume metadata

Identify the active harness, then read only its entry from
`references/harness-session-paths.md`. If the harness is unknown, omit a resume
ID and record the exact working tree state instead of guessing.
```

### Harness discovery

- Claude: `~/.claude/skills` symlink to canonical tree.
- Codex: direct discovery of `~/.agents/skills`.
- Amp: direct discovery of `~/.agents/skills`; do not also populate its
  higher-precedence `~/.config/agents/skills`, which would reintroduce masking.
- Junie: direct documented discovery of `~/.agents/skills`.
- OpenCode: direct documented discovery of `~/.agents/skills`.
- Hermes: configure its documented external skill directory support to scan
  `~/.agents/skills`; do not copy skills into `~/.hermes/skills` unless the
  installed version cannot use external directories.

Validate every canonical skill against the Agent Skills specification and check
relative references after the move.

## Phase 3: Refactor Research → Plan → Annotate → Implement

`research-plan-implement` remains the authoritative workflow skill. Split the
entry points without duplicating workflow rules:

- `~/.agents/commands/research.md`: invoke the skill, inspect deeply, write
  `research.md`, then stop.
- `~/.agents/commands/plan.md`: require reviewed `research.md`, write `plan.md`
  with paths/snippets/trade-offs, then stop for annotations.
- `~/.agents/commands/implement.md`: require explicit plan approval, add/consume
  the granular checklist, execute one plan issue at a time, mark each complete,
  verify continuously, and continue until the approved plan is finished.

The canonical skill will define the state contract:

```md
Research complete -> research.md exists and awaits review
Plan complete     -> plan.md exists and awaits annotation/approval
Implementation    -> only after explicit approval; execute checklist issue by issue
```

Each command adapter contains only native frontmatter/argument syntax and then
loads or repeats the canonical command body. Planned adapters:

- Claude: `~/.claude/commands/{research,plan,implement}.md`
- Codex: `~/.codex/prompts/{research,plan,implement}.md`, subject to installed
  Codex support verification because custom prompts have changed across releases
- Junie: `~/.junie/commands/*.md` with `allowPromptArgument: true`
- OpenCode: `~/.config/opencode/commands/*.md` using `$ARGUMENTS`
- Hermes: the canonical skill itself provides `/research-plan-implement`; add
  three thin skills or bundles named `/research`, `/plan`, and `/implement`
  because Hermes quick commands cannot contain prompt text
- Amp: Amp exposes Agent Skills but does not document generic Markdown slash
  commands. Use explicit skills named `research`, `plan`, and `implement` as the
  closest native command surface; do not claim unsupported `/command` behavior.

Where a harness automatically exposes skills as slash commands (Junie and
Hermes), avoid registering a duplicate command with the same name.

## Phase 4: Implement Oracle and Librarian as portable roles

Create both a skill and a canonical role prompt for each role:

```text
~/.agents/skills/oracle/SKILL.md
~/.agents/skills/librarian/SKILL.md
~/.agents/prompts/oracle.md
~/.agents/prompts/librarian.md
```

### Oracle contract

- Read-only analytical specialist by default.
- Receives a bounded question plus relevant local evidence.
- Used for complex plans, debugging hypotheses, architecture trade-offs, and
  security analysis.
- Returns recommendation, evidence, alternatives, uncertainty, and the next
  discriminating experiment.
- Never edits or silently expands scope.

### Librarian contract

- Read-only research specialist.
- Prioritizes primary/official sources and current documentation.
- For code review, checks documented conventions and upstream behavior.
- Returns source-linked findings, version/date scope, uncertainty, and a clear
  separation between sourced facts and inference.
- Never edits or treats search snippets as authoritative pages.

### Harness adapters

- Amp: use its built-in Oracle tool and Librarian subagent; do not shadow them.
- Claude: add `~/.claude/agents/{oracle,librarian}.md` with Claude tool names and
  read-only permissions.
- Codex: map Oracle to a high-reasoning general agent and Librarian to a
  read-only research/explorer agent through supported local agent configuration;
  otherwise invoke the skills from the main agent rather than inventing an
  unsupported definition.
- Junie: generate `~/.junie/agents/{oracle,librarian}.md` from the canonical
  prompts with Junie frontmatter and skill references.
- OpenCode: generate `~/.config/opencode/agents/{oracle,librarian}.md` with
  `mode: subagent` and deny edit/shell permissions where appropriate.
- Hermes: expose Oracle and Librarian as skills first. Optionally create named
  profiles only if true isolated subagents are required; profiles are stateful
  homes, not drop-in equivalents to Claude subagents.

The universal `AGENTS.md` will say "consult the Oracle/Librarian capability
available in the active harness," allowing Amp's built-ins and local adapters to
satisfy the same behavioral contract.

## Phase 5: Portable agent prompts and generated adapters

Do not symlink Claude agent files into other harnesses. Extract each agent's
harness-neutral body into `~/.agents/prompts/<name>.md`; retain tool/model/permission
selection in `~/.agents/adapters.yaml`.

Example configuration:

```yaml
agents:
  oracle:
    prompt: prompts/oracle.md
    read_only: true
    harnesses:
      claude:
        model: opus
        skills: [oracle]
      junie:
        model: default
        skills: [oracle]
      opencode:
        mode: subagent
        model: default
  librarian:
    prompt: prompts/librarian.md
    read_only: true
    harnesses:
      claude:
        model: sonnet
        skills: [librarian]
      junie:
        model: default
        skills: [librarian]
      opencode:
        mode: subagent
        model: default
```

Migrate Oracle, Librarian, and all twenty existing Claude agents in this
migration. Process the existing agents in a mechanical second batch after the
specialist/team dependencies are working. Amp and Hermes adapters are created
only where their native abstractions preserve the role; lack of a one-file
subagent format is not papered over with dead files.

## Phase 6: Adapter tooling

Add a YAML-driven POSIX-compatible shell workflow, following the user's config
preference:

- `adapters.yaml` is primary configuration.
- Environment variables may override paths for testing only.
- `sync-adapters.sh --check` reports drift without writing.
- `sync-adapters.sh --apply` creates parent directories, relative symlinks, and
  generated Markdown adapters.
- The script refuses to overwrite unmanaged files and writes through temporary
  files plus atomic rename.
- `verify-setup.sh` validates links, required files, skill frontmatter, duplicate
  names, broken references, yadm tracking, and harness discovery commands.
- No credentials or model API keys enter YAML or generated files.

The missing `shell-scripting` skill is not required to write these scripts; its
absence remains explicit. Script review should use ShellCheck if installed.

## Phase 7: Migration and verification

1. Back up the exact pre-migration path/type/checksum inventory in the plan's
   execution log; use `yadm` history as the recovery path for tracked files.
2. Reconcile divergent skills before deleting either copy.
3. Add canonical files to `yadm`.
4. Generate adapters in dry-run/check mode and inspect the diff.
5. Apply adapters without touching unrelated dotfiles.
6. Run syntax, link, and Agent Skills validation.
7. Start a fresh session in every installed target harness and verify:
   shared instructions loaded, canonical skills discovered, Oracle/Librarian
   callable, and research/plan/implement entry points visible.
8. Record unsupported or unavailable harnesses as untested rather than claiming
   compatibility.
9. Confirm `yadm status` contains only the approved migration files.
10. Create a dedicated branch in the `yadm` dotfiles repository, commit the
    canonical sources and generated adapters there, push it, and open a pull
    request. Do not commit directly to the default branch and do not merge the
    pull request.

## Expected file operations

### Canonical additions/moves

- Add `~/.agents/AGENTS.md`.
- Move/reconcile `~/.claude/skills/*` into `~/.agents/skills/*`.
- Add `~/.agents/prompts/`, `~/.agents/commands/`, `~/.agents/adapters.yaml`, and
  `~/.agents/scripts/`.

### Claude changes

- Replace `~/.claude/CLAUDE.md` with adapter/import content.
- Replace `~/.claude/skills` with a symlink after safe reconciliation.
- Regenerate `~/.claude/agents/*.md` from canonical prompts plus Claude metadata.
- Add `~/.claude/commands/*.md` where supported.

### Other harness adapters

- Update `~/.codex/AGENTS.md` and supported prompt/agent configuration.
- Add Amp global instruction adapter only; use native skills and built-in
  Oracle/Librarian.
- Add Junie global instruction, command, and subagent adapters.
- Add OpenCode global instruction, command, and subagent adapters.
- Configure Hermes external skills and the minimum profile/context adapter.

### Cleanup

- Remove duplicate editable skill copies only after checks pass.
- Remove stale references to absent `shell-scripting`.
- Remove or replace hard-coded Claude/Codex paths inside portable skills.
- Do not delete `.venv` or packaged artifacts until their purpose and recovery
  path are recorded during implementation.

## Trade-offs

- **Symlinks versus generation:** symlinks minimize drift for identical content;
  generation is required for different frontmatter/tool schemas. The plan uses
  both deliberately.
- **Universal agents are not standardized:** canonical prompt bodies reduce
  duplication, but adapter metadata remains necessary and should not pretend to
  be portable.
- **Slash-command parity is imperfect:** Junie, OpenCode, Claude, and Codex have
  command-file mechanisms; Hermes exposes skills as slash commands; Amp's native
  portable surface is skills. The workflow can be behaviorally consistent even
  where UI syntax differs.
- **Global instructions differ:** project `AGENTS.md` is portable; user-global
  discovery requires explicit per-harness links/adapters.
- **Hermes profiles are stateful:** creating profiles for every role adds
  operational state and should be avoided unless skill-based roles prove
  insufficient.
- **Generated files in dotfiles:** committing generated adapters improves
  reproducibility but creates diff noise. The generator and `--check` mode make
  drift explicit.
- **Delivery through PR:** both canonical sources and generated adapters are
  committed so a fresh checkout is reproducible, but all changes are delivered
  on a dedicated branch through a reviewable pull request rather than committed
  directly to the default branch.

## Validation criteria

- Exactly one editable copy of every shared skill exists.
- All canonical skills validate and all relative references resolve.
- `~/.claude/skills` exposes the canonical tree without a second copy.
- Shared instructions contain no unsupported harness-specific tool/path claims.
- Oracle and Librarian resolve to native built-ins or installed adapters in each
  tested harness.
- Research, plan, and implement entry points enforce the artifact gates and
  issue-by-issue checklist semantics.
- Adapter generation is idempotent: two consecutive runs produce no diff.
- `sync-adapters.sh --check` exits nonzero on deliberate drift.
- `yadm` tracks canonical sources and required adapters; no unrelated files are
  changed.

## Documentation references used

- AGENTS.md open convention: <https://agents.md/>
- Agent Skills specification and interoperability paths:
  <https://agentskills.io/specification> and
  <https://agentskills.io/client-implementation/adding-skills-support>
- Amp instructions, skills, and native Oracle/Librarian:
  <https://ampcode.com/docs/customize/agents-md>,
  <https://ampcode.com/docs/customize/skills>, and
  <https://ampcode.com/docs/tools>
- Junie skills, global guidelines, commands, and subagents:
  <https://junie.jetbrains.com/docs/agent-skills.html>,
  <https://junie.jetbrains.com/docs/guidelines-and-memory.html>,
  <https://junie.jetbrains.com/docs/custom-slash-commands.html>, and
  <https://junie.jetbrains.com/docs/junie-cli-subagents.html>
- OpenCode rules, skills, commands, and agents:
  <https://opencode.ai/docs/rules/>, <https://opencode.ai/docs/skills/>,
  <https://opencode.ai/v2/docs/commands>, and
  <https://opencode.ai/v2/docs/agents/>
- Hermes skills, commands, and profiles:
  <https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/>,
  <https://hermes-agent.nousresearch.com/docs/reference/slash-commands>, and
  <https://hermes-agent.nousresearch.com/docs/user-guide/profiles/>

## Resolved annotation decisions

1. Migrate all twenty existing Claude agents, plus the new Oracle and Librarian
   roles.
2. Commit canonical sources and generated adapters to `yadm`, but only on a
   dedicated branch delivered through a pull request. Do not commit directly to
   the default branch or merge the PR.
3. Behavioral command parity through skills is acceptable for Amp; literal slash
   command parity is not required there.
4. Remove the stale `shell-scripting` declaration. Do not create that skill in
   this migration.

## Implementation checklist

The implementation phase must execute and mark these items one by one. A checked
item means its verification passed, not merely that files were written.

### A. Safety and baseline

- [ ] Record the current branch, remote, `yadm status`, tracked-file list, path
      types, symlink targets, and checksums for every migration path.
- [ ] Confirm the default branch and create a dedicated migration branch without
      modifying or discarding unrelated worktree changes.
- [ ] Determine the purpose and recovery path for `.claude/skills/.venv` and
      `research-plan-implement.skill` before moving or removing either.
- [ ] Detect which target harness CLIs are installed and record their versions;
      mark missing harnesses as unavailable for live verification.

### B. Canonical instructions

- [ ] Create `~/.agents/AGENTS.md` from the shared content in
      `~/.claude/CLAUDE.md`.
- [ ] Remove `shell-scripting` and replace Claude/Codex-only path claims with
      portable capability language.
- [ ] Create and verify the thin Claude adapter/import.
- [ ] Create and verify Codex, Amp, Junie, OpenCode, and supported Hermes global
      instruction adapters.

### C. Canonical skills

- [ ] Reconcile `apple-dev`, `apple-reviewer`, and `ml-reviewer` into one version
      each without losing trigger coverage.
- [ ] Port the newer split-reference `system-design-team` and verify all four
      references.
- [ ] Make `research-plan-implement` harness-neutral and encode the artifact
      state gates.
- [ ] Make `pickup` and `warp` harness-neutral and add verified harness session
      path references.
- [ ] Move the reconciled skill collection into tracked `~/.agents/skills`.
- [ ] Replace `~/.claude/skills` with the verified relative symlink.
- [ ] Validate every skill's frontmatter, directory/name match, description
      length, and referenced files.

### D. Workflow entry points

- [ ] Create canonical `research`, `plan`, and `implement` workflow bodies.
- [ ] Ensure `implement` executes and marks the approved plan issue by issue.
- [ ] Generate Claude command adapters.
- [ ] Verify installed Codex prompt support and generate only supported adapters.
- [ ] Generate Junie command adapters with correct argument metadata.
- [ ] Generate OpenCode command adapters using its native argument syntax.
- [ ] Expose Hermes workflow skills/bundles without prompt-text quick commands.
- [ ] Expose Amp workflow skills and document behavioral rather than literal
      slash-command parity.

### E. Oracle and Librarian

- [ ] Create portable Oracle and Librarian Agent Skills.
- [ ] Create canonical read-only role prompts with evidence and uncertainty
      contracts.
- [ ] Generate and validate Claude adapters.
- [ ] Generate and validate Junie adapters.
- [ ] Generate and validate OpenCode adapters.
- [ ] Map Codex to supported local roles or explicitly fall back to skill-based
      invocation.
- [ ] Configure Hermes skill-based roles without unnecessary stateful profiles.
- [ ] Confirm Amp uses its native built-ins and is not shadowed.

### F. Remaining agents

- [ ] Extract harness-neutral bodies for all twenty existing Claude agents.
- [ ] Add every agent's harness mappings to `adapters.yaml`.
- [ ] Regenerate Claude agent definitions and compare their effective role,
      skills, model class, and permissions with the originals.
- [ ] Generate Junie/OpenCode adapters where their schemas preserve the role.
- [ ] Record intentional omissions for Amp, Codex, or Hermes rather than creating
      inert adapter files.

### G. Generator and validation tooling

- [ ] Implement YAML-driven `sync-adapters.sh` with `--check` and `--apply`.
- [ ] Implement atomic writes, managed-file markers, collision refusal, and
      environment-variable path overrides.
- [ ] Implement `verify-setup.sh` for links, skills, references, duplicates,
      tracking, and harness discovery.
- [ ] Run shell syntax checks and ShellCheck when available.
- [ ] Verify adapter generation is idempotent.
- [ ] Deliberately introduce temporary drift, confirm `--check` fails, then
      restore through the generator.

### H. Harness verification

- [ ] Verify Claude instructions, skills, agents, and workflow commands in a
      fresh session.
- [ ] Verify Codex instructions, skills, supported roles, and workflow prompts in
      a fresh session.
- [ ] Verify Amp instructions, canonical skills, workflow skills, and native
      Oracle/Librarian without masking.
- [ ] Verify Junie instructions, skills, subagents, and commands.
- [ ] Verify OpenCode instructions, skills, subagents, and commands.
- [ ] Verify Hermes external skills, workflow commands, and role skills.
- [ ] Record every unavailable or partially supported check explicitly.

### I. Review delivery

- [ ] Review the final diff for unrelated changes and secrets.
- [ ] Run final `sync-adapters.sh --check`, `verify-setup.sh`, and `yadm status`.
- [ ] Commit canonical and generated files on the dedicated branch.
- [ ] Push the branch and write a concise Markdown pull-request description.
- [ ] Open the pull request and report its URL and verification status; do not
      merge it.

## Claude review remediation (approved 2026-08-26)

The operator approved the following disposition after reviewing
`~/.claude/review-claude.md` item by item:

- [x] Define `read_only` consistently as prohibiting file edits while retaining
      shell access, and add an independent `shell` capability for roles such as
      Oracle and Librarian.
- [x] Generate Claude, Junie, and OpenCode permissions from those capabilities
      and verify Oracle/Librarian cannot edit or run shell commands.
- [x] Generate and verify all configured instruction symlinks, including Claude,
      with collision refusal and relative targets.
- [x] Make `AGENTS_ROOT` and `ADAPTER_HOME` genuine test-path overrides while
      preserving the existing defaults.
- [x] Preflight every generated target before writing so an unmanaged collision
      cannot cause a partial apply.
- [x] Move command descriptions into canonical command frontmatter and generate
      adapters from that metadata.
- [x] Update `pickup` and `warp` to read both `AGENTS.md` and a distinct
      `CLAUDE.md` when present.
- [x] Restore the linked Boris Tane attribution.
- [x] Add yadm bootstrap apply/verify integration and a pre-push drift check;
      avoid automatic mutation on every checkout or merge.
- [x] Add isolated behavioral checks for permissions, deterministic generation,
      instruction links, collision preflight, path overrides, and drift.
- [x] Keep the current generated marker; record Junie/OpenCode as statically
      verified until their CLIs are available.
- [x] Remove the tracked single-use PR-description artifact after updating the
      live PR body; retain `research.md` and `plan.md` as durable records.
- [x] Run all verification gates, update the PR, commit, and push without
      merging.

## Claude second-review remediation (approved 2026-08-27)

- [x] Stop generating Claude command files whose names collide with canonical
      skills; remove the three tracked generated Claude commands.
- [x] Reject skill/command name collisions during validation for harnesses that
      expose both through one namespace.
- [x] Make the yadm bootstrap fail early with an actionable `uv` prerequisite
      message instead of invoking a missing command.
- [x] Add configured skill-adapter symlinks and manage Claude's skill link
      through the generator, preflight, verification, and isolated tests.
- [x] Serialize command frontmatter with `safe_dump` rather than interpolating
      YAML scalars.
- [x] Replace the vacuous collision-test checksums with a real unchanged-file
      assertion and retain the missing-target assertion.
- [x] Report the exact failing path from `nested()` for malformed configuration.
- [x] Exercise both successful and deliberately failing checks, run all gates,
      update PR #1, commit, and push without merging.

## Remove generator markers from model context

Research approved: 2026-08-27. Implementation requires separate explicit
approval after review of this section.

### Decision

Replace the model-visible HTML ownership marker with a deterministic SHA-256
sidecar at `~/.agents/generated-adapters.yaml`. Do not add undocumented
frontmatter keys to Claude, Junie, OpenCode, or Codex files. Continue validating
symlinks by their link targets rather than recording them in the manifest.

The tracked manifest schema is:

```yaml
version: 1
algorithm: sha256
files:
  home/.claude/agents/oracle.md: 53e2c9...a817
  home/.codex/prompts/research.md: 0f123b...71cc
```

Keys are POSIX-style paths relative to `ADAPTER_HOME`, prefixed with `home/`.
The generator must reject regular-file targets outside `ADAPTER_HOME`, duplicate
manifest keys, unsupported versions/algorithms, non-lowercase 64-character
SHA-256 values, absolute keys, and keys containing `..`. Entries are emitted in
lexicographic order with fixed YAML settings and no timestamps or host data.

Add the manifest location to `~/.agents/adapters.yaml`:

```yaml
ownership_manifest: ~/.agents/generated-adapters.yaml
```

`AGENTS_ROOT` remaps this path during isolated tests in the same way as other
`~/.agents/...` paths.

### Ownership and apply algorithm

Render every desired file without the legacy marker, compute its exact-byte
SHA-256, load the old manifest, and preflight the complete target set before any
write or deletion.

For a desired regular file:

```text
missing file                       -> safe to create
current hash == desired hash       -> safe; also repairs a missing/stale manifest
current hash == recorded old hash  -> safe to replace with desired bytes
otherwise                          -> refuse the entire operation
```

For a manifest entry no longer present in the desired target set:

```text
file missing                       -> remove stale manifest entry
current hash == recorded old hash  -> safe to delete on --apply
otherwise                          -> refuse the entire operation
```

This ordering gives fail-safe crash recovery without a journal. Output files are
written/deleted only after full preflight; the manifest is written atomically
last. If a process stops partway through file updates, the next run accepts
already-written files because they equal freshly rendered desired bytes and
accepts untouched files because they still equal recorded old hashes. It then
completes the operation and writes the final manifest. If canonical input changes
between attempts, only files matching the newly rendered bytes or recorded old
hashes remain eligible; anything else refuses.

`--check` reports drift when file bytes, stale files, or the manifest differ from
the desired state. `--apply` performs safe writes/deletions and writes the final
manifest. `--validate-skills` remains read-only and does not require the manifest.

### One-time migration

Do not ship a permanent `--adopt-marker` or marker-based authorization path.
During implementation only, use a temporary untracked helper under
`/private/tmp` to:

1. Enumerate exactly the currently configured regular-file targets using the
   pre-change generator/configuration.
2. Require every existing target to contain the exact legacy marker at its
   generated boundary.
3. Refuse missing, extra, duplicate, or untracked paths.
4. Write the initial manifest containing hashes of the existing marker-bearing
   bytes.
5. Run the new generator once; recorded old hashes authorize replacement with
   marker-free bytes, after which it writes their new hashes.

The temporary helper is not committed. The clean generated files and final
manifest are committed together, so fresh yadm clones never need legacy-marker
migration.

### Files

- Modify `~/.agents/scripts/generate_adapters.py`: hashing, manifest parsing and
  serialization, portable path IDs, marker-free rendering, stale-file handling,
  preflight ownership, and manifest-last apply.
- Modify `~/.agents/scripts/test-adapters.sh`: manifest determinism, ownership,
  deletion, reconstruction, crash-recovery simulation, and negative tests.
- Modify `~/.agents/adapters.yaml`: declare `ownership_manifest`.
- Add generated `~/.agents/generated-adapters.yaml`.
- Regenerate all tracked agent and command adapters without the marker.
- Update `research.md` and this `plan.md`; update the live PR description without
  reintroducing a tracked single-use PR-description file.

### Trade-offs

- The manifest adds one tracked generated artifact, but removes generator text
  from every model prompt and strengthens ownership from a forgeable substring
  to exact-byte identity.
- SHA-256 is used for identity and corruption/edit detection, not secrecy.
- Automatically deleting stale manifest-owned files is necessary for removed
  adapters to converge. Deletion is allowed only after an exact recorded-hash
  match and complete preflight.
- There is no filesystem-wide atomic transaction. Manifest-last ordering plus
  dual acceptance of recorded-old and freshly-rendered hashes makes interrupted
  applies safely resumable without weakening manual-edit detection.

### Implementation checklist

- [x] Add and strictly validate the configured manifest schema and portable path
      IDs.
- [x] Remove `MARKER` from every agent and command renderer.
- [x] Compute desired hashes and enforce the old-or-desired ownership rules in
      complete preflight.
- [x] Detect and safely remove stale manifest-owned outputs.
- [x] Write regular files atomically and the deterministic manifest atomically
      last.
- [x] Build and inspect the one-time initial manifest from exact legacy outputs;
      do not commit the migration helper.
- [x] Regenerate all adapters and confirm no generated Markdown contains the
      legacy marker or generator instruction.
- [x] Test two-home byte determinism for both adapters and manifest.
- [x] Test refusal for an edited owned file, an unmanaged marker-free file, a
      malformed manifest, and a target outside `ADAPTER_HOME`.
- [x] Test manifest reconstruction when clean outputs match desired bytes.
- [x] Test canonical-input changes, stale-output deletion, and simulated
      interrupted-apply recovery.
- [x] Run bootstrap, pre-push, generator check, setup verification, behavioral
      tests, Ruff, Python compilation, shell syntax, staged diff, and secret scan.
- [x] Mark this checklist complete issue by issue, commit and push to PR #1,
      update its description, and leave it open and unmerged.
