# Plan: Universal agent configuration with Claude adapters

Date: 2026-08-26
Status: Implemented; Junie/OpenCode live validation deferred


## Implementation status

- Completed: canonical instructions, 34 validated skills, 23 canonical agent prompts, Claude/Codex/Amp/Junie/OpenCode adapters, YAML-driven generation, idempotence and negative drift checks, secret scan, and Amp discovery.
- Live verified: Claude filesystem discovery contract and Amp skill discovery.
- Initial support only: Junie and OpenCode adapters are generated, but neither
  CLI is installed or live-validated. Current official documentation indicates
  schema drift; treat these adapters as experimental pending a dedicated
  follow-up.
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

## Close Junie/OpenCode validation and records review

Planned: 2026-08-27. This section requires explicit approval before installation
or implementation.

### Operator annotation — deferred 2026-08-27

- Do not install Junie or OpenCode in this PR.
- Do not implement the schema-correction or live-validation checklist below in
  this PR.
- Current generated Junie/OpenCode adapters are initial, experimental support;
  their presence is not a compatibility claim.
- Preserve the source-backed findings and unchecked checklist below as future
  work.
- Item 9 is resolved: retain `research.md` and `plan.md` as durable decision
  records. Keep transient installers, logs, transcripts, and PR scratch files
  untracked.

Status: deferred follow-up; not approved for implementation in this PR.

### Future follow-up outcome (deferred)

Correct the source-backed schema drift, install the current stable Junie and
OpenCode CLIs for validation, and replace the broad "statically verified only"
limitation with exact versioned evidence. Retain `research.md` and `plan.md` as
the durable audit record; do not restore the deleted single-use PR-description
file.

### Future installation boundary (deferred)

Live discovery requires installed binaries. The planned installation is scoped
to validation and does not imply authentication, paid model calls, or acceptance
of broad filesystem permissions:

- OpenCode: install the current stable CLI from the maintained
  `anomalyco/tap/opencode` Homebrew formula, record `opencode --version`, and use
  offline/listing commands first.
- Junie: download the official stable installer to `/private/tmp`, inspect it,
  then execute the local file rather than piping the network response directly
  into a shell. Record `junie --version` and `junie --help`.
- Do not add either tool to `Brewfile` or bootstrap in this PR. They are optional
  harnesses, not prerequisites for cloning the universal configuration. Keep the
  installed binaries after validation unless the operator asks to remove them.
- Do not read, print, or stage credentials. If an authenticated smoke test is
  needed, stop at the login boundary for the operator to authenticate through
  the harness's supported flow. Do not initiate a paid task without explicit
  authorization.

### Schema corrections

Modify `~/.agents/scripts/generate_adapters.py` and
`~/.agents/adapters.yaml` as follows:

- Junie agents: emit only documented case-sensitive tool groups. Derive them
  from the same role/capability inputs used elsewhere:
  `Read`, `Glob`, `Grep`, `Bash`, `Write`, `Edit`, and `WebSearch`. Do not emit
  unsupported generic `search`, `web`, `shell`, or a `Skill` tool group; the
  existing `skills` frontmatter remains the skill preload surface.
- Junie agents: omit `model` until an installed environment provides a verified
  supported model ID. Remove the dead `models.junie` defaults.
- OpenCode agents: emit singular `permission`, using `edit` and `bash` keys.
  Preserve `mode: subagent` and current read-only/shell capability semantics.
- OpenCode agents: omit the invalid/unverified literal `model: default` and
  remove the dead `models.opencode` defaults. A future explicit
  `provider/model` mapping can be added when desired.
- Junie commands retain `description`, `allowPromptArgument: true`, and `$prompt`.
  OpenCode commands retain `description` and `$ARGUMENTS`; these match current
  official schemas.
- Regenerate adapters and the deterministic ownership manifest through the
  existing preflight pipeline.

Representative desired frontmatter:

```yaml
# Junie read-only reviewer with shell
tools:
  - Read
  - Glob
  - Grep
  - Bash

# OpenCode Oracle
permission:
  edit: deny
  bash: deny
```

### Validation ladder

Run the cheapest non-mutating evidence first:

1. Existing generator/unit-style behavioral suite and negative drift checks.
2. Binary versions and help output.
3. OpenCode `agent list` to confirm every generated agent parses and is
   discoverable; use available config/debug commands to inspect effective
   permissions without invoking a model.
