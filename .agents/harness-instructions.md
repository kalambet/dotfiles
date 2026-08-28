# Harness maintenance instructions

This is the maintainer guide for the shared coding-agent configuration. Read it
before changing harness instructions, skills, role prompts, workflow commands,
adapter mappings, generation logic, or validation tooling.

Edit canonical sources under `~/.agents`; do not hand-edit generated adapters.
Recheck the target harness's official documentation before changing discovery
paths or frontmatter schemas.

This file is intentionally not loaded into every agent session. The short rule
in `~/.agents/AGENTS.md` routes configuration work here when needed.

## Sources of truth

| Concern | Canonical source | Adapter declaration or output |
|---|---|---|
| Shared instructions | `~/.agents/AGENTS.md` | `instruction_adapters` in `adapters.yaml` |
| Portable skills | `~/.agents/skills/<name>/SKILL.md` | Native discovery plus `skill_adapters` |
| Reusable roles | `~/.agents/prompts/<name>.md` | `agent_directories` |
| Workflow commands | `~/.agents/commands/<name>.md` | `command_directories` |
| Harness mappings | `~/.agents/adapters.yaml` | Read by `generate_adapters.py` |
| Generated ownership | Canonical inputs above | `~/.agents/generated-adapters.yaml` |
| Generation | `~/.agents/scripts/generate_adapters.py` | Harness-native files and symlinks |
| Verification | `verify-setup.sh`, `test-adapters.sh` | Setup and behavioral evidence |
| Decisions | `~/.agents/records/universal-agent-config/` | Research and approved plans |

Generated regular files are identified by SHA-256 in
`generated-adapters.yaml`. Symlinks are validated by their targets. A generated
file's lack of an inline marker is deliberate: generator notes must not pollute
model-visible prompts or rely on undocumented frontmatter.

## Status vocabulary

- **Verified:** exercised locally through the harness or its native discovery
  surface, in addition to static generation checks.
- **Partial:** some native behavior is verified, but a named discovery or
  execution path still needs confirmation.
- **Experimental:** generated from a researched but unverified contract, with a
  known limitation or no installed CLI. Presence of files is not compatibility
  evidence.

Always record the harness version, date, command or UI surface used, and the
boundary of the evidence. Parser/listing success proves schema and discovery;
only a live invocation proves delegation and effective permissions.

## Harness map

### Claude Code — verified

- Installed evidence: Claude Code 2.1.250 on 2026-08-28.
- Instructions: `~/.claude/CLAUDE.md` is a managed symlink to
  `~/.agents/AGENTS.md`.
- Skills: `~/.claude/skills` is a managed symlink to `~/.agents/skills`.
- Agents: `~/.claude/agents/*.md` are generated from canonical prompts.
- Workflows: the `research`, `plan`, and `implement` skills provide the command
  surface. Do not generate same-name files in `~/.claude/commands/`.
- Validation: run `/context`, inspect the skill list, invoke each workflow skill,
  and delegate a small task to representative read-only and developer agents.

Current Claude documentation says a skill takes precedence over a same-name
legacy command. An earlier locally installed state showed the skill disappearing
when the command existed. Keep the conservative collision guard until a deliberate
versioned experiment proves it unnecessary; do not infer precedence from docs
alone.

Official documentation:

