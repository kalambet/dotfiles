# Review mode

Use this procedure after the shared brief is complete. All three architects
participate, including outside-lens reviewers for domains the system does not use.

## Round 1: independent review

Dispatch all architects concurrently. Each reads `design/brief.md`, the artifact
under review, and its companion skill, then writes
`design/review.<domain>.md`.

Each review must contain:

- Findings ordered by Critical, Major, and Minor severity, using the finding schema
  in `templates.md`.
- Boundary concerns addressed as questions to a named architect. Require at least
  one concern, or an explicit statement that no interface with another domain
  exists.
- What is genuinely working well. This must be evidence of understanding, not
  generic praise.

## Round 2: cross-examination

Continue with the same architects. Give each the other reviews and require a
position on every finding touching its domain or a boundary, plus answers to every
question addressed to it. Each writes `design/rebuttal.<domain>.md` using the
response vocabulary in `debate-protocol.md`.

Update `design/conflicts.md` after the responses. If no item remains `CONTESTED`,
skip reconciliation and record why.

## Round 3: reconciliation

Run only for contested items. Each holdout gives its final position, what evidence
would change it, and one concession it could make. Update the conflict ledger and
stop after this round even if disagreement remains.

## Final output

Write `design/consensus.md` using the format in `templates.md`. Consolidate agreed
and amended findings rather than concatenating reviews. Preserve withdrawn claims
and unresolved decisions so concessions and remaining trade-offs are visible.
