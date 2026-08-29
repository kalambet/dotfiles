# Decision Guide: Choosing the System Shape

The goal of this file is to help you route a problem to the *simplest shape that
fits*, and to give you the judgment to push back when a user reaches for
complexity they don't need. Complexity is a cost paid on every request forever —
in latency, dollars, failure surface, and debugging time. Make the problem earn
it.

## The ladder (climb only as far as you must)

Think of system shapes as a ladder. Each rung adds capability but also adds
failure modes, cost, and latency. Start at the bottom and stop as soon as the
problem is solved.

1. **Single model call.** One prompt, one response. Knowledge is in the model or
   pasted into context. The task is one step. This is the most reliable, fastest,
   cheapest, most debuggable thing you can build. A surprising number of "AI
   features" are this and shouldn't be more.

2. **Prompt pipeline (chain).** A fixed sequence of calls where the control flow
   is decided by *you* at design time, not by the model at runtime (e.g.
   extract → classify → draft → format). Deterministic, inspectable, easy to
   eval per stage. Reach here when one call is doing too many things and quality
   suffers, or when stages need different models/prompts.

3. **Retrieval-augmented (RAG).** Add a retrieval step that pulls relevant
   knowledge into context at runtime. Reach here when the knowledge the system
   needs is too big for the context window, changes too often to bake into the
   prompt, or is private/proprietary. RAG is a *knowledge* solution, not a
   reasoning solution — it won't make a weak model reason better. See `rag.md`.

4. **Agentic (single agent, tool-using).** Give the model tools and let it
   decide *at runtime* which to call and in what order, looping until done.
   Reach here only when the task genuinely can't be expressed as a fixed pipeline
   — the steps depend on what's discovered along the way, or the system must take
   actions in the world. This trades determinism for flexibility; you can no
   longer fully predict the path. See `agents.md`.

5. **Multi-agent.** Multiple agents with separate contexts/roles coordinating.
   The highest complexity rung. Justified only by genuine sub-task separation,
   parallelism you actually need, or context-isolation requirements — not by a
   vague sense that "specialized agents" sound better. See `agents.md` for the
   skeptical case.

## How to route

Ask these questions in order. The first "yes" that forces you up the ladder is
your answer — but always confirm you can't solve it one rung lower.

**Does the model already know enough to do the task well?**
Test it. Prompt a capable model with a few real examples. If it succeeds, you may
be done at rung 1–2. Don't build retrieval for knowledge the model already has.

**Does the task need external or fresh knowledge?**
If yes and the knowledge fits in context (a handful of documents, a schema, a
policy), just put it in the prompt — that's still rung 1–2. Only when the
knowledge base is too large or too dynamic to fit does RAG (rung 3) become
necessary.

**Does the system need to *act* — call APIs, write to systems, run code,
navigate — or decide its own steps?**
If the steps are fixed and known, a pipeline (rung 2) with those calls hardcoded
is more reliable than an agent. Only when the sequence must be decided at runtime
based on intermediate results do you need an agent (rung 4).

**Are there genuinely separable, parallelizable sub-tasks, or a need to isolate
context between roles?**
Only then consider multi-agent (rung 5). "It feels cleaner to have a researcher
agent and a writer agent" is usually not enough; a two-stage pipeline gets you
the same separation without the coordination overhead.

## Worked judgment calls

**"We want a chatbot over our 500-page employee handbook."**
Rung 3 (RAG). 500 pages won't fit sensibly in every request, and the handbook
changes. But note: if it were a 5-page handbook, the answer is rung 1 — just put
it in the system prompt. Size and change frequency drive the decision, not the
word "chatbot".

**"We want an AI that reads a support ticket and drafts a reply using our docs."**
Likely rung 2 + retrieval: classify the ticket, retrieve relevant docs, draft.
The steps are fixed, so a pipeline beats an agent. Add rung-4 agency only if the
system must, say, look up the customer's order status via an API *and* decide
whether to escalate *and* the path varies per ticket.

**"We want an agent that can do anything a user asks in our app."**
Push back gently. "Do anything" is not a spec. Find the 3–5 concrete tasks users
actually need, and you'll usually find most are pipelines and one or two need
real agency. Design those specifically. An unbounded agent is the hardest thing
to eval and the easiest to break.

**"Let's use multiple agents so each is an expert."**
Ask what breaks if it's one agent with good prompting and the union of the tools.
Usually nothing. Multi-agent earns its keep when contexts must stay separate
(e.g. one agent shouldn't see another's raw data), when sub-tasks run in
parallel for latency, or when a single context window can't hold everything.
Absent those, prefer one agent or a pipeline.

## Anti-patterns to name when you see them

- **Agent-first design.** Reaching for an autonomous agent before checking
  whether a fixed pipeline does the job. Costs determinism and evaluability for
  flexibility that isn't needed.
- **RAG as a reasoning fix.** Adding retrieval hoping it improves reasoning or
  reduces hallucination on tasks that are actually about reasoning, not
  knowledge. RAG grounds; it doesn't think.
- **Complexity as insurance.** Building the elaborate version "so we don't have
  to redo it later." You'll redo it anyway once you learn what the problem
  actually is. Ship the simple version, measure, then add.
- **The unmeasurable system.** Any design with no answer to "how will we know
  this is good?" Route back to `evals.md` before proceeding.
- **Model-shopping instead of designing.** Swapping models hoping quality
  appears, when the real issue is retrieval, context assembly, or an
  underspecified task.
