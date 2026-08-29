# Harness session paths

Use only the active harness entry. Treat every result as a newest-transcript
heuristic and label it accordingly.

## Claude Code

```bash
ls -t ~/.claude/projects/"$(pwd | sed 's|/|-|g')"/*.jsonl 2>/dev/null | head -1
```

Resume with `claude --resume <session-id>` when the ID is available.

## Codex

```bash
ls -t ~/.codex/sessions/*/*/*/*.jsonl 2>/dev/null | head -1
```

Resume through the installed Codex resume command. Do not infer the session ID
from a filename without checking the installed CLI format.

## Other harnesses

Do not guess undocumented state paths. Record the working directory, branch,
commit, dirty state, and next action; omit the session ID.
