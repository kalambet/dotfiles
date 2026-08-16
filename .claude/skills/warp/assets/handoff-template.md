# Handoff: <Title>

**Date:** YYYY-MM-DD
**Status:** open | picked up YYYY-MM-DD | superseded by <path> | abandoned
**Author:** <name or agent>
**Repo(s):** <repo, or the list for cross-repo work>
**Branch:** <branch> @ <sha>
**Follows:** <path to the previous handoff, or "none — first in this arc">

## TL;DR

Three sentences. What this work is, where it stopped, what happens next. Enough for
someone to decide whether to pick it up without reading further.

## Current state

### Done and verified

What is finished **and was actually run**. Each item names the command that proved it
and what it produced.

- <thing> — verified by `<command>` → <what it output>

### Done but untested

Written, plausible, unconfirmed. An item leaves this list only by being executed,
never by looking correct.

- <thing> — untested because <reason: no hardware, needs testnet funds, blocked on X>

### Not started

Scoped but not begun. Distinguish from untested — this is absence, not risk.

## Immediate next action

One concrete step, imperative, naming the file and the change. Not a category.

> <e.g. "Add `--cvm-id` to the upgrade path in `orchestrator/src/deploy.rs::upgrade_cvm`
> so it updates in place instead of creating a new CVM.">

If the next step is a decision rather than an edit, say what the decision is and who
makes it.

## Decisions and rationale

The highest-value section. Without the rejected alternatives, the next session
re-opens settled questions and sometimes reverses them.

| Decision | Why | Rejected alternative, and why | Firmness |
|---|---|---|---|
| <what was decided> | <the constraint or evidence that forced it> | <what else was considered, why it lost> | settled / provisional |

Anything here that durably constrains future work belongs in an ADR — note which.

## Dead ends

Approaches already tried that do not work. **State the reason, not just the verdict** —
the reason is what saves the next session, and is sometimes a design insight.

- **<approach>** — fails because <mechanism>. Evidence: <command output, error, doc link>.

Sharp edges too: flags that look right and aren't, documentation that is wrong,
tooling that lies.

## File map

Key paths, what lives in each, what changed. **Symbol names, not line numbers** —
line numbers go stale within one edit.

| Path | What lives here | Touched this session |
|---|---|---|
| `<repo>/<path>` | <one phrase> | <what changed, by symbol name> |

## Runtime state

Not reconstructible from the repo — which is why it is here.

- **Branch / sha:** <branch> @ <sha>
- **Uncommitted:** <`git status --porcelain` summary, or "clean">
- **Stashed:** <`git stash list`, or "none"> ← routinely forgotten
- **Unpushed commits:** <list, or "none">
- **CI:** <run URL, which jobs actually executed, conclusion>
- **Services running:** <name, port, how started>
- **Env vars required:** <NAME — where it comes from. Never the value.>
- **Migrations / external state:** <deployments, testnet txs, published artifacts>

## Verification commands

Run these **first** to confirm the starting point is not already broken.

```bash
# <what this proves>  — last seen: passing YYYY-MM-DD / failing with <error>
<exact invocation>
```

## Open questions

### Needs the human

Judgement, authority, or information not in the repo. For each, say what you would do
absent an answer, so silence does not block progress.

- <question> — absent an answer, I would <default>.

### The agent can resolve these

Answerable by reading code or running something. Work items, not blockers.

- <question> — <where to look>

## Links

- PR / issue: <url>
- Records and ADRs: <paths>
- Session: `claude --resume <id>` — most-recent-transcript heuristic, not certain
