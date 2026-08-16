# records/handoffs/

Session handoffs. What one working session knew when it stopped, written so the next one
can resume cold — the state, the decisions, the dead ends, and the single next action.

**Append-only, like all of `records/`.** A handoff is a snapshot of what was true and what
was believed at the moment work stopped. It is never edited to match what was learned
afterwards; a later handoff supersedes it. The one permitted edit is the status line, to
mark a handoff picked up or superseded — the same exception `records/` already makes for
supersession generally.

**Handoffs chain.** Each cites its predecessor in a `**Follows:**` line and says what
changed since. Reading a chain backwards reconstructs a multi-day arc without opening
every file in the directory.

The distinction from the siblings:

- [`../plans/`](../plans/) holds a plan for work *to be done*, archived when finished. A
  handoff records where execution *actually stopped*, which is rarely where the plan said
  it would. A plan is the intent; a handoff is the position.
- [`../changes/`](../changes/) records what happened to a *machine*. A handoff records
  what happened to a *task* — and points at any `changes/` entry the session produced.
- [`../experiments/`](../experiments/) records what was run and what came out. A handoff
  cites experiments; it does not restate them.

## Naming

`YYYY-MM-DD-kebab-title.md`, titled by the work in flight rather than the word "handoff".
Absolute dates. Append `-2` for a second handoff on the same day.

## Rules

- **The verified/untested boundary is the point of the document.** Done-and-verified and
  done-but-untested are separate lists, and an item moves between them only by being run.
  A handoff that rounds "probably fine" up to "done" costs the next session a day.
- **Record dead ends with their reason.** "X doesn't work" is nearly useless; "X fails
  because <mechanism>" is what saves turns, and is often the most reusable thing here.
- **Rejected alternatives are not optional.** They are what stops the next session from
  re-litigating a settled decision and occasionally reversing it.
- **No secrets.** Name the credential and its source; never quote a value. This is a
  committed file.
- **Symbol names, not line numbers.** Line numbers are stale before the file is read.
- **Cite, don't restate.** Link the spec, the ADR, the experiment. A handoff that
  paraphrases settled documentation becomes a second source of truth that drifts.

Written by the `warp` skill, consumed by the `pickup` skill. Template: `TEMPLATE.md`.
