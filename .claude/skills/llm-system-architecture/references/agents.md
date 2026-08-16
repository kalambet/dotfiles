# Agentic and Multi-Agent Design

Read this when the system must *take actions* or *decide its own steps at
runtime*. An agent is a model in a loop with tools: it observes, decides which
tool to call, acts, observes the result, and repeats until the task is done or a
limit is hit.

This file is deliberately skeptical. Agents trade determinism for flexibility,
and that trade is often a bad deal. The strongest agentic designs use *as little*
agency as the task allows.

## First: do you actually need an agent?

Before designing an agent, rule out the simpler shape. You need agency only when
**the sequence of steps cannot be known in advance** — it depends on what the
system discovers as it goes. If you can draw the flowchart at design time, build
that flowchart as a pipeline (see `decision-guide.md`); it will be more reliable,
cheaper, faster, and far easier to eval.

Signs you genuinely need an agent:
- The number and order of steps vary per input and can't be enumerated.
- The system must react to tool results it can't predict (search, then decide
  what to do based on what it found).
- The task is open-ended exploration or problem-solving, not a fixed transform.

Signs you *don't* (use a pipeline instead):
- "It calls an API then formats the result" — fixed steps.
- "It classifies then routes to one of three prompts" — a switch, not an agent.
- You're reaching for an agent because it sounds more capable, not because the
  control flow demands it.

## Designing a single agent

### Tools are the agent's real interface — design them like an API

An agent is only as good as its tools. Tool design is where most agent quality is
won or lost:

- **Make each tool do one clear thing** with an unambiguous name and description.
  The model chooses tools from these descriptions the way a developer reads API
  docs — vague descriptions cause wrong calls.
- **Design for the model's understanding, not the underlying system.** Wrap messy
  internal APIs in clean, purpose-shaped tools. A tool named `search_orders` that
  takes a customer id beats exposing three raw database endpoints.
- **Return useful, concise observations.** Tool outputs go back into the context
  window. Return what the model needs to decide the next step, not a giant raw
  dump. Trim and structure results.
- **Make errors informative and recoverable.** A tool error should tell the model
  what went wrong and how to fix the call, so it can self-correct rather than
  spiral.
- **Least privilege.** Give the agent the narrowest tool scopes that accomplish
  the task. An agent with broad write access is a broad liability.

### Control the loop

- **Bound it.** Hard caps on steps, tokens, wall-clock time, and cost. An
  unbounded loop is an unbounded bill and an unbounded failure surface.
- **Termination.** Define exactly how the agent knows it's done (a "finish" tool,
  a success condition, a max-steps fallback). Ambiguous termination causes
  looping or premature stops.
- **Progress/observability.** Log every step (thought, tool call, observation) so
  runs are debuggable and evaluable. Agent failures are opaque without a trace.
- **Human-in-the-loop gates.** For high-impact or irreversible actions (spending,
  sending, deleting, external commitments), require confirmation. Decide which
  actions are auto-approved vs. gated based on the failure cost from discovery.

### Memory

Decide what the agent remembers and how:
- **Working memory** = the current context window (the task, recent steps).
  Manage overflow with summarization or by writing intermediate results to
  external storage and retrieving as needed.
- **Long-term memory** (facts/preferences/history across sessions) is retrieval,
  not context — store it and pull it in when relevant. Don't try to keep
  everything in the window.
- Be explicit about what persists, where, and for how long — memory is also a
  privacy surface.

## Multi-agent: the high bar

Multiple coordinating agents is the most complex shape and the easiest to get
wrong. Coordination overhead, error propagation between agents, latency, cost,
and debugging difficulty all multiply. Reach for it only when at least one of
these genuinely holds:

- **Context isolation is required** — an orchestrator must delegate a sub-task
  without exposing its full context, or one agent must not see another's raw
  data (e.g. for privacy or to avoid context pollution).
- **Parallelism you actually need** — independent sub-tasks run concurrently to
  cut latency (e.g. fan out research across several sources at once).
- **A single context window can't hold the work** — the task is large enough that
  splitting it across agents with separate windows is the only way to fit it.

If none hold, one well-prompted agent with the union of the tools — or a
pipeline — is more reliable. "Specialized roles feel cleaner" is not sufficient
justification.

### Multi-agent patterns

- **Orchestrator–worker.** A lead agent decomposes the task, spins up workers for
  sub-tasks (often in parallel), and synthesizes their results. The dominant
  useful pattern. The hard parts are giving workers crisp, self-contained briefs
  and merging their outputs coherently.
- **Pipeline of specialists.** A fixed hand-off chain (e.g. research → draft →
  critique → revise). If the chain is fixed, this is really a prompt pipeline
  where some stages happen to be agentic — treat it as such and eval each stage.
- **Debate / critic.** One agent produces, another critiques, improving quality
  on reasoning-heavy tasks at the cost of extra calls. Use when quality matters
  more than latency/cost and evals show single-pass isn't enough.

### Coordination concerns to design for

- **Task decomposition quality** — bad splits produce overlapping or gappy work.
  The orchestrator's decomposition prompt is critical.
- **Communication contract** — define exactly what each agent receives and
  returns (a schema), or hand-offs degrade into telephone.
- **Error propagation** — one worker's bad output can poison the synthesis.
  Validate worker outputs before merging.
- **Cost/latency multiplication** — N agents ≈ N× the calls. Budget for it and
  justify it against the single-agent baseline.

## Evaluating agents (summary — details in evals.md)

Agents need *trajectory* evaluation, not just final-answer checks:
- **Outcome:** did it accomplish the task? (task success rate on a fixed set)
- **Trajectory:** did it take a sensible path — right tools, no needless loops,
  reasonable step count and cost? Evaluate the trace, not only the endpoint.
- **Tool-use correctness:** were tools called with valid arguments at the right
  time?
- **Safety:** did it respect gates and never take an unauthorized high-impact
  action?
- **Robustness:** how does it behave when a tool errors or returns junk? Test the
  unhappy path explicitly.