4. Inspect OpenCode command discovery through its non-model CLI/TUI surface if
   exposed by the installed version.
5. Use Junie's explicit `--agent-location` and `--command-location` options with
   isolated temporary fixtures. Prefer a listing/ACP surface that does not call
   a model; record when the installed CLI offers no unauthenticated listing.
6. If authentication is available and the operator authorizes model calls, run
   minimal smoke tests: list commands/skills, invoke one workflow command, invoke
   Oracle, and confirm a deliberately requested sentinel edit is denied. Perform
   these in an isolated temporary repository and record model/cost scope.

A parser/listing result proves schema and discovery. Only an authorized live
invocation can prove delegation, prompt loading, and effective runtime
permissions. Report these evidence levels separately rather than rounding
partial verification up to "fully verified."

### Durable records

- Keep `~/.agents/records/universal-agent-config/research.md` and `plan.md`.
- Update the implementation-status section with installed versions, commands
  executed, schema corrections, authenticated/unauthenticated scope, and any
  remaining limitation.
- Keep transient installer copies, logs containing environment details, session
  transcripts, credentials, and PR-body scratch outside yadm.
- Update PR #1 from an untracked temporary Markdown body and leave it open.

### Checklist

- [ ] Correct Junie tool-group casing/vocabulary and omit its unverified model.
- [ ] Correct OpenCode `permission`/`bash` metadata and omit its unverified model.
- [ ] Update behavioral assertions and regenerate all affected adapters plus the
      ownership manifest.
- [ ] Download, inspect, and install the stable Junie CLI; record its version.
- [ ] Install stable OpenCode from its maintained Homebrew tap; record its
      version.
- [ ] Run unauthenticated/offline parser, agent-discovery, command-discovery, and
      effective-config checks exposed by each installed binary.
- [ ] Stop for operator authentication/paid-call authorization if either harness
      requires it for the remaining live smoke tests.
- [ ] If authorized, run isolated command, skill, agent, and permission smoke
      tests without touching the real workspace.
- [ ] Record exact evidence and residual limitations in `research.md`, `plan.md`,
      and PR #1; retain the two durable records only.
- [ ] Run generator check, setup verification, behavioral tests, Ruff, Python
      compilation, shell syntax, staged diff, secret scan, and yadm hooks.
- [ ] Commit and push the approved corrections to PR #1 without merging.

## Address third-review minor findings

Planned: 2026-08-28. Research approved by the operator; implementation awaits
explicit approval of this section.

### Scope and disposition

Implement findings 1, 5, and 6. Record findings 2, 3, and 4 as intentionally
deferred or accepted limitations; do not add undocumented harness metadata, a
transaction journal, or destructive orphan scanning in this PR.

This keeps the change local to validation, dead rendering code, verification,
tests, and durable records. Junie/OpenCode schema remediation remains deferred
under the preceding operator annotation.

### 1. Put collision validation on the ordinary check path

Modify `~/.agents/scripts/generate_adapters.py` so both `--check` and `--apply`
validate canonical skills and configured command collisions before rendering or
preflight. Retain `--validate-skills` as a focused mode that validates and exits.

The intended control flow is:

```python
validate_skills(config, paths)
if args.validate_skills:
    return 0

targets: list[Target] = []
```

This deliberately makes `sync-adapters.sh --check`, the yadm pre-push hook, and
ordinary applies fail before touching output whenever a collision exists. It
avoids coupling the hook to the broader presentation logic in
`verify-setup.sh` while ensuring every generator entry point enforces the
invariant.

Update `~/.agents/scripts/test-adapters.sh` so the collision fixture observes
both focused validation and ordinary `--check` fail. Restore the fixture and
confirm `--check` succeeds afterward. This is a negative test of the real gate,
not a presence assertion.

### 2. Preserve sidecar-only ownership and experimental disclosure

Do not add `generated: true`, comments, or other undocumented frontmatter to
generated adapters. Ownership remains exclusively in
`~/.agents/generated-adapters.yaml`, outside model-visible prompt bodies.

Keep the Junie/OpenCode experimental label in `research.md`, `plan.md`, and the
PR limitations. A point-of-edit marker requires verified native metadata and is
future work; it is not represented as completed.