- [Instructions and CLAUDE.md](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)
- [Subagents](https://code.claude.com/docs/en/sub-agents)

### Codex — partial

- Installed evidence: Codex CLI 0.149.1 on 2026-08-28.
- Instructions: `~/.codex/AGENTS.md` is a managed symlink to
  `~/.agents/AGENTS.md`.
- Skills: Codex discovers the canonical `~/.agents/skills` collection in the
  current environment.
- Workflows: generated prompt adapters live in `~/.codex/prompts`.
- Agents: this repository does not generate Codex-specific role files; use native
  subagents when available or invoke the portable role skills/prompts explicitly.
- Limitation: instruction and skill discovery work, but custom prompt discovery
  still needs confirmation in a fresh interactive session.
- Validation: inspect loaded instructions and available skills, invoke a
  representative skill, then confirm `research`, `plan`, and `implement` appear
  and run in a newly started interactive session.

Official OpenAI documentation:

- [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Skills](https://learn.chatgpt.com/docs/build-skills)

### Amp — verified for instructions and skills

- Installed evidence: Amp build `0.0.1775636421-g1ea6b1` on 2026-08-28.
- Instructions: `~/.config/AGENTS.md` is a managed symlink to
  `~/.agents/AGENTS.md`.
- Skills: Amp has discovered canonical Oracle, Librarian, and workflow skills.
- Workflows: parity is skill-based. Do not claim a custom Markdown slash-command
  surface equivalent to Codex, Junie, or OpenCode.
- Agents: no Amp role adapters are generated. Amp's native subagents remain
  available independently.
- Validation: use the command-palette `agents-md list`, inspect available skills,
  invoke a workflow skill, and run a minimal native subagent task.

Official documentation:

- [AGENTS.md](https://ampcode.com/docs/customize/agents-md)
- [Models and subagents](https://ampcode.com/docs/models-and-subagents)

### JetBrains Junie — experimental

Junie was not installed or live-tested when this guide was created on
2026-08-28. The repository links `~/.junie/AGENTS.md` to canonical instructions,
generates agents under `~/.junie/agents`, and generates workflow commands under
`~/.junie/commands`. Junie documents direct discovery of `~/.agents/skills` and
user-scope subagents from `~/.agents`, but the current canonical role prompts are
stored under `~/.agents/prompts` and require an adapter unless the layout changes.

Known limitation: generated Junie agents currently use lowercase generic tool
names and `model: default`. Current documentation describes case-sensitive tool
groups and environment-dependent model values. Do not call these agents
compatible until corrected and tested.

#### When Junie is first installed

If Junie is now installed, do not treat the generated adapters as compatible
merely because they exist. Recheck the official documentation, record the
installed version, correct the canonical generator/configuration, regenerate,
and replace this experimental status with exact validation evidence. Never patch
generated adapter files directly.

1. Record `junie --version`; inspect current help and discovery surfaces.
2. Recheck guideline, skill, subagent, command, tool-group, and model docs for
   that installed version.
3. Update `~/.agents/scripts/generate_adapters.py` and
   `~/.agents/adapters.yaml` to emit documented case-sensitive tool groups.
   Omit `model` or replace `default` only with a verified supported value.
4. Check whether direct `~/.agents` subagent discovery can simplify the adapter
   layer without changing canonical prompt semantics. Prefer the simplest
   arrangement proven by the installed version.
5. Run `sync-adapters.sh --apply`, then verify `/skills`, `/commands`,
   instructions, subagent discovery, and isolated read-only/shell behavior.
6. Stop for operator approval before authentication or paid model calls.
7. Update this section, the evidence table, and the durable research/plan records
   with the exact version and results.

Official documentation:

- [Guidelines and memory](https://junie.jetbrains.com/docs/guidelines-and-memory.html)
- [Agent skills](https://junie.jetbrains.com/docs/agent-skills.html)
- [Custom subagents](https://junie.jetbrains.com/docs/junie-cli-subagents.html)
- [Custom slash commands](https://junie.jetbrains.com/docs/custom-slash-commands.html)

### OpenCode — experimental

OpenCode was not installed or live-tested when this guide was created on
2026-08-28. The repository links `~/.config/opencode/AGENTS.md` to canonical
instructions, uses OpenCode's native discovery of `~/.agents/skills`, generates
agents under `~/.config/opencode/agents`, and generates workflow commands under
`~/.config/opencode/commands`.

Known limitation: generated OpenCode agents currently use plural `permissions`,
the `shell` key, and `model: default`. Current documentation specifies singular
`permission`, the `bash` permission key, and model identifiers in
`provider/model` form. Do not call these agents compatible until corrected and
tested.

#### When OpenCode is first installed

If OpenCode is now installed, do not treat the generated adapters as compatible
merely because they exist. Recheck the official documentation, record the
installed version, correct the canonical generator/configuration, regenerate,
and replace this experimental status with exact validation evidence. Never patch
generated adapter files directly.

1. Record `opencode --version`; inspect current configuration and help output.
2. Recheck rules, skills, agents, commands, permissions, and model docs for that
   installed version.
3. Update `~/.agents/scripts/generate_adapters.py` and
   `~/.agents/adapters.yaml` to emit singular `permission`, use `bash`, and omit
   `model` or replace `default` with a verified `provider/model` identifier.
4. Run `sync-adapters.sh --apply`; verify rule and skill discovery,
   `opencode agent list`, command discovery, delegation, and permission denial in
   an isolated workspace.
5. Stop for operator approval before authentication or paid model calls.
6. Update this section, the evidence table, and the durable research/plan records
   with the exact version and results.

Official documentation:

- [Rules](https://opencode.ai/docs/rules)
- [Skills](https://opencode.ai/docs/skills)
- [Agents](https://opencode.ai/docs/agents/)
- [Commands](https://opencode.ai/docs/commands)

## Maintenance procedures

### Change shared instructions

1. Edit `~/.agents/AGENTS.md`.
2. Keep universal behavior harness-neutral; put adapter mechanics in this guide.
3. Run adapter check and setup verification. Instruction adapters are symlinks,
   so no generated regular-file diff is expected.
4. Start fresh harness sessions when validating startup-loaded instructions.

### Add or update a skill

1. Edit `~/.agents/skills/<name>/SKILL.md` and its supporting resources.
2. Keep the directory and frontmatter `name` identical; use lowercase words with
   single hyphens and keep `description` within 1–1024 characters.
3. Avoid names that collide with configured command directories.
4. Run `generate_adapters.py ... --validate-skills`, setup verification, and the
   behavioral suite; validate discovery in each claimed harness.

### Add or update a role

1. Edit `~/.agents/prompts/<name>.md`, including canonical `name`, `description`,
   `model_class`, `read_only`, `shell`, and `skills` metadata.
2. Update `adapters.yaml` or rendering functions only when the native mapping
   changes. Recheck official schemas first.
3. Apply generation and review every affected native file plus the ownership
   manifest. Test effective permissions, not just parsed frontmatter.

### Add or update a workflow command

1. Edit `~/.agents/commands/<name>.md`; use `$ARGUMENTS` canonically.
2. Keep argument translation inside `render_commands()`.
3. Do not restore Claude command adapters with names already exposed as skills.
4. Regenerate and test command discovery and argument forwarding separately in
   every claimed harness.

### Add a harness

1. Research current primary documentation for global/project instructions,
   skills, agents, commands, precedence, permissions, models, and reload rules.
2. Record what is native, what requires adaptation, and what cannot be preserved.
3. Add only required YAML mappings and the smallest renderer branch.
4. Add isolated positive and negative fixtures before generating into the real
   home directory.
5. Install or authenticate only with operator authorization. Label support
   experimental until native discovery and behavior are observed.
6. Add the harness here with official sources, versioned evidence, limitations,
   and a revalidation procedure.

## Regenerate and verify

From any directory:

```shell
~/.agents/scripts/sync-adapters.sh --check
~/.agents/scripts/sync-adapters.sh --apply
~/.agents/scripts/verify-setup.sh
~/.agents/scripts/test-adapters.sh ~/.agents
yadm diff --check
```

Before delivery, also run the yadm bootstrap and pre-push hook, inspect the
generated and manifest diffs, run applicable language checks, and scan the staged
diff for secrets. `--check` returning success is meaningful only when the test
has also been observed failing for the property it claims to guard.

## Safety invariants

- Never overwrite an unmanaged or locally modified generated target.
- Delete a stale file only when the manifest proves ownership and its digest is
  unchanged.
- Keep all generated targets inside `ADAPTER_HOME`; reject traversal.
- Write the ownership manifest last. Current interrupted-apply recovery is
  fail-closed; a simultaneous canonical change may require manual recovery.
- Do not sweep pre-manifest orphans automatically: adapter directories are not
  declared generator-exclusive.
- Keep ownership metadata out of model-visible bodies and undocumented
  frontmatter.
- Preserve read-only and shell restrictions semantically per harness; identical
  field names are not portable.
- Do not equate file presence, parsing, discovery, delegation, and permission
  enforcement. Record each evidence level separately.

## Troubleshooting

- **Adapter drift:** run `sync-adapters.sh --check`; edit canonical input, then
  apply. Do not patch the reported output.
- **Unmanaged or modified-file refusal:** inspect the file and manifest digest.
  Preserve human work; remove or adopt a file only after ownership is resolved.
- **Skill/command collision:** remove or rename the duplicate native command.
  Ordinary check/apply runs validate configured collision directories.
- **Missing skills or agents:** verify native path, symlink target, frontmatter,
  precedence, and the harness version. Restart when the discovery directory was
  created after the session started.
- **Unexpected permissions:** stop using the agent, compare current official
  schema with generated frontmatter, and reproduce in an isolated workspace.
- **Interrupted apply:** rerun with unchanged canonical sources first. If sources
  changed and ownership is refused, reconcile the file and manifest manually;
  do not weaken the ownership condition.

## Validation evidence

| Harness | Version/date | Status | Evidence boundary |
|---|---|---|---|
| Claude Code | 2.1.250, 2026-08-28 | Verified | Instructions, skills, workflow visibility, and generated agents; conservative collision guard retained |
| Codex | 0.149.1, 2026-08-28 | Partial | Instructions and skills; fresh-session custom prompts still unconfirmed |
| Amp | `0.0.1775636421-g1ea6b1`, 2026-08-28 | Verified | Global instructions and canonical Oracle/Librarian/workflow skills |
| Junie | Not installed, 2026-08-28 | Experimental | Static research only; known agent schema drift |
| OpenCode | Not installed, 2026-08-28 | Experimental | Static research only; known agent schema drift |

Update this table whenever a harness version or evidence boundary changes. Keep
historical reasoning in `records/`; keep this guide focused on the current
maintenance contract.
