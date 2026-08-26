---
name: warp
description: Write a handoff record that lets a future session resume this work cold. Use when the user says "warp", "hand off", "write a handoff", "I'm stopping here", "save state", "wrap up for now", "context is getting full", or otherwise wants the current work captured before ending a session, switching tasks, or compacting. Produces a dated, append-only handoff in records/handoffs/ (Control Center layout) with verified-vs-untested state, the single next action, decisions and rejected alternatives, dead ends, a file map, runtime state, verification commands, and open questions. Pair with the `pickup` skill, which consumes it.
---

# warp

Write the record that lets a future session — with none of your context — resume this
work without re-deriving it.

The measure of a good handoff is not completeness, it's **turns saved**. A session
that picks this up should reach its first correct action without re-reading the
codebase, re-running settled debates, or re-discovering a dead end. Everything below
serves that.

Consumed by the **`pickup`** skill.

---

## 1. Where it lands

Detect the layout, don't assume it:

| Condition | Location |
|---|---|
| Repo has `records/` with a `records/README.md` (Control Center pattern) | `records/handoffs/` |
| Otherwise, repo has `docs/` | `docs/handoffs/` |
| Otherwise | `.handoffs/` at the repo root |

**Multi-repo projects: the handoff goes in the control-center repo, not the code
repo.** If the working directory is a sibling of a repo that has the `records/`
layout (e.g. any `verity-*` repo alongside `verity-foundation`), write the handoff
there and qualify every path in the file map with its repo name
(`verity-verifier/src/quote.rs`). Work that spans repos produces one handoff, not
three — three cannot be read in an order that makes sense.

**Naming:** `YYYY-MM-DD-kebab-title.md`, titled by the work in flight, not by the
word "handoff" (`2026-08-09-verifier-mrconfigid-parsing.md`). Absolute dates, never
"today". If the name collides with an earlier handoff the same day, append `-2`.

**First use in a repo:** create the directory's `README.md` from
`assets/handoffs-readme.md` and `TEMPLATE.md` from `assets/handoff-template.md`.
Every directory under `records/` states what belongs in it — a new one without a
README is a convention violation.

## 2. Append-only

Handoffs are records. **Never edit a previous handoff**, with exactly one exception:
its status line, to mark it superseded or picked up. That is the same exception the
Control Center already makes for records generally.

Handoffs **chain**. Each cites its predecessor and says what changed since. Link the
predecessor in the header and set its status line to
`**Status:** superseded by <path>`. The chain is how someone reconstructs a multi-day
arc without reading every file.

## 3. Gather state — do not recall it

**Run these. Do not write runtime state from memory.** Your recollection of the
branch, of what's staged, of whether that test passed is precisely the thing most
likely to be stale, and a handoff that lies about its starting point is worse than
no handoff — the next session builds on a false premise and finds out late.

```bash
git rev-parse --abbrev-ref HEAD                 # branch
git status --porcelain                          # uncommitted / untracked
git stash list                                  # stashed work — routinely forgotten
git log --oneline -10                           # recent commits
git log @{upstream}..HEAD --oneline 2>/dev/null # committed but unpushed
git diff --stat HEAD                            # size of what's outstanding
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null
gh run list --branch "$(git rev-parse --abbrev-ref HEAD)" --limit 3 2>/dev/null
```

For a session ID fallback, read
[references/harness-session-paths.md](references/harness-session-paths.md) and use
only the entry for the active harness. This is a most-recent-transcript heuristic,
not self-identification; say so in the handoff. If the harness is unknown or no
transcript is found, omit the field rather than inventing one.

Also capture, from the session rather than from git: running services and their
ports, env vars the work requires, migrations applied, external state changed
(deployed CVMs, testnet transactions, published artifacts). None of this is
reconstructible from the repo, which is exactly why it belongs here.

## 4. The sections that earn their place

Write to `assets/handoff-template.md`. The rules per section:

**TL;DR** — three sentences: what this work is, where it stopped, what happens next.
Someone should be able to decide from this alone whether to pick it up.