### 3. Preserve fail-closed crash recovery

Do not implement `current_hash in {ownership.get(key), desired}` because it does
not authorize the intermediate generation in the reported scenario. Retain the
current behavior: unchanged canonical input self-heals, while a simultaneous
canonical change may require manual recovery rather than risking overwrite.

A pending-manifest or journal protocol is future work if operational evidence
justifies its complexity. No ownership condition changes in this pass.

### 4. Preserve manifest-bounded stale cleanup

Do not enumerate or reap files absent from both desired targets and the manifest.
Adapter directories are not declared generator-exclusive, so an orphan sweep
could misclassify legitimate local files. Continue deleting only stale files
whose ownership and unchanged digest are proven by the manifest.

### 5. Remove dead Claude command rendering

Modify `render_commands()` in
`~/.agents/scripts/generate_adapters.py` to remove the unused `"claude"` entry
from `contents`:

```python
contents = {
    "codex": f"{body}\n",
    "junie": ...,
    "opencode": ...,
}
```

Keep the existing unsupported-adapter error. Therefore, accidentally adding a
Claude command directory fails explicitly instead of silently re-enabling the
known skill-shadowing path. The behavioral test continues to assert that no
Claude workflow command is emitted.

### 6. Remove duplicate hardcoded skills-link checks

Modify `~/.agents/scripts/verify-setup.sh` to remove:

```sh
check test -L "$HOME/.claude/skills"
check test "$(readlink "$HOME/.claude/skills")" = "../.agents/skills"
```

The following generator `--check` already validates every configured
`skill_adapters` link using `AGENTS_ROOT` and `ADAPTER_HOME`. The isolated
behavioral suite retains its explicit expected-target assertion, so link
semantics remain tested without duplicating runtime configuration in the setup
wrapper.

### Files changed

- `~/.agents/scripts/generate_adapters.py`
- `~/.agents/scripts/test-adapters.sh`
- `~/.agents/scripts/verify-setup.sh`
- `~/.agents/records/universal-agent-config/research.md`
- `~/.agents/records/universal-agent-config/plan.md`
- PR #1 description, updated from an untracked temporary Markdown file

Generated adapters and `generated-adapters.yaml` should remain byte-identical;
the generator rendering change removes only an unreachable dictionary entry.

### Verification and delivery

Run the collision negative test before and after the implementation to prove the
ordinary `--check` path changes from incorrectly green to correctly red. Then
run:

- generator `--check` and focused `--validate-skills`
- `verify-setup.sh`
- `test-adapters.sh`
- Ruff and Python compilation
- POSIX shell syntax checks
- yadm diff check, staged secret-pattern scan, bootstrap/pre-push hooks

The Python reviewer cannot provide type-review sign-off because this scripts-only
repository has no configured `pyproject.toml` type checker. Do not introduce a
new project/type-checking stack for these minor fixes; report that limitation.

Commit and push the approved changes to the existing PR branch, update the PR
description with the exact disposition of all six findings, and leave the PR
open and unmerged.

### Checklist

- [x] Capture a pre-change negative test showing ordinary `--check` currently
      misses a skill/command collision.
- [x] Invoke `validate_skills()` on ordinary `--check` and `--apply`, retaining
      focused `--validate-skills` behavior.
- [x] Extend the behavioral collision fixture to prove ordinary `--check` fails
      and succeeds again after cleanup.
- [x] Remove the dead Claude entry from `render_commands()` and retain the
      no-Claude-command assertion.
- [x] Remove the two hardcoded Claude skills-link checks from `verify-setup.sh`.
- [x] Confirm no generated adapter or manifest content changes.
- [x] Run all generator, setup, behavioral, lint, compile, shell, diff, secret,
      bootstrap, and pre-push gates listed above.
- [x] Mark this checklist complete issue by issue and record exact verification
      evidence in this plan.
- [x] Commit and push to PR #1, update its description, and leave it open and
      unmerged.

### Implementation evidence — 2026-08-28

- Before the fix, an isolated fixture containing
  `.claude/commands/oracle.md` returned exit code 0 from ordinary `--check`,
  reproducing the pre-push gap.
