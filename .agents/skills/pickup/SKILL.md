---
name: pickup
description: Resume work from a handoff record written by the `warp` skill. Use when the user says "pickup", "pick up where we left off", "resume", "continue the last session", "what was I working on", "read the handoff", or starts a session expecting prior context that this session does not have. Finds the latest handoff in records/handoffs/, verifies the starting point still holds before trusting it, reconciles drift since it was written, and states the next action for confirmation.
---

# pickup

Resume work from a handoff without inheriting its mistakes.

A handoff is a **claim about the past**, not a description of the present. It was true
when written; the repo may have moved, someone may have committed, a service may be
down, and the "verified" list may have rotted. Your job is to establish what still
holds *before* acting on any of it.

The two failure modes, in order of cost:

1. **Trusting stale state** — building on a claimed-green test that now fails, or a
   branch that has since been rebased. Cheap to prevent, expensive to discover late.
2. **Re-litigating settled decisions** — reading the decisions section as suggestions
   and quietly reversing a call the last session made for a reason you no longer see.

## 1. Find the handoff

Search in order: `records/handoffs/`, `docs/handoffs/`, `.handoffs/`. In a multi-repo
project, also check the control-center sibling — handoffs for `verity-*` work live in
`verity-foundation/records/handoffs/`, not in the code repo.

Take the newest by filename date, then confirm by status line: a handoff marked
`superseded by <path>` is not the one to read — follow the pointer. If several are
`open`, list them with their TL;DRs and ask which.

Read its **`Follows:`** chain back one or two links if the current one references
decisions or dead ends it does not restate. Do not read the whole chain by default;
that is what supersession is for.

Also read the repo's `AGENTS.md` and `CLAUDE.md` when present, plus
`ARCHITECTURE.md` / `LIBRARIAN.md`. If both instruction files resolve to the
same file, read it once. The handoff assumes them.

## 2. Verify before you trust — do this before any work

Run the handoff's **verification commands first.** This is the whole point of the
section: it establishes whether the starting point is already broken. A session that
skips this and starts editing will attribute a pre-existing failure to its own change
and debug the wrong thing.

Then reconcile the claimed runtime state against reality:

```bash
git rev-parse --abbrev-ref HEAD                 # same branch as claimed?
git log --oneline -5                            # same head sha?
git status --porcelain                          # uncommitted work still present?
git stash list                                  # stashes still there?
git log <handoff-sha>..HEAD --oneline           # what landed since the handoff
```

Report drift explicitly before proceeding — branch moved, work committed or lost,
stash gone, a service that should be running isn't, CI now red. **Drift is a finding,
not a nuisance.** If the tree diverged materially from what the handoff describes,
stop and say so rather than reinterpreting the plan around it.

Treat the two state lists differently:

- *Done and verified* — re-run the cited command. Trust the result, not the claim.
- *Done but untested* — still untested. Picking up a handoff does not promote
  anything. If the next action depends on one of these, verifying it **is** the next
  action.

## 3. Treat decisions as binding

The decisions table and the dead ends are the sections you did not pay for and cannot
reconstruct. Read them as **constraints on this session**, not as background.

- A decision marked `settled` is not reopened because you would have chosen
  differently. If you believe it is wrong, say so explicitly to the user with your
  reasoning and let them decide — do not silently re-implement around it.
- A decision marked `provisional` is open, and the handoff is telling you so.
- A dead end is not re-attempted. If you think its stated reason no longer applies,
  say why before spending turns on it.
- Anything the handoff routed to an ADR or the spec: read that, and let it win. The
  handoff is a session's memory; the ADR is the project's.

## 4. Report the position, then act

Before doing work, give the user a short status — this is what they came for:

1. **Where things stand** — one line, from the TL;DR, corrected by what you verified.
2. **What verification showed** — which commands passed, which failed, what drifted.
   Say it plainly if the starting point is broken.
3. **Open questions needing them**, from that section of the handoff, with the
   handoff's stated default for each. These come first because they may change
   everything downstream.
4. **The immediate next action**, verbatim from the handoff, adjusted for anything you
   found — and say what you adjusted and why.

Then confirm before executing, unless the user's request already made it clear they
want you to just continue. Questions the handoff marked *agent can resolve* are yours
to answer — resolve them as part of the work rather than asking.

## 5. Mark it picked up

Update the handoff's **status line only** — `**Status:** picked up YYYY-MM-DD` —
and nothing else. Handoffs are append-only records; the status line is the sole
sanctioned edit. Corrections do not go here. If the handoff was wrong, that fact is
recorded in the *next* handoff, which supersedes this one and says what it got wrong.

## 6. Close the loop

When the session's work stops, run **`warp`** to write the successor, citing this one
in its `Follows:` line and setting this one to `superseded by <path>`. An arc picked
up but never warped back leaves the chain broken, and the next session inherits a
handoff that is one session out of date while looking current.
