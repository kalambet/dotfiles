---
name: feature-team
description: Feature Team — assembles a multi-agent team to implement a feature end-to-end. Use when the user asks to implement a feature that involves both Apple platform (iOS/macOS) and AI/ML components and needs a full review cycle.
---

# Feature Team

Create an agent team for this feature:

Teammate "ai-apple-engineer" should use the ai-apple-engineer agent definition. When the task is assigned to them, they should be the one to look at the details, @ARCHITECTURE.md and @docs and explain the solution and pass the task to the apple-builder or ai-builder depending of the task type.

Teammate "apple-builder" should use the apple-engineer agent definition. They should be consulted about any iOS/macOS and other Apple OS decisions. They are doing the implementation of iOS/macOS related tasks and issues.

Teammate "apple-reviewer" should use the apple-reviewer agent definition. They should work in pair with apple-builder and as soon as apple-builder is finished, review the changes in ReadOnly format and provide feedback to apple-builder.

apple-builder can finish the implementation as soon as apple-reviewer approves the changes.

Teammate "ai-builder" should use the ai-apple-engineer agent definition. They should be consulted about any AI/Local ML/LLM/MLX decisions.

Teammate "ai-reviewer" should use the ml-reviewer agent definition. They should work in pair with ai-builder and as soon as ai-builder is finished, review the changes in ReadOnly format and provide feedback to ai-builder.

ai-builder can finish the implementation as soon as ai-reviewer approves the changes.

Teammate "reviewer" should wait for "apple-builder" and "ai-builder" and "ai-reviewer" and "apple-reviewer" to finish, then review all changed files. Use both the full-reviewer agent definition. Read-only — don't modify any files.

After the review Teammates "apple-builder" and "ai-builder" should fix all the comments and this process needs to be repeated till "reviewer" is satisfied and gives the APPROVED status.