- After the fix, `test-adapters.sh` proves the same ordinary `--check` fails for
  the collision and succeeds after the fixture is removed; the full behavioral
  suite passed.
- Generator `--check`, focused `--validate-skills`, `verify-setup.sh`, Ruff,
  Python compilation, POSIX shell syntax, yadm bootstrap, and the yadm pre-push
  hook all passed.
- Yadm status contains only the three approved implementation files and the two
  durable record files. No generated adapter or ownership-manifest file changed.
- Python type-review sign-off remains unavailable because no Python type checker
  is configured; no new dependency or type-checking stack was introduced.

## Add the harness-maintainer guide

Planned: 2026-08-28. Research approved by the operator; implementation awaits
explicit approval of this section.

### Outcome

Create `~/.agents/harness-instructions.md` as the durable operating guide for
maintaining the universal agent configuration across Claude Code, Codex, Amp,
JetBrains Junie, and OpenCode. Keep it out of default model context, but add a
short routing rule to canonical `AGENTS.md` so every supported harness knows to
read it before changing harness configuration.

The document is a maintenance map, not another source of behavioral policy and
not a copy of every volatile harness schema.

### 1. Create the maintainer guide

Add `~/.agents/harness-instructions.md` with these sections:

1. Purpose, audience, and source-of-truth rules.
2. A canonical-to-native mapping table for instructions, skills, role prompts,
   workflow commands, generated ownership, and validation tooling.
3. A status vocabulary: `verified`, `partial`, and `experimental`.
4. Per-harness sections for Claude Code, Codex, Amp, Junie, and OpenCode.
5. Standard procedures for editing instructions, adding/updating a skill,
   adding/updating a role prompt, adding/updating a workflow command, and adding
   a new harness.
6. Regeneration, verification, and review commands.
7. Safety invariants and troubleshooting.
8. Versioned local evidence and primary documentation links.

The opening contract should be explicit:

```markdown
Edit canonical sources under `~/.agents`; do not hand-edit generated adapters.
Recheck the target harness's official documentation before changing discovery
paths or frontmatter schemas.
```

The mapping table will point to live configuration rather than repeat every
generated file:

| Concern | Canonical source | Adapter declaration/output |
|---|---|---|
| Instructions | `~/.agents/AGENTS.md` | `instruction_adapters` |
| Skills | `~/.agents/skills/` | native discovery plus `skill_adapters` |
| Roles | `~/.agents/prompts/` | `agent_directories` |
| Workflows | `~/.agents/commands/` | `command_directories` |
| Ownership | canonical inputs | `generated-adapters.yaml` |

Per-harness entries must name native locations, support level, locally observed
evidence, known limitations, verification commands/surfaces, and official links.
They must distinguish current documentation from local observation:

- Claude Code: verified instruction symlink, skills symlink, and generated
  agents. Preserve the conservative command-collision guard because local
  evidence previously differed from current official precedence documentation.
- Codex: instructions and skills working; custom prompt discovery remains
  partial pending a fresh interactive confirmation.
- Amp: instructions and skills verified; workflow parity is skill-based and no
  role-agent adapter is generated.
- Junie: instructions/skills paths documented, but generated agent metadata is
  experimental with known tool/model schema drift. State explicitly that the CLI
  was not installed or live-tested as of 2026-08-28.
- OpenCode: instructions/skills paths documented, but generated agent metadata
  is experimental with known permission/model schema drift. State explicitly
  that the CLI was not installed or live-tested as of 2026-08-28.

Do not claim authentication, paid invocation, or runtime permission behavior
that was not tested.

#### First-install remediation runbooks

The Junie and OpenCode sections must each include a prominent instruction for a
future session running under that harness:

```markdown
If this harness is now installed, do not treat the generated adapters as
compatible merely because they exist. Recheck the linked official documentation,
record the installed version, correct the canonical generator/configuration,
regenerate, and replace this experimental status with exact validation evidence.
Never patch generated adapter files directly.
```

The Junie runbook must identify the already known correction path:

1. Record `junie --version` and inspect current help/discovery surfaces.
2. Recheck official guideline, skill, subagent, command, tool-group, and model
   documentation for that installed version.
3. Update `generate_adapters.py` and `adapters.yaml` to use documented,
   case-sensitive Junie tool groups and omit or replace the unverified literal
   `model: default` with an actually supported model value.
