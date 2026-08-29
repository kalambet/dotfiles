# AI Tooling Landscape Reference

Opinionated guide to the AI infrastructure ecosystem. This reference covers the major categories of tools, when to use them, and common pitfalls. The landscape changes fast — focus on understanding the categories and selection criteria rather than memorizing specific tools.

## Table of Contents
1. [Orchestration Frameworks](#orchestration-frameworks)
2. [Vector Databases](#vector-databases)
3. [Model Serving and Inference](#model-serving-and-inference)
4. [Evaluation and Testing](#evaluation-and-testing)
5. [Observability and Monitoring](#observability-and-monitoring)
6. [Fine-Tuning and Training](#fine-tuning-and-training)
7. [Agent Frameworks](#agent-frameworks)
8. [RAG Infrastructure](#rag-infrastructure)
9. [Architecture Decision Patterns](#architecture-decision-patterns)

---

## Orchestration Frameworks

These frameworks provide abstractions for building LLM-powered applications. The key question is whether the abstraction helps or hurts for your use case.

### The major players
- **LangChain / LangGraph:** The most widely adopted. LangChain provides chains, agents, retrieval, memory. LangGraph adds stateful, graph-based workflows. Mature ecosystem with many integrations. Criticism: over-abstraction, implicit behavior, debugging difficulty. Use when you need rapid prototyping, many integrations, or you value ecosystem breadth. Avoid when you need fine-grained control or your use case is simple enough for direct API calls
- **LlamaIndex:** Focused on data ingestion and retrieval (RAG). Strongest when your core problem is "get the right context to the model." Has agents and workflows too, but RAG is where it shines. Better than LangChain for complex document processing pipelines
- **Semantic Kernel (Microsoft):** Enterprise-oriented. Good .NET/Java support. Plugin-based architecture. Use if you're in the Microsoft ecosystem
- **Haystack (deepset):** Pipeline-based, modular. Good for production RAG systems. Less hype, more engineering-focused
- **Pydantic AI:** Lightweight, type-safe. Thin wrapper around LLM APIs with structured output. Good when you want structure without heavyweight frameworks
- **Instructor:** Even thinner — just structured output extraction from LLMs using Pydantic models. Often all you need

### When to skip the framework
Direct API calls + your own thin wrapper is often the right choice when:
- You're building a single feature, not a platform
- Your pipeline is linear (no complex branching or state management)
- You want full control over retry logic, caching, and error handling
- Your team is comfortable with the LLM APIs directly
- Debugging and observability are critical (framework abstractions can obscure issues)

## Vector Databases

### Purpose-built vector databases
- **Pinecone:** Fully managed, serverless option available. Simple API, good performance. No self-hosting option. Use when you want zero operational overhead and can tolerate vendor lock-in
- **Weaviate:** Open-source, written in Go. Hybrid search (vector + BM25) built-in. Good for complex retrieval pipelines. Self-host or cloud. Mature and well-documented
- **Qdrant:** Open-source, written in Rust. Fast, feature-rich (filtering, payloads, sparse vectors). Excellent performance. Self-host or cloud. Strong choice for production
- **Milvus/Zilliz:** Open-source, designed for massive scale. GPU-accelerated. More complex to operate but handles billions of vectors. Use when scale is a primary concern
- **Chroma:** Open-source, designed for simplicity. Good for prototyping and small-to-medium scale. Python-native. Less mature for production at scale

### Vector-capable existing databases
- **pgvector (PostgreSQL):** Vector similarity search as a Postgres extension. If you already use Postgres, this avoids adding a new database to your stack. Performance is good up to ~1M vectors with proper indexing (HNSW). The pragmatic choice for most applications
- **Redis (vector search):** Vector search module in Redis Stack. Good if Redis is already in your architecture
- **Elasticsearch/OpenSearch:** Dense vector search alongside traditional search. Good for hybrid use cases where you need both full-text and vector search on the same data
- **SQLite + sqlite-vec:** Embedded vector search. Perfect for mobile apps, CLI tools, or single-binary deployments

### Selection criteria
1. **Scale:** <100K vectors → pgvector or SQLite. 100K-10M → any purpose-built or pgvector with HNSW. >10M → Qdrant, Weaviate, Milvus
2. **Operational complexity:** Want managed → Pinecone. Want self-hosted → Qdrant or Weaviate. Already have Postgres → pgvector
3. **Hybrid search:** Need BM25 + vector → Weaviate, Elasticsearch, or build it yourself with separate indices
4. **Filtering:** Need complex metadata filtering alongside vector search → Qdrant, Weaviate (purpose-built for this)

## Model Serving and Inference

### Local inference engines
- **llama.cpp:** The foundational local inference engine. C/C++, GGUF format, runs on CPU, Metal, CUDA, Vulkan. The most hardware-compatible option. Use directly or through higher-level tools
- **Ollama:** Wraps llama.cpp in a user-friendly service with model management. REST API, automatic model downloads. The easiest path to local inference. Good for development, prototyping, and personal use
- **vLLM:** High-throughput inference engine. PagedAttention, continuous batching, tensor parallelism. The standard for production GPU serving. Python-based
- **TGI (Text Generation Inference, Hugging Face):** Production inference server. Good integration with HF ecosystem. Supports many model architectures
- **SGLang:** High-performance serving with advanced features like RadixAttention for prefix caching. Competitive with vLLM on throughput
- **MLX (Apple):** Apple Silicon-native. Best performance on Macs. Python and Swift APIs. Growing model support

### Cloud inference APIs
- **Anthropic API:** Claude models. Strong at reasoning, coding, analysis, long context. Tool use support. Batch API for non-real-time workloads at 50% discount
- **OpenAI API:** GPT-4o, o1/o3 reasoning models. Largest ecosystem. Assistants API for stateful conversations
- **Google Vertex AI / Gemini:** Gemini models. Long context (up to 2M tokens). Good multimodal support. Grounding with Google Search
- **Amazon Bedrock:** Multi-model access (Claude, Llama, Mistral, etc.) through AWS. Good for enterprises already on AWS
- **Groq, Together, Fireworks, etc.:** Inference-as-a-service providers. Often cheaper for open-source models. Groq notable for extreme speed (custom LPU hardware)
- **OpenRouter:** API aggregator — single API, many models. Useful for model comparison and fallback routing

### Selection criteria
**Latency priority:** Groq (fastest raw speed) or local inference (no network roundtrip)
**Throughput priority:** vLLM or SGLang (self-hosted), or batch APIs (cloud)
**Quality priority:** Claude Opus/Sonnet, GPT-4o, Gemini Pro — evaluate on your specific task
**Cost priority:** Open-source models on your own hardware, or batch APIs for async workloads
**Privacy priority:** Local inference or private cloud deployment

## Evaluation and Testing

This is the most underinvested area in most AI projects, and the one that matters most for production quality.

### Evaluation frameworks
- **Evals (OpenAI):** Open-source eval framework. Supports custom evaluators, multi-turn conversations, model-graded evals. Good foundation
- **RAGAS:** Specifically for RAG evaluation. Measures faithfulness, relevance, context precision/recall. Essential if you're building RAG
- **DeepEval:** Python framework for LLM evaluation. Supports many metrics, integrates with CI/CD
- **promptfoo:** Open-source tool for prompt testing and evaluation. Supports multiple providers, assertions, red-teaming. Good for prompt engineering workflows
- **Braintrust:** Platform for AI evaluation, logging, and prompt management. Strong UI for reviewing outputs
- **LangSmith (LangChain):** Tracing, evaluation, and monitoring for LangChain apps. Good if you're already using LangChain

### Evaluation strategy
Build evaluation into your development workflow from day one:

1. **Define metrics before building.** What does "good" mean for your use case? Accuracy? Completeness? Conciseness? Safety?
2. **Start with a small eval set (20-50 examples).** Manually curated, covering key scenarios and edge cases
3. **Automate evaluation runs.** Run evals on every prompt change, model upgrade, or significant code change
4. **Use LLM-as-judge for subjective quality**, but validate the judge against human ratings first
5. **Track metrics over time.** Regressions happen silently without continuous monitoring
6. **Expand the eval set continuously.** Every production failure is a new test case

### Red-teaming and safety
- **Prompt injection testing:** Test with known injection patterns (ignore previous instructions, role-play attacks, encoding tricks)
- **Boundary testing:** What happens at context window limits? With adversarial inputs? With empty inputs?
- **Bias and fairness:** Test with diverse demographic inputs. Check for differential treatment
- **Content safety:** Verify content filters catch harmful outputs. Test edge cases where the model might produce inappropriate content

## Observability and Monitoring

### Tracing and logging
- **LangSmith:** Tracing for LangChain/LangGraph apps. Good visualization of chain execution
- **Langfuse:** Open-source LLM observability. Tracing, evaluation, prompt management. Self-hostable. Strong community
- **Arize Phoenix:** Open-source observability for LLM apps. Tracing, evaluation, embedding visualization
- **OpenTelemetry + custom spans:** If you already have OTel infrastructure, add custom spans for LLM calls. Works with any observability backend (Datadog, Grafana, etc.)
- **Helicone:** Proxy-based logging. Sits between your app and the LLM API, logs everything. Minimal integration effort

### What to monitor in production
- **Latency:** TTFT (time to first token), total generation time, p50/p95/p99
- **Cost:** Per-request, per-user, per-feature. Track input vs. output tokens separately
- **Quality:** Sample outputs regularly for human review. Automate what you can with eval metrics
- **Errors:** Rate limit hits, content filter triggers, malformed outputs, timeouts
- **Usage patterns:** Token usage distribution, peak hours, feature adoption

## Fine-Tuning and Training

### When to fine-tune
Fine-tuning is often over-prescribed. Consider it only when:
- Prompting (including few-shot) doesn't achieve required quality
- You have a specific, well-defined task with consistent format
- You have high-quality training data (hundreds to thousands of examples)
- Cost per request matters and a fine-tuned smaller model could replace a larger one
- You need specific style, tone, or domain knowledge that's hard to prompt

### Fine-tuning approaches
- **Full fine-tuning:** Update all parameters. Best quality but requires significant compute. Rarely needed for most applications
- **LoRA / QLoRA:** Update small adapter layers, keep base model frozen. 10-100x less compute. The standard approach for most fine-tuning tasks. QLoRA adds quantization for even less memory
- **Prefix tuning / P-tuning:** Prepend learnable tokens. Lightweight but less flexible than LoRA
- **RLHF / DPO / ORPO:** Alignment techniques. DPO (Direct Preference Optimization) is simpler than RLHF and often works as well. Use when you have preference data (chosen vs. rejected responses)

### Fine-tuning tools
- **Hugging Face TRL:** Standard library for fine-tuning with LoRA, DPO, RLHF. Python
- **Axolotl:** Configuration-driven fine-tuning. Abstracts away much of the complexity. Good for getting started
- **Unsloth:** Optimized fine-tuning — 2-5x faster than standard implementations with lower memory usage
- **MLX fine-tuning:** Fine-tune on Apple Silicon using MLX. Growing support for LoRA
- **Provider fine-tuning APIs:** OpenAI, Anthropic, Google all offer fine-tuning through their APIs. Easiest path but less control

### Data quality matters more than quantity
100 high-quality, carefully curated examples often outperform 10,000 noisy ones. Invest in data quality:
- Remove duplicates and near-duplicates
- Verify accuracy of all examples
- Ensure consistent formatting and style
- Include diverse scenarios and edge cases
- Balance the dataset across categories/intents

## Agent Frameworks

### Current landscape
- **Claude tool use / OpenAI function calling:** Native agent capabilities in the APIs. Often sufficient without a framework. Start here
- **CrewAI:** Multi-agent framework. Define agents with roles, goals, and tools. Good for complex workflows where different "personas" handle different aspects. Can be over-engineered for simple tasks
- **AutoGen (Microsoft):** Multi-agent conversation framework. Agents communicate via messages. Good for research and experimentation
- **Claude Code agent SDK:** Anthropic's SDK for building agent applications. Integrates with Claude Code's infrastructure. Good for terminal/developer-focused agents
- **Smolagents (Hugging Face):** Lightweight agent framework. Code-based agents that write and execute Python. Simple and effective
- **Mastra:** TypeScript agent framework. Good if your stack is TypeScript
- **LangGraph:** Stateful agent workflows as graphs. The most mature option for complex, multi-step agent logic with branching and cycles. Worth the learning curve for complex agents

### Agent architecture patterns
- **ReAct (Reasoning + Acting):** Think → Act → Observe → Repeat. The basic agent loop. Most frameworks implement this
- **Plan-and-execute:** Generate a plan first, then execute steps. Better for complex, multi-step tasks. Easier to debug and correct
- **Multi-agent:** Specialized agents collaborate. Use when tasks naturally decompose into different expertise areas. Be wary of coordination overhead
- **Reflexion:** Agent critiques its own output and iterates. Improves quality at the cost of more LLM calls

### Agent pitfalls
- **Cost explosion:** Each tool call and reasoning step costs tokens. An agent loop that runs 10 steps with a large context can cost 10-50x a single API call
- **Error accumulation:** Each step can introduce errors. By step 10, the agent may be far off track. Use shorter loops with human checkpoints
- **Infinite loops:** Always set a max_steps limit. Agents can get stuck in unproductive cycles
- **Over-engineering:** Most tasks don't need agents. If a single prompt with structured output works, use that

## RAG Infrastructure

### The RAG pipeline
```
Query → Embed → Retrieve → (Rerank) → Augment prompt → Generate → (Cite)
```

### Chunking services
- **Unstructured.io:** Document parsing and chunking. Handles PDFs, images, tables. The most comprehensive document processing tool
- **LlamaParse:** From LlamaIndex. PDF and document parsing optimized for LLM consumption
- **Docling (IBM):** Document conversion to markdown/JSON. Good for complex documents

### Reranking
Reranking is one of the highest-ROI improvements for RAG quality:
- **Cohere Rerank:** API-based reranking. High quality, easy to integrate
- **Cross-encoder models:** Run locally via sentence-transformers. More control but requires GPU for reasonable latency
- **ColBERT / ColPali:** Late-interaction models. Good quality-latency tradeoff
- **LLM reranking:** Use a small, fast LLM to score relevance. Flexible but slower

### Advanced RAG patterns
- **Parent-child chunking:** Small chunks for retrieval precision, retrieve the parent (larger) chunk for context
- **Multi-index:** Separate indices for different content types (code, docs, conversations)
- **Agentic RAG:** The retrieval step itself is an agent loop — query, retrieve, evaluate, refine query, retrieve again
- **Graph RAG:** Build a knowledge graph from documents, use graph traversal alongside vector search for more structured retrieval

## Architecture Decision Patterns

### Complexity ladder
Start at the simplest level that works. Only climb when you can name the specific limitation:

1. **Direct prompting:** Single API call with a well-crafted prompt. Covers 60%+ of use cases
2. **Structured output:** Same, but with typed output (tool use / function calling). Adds reliability
3. **RAG:** Add retrieved context to the prompt. Use when the model needs information it doesn't have
4. **Fine-tuning:** Customize the model itself. Use when prompting can't achieve the quality/cost target
5. **Agents:** Multi-step, tool-using workflows. Use when the task genuinely requires dynamic decision-making
6. **Multi-agent:** Multiple specialized agents. Use when tasks naturally decompose and benefit from parallel expertise

### Cost estimation framework
For any AI feature, estimate before building:
- Average tokens per request (input + output)
- Expected requests per day/month
- Model pricing (check current rates)
- Infrastructure costs (vector DB, GPU serving, etc.)
- Multiply by 3x for safety margin (usage often exceeds projections)

### Build vs. buy
- **Build** your core AI logic (prompts, evaluation, orchestration for your specific use case)
- **Buy/use** infrastructure (model APIs, vector databases, observability tools)
- **Be cautious** with thick orchestration frameworks — they speed up prototyping but can slow down production iteration
