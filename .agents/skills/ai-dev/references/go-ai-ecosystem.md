# Go AI Ecosystem Reference

Comprehensive reference for building AI-powered applications in Go. The Go AI ecosystem is maturing rapidly — there are solid native options for most common tasks, and wrapping Python is rarely necessary.

## Table of Contents
1. [LLM API Clients](#llm-api-clients)
2. [Embedding and Vector Operations](#embedding-and-vector-operations)
3. [RAG Patterns in Go](#rag-patterns-in-go)
4. [Agent Frameworks](#agent-frameworks)
5. [Local Inference](#local-inference)
6. [Structured Output and Parsing](#structured-output-and-parsing)
7. [Testing and Evaluation](#testing-and-evaluation)
8. [Production Patterns](#production-patterns)

---

## LLM API Clients

### Official SDKs
- **Anthropic:** `github.com/anthropics/anthropic-sdk-go` — Official Go SDK. Supports messages API, streaming, tool use, vision. Idiomatic Go with strong typing
- **OpenAI:** `github.com/openai/openai-go` — Official Go SDK. Covers chat completions, embeddings, images, audio, assistants
- **Google (Gemini/Vertex):** `cloud.google.com/go/vertexai` and `github.com/google/generative-ai-go` — Official clients for Vertex AI and Gemini API

### Multi-provider abstractions
- **LangChainGo:** `github.com/tmc/langchaingo` — Go port of LangChain concepts. Provides a unified interface across providers (OpenAI, Anthropic, Ollama, etc.), plus chains, agents, memory, and document loaders. The most mature Go orchestration library, though it inherits some of LangChain's abstraction-heaviness. Use it when you need multi-provider switching or its RAG pipeline components; skip it when direct SDK calls suffice
- **Genkit (Go):** `github.com/firebase/genkit/go` — Google's AI framework for Go. Model-agnostic with plugin system, built-in flows (stateful pipelines), dotprompt templating, and observability. Worth evaluating if you're in the Google Cloud ecosystem

### Streaming patterns in Go
Go's concurrency model is excellent for streaming LLM responses. Prefer channel-based or `io.Reader`-style streaming:

```go
// Channel-based streaming pattern
func StreamCompletion(ctx context.Context, prompt string) (<-chan string, <-chan error) {
    chunks := make(chan string, 32)  // buffer to avoid backpressure
    errs := make(chan error, 1)
    go func() {
        defer close(chunks)
        defer close(errs)
        // ... call API with streaming, send chunks
    }()
    return chunks, errs
}
```

For SSE (Server-Sent Events) from APIs, use `bufio.Scanner` with a custom split function or a library like `github.com/r3labs/sse/v2`.

### Error handling for LLM APIs
LLM APIs have unique failure modes. Build retry logic that handles:
- **Rate limits (429):** Exponential backoff with jitter. Respect Retry-After header. Consider a token bucket or leaky bucket rate limiter (`golang.org/x/time/rate`)
- **Context length exceeded (400):** Truncate input or switch to a larger-context model. Don't retry the same request
- **Content filter (400/403):** Log and surface to user. Don't retry
- **Server errors (500/502/503):** Retry with backoff. These are transient
- **Timeout:** Set reasonable timeouts (30-120s for non-streaming). For streaming, use a per-chunk timeout rather than a total timeout

## Embedding and Vector Operations

### Generating embeddings
Use the provider SDKs directly for embedding generation. For batch embedding, parallelize with worker pools:

```go
// Worker pool for batch embedding
func EmbedBatch(ctx context.Context, client *openai.Client, texts []string, concurrency int) ([][]float32, error) {
    results := make([][]float32, len(texts))
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(concurrency)
    for i, text := range texts {
        i, text := i, text
        g.Go(func() error {
            resp, err := client.Embeddings.New(ctx, openai.EmbeddingNewParams{
                Model: openai.EmbeddingModelTextEmbedding3Small,
                Input: openai.EmbeddingNewParamsInputUnion{OfArrayOfStrings: []string{text}},
            })
            if err != nil { return err }
            results[i] = resp.Data[0].Embedding
            return nil
        })
    }
    return results, g.Wait()
}
```

### Vector similarity in Go
For in-process similarity search (up to ~100K vectors), pure Go is fast enough:

```go
func CosineSimilarity(a, b []float32) float32 {
    var dot, normA, normB float32
    for i := range a {
        dot += a[i] * b[i]
        normA += a[i] * a[i]
        normB += b[i] * b[i]
    }
    return dot / (float32(math.Sqrt(float64(normA))) * float32(math.Sqrt(float64(normB))))
}
```

For larger scale, use SIMD-optimized libraries or delegate to a vector database.

### Vector database clients in Go
- **Weaviate:** `github.com/weaviate/weaviate-go-client` — Native Go client, Weaviate itself is written in Go
- **Qdrant:** `github.com/qdrant/go-client` — gRPC-based client
- **Milvus:** `github.com/milvus-io/milvus-sdk-go` — Official Go SDK
- **pgvector:** Use any PostgreSQL driver (`pgx`, `lib/pq`) with the pgvector extension. Often the simplest choice if you already use Postgres
- **ChromaDB:** Community Go clients exist but are less mature. Consider Qdrant or pgvector instead for Go-native projects
- **SQLite + vector extensions:** `github.com/asg017/sqlite-vec` via CGo. Good for embedded/single-binary deployments

## RAG Patterns in Go

### Document ingestion pipeline
```
Files → Loader → Chunker → Embedder → Vector Store
```

**Loaders:** LangChainGo has loaders for PDF, HTML, CSV, markdown. For PDFs, `github.com/ledongthuc/pdf` or shell out to `pdftotext`. For web content, `github.com/nicholasgasior/gocolly` or `net/html` from the standard library.

**Chunking strategies:**
- **Fixed-size with overlap:** Simple and effective for most text. 512-1024 tokens with 10-20% overlap
- **Semantic chunking:** Split on paragraph/section boundaries, then merge small chunks and split large ones. Better preserves meaning but more complex
- **Recursive character splitter:** LangChainGo's default. Tries to split on paragraphs, then sentences, then words

**Retrieval patterns:**
- **Simple top-k:** Embed query, find k nearest vectors. Works for straightforward questions
- **Hybrid search:** Combine vector similarity with BM25 keyword search. Weaviate and Qdrant support this natively
- **Reranking:** Retrieve a broad set (top-20), then rerank with a cross-encoder or a small LLM call. Significantly improves precision
- **HyDE (Hypothetical Document Embeddings):** Generate a hypothetical answer first, embed that, then search. Helpful when query embeddings don't align well with document embeddings

## Agent Frameworks

### Native Go options
- **LangChainGo agents:** Supports ReAct-style agents with tool binding. Functional but less mature than Python LangChain
- **Custom agent loops:** Go's simplicity makes it practical to write your own agent loop. A basic ReAct agent is ~200 lines:

```go
type Tool struct {
    Name        string
    Description string
    Execute     func(ctx context.Context, input string) (string, error)
}

type Agent struct {
    Client   *anthropic.Client
    Tools    []Tool
    MaxSteps int
}

func (a *Agent) Run(ctx context.Context, task string) (string, error) {
    messages := []anthropic.MessageParam{
        anthropic.NewUserMessage(anthropic.NewTextBlock(task)),
    }
    for step := 0; step < a.MaxSteps; step++ {
        resp, err := a.Client.Messages.New(ctx, anthropic.MessageNewParams{
            Model:    anthropic.ModelClaude4Sonnet20250514,
            Messages: messages,
            Tools:    a.toolDefinitions(),
        })
        if err != nil { return "", err }
        if resp.StopReason == anthropic.MessageStopReasonEndTurn {
            return extractText(resp), nil
        }
        // Process tool calls, execute tools, append results
        messages = append(messages, processToolCalls(resp, a.Tools)...)
    }
    return "", fmt.Errorf("agent exceeded max steps")
}
```

### Tool design principles
- Tools should have clear, specific descriptions. The model uses the description to decide when to call it
- Return structured data (JSON) from tools, not prose
- Include error information in tool results — the model can often recover from errors if it understands what went wrong
- Implement timeouts on all tool executions. A hung tool blocks the entire agent loop
- Log every tool call and result for debugging and evaluation

## Local Inference

### Go bindings for local models
- **llama.cpp via CGo:** `github.com/ggerganov/llama.cpp/examples/server` — Run the server and call its HTTP API from Go. This is more reliable than CGo bindings
- **Ollama API:** `github.com/ollama/ollama/api` — Ollama manages model downloads and serving. Clean REST API, easy to call from Go. The simplest path to local inference
- **ONNX Runtime:** `github.com/yalue/onnxruntime_go` — Run ONNX models directly in Go. Good for embedding models and small classifiers

### When to use local vs. API
**Use local inference when:**
- Privacy/data sovereignty is required
- Latency is critical (LAN roundtrip < API roundtrip)
- You're doing high-volume, simple tasks (classification, extraction) where a small model suffices
- You need offline capability

**Use API when:**
- You need frontier model quality
- You don't want to manage GPU infrastructure
- Usage is bursty (pay per token beats idle GPU costs)
- You need the latest models immediately

## Structured Output and Parsing

### JSON output from LLMs
Anthropic and OpenAI support structured tool-use responses. Prefer tool use over asking the model to output raw JSON — it's more reliable and typed.

For parsing free-form LLM output in Go:
```go
// Extract JSON from a response that might contain surrounding text
func ExtractJSON[T any](response string) (T, error) {
    var result T
    // Find JSON boundaries
    start := strings.Index(response, "{")
    end := strings.LastIndex(response, "}") + 1
    if start == -1 || end == 0 {
        return result, fmt.Errorf("no JSON found in response")
    }
    err := json.Unmarshal([]byte(response[start:end]), &result)
    return result, err
}
```

### Schema validation
Use `github.com/santhosh-tekuri/jsonschema/v5` to validate LLM outputs against JSON Schema. Define your expected output schema and validate before processing — don't trust that the model's output is well-formed even with structured output modes.

## Testing and Evaluation

### Testing LLM-integrated code
LLM outputs are non-deterministic. Testing strategies:

- **Unit tests with mocked LLM:** Define interfaces for your LLM client, use mocks for unit tests. Test your parsing, error handling, and orchestration logic without hitting the API
- **Snapshot/golden file tests:** Capture expected outputs at temperature=0, assert future runs match. Useful for prompt regression testing, but brittle if the model or API version changes
- **Property-based tests:** Assert properties of the output rather than exact content. "Response contains valid JSON", "Response mentions all required fields", "Response is under 500 tokens"
- **Evaluation sets:** Build a dataset of (input, expected_output) pairs. Run periodically and track metrics over time. This is the most important testing pattern for production AI features

### Evaluation metrics
- **Exact match:** For structured outputs, classification
- **Contains/regex:** For checking presence of key information
- **LLM-as-judge:** Use a separate LLM call to evaluate quality. More flexible but adds cost and its own failure modes
- **Human evaluation:** The gold standard. Build a simple review UI and sample regularly

## Production Patterns

### Circuit breaking and fallback
```go
type LLMCircuitBreaker struct {
    failures    atomic.Int32
    threshold   int32
    resetAfter  time.Duration
    lastFailure atomic.Int64
    fallback    func(ctx context.Context, prompt string) (string, error)
}
```

When the primary model/provider is down, fall back to a secondary. Common patterns: Claude → OpenAI, large model → small model, API → local model.

### Caching
Cache identical requests to avoid redundant API calls:
- **Exact match cache:** Hash the full request (model + messages + parameters). Use Redis or in-memory LRU. Effective for deterministic tasks (temp=0) with repeated inputs
- **Semantic cache:** Embed the query, check if a similar query was recently answered. Higher hit rate but adds complexity and potential for stale/wrong cache hits. Use cautiously

### Observability
- Log every LLM request/response with: model, tokens (input/output), latency, cost estimate, request ID
- Track per-endpoint cost and latency distributions
- Alert on: error rate spikes, latency p99 increases, cost anomalies, content filter rate increases
- Consider structured logging with `log/slog` and exporting to your observability stack

### Cost estimation
```go
func EstimateCost(model string, inputTokens, outputTokens int) float64 {
    // Maintain a pricing table — update when providers change prices
    prices := map[string][2]float64{
        "claude-sonnet-4-5-20250514":   {3.0 / 1e6, 15.0 / 1e6},
        "claude-haiku-4-5-20250414":    {0.80 / 1e6, 4.0 / 1e6},
        "gpt-4o":                       {2.50 / 1e6, 10.0 / 1e6},
        "gpt-4o-mini":                  {0.15 / 1e6, 0.60 / 1e6},
    }
    if p, ok := prices[model]; ok {
        return float64(inputTokens)*p[0] + float64(outputTokens)*p[1]
    }
    return 0
}
```

**Warning:** Pricing changes frequently. Maintain this as configuration, not hardcoded constants. The numbers above are examples and may be outdated.