4. Decide from current docs and live discovery whether direct `~/.agents`
   subagent discovery can replace any generated Junie adapter layer; prefer the
   simplest verified arrangement.
5. Regenerate through `sync-adapters.sh --apply`; validate `/skills`,
   `/commands`, instruction discovery, subagent discovery, delegation, and
   effective read-only/shell restrictions in an isolated workspace.
6. Require operator authorization before authentication or paid model calls.
7. Update the guide's version/evidence/status entry and durable records.

The OpenCode runbook must identify its known correction path:

1. Record `opencode --version` and inspect current configuration/help output.
2. Recheck official rules, skills, agents, commands, permission, and model
   documentation for that installed version.
3. Update `generate_adapters.py` and `adapters.yaml` to emit singular
   `permission`, use the documented `bash` permission key, and omit or replace
   the unverified literal `model: default` with a valid `provider/model` value.
4. Regenerate through `sync-adapters.sh --apply`; validate rule and skill
   discovery, `opencode agent list`, command discovery, delegation, and
   effective permission denial in an isolated workspace.
5. Require operator authorization before authentication or paid model calls.
6. Update the guide's version/evidence/status entry and durable records.

For both harnesses, parser or listing success proves schema/discovery only.
Runtime delegation and permission claims require an explicitly authorized live
smoke test and must be reported separately.

### 2. Add a discovery route to universal instructions

Modify `~/.agents/AGENTS.md` under configuration preferences or portable
capabilities with one concise rule:

```markdown
- Before changing shared harness instructions, skills, agents, commands,
  adapters, or validation tooling, read `~/.agents/harness-instructions.md`.
```

This sentence is intentionally the only part loaded in every harness session.
Do not import or inline the entire guide into `AGENTS.md`, `CLAUDE.md`, or other
native instruction adapters.

Because native instruction files are symlinks to `~/.agents/AGENTS.md`, this
canonical edit propagates without regeneration or duplicate edits.

### 3. Link the guide from the repository README

Update `~/README.md` in the universal-agent section so a human browsing the
repository can find `~/.agents/harness-instructions.md`. Describe it as the
maintenance and troubleshooting guide; keep the README's installation material
unchanged.

### 4. Verification

Verify documentation and runtime boundaries:

- Confirm every referenced local path exists or is explicitly described as a
  generated destination.
- Confirm all official links resolve to primary documentation.
- Compare mapping/status claims against `adapters.yaml`, generator rendering,
  installed versions, and the durable research record.
- Confirm `harness-instructions.md` is not listed in `instruction_adapters`, is
  not symlinked into a native always-loaded path, and is not added to the
  ownership manifest.
- Run generator `--check`, `verify-setup.sh`, `test-adapters.sh`, yadm bootstrap,
  pre-push, Markdown whitespace/diff checks, and staged secret-pattern scan.
- Confirm generated adapters and `generated-adapters.yaml` remain unchanged.

### Files changed

- `~/.agents/harness-instructions.md` (new)
- `~/.agents/AGENTS.md`
- `~/README.md`
- `~/.agents/records/universal-agent-config/research.md`
- `~/.agents/records/universal-agent-config/plan.md`
- PR #1 description, updated through an untracked temporary Markdown file

No generator, adapter schema, generated adapter, dependency, or optional harness
installation is in scope.

### Delivery

Commit and push the approved documentation to the existing
`refactor/universal-agent-config` branch, update PR #1, and leave it open and
unmerged. The previously discussed record cleanup remains deferred until after
the PR is merged.

### Checklist

- [x] Create `~/.agents/harness-instructions.md` with mapping, status,
      per-harness, workflow, safety, troubleshooting, evidence, and source
      sections.
- [x] State that Junie and OpenCode were not installed or live-tested as of
      2026-08-28 and add actionable first-install remediation runbooks for both.
- [x] Add the one-line conditional routing rule to `~/.agents/AGENTS.md` without
      importing the guide into default context.
- [x] Link the guide from `~/README.md`.
- [x] Validate every local path and primary documentation link.
- [x] Confirm the guide is neither a generated target nor an always-loaded
      native adapter.
- [x] Run generator, setup, behavioral, bootstrap, pre-push, diff, and secret
      gates; confirm generated files and manifest are unchanged.
