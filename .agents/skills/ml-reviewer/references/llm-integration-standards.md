# LLM Integration Review Standards

Review standards for code that integrates with LLM APIs. This is the primary reference for the ml-reviewer skill — LLM integration is where the most money is burned, the most security holes hide, and the most silent failures occur.

## Table of Contents
1. [Prompt Engineering Quality](#prompt-engineering-quality)
2. [Error Handling and Resilience](#error-handling-and-resilience)
3. [Cost Management](#cost-management)
4. [Security](#security)
5. [Streaming and Concurrency](#streaming-and-concurrency)
6. [Structured Output and Parsing](#structured-output-and-parsing)
7. [RAG-Specific Standards](#rag-specific-standards)
8. [Agent-Specific Standards](#agent-specific-standards)

---

## Prompt Engineering Quality

### Clarity and structure
- **System vs. user message separation:** System instructions must be in the system message, not mixed into user content. If the framework doesn't support system messages, use clear structural delimiters (XML tags, markdown headers) — never rely on plain text like "You are a helpful assistant" buried in a paragraph
- **Instruction specificity:** Vague instructions ("be helpful", "format nicely") are review findings. Instructions must be precise enough that two different models would produce structurally similar outputs
- **Output format specification:** Every prompt that expects structured output must explicitly define the format. Prefer JSON schema definitions, XML templates, or concrete examples over prose descriptions
- **Delimiter hygiene:** If the prompt uses delimiters to separate sections (```xml```, `---`, etc.), verify that user input cannot contain those same delimiters and break the prompt structure

### Few-shot examples
- **Quality over quantity:** Each example must be correct, representative, and demonstrate the desired behavior including edge cases. One wrong example poisons the model's behavior more than five correct ones fix it
- **Diversity:** Examples should cover the range of expected inputs, not just the happy path. Include at least one edge case example
- **Token cost:** Each example consumes context. If examples exceed 30% of the available context window, flag for optimization — consider dynamic example selection based on input similarity
- **Ordering:** Examples should progress from simple to complex. The last example has the most influence on model behavior

### Token efficiency
- **System prompt bloat:** System prompts over 1000 tokens need justification. Every 100 tokens costs money on every single request. Review for redundancy, unnecessary verbosity, and instructions the model already follows by default
- **Context stuffing:** Flag any pattern where the full context is included when a summary, excerpt, or filtered subset would suffice. The "lost in the middle" effect means more context can actually reduce quality
- **Repeated instructions:** If the same instruction appears in both the system prompt and user message, flag it. Repetition wastes tokens and can confuse the model

### Versioning and configuration
- **Prompt version control:** Prompts must be versioned. If prompts are hardcoded strings in application code, flag as MEDIUM — they should be in separate files, config, or a prompt management system
- **Temperature and sampling params:** Must be explicitly set, not left to defaults. Must be appropriate for the task: near-zero for deterministic tasks (classification, extraction, structured output), higher for creative generation
- **Model parameter as config:** The model name/ID must be configurable, not hardcoded. Model names change, models get deprecated, and you need to switch models without code changes

## Error Handling and Resilience

### Rate limit handling
- **Exponential backoff with jitter:** Must be present. Linear retry or fixed-delay retry is a review finding
- **Retry-After header respect:** If the API returns a Retry-After header, the code must honor it, not ignore it and use its own backoff
- **Rate limiter on the client side:** Proactive rate limiting (token bucket, leaky bucket) prevents hitting provider limits in the first place. Flag if absent in high-throughput systems
- **Per-model and per-endpoint limits:** Different models and endpoints have different rate limits. A single global rate limiter is insufficient

### Timeout configuration
- **Connection timeout:** Must be set. Default "no timeout" is a blocking finding (CRITICAL) — a hung connection can block the entire request pipeline
- **Response timeout:** Separate from connection timeout. For non-streaming: 30-120s depending on model and task. For streaming: use per-chunk timeout, not total timeout
- **Deadline propagation:** If the caller has a deadline (HTTP request timeout, user-facing SLA), the LLM call must respect it. Don't start a 60s LLM call when you only have 10s left on the request deadline

### Content filter and refusal handling
- **Content filter responses are not errors to retry.** If the code retries on content filter (400/403 with content policy reason), that's a CRITICAL finding — it wastes money and will never succeed
- **Refusal detection:** The model may refuse a request in its response text without returning an error status code. Code that processes model output must handle refusal responses, not just HTTP errors
- **Graceful degradation:** What does the user see when the model refuses? If the answer is "an unhandled exception" or "a raw error dump," that's a HIGH finding

### Malformed output recovery
- **Parse failure handling:** Every JSON/structured output parse must have an error path. What happens when the model returns invalid JSON? Truncated output? An apology instead of data?
- **Retry with correction:** On parse failure, a retry with a correction prompt ("Your previous response was not valid JSON. Please respond with only valid JSON matching this schema: ...") is acceptable. Retry without modification is not — it will likely fail the same way
- **Fallback strategy:** After N retries, what happens? The answer cannot be "crash" or "return null." There must be a defined fallback: default value, error to user, queue for manual review

### Provider failover
- **Single provider is a CRITICAL finding** for any production system. LLM API outages are frequent and prolonged. There must be a fallback provider or a graceful degradation path
- **Circuit breaker pattern:** After N consecutive failures, stop calling the failing provider and switch to fallback. Don't keep hammering a dead API and accumulating timeouts
- **Provider abstraction:** The LLM client interface should be abstract enough to swap providers without changing application logic. If provider-specific code is scattered throughout the application, flag as HIGH

### Partial response handling (streaming)
- **Mid-stream disconnection:** What happens when the stream drops mid-response? Is the partial response discarded, saved, or surfaced to the user? Each can be valid depending on context, but it must be an explicit decision
- **Incomplete structured output:** If streaming structured output (JSON), a disconnection will produce invalid JSON. The code must handle this — not assume the stream always completes

## Cost Management

### Per-request cost estimation
- **Token counting:** The application should estimate or track token usage per request. If there's no token counting at all, flag as HIGH — you're flying blind on cost
- **Input vs. output token tracking:** Input and output tokens have different prices (often 3-5x difference). Track them separately
- **Cost logging:** Every LLM call should log: model, input tokens, output tokens, estimated cost, request context (feature, user, endpoint). Without this, cost attribution is impossible

### Cost at scale
- **Scale projection:** Has anyone calculated what this costs at 10x and 100x current traffic? If not, flag as MEDIUM. Cost surprises are a real production risk
- **Cost per user/feature:** Can costs be attributed to specific users or features? This is essential for identifying abuse, optimizing high-cost features, and business decisions about pricing

### Token budgeting
- **max_tokens setting:** Must be set explicitly and appropriately for the task. Default (often 4096 or model maximum) wastes money on tasks that need 200 tokens of output
- **Context window utilization:** If the code constructs prompts that routinely use less than 20% of the context window, consider whether a smaller, cheaper model would suffice
- **Dynamic context management:** For variable-length inputs (conversation history, document context), there must be a strategy for when input exceeds the budget: truncation, summarization, or sliding window. Not "hope it fits"

### Model selection
- **Right-sizing:** Using a large, expensive model for a simple task (classification, extraction, short generation) is a HIGH finding. Evaluate whether a smaller model (Haiku, GPT-4o-mini) produces acceptable quality
- **Task routing:** Systems that handle diverse tasks should route to different models based on task complexity. One model for everything is lazy and expensive
- **Batch API usage:** Non-real-time workloads (batch processing, overnight jobs, analytics) should use batch APIs where available — typically 50% cheaper

### Caching
- **Identical request caching:** For deterministic tasks (temperature=0, same input), responses should be cached. Flag if absent in any system making repeated similar requests
- **Cache invalidation:** How does the cache handle model changes, prompt changes, or stale data? A cache without invalidation strategy is a bug factory
- **Semantic caching caution:** Caching based on "similar enough" queries is risky. False cache hits return wrong answers. Only acceptable with thorough evaluation of similarity thresholds

## Security

### Prompt injection
- **Structural separation:** User input must be structurally separated from system instructions. Text-based separation ("User input below:") is insufficient — use the API's native system/user message roles, XML tags, or other structural mechanisms
- **Input sanitization:** User input that flows into prompts should be sanitized: strip or escape potential instruction-like patterns, enforce length limits, reject anomalous inputs
- **Output-as-input chains:** If model output from step N becomes input to step N+1 (agent loops, chains), injection can propagate. Each step must treat the previous step's output as untrusted
- **Indirect injection:** Data retrieved from external sources (RAG documents, web scraping, database records) can contain injected instructions. Retrieved content is untrusted input

### Output sanitization
- **HTML/script injection:** If model output is rendered in a web UI, it must be sanitized against XSS. Models can be tricked into producing malicious HTML/JavaScript
- **Command injection:** If model output is used to construct shell commands, SQL queries, or file paths, it must be parameterized/escaped. Never interpolate raw model output into executable strings
- **Structured output validation:** Even when using structured output modes, validate the output against the expected schema. Don't trust that field values are within expected ranges or that enums contain valid values

### API key management
- **Keys in code or config files:** CRITICAL finding. Keys must be in environment variables, secret managers (Vault, AWS Secrets Manager, GCP Secret Manager), or equivalent
- **Keys in logs:** Check that request/response logging doesn't include authorization headers. Log redaction must be explicit
- **Key rotation:** Is there a plan for rotating API keys? If a key is compromised, how quickly can it be replaced without downtime?
- **Key scoping:** Are API keys scoped to the minimum necessary permissions? A single god-key for all environments and all features is a risk

### PII in prompts
- **User data to LLM APIs:** Is personally identifiable information (names, emails, addresses, etc.) being sent to LLM APIs? Is this disclosed in the privacy policy? Is it compliant with GDPR/CCPA?
- **PII in logs:** If LLM request/response logs contain user PII, they must be treated as sensitive data with appropriate retention, access controls, and deletion capabilities
- **PII in training:** Are you using an API that may train on your data? Check the provider's data usage policy. Opt out of training if sending user data

### Tool use security
- **Tool action scope:** If the model can call tools, what can those tools do? Flag any tool that can write to a database, send a message, make a payment, or modify state — these must have explicit authorization checks, not just "the model decided to call it"
- **Tool input validation:** Tool inputs from the model must be validated with the same rigor as user input. The model can hallucinate invalid parameters, SQL injection payloads, or other malicious inputs
- **Confirmation gates:** Destructive or expensive tool actions should require human confirmation, not automatic execution

## Streaming and Concurrency

### Streaming implementation
- **User-facing responses must stream:** If the response goes to a human user and the framework supports streaming, not streaming is a HIGH finding. The TTFT improvement is significant for UX
- **Backpressure handling:** If the consumer is slower than the producer (e.g., database writes from streaming output), there must be buffering or backpressure. Unbounded buffers are a memory leak; dropped chunks are data loss

### Concurrency controls
- **Concurrent request limits:** There must be a semaphore, worker pool, or equivalent limiting concurrent LLM calls. Unbounded concurrency leads to rate limit avalanches and resource exhaustion
- **Context growth in conversations:** Multi-turn conversation history grows with each turn. There must be a strategy (sliding window, summarization, max turns) to prevent unbounded context growth that increases cost and eventually exceeds the context window
- **Cancellation propagation:** If a user cancels a request, does the underlying LLM API call get cancelled? Or does it continue consuming tokens (and money) in the background? Flag if cancellation doesn't propagate

## Structured Output and Parsing

### Tool use vs. raw JSON
- **Prefer tool use / function calling** over asking the model to output raw JSON in its response. Tool use is more reliable, provides type information to the model, and has better error handling in most SDKs
- **If raw JSON is used:** The prompt must include the exact schema, ideally with examples. "Return a JSON object" without schema specification is a finding

### Schema validation
- **Every parsed output must be validated** against the expected schema before use. Don't trust that fields exist, types are correct, or values are within range
- **Strict vs. lenient parsing:** Prefer strict parsing that rejects unexpected fields. Lenient parsing can silently swallow errors where the model returned a completely different structure that happens to partially match

### Error recovery
- **Retry budget:** Maximum 2-3 retries on parse failure. More than that indicates the prompt or schema needs fixing, not more retries
- **Correction prompts:** On retry, include the failed output and specific error ("Expected field 'score' to be a number between 0 and 1, got 'high'"). Don't just repeat the same request
- **Fallback values:** After exhausting retries, there must be a defined behavior. Acceptable: return error to user, use a safe default, queue for manual review. Not acceptable: return null, crash, return the raw unparsed text

### Edge cases
- **Empty responses:** What happens when the model returns an empty string? A response that's only whitespace? These happen and must be handled
- **Truncated output:** If the response hits max_tokens, the output may be truncated mid-JSON. The code must detect this (check stop_reason/finish_reason) and handle it — not try to parse truncated JSON
- **Unicode and encoding:** Model output can contain unexpected Unicode characters, including zero-width spaces, RTL markers, and emoji. Parsing and storage must handle this correctly

## RAG-Specific Standards

### Retrieval quality
- **Retrieval evaluation metrics:** If there are no metrics measuring retrieval quality (precision@k, recall@k, MRR, NDCG), that's a HIGH finding. You cannot improve what you don't measure
- **Retrieval vs. generation evaluation:** These must be measured separately. Good generation on bad retrieval means the model is hallucinating or got lucky. Bad generation on good retrieval means the prompt needs work
- **Baseline comparison:** Is retrieval compared against a baseline (BM25, random, previous version)? Without a baseline, you don't know if your vector search is actually helping

### Context quality
- **Relevance filtering:** Are retrieved chunks filtered for relevance before being included in the prompt? Low-relevance chunks add noise and cost. A similarity threshold or reranker should gate inclusion
- **Context ordering:** Retrieved chunks should be ordered by relevance. Due to the "lost in the middle" effect, the most relevant chunks should be at the beginning or end of the context, not buried in the middle
- **Deduplication:** If retrieval returns overlapping or duplicate chunks (common with overlapping chunk strategies), they should be deduplicated before inclusion

### Citation and attribution
- **Source tracking:** Can the system identify which retrieved chunk(s) contributed to each part of the generated response? Without this, you can't verify correctness or debug wrong answers
- **Citation accuracy:** If the system claims to cite sources, verify that citations actually correspond to retrieved content and not hallucinated references

### Index maintenance
- **Stale content:** How often is the index updated? What happens when source documents change? If the answer is "manual reindex," flag as MEDIUM — this should be automated
- **Embedding model changes:** If the embedding model is updated, all existing vectors become incompatible. There must be a reindexing plan. Mixing embeddings from different models in the same index is a CRITICAL finding
- **Index monitoring:** Track index size, query latency, and retrieval quality over time. Degradation often correlates with index growth or data drift

### Chunk boundaries
- **Chunk size vs. embedding model:** The chunk size should be appropriate for the embedding model's training window. Chunks significantly larger than the model's effective window produce diluted embeddings
- **Semantic coherence:** Chunks should not cut off mid-sentence or mid-thought. Overlap or semantic-aware chunking should be used
- **Metadata preservation:** Chunks should carry metadata (source document, section, page, timestamp) for filtering and attribution

## Agent-Specific Standards

### Loop bounds
- **Maximum steps:** Every agent loop must have a hard maximum step limit. Unbounded agent loops are a CRITICAL finding — they can run indefinitely, consuming tokens and money
- **Cost ceiling:** In addition to step limits, there should be a token/cost budget. If the agent has spent $X without completing the task, it should stop and report

### Cost explosion prevention
- **Per-step cost tracking:** Log the cost of each agent step. This enables detection of runaway loops and cost optimization
- **Context growth monitoring:** Agent context grows with each step (tool results, reasoning traces). Track context size per step and alert when it approaches the window limit
- **Tool call deduplication:** Detect and prevent the agent from calling the same tool with the same parameters repeatedly — a common failure mode

### Error accumulation
- **Error handling in tool results:** When a tool returns an error, the agent should attempt recovery, not blindly continue. After 2-3 consecutive tool errors, the agent should stop and report
- **Drift detection:** Agents can gradually drift off-task, especially in long loops. Review for mechanisms to detect and correct drift (periodic goal restatement, relevance checks)
- **Partial progress preservation:** If an agent fails mid-task, can the completed work be salvaged? Or is it all-or-nothing?

### Tool security scoping
- **Principle of least privilege:** Each tool should have the minimum permissions needed. An agent that can read files should not automatically be able to write them
- **Destructive action gates:** Tools that modify state (write, delete, send) should require explicit confirmation or be gated behind an approval mechanism
- **Scope boundaries:** The agent's tool access should be scoped to the relevant domain. An agent helping with code should not have access to email-sending tools

### Observability
- **Step-level logging:** Every agent step must be logged: the reasoning, the tool call, the tool result, and the decision to continue or stop. Without this, debugging agent failures is impossible
- **Trace visualization:** For complex multi-step agents, there should be a way to visualize the execution trace — not just raw logs
- **Performance metrics:** Track: steps per task, tokens per task, cost per task, success rate, common failure modes