**Current state — the verified/untested boundary.** Two separate lists, never one:

- *Done and verified* — with the command that verified it and what it output.
- *Done but untested* — written, plausible, unconfirmed.

An item moves from the second list to the first **only by being run**, never by
looking correct. This is the single most important line in the document: a next
session that trusts "done" for something never executed will build on sand and lose
a day. Related: a CI job that did not run is not a job that passed — read the step
list, not the badge, and record what actually executed.

**The immediate next action** — one concrete step, in the imperative, naming the
file and the change. Not a category. "Wire tachi's sandbox profile into the systemd
unit at `deployments/hosts/tachi/default.nix`" — not "continue infra work". If you
genuinely don't know, say what the next *decision* is and who makes it.

**Decisions and rationale — the highest-value section.** Every non-obvious choice
made this session: what was decided, why, and **what was rejected and why**. Without
the rejected alternatives, the next session re-opens settled questions and sometimes
reverses them, having re-derived only half the reasoning. Include the constraint or
evidence that forced each call, and mark anything provisional as provisional. Where a
decision constrains future work durably, it belongs in an ADR, not only here — say so.

**Dead ends** — approaches tried that failed, each with the *reason* it failed.
"Approach X doesn't work" is nearly useless; "X fails because the guest agent
serialises the volume before `migrate` runs, so the hook never sees the old data" is
a turn-saver and sometimes a design insight. Include the sharp edges too: the flag
that looks right and isn't, the doc that's wrong.

**File map** — key paths with a phrase on what lives there and what you changed.
**Reference symbols (function, type, test name), not line numbers** — line numbers go
stale within an edit, symbol names survive refactors. Qualify with the repo name in
multi-repo work.

**Runtime state** — the gathered output from §3. Branch, uncommitted and stashed
work, unpushed commits, services and ports, env vars *by name*, migrations, external
state touched.

**Verification commands** — the exact invocations, copy-pasteable, with what each
should produce when healthy and when you last saw it pass. The next session runs
these *first*, to confirm the starting point isn't already broken. A handoff without
these forces a re-derivation of how to even check the work.

**Open questions**, in two separated groups:

- *Needs the human* — decisions requiring judgement, authority, or information not
  in the repo. Say what you'd do absent an answer, so silence isn't a blocker.
- *Agent can resolve* — answerable by reading code or running something. These are
  work items, not blockers, and conflating the two stalls the next session on
  questions it could have answered itself.

**Links** — PR and issue URLs, relevant records and ADRs, the session ID.

## 5. Hard rules

1. **No secrets, ever.** Name the credential and where it comes from; never quote a
   value. Env vars appear as `PHALA_API_KEY (from 1Password: …)`, never with the key.
   Agents get no operator secrets, and a handoff is a durable, committed file — the
   worst possible place to leak one.
2. **Honest state or the document is worthless.** If tests fail, say so and paste the
   failure. If a step was skipped, say it was skipped. Never round "probably fine" up
   to "done". Hedged completeness beats confident fiction.
3. **Respect the repo's invariants.** Read `AGENTS.md`, `ARCHITECTURE.md`, and
   `LIBRARIAN.md` if present, and don't write anything the project forbids — for
   Verity that includes never calling the system "trustless" and using
   `licensed_composeHash == attested_composeHash` in new text.
4. **Cite, don't restate.** If the spec or an ADR already says it, link it. A handoff
   that paraphrases settled documentation adds a second source of truth that will
   drift from the first.
5. **Right-size it.** An hour of work on one file does not need a full template — a
   short TL;DR, next action, and runtime state is a complete handoff for it. Reserve
   the full form for work that spans sessions, repos, or unfinished state.

## 6. Finish

Report the path, the immediate next action verbatim, and the one thing you're least
confident is accurate. Then offer — don't perform — the follow-ups: committing the
handoff, and archiving a concluded `plan.md` to `records/plans/` per that
directory's README.