- [x] Record exact verification evidence and mark the checklist complete issue
      by issue.
- [x] Commit and push to PR #1, update its description, and leave it open and
      unmerged.

### Implementation evidence — 2026-08-28

- All referenced local canonical, native adapter, generated, and validation
  paths exist.
- All sixteen linked primary documentation pages for Claude Code, Codex, Amp,
  Junie, and OpenCode resolved successfully on 2026-08-28.
- `harness-instructions.md` is absent from `adapters.yaml` and
  `generated-adapters.yaml`; it is not linked into any native instruction path.
  Only the conditional routing sentence in canonical `AGENTS.md` enters default
  context.
- Generator check, setup verification, the full adapter behavioral suite, yadm
  bootstrap, pre-push, and whitespace checks passed.
- Yadm status shows only the new guide, canonical `AGENTS.md`, README, and the
  two durable records. No generated adapter or ownership-manifest file changed.
- The first verification attempt exposed a zsh-specific test-script mistake:
  assigning loop variable `path` overwrote zsh's special `$path`/`$PATH` array.
  The corrected verification used `required_path`; this affected only the
  ephemeral command and no tracked file.

## Restore Claude capabilities found in fourth review

Planned: 2026-08-28. Regression research approved by the operator;
implementation awaits explicit approval of this section.

### Outcome

Restore the exact intentional Claude capabilities lost from `origin/master`
without broadening or narrowing unrelated roles:

- return `WebSearch` and `WebFetch` to `ai-apple-engineer`;
- remove Bash from `apple-reviewer`, `ml-reviewer`, and `full-reviewer`;
- preserve Bash for the four language reviewers that had it on master;
- restore literal retrieval syntax in three skill descriptions.

Do not restore the old Claude capability catalogue, delete the deferred legacy
file, or modify Junie/OpenCode schemas in this pass.

### 1. Add an explicit web capability

Modify `~/.agents/prompts/ai-apple-engineer.md`:

```yaml
model_class: developer
read_only: false
web: true
```

Modify `~/.agents/scripts/generate_adapters.py` so prompt metadata parses
`web` with a strict boolean default of `false`:

```python
web = require_bool(metadata.get("web", False), f"{source}: web")
```

Extend `claude_tools()` with `web: bool`. After selecting the model-class bundle,
append `WebSearch` and `WebFetch` only when requested and not already present:

```python
if web:
    for tool in ("WebSearch", "WebFetch"):
        if tool not in tools:
            tools.append(tool)
```

Pass `web` from `render_agents()` into the Claude tool mapper. Do not add web
metadata to Junie or OpenCode rendering: their known schema drift remains
deferred, and the web change is specifically restoring Claude parity.

### 2. Restore strict no-shell reviewer roles

Add `shell: false` to these canonical prompts:

- `~/.agents/prompts/apple-reviewer.md`
- `~/.agents/prompts/ml-reviewer.md`
- `~/.agents/prompts/full-reviewer.md`

Do not change the meaning or implementation of `read_only`. In the current
capability model:

- `read_only: true` removes direct `Write` and `Edit` tools;
- `shell: false` removes Bash.

This distinction preserves Bash for `python-reviewer`, `rust-reviewer`,
`solidity-reviewer`, and `typescript-reviewer`, matching `origin/master`.

Operator annotation accepted 2026-08-29: `shell` is a portable semantic
capability, so `shell: false` must propagate to every generated harness adapter.
For the three affected reviewers this removes Bash in Claude, removes the shell
tool in Junie, and emits shell denial in OpenCode. This does not claim the
experimental Junie/OpenCode schemas are otherwise compatible.

Operator amendment approved 2026-08-29: the full parity gate found that
`ai-architect` also lost Bash, which the fourth review had mislabeled as a tool
reordering. Make `shell` tri-state: omitted preserves the model-class bundle,
explicit `true` adds shell, and explicit `false` removes shell. Set
`shell: true` only on `ai-architect`; this restores Bash without adding it to the
other architect roles. Junie/OpenCode already treat omitted and true as enabled,
so their `ai-architect` outputs remain unchanged.

Update `~/.agents/harness-instructions.md` in the role-maintenance section to
state this two-axis contract and warn that `read_only` is not a security sandbox
when shell remains enabled.

