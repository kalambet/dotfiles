# AI/ML Anti-Patterns Catalog

A catalog of common anti-patterns and code smells in AI/ML systems. Each entry follows a consistent format for quick reference during code reviews. The LLM Integration section is the most extensive, reflecting where the most damage occurs in modern AI systems.

## Table of Contents
1. [Data Anti-Patterns](#data-anti-patterns)
2. [Model Training Anti-Patterns](#model-training-anti-patterns)
3. [LLM Integration Anti-Patterns](#llm-integration-anti-patterns)
4. [Production Anti-Patterns](#production-anti-patterns)
5. [Architecture Anti-Patterns](#architecture-anti-patterns)

---

## Data Anti-Patterns

### Train-Test Contamination
**Severity:** CRITICAL
**Symptom:** Preprocessing (scaling, encoding, feature selection) fitted on the full dataset before splitting; duplicate records appearing in both train and test sets; temporal data split randomly instead of by time
**Why it's harmful:** Inflated evaluation metrics that don't reflect real-world performance. The model appears to perform well but fails in production because it was evaluated on data it effectively already saw
**Fix:** Always split first, then preprocess. Fit transformers on training data only. For time-series, split by time with a gap period. Deduplicate before splitting. Assert no overlap between splits

### Silent Data Corruption
**Severity:** CRITICAL
**Symptom:** No schema validation on input data. No assertions on data shape, range, or type. NaN and null values propagated without detection. String "None" or "null" treated as valid values
**Why it's harmful:** Garbage in, garbage out — but silently. The model trains on corrupted data, produces degraded predictions, and nobody notices until downstream business impact becomes undeniable
**Fix:** Validate all input data against an explicit schema. Assert expected shapes, ranges, and distributions. Fail loudly on unexpected values. Use data validation libraries (Great Expectations, Pandera, or equivalent)

### The Infinite Accumulator
**Severity:** HIGH
**Symptom:** Training data grows by appending new data without deduplication, quality filtering, distribution analysis, or versioning. Data pipeline has an "append" step but no "validate" or "deduplicate" step
**Why it's harmful:** Data quality degrades over time. Duplicates bias the model. Distribution shift goes undetected. Storage costs grow linearly. Retraining becomes slower and more expensive with each iteration
**Fix:** Version training data explicitly. Deduplicate on every append. Monitor distribution statistics across versions. Implement quality gates that reject data batches below quality thresholds

### Undocumented Transforms
**Severity:** MEDIUM
**Symptom:** Data transformations with no comments, no tests, and no documentation explaining the "why." Magic numbers in preprocessing code. Feature engineering logic that only the original author understands
**Why it's harmful:** When something breaks, nobody can debug it. When the original author leaves, the knowledge is gone. When the transform needs updating, nobody knows the invariants it must preserve
**Fix:** Every non-trivial transform gets a docstring explaining what it does and why. Magic numbers become named constants. Critical transforms get unit tests. Data lineage is documented

### Survivorship Bias in Training Data
**Severity:** HIGH
**Symptom:** Training data only includes successful outcomes (approved loans, completed purchases, retained users). No representation of the counterfactual (what would have happened with a different decision)
**Why it's harmful:** The model learns to predict "success" for cases that look like past successes, perpetuating existing biases. It cannot learn from the absence of data — rejected loan applicants who would have repaid, users who were never shown a feature
**Fix:** Acknowledge the bias explicitly. Use techniques like inverse propensity weighting, randomized exploration data, or causal inference methods. At minimum, document the known bias and its expected impact on predictions

## Model Training Anti-Patterns

### The Unmonitored Training Run
**Severity:** HIGH
**Symptom:** No logging of loss curves, gradient norms, or learning rate schedule during training. No early stopping. No checkpointing. Training runs overnight with the assumption that it "probably worked"
**Why it's harmful:** Wasted compute when training diverges. No ability to diagnose why a model underperforms. No way to resume from a checkpoint if the run is interrupted. No historical record for comparison
**Fix:** Log loss (train and validation) every N steps. Log gradient norms. Checkpoint at regular intervals. Implement early stopping on validation metric. Use experiment tracking (MLflow, W&B, or structured logs)

### Hyperparameter Cargo-Culting
**Severity:** MEDIUM
**Symptom:** Learning rate, batch size, regularization, and architecture choices copied from a tutorial, paper, or blog post without any tuning for the current dataset and task
**Why it's harmful:** Hyperparameters that work for ImageNet don't work for your 10K-sample tabular dataset. Optimal settings depend on data size, distribution, and task. Copied settings are a coincidence, not a strategy
**Fix:** Establish a baseline with reasonable defaults. Run at least a coarse hyperparameter search (grid or random over 20-50 trials). Document which hyperparameters were tuned and which are defaults. Track the relationship between hyperparameters and validation metrics

### The Metric Mirage
**Severity:** HIGH
**Symptom:** Optimizing a metric that doesn't correlate with business value. Accuracy on an imbalanced dataset. BLEU score for a task where human preference diverges from BLEU. Aggregate metrics that hide per-class or per-segment failures
**Why it's harmful:** The model improves on paper but doesn't improve the product. Resources are spent optimizing the wrong objective. Stakeholders lose trust in ML when reported improvements don't translate to outcomes
**Fix:** Define the business metric first. Choose an evaluation metric that correlates with it (validate this correlation empirically). Report per-class and per-segment metrics alongside aggregates. When in doubt, use human evaluation

### Overfitting to the Validation Set
**Severity:** HIGH
**Symptom:** The same validation set used for dozens of experiments. Hyperparameters, architecture, and even data augmentation tuned until validation metrics look good. The "test set" has been peeked at more than once
**Why it's harmful:** The validation set has become a second training set through indirect optimization. Reported metrics are optimistic. The true held-out performance is unknown. This is a more subtle form of train-test contamination
**Fix:** Use a true held-out test set that is evaluated at most once at the end of development. Use cross-validation for hyperparameter tuning. If the validation set has been heavily optimized against, collect a fresh test set before claiming final results

### The One-Off Script
**Severity:** MEDIUM
**Symptom:** Training logic lives in a Jupyter notebook or ad-hoc Python script with no version control, no config management, no reproducibility guarantees. "I'll clean it up later"
**Why it's harmful:** Experiments are not reproducible. Knowledge is lost when the notebook is overwritten. There's no way to audit what configuration produced which model. "Later" never comes
**Fix:** Extract training logic into version-controlled code with configuration files. Use experiment tracking from day one. Make "run this experiment" a single command with all parameters specified, not a notebook you scroll through executing cells

## LLM Integration Anti-Patterns

### The Infinite Context
**Severity:** HIGH
**Symptom:** Stuffing everything into the prompt — full conversation history, all retrieved documents, complete system instructions — with no consideration for token limits, relevance, or the "lost in the middle" effect
**Why it's harmful:** Exceeding the context window causes silent truncation or API errors. Even within limits, more context dilutes attention on what matters. Cost scales linearly with input tokens. The model may attend to irrelevant context and produce worse outputs
**Fix:** Set a token budget for each section of the prompt (system: N, context: M, history: K). Implement truncation or summarization strategies. Filter retrieved context by relevance score. Prune conversation history beyond N turns

### Prompt Injection Blindness
**Severity:** CRITICAL
**Symptom:** User input concatenated directly into prompts without structural separation, sanitization, or injection awareness. Using string formatting or template literals to build prompts from user data
**Why it's harmful:** Users (or data sources) can hijack the model's behavior. The model may ignore system instructions and follow injected instructions. This can lead to data exfiltration, unauthorized actions (via tool use), or reputation damage
**Fix:** Use the API's native role-based message structure (system/user/assistant). Wrap user content in XML tags or delimiters. Implement input validation and length limits. For tool-using agents, validate tool calls independently of the model's reasoning. Never trust user input in a prompt

### Parse and Pray
**Severity:** HIGH
**Symptom:** Calling `json.Unmarshal` / `JSON.parse` on raw model output with no validation, no error handling, and no retry logic. Assuming the model will always return valid, schema-compliant structured data
**Why it's harmful:** Models produce invalid JSON, truncated output, extra text before/after JSON, and structurally valid JSON with semantically wrong values. Any of these will cause a runtime error or silent data corruption
**Fix:** Use tool use / function calling instead of raw JSON generation. Validate output against a schema. Implement retry with correction prompt on parse failure. Have a fallback for when parsing fails after retries. Check stop_reason for truncation

### The Cost Bomb
**Severity:** CRITICAL
**Symptom:** Agent loops with no step limit. Retry logic with no maximum. Conversation history that grows unbounded. No per-request cost tracking. No alerting on cost anomalies
**Why it's harmful:** A single runaway request can cost hundreds or thousands of dollars. This has happened to real companies. An agent loop that runs 50 steps with a 128K context at each step is catastrophically expensive
**Fix:** Hard limits on agent steps (10-20 for most tasks). Cost ceilings per request. Budget alerts. Per-request cost logging. Circuit breakers that stop spending when cost exceeds thresholds. max_tokens always set explicitly

### Model Lock-In
**Severity:** MEDIUM
**Symptom:** Provider-specific code (API format, error types, response parsing) scattered throughout the application. No abstraction layer between application logic and the LLM provider. Model name hardcoded in multiple places
**Why it's harmful:** When you need to switch providers (outage, pricing change, quality regression, new model), it requires touching every file that calls the LLM. Migration takes days or weeks instead of hours
**Fix:** Define an interface for LLM calls (request/response types, streaming interface, error types). Implement provider-specific adapters behind this interface. Model name and configuration as environment/config values, not hardcoded strings

### The Synchronous Bottleneck
**Severity:** HIGH
**Symptom:** LLM API calls made synchronously in the request path. User waits 5-30 seconds for a page to load because the server is blocking on an LLM response. No streaming, no async processing, no background jobs
**Why it's harmful:** Terrible user experience. Server threads/goroutines are blocked waiting on external API calls, limiting throughput. A slow LLM response degrades the entire application
**Fix:** Stream responses to the user when possible. Use async processing for non-interactive tasks. Implement background job queues for batch operations. Set appropriate timeouts. Show partial results while waiting

### Temperature Roulette
**Severity:** MEDIUM
**Symptom:** Temperature not set explicitly, relying on provider defaults. High temperature for deterministic tasks (classification, extraction). Zero temperature for creative tasks. Temperature chosen by vibes, not evaluation
**Why it's harmful:** Wrong temperature causes inconsistent outputs (too high for deterministic tasks) or boring, repetitive outputs (too low for creative tasks). Provider defaults may change. Non-determinism in deterministic pipelines makes debugging impossible
**Fix:** Set temperature explicitly for every call. Use 0.0-0.3 for extraction, classification, and structured output. Use 0.7-1.0 for creative generation. Evaluate the impact of temperature on your specific task. Document the choice

### The System Prompt Novel
**Severity:** MEDIUM
**Symptom:** System prompts exceeding 2000+ tokens with verbose instructions, redundant rules, contradictory guidance, and instructions the model follows by default anyway. The system prompt is a dump of every requirement anyone ever mentioned
**Why it's harmful:** Every token costs money on every request. Verbose instructions dilute important ones. Contradictory instructions cause inconsistent behavior. The model's attention is finite — a 5000-token system prompt means less attention for the actual task
**Fix:** Audit the system prompt ruthlessly. Remove instructions the model follows by default. Eliminate redundancy. Test each instruction's impact by removing it — if output quality doesn't change, it's dead weight. Target 500-1000 tokens for most use cases

### The Context Hoarder
**Severity:** HIGH
**Symptom:** Full conversation history passed to every API call with no truncation, summarization, or relevance filtering. In a 50-turn conversation, every turn's full content (including tool results and reasoning) is included
**Why it's harmful:** Cost grows quadratically with conversation length (more input tokens per call, more calls over time). Eventually exceeds context window. Old, irrelevant context dilutes attention on the current task
**Fix:** Implement sliding window (last N turns), or summarize older turns. Strip verbose tool results from history — keep the tool call and a brief summary of the result. Set a maximum context budget for history and enforce it

### The Retry Avalanche
**Severity:** HIGH
**Symptom:** Aggressive retry logic with no backoff, no jitter, and no maximum. On rate limit errors, immediately retry. On timeout, immediately retry. Multiple services all retrying simultaneously
**Why it's harmful:** Amplifies the original problem. Rate limits exist for a reason — retrying immediately hammers the API harder. Multiple services retrying create thundering herd effects. Cost multiplied by retry count
**Fix:** Exponential backoff with jitter, always. Respect Retry-After headers. Maximum 3 retries for transient errors. Zero retries for content filter and client errors. Circuit breaker for sustained failures. Log every retry

## Production Anti-Patterns

### The Silent Degradation
**Severity:** CRITICAL
**Symptom:** No monitoring of model output quality in production. No automated evaluation. No sampling for human review. The model could be returning nonsense for days before anyone notices
**Why it's harmful:** ML models degrade silently. Data drift, prompt regression, API changes, and model updates can all degrade quality without causing errors. By the time someone notices, the damage (lost revenue, wrong decisions, user trust erosion) is done
**Fix:** Instrument production quality metrics. Sample outputs for automated evaluation (LLM-as-judge for fast feedback, human review for ground truth). Alert on metric degradation. Track output distribution statistics and alert on shifts

### The Immutable Model
**Severity:** HIGH
**Symptom:** A model deployed with no mechanism for updating, rolling back, A/B testing, or gradual rollout. Deployment is a one-shot event with no plan for what comes next
**Why it's harmful:** When the model needs updating (it always does), you're deploying from scratch. When the new version regresses, there's no quick rollback. You can't compare model versions in production. Every deployment is a big bang with full blast radius
**Fix:** Implement model versioning with instant rollback capability. Use canary or shadow deployments for new versions. A/B test before full rollout. Feature flags for model version selection. Define rollback criteria and automate rollback triggers

### Log Nothing, Debug Everything
**Severity:** HIGH
**Symptom:** No request/response logging for LLM calls. No logging of model inputs, outputs, latency, or token usage. When something goes wrong, the only debugging tool is "try to reproduce it"
**Why it's harmful:** ML debugging requires seeing the inputs and outputs that led to the failure. Without logs, you can't diagnose wrong answers, can't identify patterns in failures, can't do post-hoc evaluation, and can't attribute costs
**Fix:** Log every LLM call: model, input (or hash), output, token counts, latency, cost estimate, request context. Implement structured logging with correlation IDs. Set appropriate retention. Ensure logs are queryable for debugging and evaluation

### The Single Point of Failure
**Severity:** CRITICAL
**Symptom:** One LLM provider, no fallback. One embedding model, no alternative. One vector database instance, no replica. When any single component fails, the entire AI feature is down
**Why it's harmful:** LLM API outages happen regularly (hours, not minutes). Vector database corruption happens. Embedding model endpoints go down. A single point of failure means your SLA is the minimum of all your dependencies' SLAs
**Fix:** Provider failover for LLM calls. Replica or fallback for vector database. Graceful degradation path when AI features are unavailable (show cached results, fall back to non-AI behavior, show "temporarily unavailable"). Define and test the degradation path

### GPU YOLO
**Severity:** HIGH
**Symptom:** Self-hosted inference with no resource limits. No request queuing. No batch management. No memory monitoring. One large request can exhaust GPU memory and crash the inference server
**Why it's harmful:** OOM kills affect all in-flight requests, not just the one that caused the issue. Without queuing, burst traffic overwhelms the GPU. Without monitoring, you don't know you're approaching limits until you hit them
**Fix:** Set max batch size and max sequence length. Implement request queuing with backpressure. Monitor GPU memory utilization and temperature. Set up alerts for resource thresholds. Implement graceful request rejection when at capacity

### The Versioning Void
**Severity:** HIGH
**Symptom:** No model versioning. No way to know which model version produced a given prediction. No mapping between model version and code version. Model artifacts stored in ad-hoc locations with informal naming
**Why it's harmful:** Can't reproduce past predictions. Can't rollback to a known-good version. Can't audit which model was responsible for a decision. Can't track quality trends across versions
**Fix:** Model registry with versioned artifacts and metadata. Every prediction tagged with model version. Version mapping: code commit -> training config -> data version -> model artifact -> deployed version. Automated lineage tracking

## Architecture Anti-Patterns

### Framework-Driven Design
**Severity:** MEDIUM
**Symptom:** Architecture shaped by the chosen framework (LangChain chains, CrewAI crews, etc.) rather than by the problem requirements. "We need agents" before defining what the agents should do. Technology choice precedes problem analysis
**Why it's harmful:** Over-engineering. Unnecessary complexity. The framework's abstractions become constraints rather than enablers. When the framework doesn't support a requirement, workarounds are uglier than building from scratch would have been
**Fix:** Define requirements first. Design the solution second. Choose tools third. Start with the simplest implementation (direct API call). Add framework abstractions only when you can name the specific problem they solve

### Premature Agent-ification
**Severity:** HIGH
**Symptom:** Building a multi-step agent system for a task that could be solved with a single well-crafted prompt and structured output. Agent loops for classification, extraction, or formatting tasks
**Why it's harmful:** 5-10x cost increase. 5-10x latency increase. Dramatically higher failure rate (errors compound across steps). More complex debugging. More code to maintain. All for zero benefit when a single call suffices
**Fix:** Start with a single API call. Measure quality. Only add agent steps when you can demonstrate that the single-call approach fails on specific, documented cases. Every agent step must justify its existence with a measurable quality improvement

### The Embedding Graveyard
**Severity:** MEDIUM
**Symptom:** Embeddings generated and stored in a vector database but never evaluated for retrieval quality. No metrics on whether the embeddings actually capture the relevant semantic similarities for the use case
**Why it's harmful:** Expensive infrastructure (vector database, embedding compute) that may not be working. Retrieval quality directly impacts RAG quality — bad embeddings mean bad retrieval means bad answers, and you won't know it without evaluation
**Fix:** Build an evaluation set of (query, expected_relevant_documents) pairs. Measure precision@k and recall@k. Compare against baselines (BM25, different embedding models). Iterate on chunk size, embedding model, and similarity thresholds based on metrics

### The Everything RAG
**Severity:** MEDIUM
**Symptom:** Using RAG for information that should be in the prompt (static, small, always needed), fine-tuned into the model (consistent style/behavior), or handled by a simple database lookup (structured, queryable data)
**Why it's harmful:** RAG adds latency (embedding + retrieval + augmented prompt), cost (embedding compute, vector database, larger prompts), and failure modes (bad retrieval, stale index, chunk boundary issues). These costs are justified only when the information is large, dynamic, and varied
**Fix:** Ask: Is this information static and small? Put it in the system prompt. Is this a structured lookup? Use a database query. Is this a consistent behavioral change? Consider fine-tuning. Is this a large, dynamic corpus that changes faster than you can fine-tune? RAG is appropriate

### Over-Abstraction
**Severity:** MEDIUM
**Symptom:** Seven layers of abstraction between the application code and the actual LLM API call. Generic interfaces, factory patterns, strategy patterns, middleware chains — all for a system that uses one model through one provider
**Why it's harmful:** When something goes wrong (and it will), debugging requires traversing seven layers to find the actual API call, the actual prompt, the actual response. Added abstraction slows iteration speed. YAGNI applies even more to ML systems, where rapid experimentation is essential
**Fix:** Build the abstraction you need today, not the one you might need in six months. One provider? One adapter, no factory. One model? Model name as config, no routing layer. Add abstraction when you add the second provider or the second model, not before
