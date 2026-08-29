---
name: research-plan-implement
description: A disciplined Research → Plan → Annotate → Implement workflow for non-trivial coding work in an existing codebase. Use this skill whenever the user asks to implement a feature, add functionality, fix a cross-cutting or non-obvious bug, refactor, or make any substantial multi-file change — especially phrasings like "implement X", "add Y", "build this feature", "refactor Z", or kicking off a new piece of work. It enforces deep code research written to research.md, a reviewable plan in plan.md, a human annotation cycle before any code is written, and mechanical execution afterwards. Reach for it before writing code for anything beyond a trivial change, even when the user doesn't explicitly mention planning. Do NOT use it for tiny, self-evident fixes (typos, one-liners, obvious renames) where a written plan would be pure overhead — just do those directly.
---

# Research → Plan → Implement

## Core Principle

**Never write code until the human has reviewed and approved a written plan.**

Separate thinking from typing. Research prevents ignorant changes. The plan prevents wrong changes. The annotation cycle injects human judgement. Implementation runs without interruption once every decision has been made.

This skill is for substantial work. For trivial, self-evident fixes, skip the ceremony and just make the change.

## Workflow Pipeline

```
Research → Plan → Annotate (repeat 1–6×) → Implement
```

Run all phases in a **single long session**. Do not split across separate sessions — context built during research and planning must carry through to implementation. The plan document survives compaction and serves as the persistent source of truth.

---

## Phase 1: Research

Before planning anything, deeply read the relevant code. Surface-level skimming is not acceptable.

- Read the specified folders/files in depth — understand how the code works, what it does, and all its specificities.
- Study the intricacies of the systems involved.
- Look for existing patterns, conventions, caching layers, ORM conventions, and reusable logic.
- Write all findings into `research.md`. Never give a verbal summary only.

**Example directives the user might give:**

> "Read this folder in depth, understand how it works deeply, what it does and all its specificities. When that's done, write a detailed report of your learnings and findings in research.md."

> "Go through the task scheduling flow, understand it deeply and look for potential bugs. Keep researching until you find all the bugs, then write a detailed report in research.md."

**Why this matters:** If the research is wrong, the plan will be wrong, and the implementation will be wrong. The most expensive failure mode is an implementation that works in isolation but breaks the surrounding system — a function that ignores an existing caching layer, a migration that doesn't account for ORM conventions, an endpoint that duplicates logic that already exists.

Stop after writing `research.md` and let the human review it before planning.

---

## Phase 2: Plan

Once the human has reviewed `research.md`, create a detailed implementation plan in a **separate** file, `plan.md`.

The plan must include:

- A detailed explanation of the approach.
- Code snippets showing the actual changes.
- The file paths that will be modified.
- Considerations and trade-offs.

**Reference implementations:** When available, work from concrete reference implementations in the codebase or open-source projects. Working from a reference produces dramatically better results than designing from scratch.

**Critical:** After writing the plan, **stop**. Do not implement. Wait for human annotation.

---

## Phase 3: Annotation Cycle

This is where the human adds the most value. They open `plan.md` and add inline notes directly into the document — correcting assumptions, rejecting approaches, adding constraints or domain knowledge, redirecting whole sections.

**Examples of real annotations:**

- *"Use drizzle:generate for migrations, not raw SQL"* — domain knowledge
- *"No — this should be a PATCH, not a PUT"* — correcting a wrong assumption
- *"Remove this section entirely, we don't need caching here"* — rejecting an approach
- *"The queue consumer already handles retries, so this retry logic is redundant. Remove it and just let it fail"* — explaining existing system behavior
- *"This is wrong, the visibility field needs to be on the list itself, not on individual items"* — redirecting the design

After each annotation round, update the plan based on the notes, then **stop again** — do not implement yet. The cycle repeats 1–6 times until the human is satisfied.

**Before implementation:** Add a granular todo list to the plan covering all phases and individual tasks. This serves as the progress tracker.

> "Add a detailed todo list to the plan, with all the phases and individual tasks necessary to complete the plan — don't implement yet."

---

## Phase 4: Implementation

When the human approves the plan, execute everything in one continuous run. The canonical instruction:

> "Implement it all. When you're done with a task or phase, mark it as completed in the plan document. Do not stop until all tasks and phases are completed. Do not add unnecessary comments or jsdocs, do not use `any` or `unknown` types. Continuously run typecheck to make sure you're not introducing new issues."

| Instruction | Purpose |
|---|---|
| "Implement it all" | Do everything in the plan, don't cherry-pick |
| "Mark it as completed in the plan document" | The plan is the source of truth for progress |
| "Do not stop until all tasks and phases are completed" | Don't pause for confirmation mid-flow |
| "Do not add unnecessary comments or jsdocs" | Keep the code clean |
| "Do not use `any` or `unknown` types" | Maintain strict typing |
| "Continuously run typecheck" | Catch problems early |

Implementation should be **boring**. All creative decisions were made in the annotation cycles.

---

## Feedback During Implementation

Once implementation is running, the human's role shifts from architect to supervisor, and prompts become short and direct — *"You didn't implement the `deduplicateByTitle` function."*, *"You built the settings page in the main app when it should be in the admin app, move it."*, *"Wider."*, *"Still cropped."*, *"There's a 2px gap."*

- For visual issues, expect screenshots — they communicate faster than descriptions.
- Reference existing code: *"This table should look exactly like the users table — same header, same pagination, same row density."*
- When something goes wrong, **revert and re-scope** rather than patching: *"I reverted everything. Now all I want is to make the list view more minimal — nothing else."*

---

## Key Rules

1. **Never implement without an approved plan.** The plan document sits between the agent and the code.
2. **Research first, always.** Understand the existing system before proposing changes.
3. **Write artifacts, not chat.** All research, plans, and progress live in markdown files — not in conversation history.
4. **Respect the annotation cycle.** When told "don't implement yet," stop and wait for human input.
5. **Stay in a single session.** Context compounds — research informs planning, planning informs implementation.
6. **The plan is the source of truth.** Mark tasks complete in the plan. Point back to it when context is needed.
7. **Keep implementation mechanical.** All decisions are pre-made. Execute the plan faithfully.
8. **Run typechecks continuously.** Don't accumulate errors — catch them as they happen.

---

*Based on [Boris Tane's Research → Plan → Implement workflow](https://boristane.com/blog/how-i-use-claude-code/).*