### 3. Restore literal skill-description syntax

Modify only the description text in:

- `~/.agents/skills/rust-architect/SKILL.md`: restore
  `Arc<Mutex<T>> or channel`;
- `~/.agents/skills/rust-developer/SKILL.md`: restore `Arc<Mutex>`;
- `~/.agents/skills/solidity-reviewer/SKILL.md`: restore
  ``Override: HARD FAIL <id> for reason <reason>``.

Keep the existing `>-` folded YAML representation, which safely handles the
colon-space in the Solidity description. Do not revert the five valid YAML
normalizations or change skill bodies.

### 4. Strengthen behavioral parity tests

Update `~/.agents/scripts/test-adapters.sh` with outcome assertions against
generated Claude agents:

- `ai-apple-engineer` contains both `WebSearch` and `WebFetch`;
- a normal developer role without `web: true` does not gain web tools;
- `apple-reviewer`, `ml-reviewer`, and `full-reviewer` omit Bash;
- `python-reviewer` retains Bash;
- the three restored literal description fragments survive PyYAML parsing and
  validation.

Prefer exact `tools:` assertions for the affected agents so the test detects
both missing and accidentally added capabilities. Keep the existing full
behavioral suite intact.

Also add a negative fixture that changes `web: true` to a non-boolean value and
observes generator refusal. This proves strict metadata validation rather than
only the happy path.

### 5. Regenerate and review ownership changes

Run `sync-adapters.sh --apply`. Expected generated changes are limited to:

- Claude `ai-apple-engineer`, `apple-reviewer`, `ml-reviewer`, and
  `full-reviewer` agent frontmatter;
- Junie and OpenCode `apple-reviewer`, `ml-reviewer`, and `full-reviewer`
  frontmatter, reflecting the accepted portable no-shell capability;
- generated agent files that embed the three corrected skill descriptions only
  if their canonical role metadata references those descriptions (none are
  expected under the current renderer);
- `generated-adapters.yaml` digests for the four changed Claude agents.

Canonical skill description edits do not themselves generate adapters. No other
Junie or OpenCode generated file may change.

Compare affected Claude `tools:` values directly to `origin/master`. `Skill` is
an intentional branch addition, so parity means restoring lost web/no-shell
semantics, not byte-identical full tool lines.

### Verification

Run:

- all 34 skills through PyYAML/frontmatter validation;
- generator `--check` and focused `--validate-skills`;
- `verify-setup.sh` and `test-adapters.sh`;
- Ruff and Python compilation;
- POSIX shell syntax checks;
- explicit master-versus-generated tool comparisons for all 21 legacy agents;
- yadm bootstrap, pre-push, diff check, and staged secret-pattern scan.

The comparison must show no new capability loss or gain beyond the intentional
branch-wide `Skill` addition and harmless tool ordering. Record the absence of a
configured Python type checker as a review limitation.

### Files changed

- `~/.agents/prompts/ai-apple-engineer.md`
- `~/.agents/prompts/ai-architect.md`
- `~/.agents/prompts/apple-reviewer.md`
- `~/.agents/prompts/ml-reviewer.md`
- `~/.agents/prompts/full-reviewer.md`
- `~/.agents/scripts/generate_adapters.py`
- `~/.agents/scripts/test-adapters.sh`
- `~/.agents/skills/rust-architect/SKILL.md`
- `~/.agents/skills/rust-developer/SKILL.md`
- `~/.agents/skills/solidity-reviewer/SKILL.md`
- `~/.agents/harness-instructions.md`
- four generated Claude agent files and `~/.agents/generated-adapters.yaml`
- durable `research.md` and `plan.md`
- PR #1 description through an untracked temporary Markdown file

### Delivery

Commit and push the approved regression fixes to the existing branch, update PR
#1 with the restored capability contract and tests, and leave it open and
unmerged.

### Checklist

- [x] Add strict canonical `web` parsing and additive Claude web-tool mapping.
- [x] Set `web: true` for `ai-apple-engineer` and prove both web tools return.
- [x] Implement tri-state shell semantics, set `shell: true` for `ai-architect`,
      and prove its Bash capability returns without affecting other architects.
- [x] Set `shell: false` for the three affected reviewers and prove Bash is
      removed only from those roles.
