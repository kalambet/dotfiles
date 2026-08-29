---
name: pr-review
description: Universal code-review framework — language-agnostic principles plus the two reviewer modes (operator-reviewing-agent and agent-reviewing-PR). Use this skill whenever the user is reviewing a PR, asking for a code review, checking how to review, deciding what to flag vs fix, or handling a review disagreement. EVEN IF the user does not explicitly ask for "review" — triggers on "look at this PR", "check this diff", "what should I look for in this PR", "is this code OK", "how do I review", "approve this PR", "block this PR", "review disagreement", "review comments", "nit prefix", "should I flag this". For language-specific review (Rust, Solidity, TypeScript, Python), additionally load the corresponding language reviewer skill (rust-reviewer, solidity-reviewer, typescript-reviewer, python-reviewer).
metadata:
  type: workflow
  authored-via: anthropic-skills:skill-creator (2026-05-27)
---

# PR Review

Universal review framework. Two reviewer modes; language-specific surface lives in the language reviewer skills.

## Universal principles

- **Approve when the change improves overall code health.** "Perfect" isn't the bar. Forward progress against current quality is.
- **Technical facts and data overrule opinions and personal preferences.** If two designs are equally valid, respect the author's choice.
- **Authority ladder:** style guide > current codebase conventions > author preference.
- **Prefix nits.** Taste/preference/teaching comments get `nit:` prefix so author knows they can ignore.
- **Note the good things.** Reviews skewed toward only-mistakes train authors to be defensive.

## What to look for

- **Design.** Do the pieces fit? Readability beats DRY.
- **Functionality.** Does the code do what was intended? Is the intent good for users + future developers?
- **Complexity.** Especially over-engineering. Solve the problem you have now.
- **Naming.** Long enough to communicate, short enough to read.
- **Comments.** Explain *why*, not *what*.
- **Every line.** Look at every assigned line.
- **Context.** Sometimes pull the branch.

## Reviewing a check, a gate, or a test

A change that adds a check needs a different question than a change that adds a feature.
Not "does it work" but **"can it fail, and does it fail for the reason it names?"** These
four rules are what a run of five review cycles produced; each cost a real defect to learn.

- **A check that has never been seen to fail is not evidence.** Break the thing it guards,
  watch it go red, put it back. Applies to tests as much as to CI jobs — a test written at
  the moment its author became convinced the property holds is exactly the one written from
  a belief rather than from a failure.
- **A fixture that varies its input must not share an implementation with the thing under
  test**, or it inherits its blind spots. A permuter built from the parser it is testing can
  only generate permutations that parser already sees. Cheaper and stronger: assert
  invariants that do not mention the implementation at all.
- **A presence-check is acceptable where the property it stands in for is not the one the
  reviewer must judge, and unacceptable where it is.** "The named test exists" is a fact.
  "A comment is present at the flagged site" is a proxy for "this is justified", on the one
  item a human is supposed to judge — and it will be read as having checked it.
- **An unreachable refusal is the same defect as a missing one.** A second gate downstream
  of a strictly stronger first gate can never be observed failing, so it is decoration.

Two related smells: a gate that reports success having examined nothing (check what it
actually read, not just its exit code), and a job that finishes far faster than the work it
claims to do.

## Speed of review

Default service level: **review within one business day**. If you can't, say so and propose when you can. If author is blocked on critical path, drop other work for it.

This applies to agent reviewers too — agents that "review eventually" defeat the purpose.

## Mode (a) — Operator reviewing agent output

Most agent-authored PRs need the same scrutiny. What to verify:

- **The plan matches the diff.** Drift between linked `plan.md` and the diff is the most common quiet failure.
- **Fabrication.** Imports that don't exist, wrong-signature function calls, broken doc references. Verify.
- **Silent scope creep.** Files in the diff not in the original plan — PR description should name each with a reason.
- **Over-eager refactor.** Each unrelated improvement is its own PR.
- **Generic comments.** Cut comments that restate what the code does.
- **Test theatre.** Tests asserting "function was called" rather than its effect. Read test bodies.
- **Type laxity.** `any`, `unknown`, untyped returns, missing error handling.
- **Undeclared operational contract.** Env vars, config, secrets, schema/migrations, ports, or a public signature changed without an operational-impact declaration — the change that becomes an ops problem later.

### When to demand re-plan vs accept vs reject

- **Re-plan:** diff drifted from plan; agent made unapproved design choices; unrelated changes included; fabrication present. Go back to the plan; don't patch.
- **Accept with notes:** minor issues that don't change the shape.
- **Reject entirely:** wrong direction. Close PR; reopen with fresh plan.

### What the operator cannot delegate

- The merge decision.
- The judgment on whether HARD FAIL findings are properly addressed.
- The sign-off that the audit trail is sufficient.

## Mode (b) — Agent reviewing a PR

### Checklist

- Run lint/type-check/test against the branch; report failures.
- Diff against the linked plan or spec; flag deviations.
- Apply the relevant language reviewer skill (`rust-reviewer`, `solidity-reviewer`, `typescript-reviewer`, `python-reviewer`).
- Check PR-description completeness (what/why/acceptance/**operational impact**/AI declaration/scope flags); flag undeclared env-var / config / schema / public-signature changes.
- Verify references are real.
- Flag missing or thin commit messages.

### Flag vs fix in place

- **Flag, don't fix:** design choices, complexity, naming, anything subjective.
- **Suggest with code suggestion:** trivial nits (typos, lint, formatting).
- **Never fix and push to author's branch** without explicit operator authorization.

### How to phrase comments

- Lead with concern, not fix.
- Cite the rule when there is one.
- Use `nit:` for taste-level.
- Avoid "you" framing for design comments.

### When the agent refuses to review

Escalate rather than reviewing if:

- HARD FAIL findings the agent can't evaluate (mismatched tool).
- PR description missing — nothing to review against.
- Diff touches code the agent has been told not to operate on.

## When reviews go wrong

- **Stale review** (no response >3 business days): reviewer pings once; if no response, the maintainer unblocks.
- **Heated thread:** take it off the PR. 5-minute call beats 30-comment argument.
- **Design disagreement:** not the reviewer's call to overrule. Escalate to the maintainer.
- **Author pushes for merge despite open comments:** the maintainer decides. The reviewer isn't the merge gate alone.

## Related

- Language reviewer skills: `rust-reviewer`, `solidity-reviewer`, `typescript-reviewer`, `python-reviewer`