- [x] Prove `python-reviewer` and the other language reviewers retain Bash.
- [x] Restore the three literal skill-description fragments under valid folded
      YAML.
- [x] Document the `read_only`/`shell` distinction in the harness guide.
- [x] Add positive capability assertions and a non-boolean `web` rejection test.
- [x] Regenerate and confirm only the expected Claude agents, the three accepted
      Junie/OpenCode reviewer adapters, and their ownership digests change.
- [x] Run all validation, behavioral, lint, compile, shell, comparison, yadm,
      and secret gates.
- [x] Record exact evidence and mark this checklist complete issue by issue.
- [x] Commit and push to PR #1, update its description, and leave it open and
      unmerged.

### Implementation evidence — 2026-08-29

- `ai-apple-engineer` now has `WebSearch` and `WebFetch`; the ordinary
  `apple-engineer` developer bundle did not gain them. A non-boolean `web`
  fixture is rejected.
- `apple-reviewer`, `ml-reviewer`, and `full-reviewer` now have no Bash in
  Claude, no shell tool in Junie, and shell denial in OpenCode.
- `python-reviewer` and the other language reviewers retain Bash.
- The all-legacy-agent semantic comparison initially caught an additional
  `ai-architect` Bash loss missed by the external review. After the approved
  tri-state amendment, all master tools are present for every legacy agent;
  the only allowed new tool is `Skill`.
- All 34 skill frontmatter documents validate, and the exact
  `Arc<Mutex<T>>`, `Arc<Mutex>`, and `<id>/<reason>` strings survive.
- Generated changes are exactly five Claude agents, three Junie reviewers,
  three OpenCode reviewers, and their ownership-manifest digests.
- Generator check, focused skill validation, setup verification, behavioral
  tests, Ruff, Python compilation, POSIX shell syntax, yadm bootstrap, pre-push,
  and whitespace checks passed.
- Python type-review sign-off remains unavailable because no type checker is
  configured for this scripts-only repository.

## Fifth-review leftover plan (2026-08-29)

### Approach

Clarify the existing harness capability contract without changing canonical
metadata or generated adapters. Add one paragraph beside the `web` guidance in
`~/.agents/harness-instructions.md`:

```markdown
`web` currently controls only Claude's generated tool list. The experimental
Junie renderer grants web access uniformly, and the OpenCode renderer does not
model a separate web capability; do not treat `web: false` as portable
enforcement until those adapters are corrected and validated with their CLIs.
```

This makes the asymmetry explicit while preserving the previously approved
decision not to install or repair Junie/OpenCode in this PR. Do not restore the
Claude-only catalogue, alter reviewer shell permissions, add unused generator
fixtures, or delete the deferred orphaned legacy file.

### Verification

- Confirm the clarification sits with the canonical capability-field guidance
  and is consistent with the existing experimental-harness warning.
- Run Markdown/diff whitespace checks and `verify-setup.sh`; adapter output is
  expected to remain unchanged.
- Update the durable plan/research records and PR description, then commit and
  push the documentation cleanup to PR #1 without merging it.

### Files changed

- `~/.agents/harness-instructions.md`
- durable `research.md` and `plan.md`
- PR #1 description through the existing Markdown record

### Checklist

- [x] Add the Claude-only `web` mapping clarification and experimental adapter
      warning to `harness-instructions.md`.
- [x] Confirm no canonical metadata, generator, generated adapter, permission,
      catalogue, or deferred legacy-file change entered the diff.
- [x] Run setup, adapter-currentness, Markdown, whitespace, and secret checks.
- [x] Record verification evidence and mark this checklist complete.
- [ ] Commit and push to PR #1, update its Markdown description, and leave the
      PR open and unmerged.

### Implementation evidence — 2026-08-29

- The guide now states that canonical `web` metadata affects only Claude's
  generated tool list today and cannot be treated as portable enforcement for
  the experimental Junie/OpenCode adapters.
- The focused worktree diff contains only the guide and durable research/plan
  records; canonical prompts, generator code, generated adapters, permissions,
  catalogues, and the deferred orphan are unchanged.
- Generator currentness, all 34 skill validations, setup verification, adapter
  behavioral tests, and yadm whitespace checks passed. The first generator
  invocation used a stale `--config` spelling and was rerun successfully with
  the required positional configuration path.
