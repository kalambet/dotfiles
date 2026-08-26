# Swift AI Ecosystem Reference

Comprehensive reference for building AI-powered applications in Swift, with emphasis on Apple platform integration and on-device inference. Swift's position in the AI ecosystem is unique: it's the native language for the platform with the most consumer AI hardware (Apple Neural Engine + GPU in every iPhone, iPad, and Mac).

## Table of Contents
1. [On-Device Inference](#on-device-inference)
2. [LLM API Clients](#llm-api-clients)
3. [Apple Intelligence and Foundation Models](#apple-intelligence-and-foundation-models)
4. [MLX for Swift](#mlx-for-swift)
5. [CoreML Integration](#coreml-integration)
6. [Embedding and Vector Operations](#embedding-and-vector-operations)
7. [SwiftUI + AI Patterns](#swiftui--ai-patterns)
8. [Production Patterns](#production-patterns)

---

## On-Device Inference

The Apple ecosystem provides the best consumer hardware for on-device AI inference. Key hardware:

- **Neural Engine (ANE):** Dedicated ML accelerator in Apple Silicon. 15.8 TOPS (M1) to 38 TOPS (M4). Optimized for CoreML models. Extremely power-efficient but limited to specific operation types
- **GPU:** Metal-based GPU compute. More flexible than ANE, handles arbitrary operations. M-series unified memory means no CPU↔GPU copy overhead
- **Unified Memory Architecture:** Apple Silicon shares memory between CPU, GPU, and ANE. A Mac with 128GB RAM can load models that would require multiple GPUs on conventional hardware. This is why Macs are popular for local LLM inference despite not having discrete GPUs

### Memory considerations
- 7B model (Q4): ~4-5 GB — runs on any Apple Silicon Mac, iPhone 15 Pro+
- 13B model (Q4): ~8-9 GB — needs 16GB+ Mac
- 70B model (Q4): ~35-40 GB — needs 64GB+ Mac (M2/M3/M4 Pro/Max/Ultra)
- Leave 4-8 GB headroom for OS and other apps

## LLM API Clients

### Official and community SDKs
- **Anthropic:** No official Swift SDK currently. Use the REST API directly with URLSession or a community wrapper. The API is straightforward — build a thin client:

```swift
actor AnthropicClient {
    private let apiKey: String
    private let session = URLSession.shared
    private let baseURL = URL(string: "https://api.anthropic.com/v1")!

    func createMessage(_ params: MessageParams) async throws -> MessageResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(params)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError(response: response, data: data)
        }
        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }
}
```

- **OpenAI:** `github.com/MacPaw/OpenAI` — Community Swift SDK, well-maintained. Supports chat completions, streaming, function calling, vision
- **Google Gemini:** `github.com/google-gemini/generative-ai-swift` — Official Swift SDK

### Streaming with AsyncSequence
Swift's async/await and AsyncSequence are ideal for streaming LLM responses:

```swift
func streamMessage(_ params: MessageParams) -> AsyncThrowingStream<StreamEvent, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let (bytes, _) = try await session.bytes(for: buildRequest(params))
                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let json = String(line.dropFirst(6))
                    if json == "[DONE]" { break }
                    if let event = try? JSONDecoder().decode(StreamEvent.self,
                                                             from: json.data(using: .utf8)!) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```

## Apple Intelligence and Foundation Models

Starting with iOS 18.4 / macOS 15.4, Apple provides the Foundation Models framework for on-device LLM inference using Apple's own models.

### Key characteristics
- Runs entirely on-device using Apple Silicon (ANE + GPU)
- No API key, no network required after initial setup
- Optimized for Apple's hardware — lower latency than any cloud API for supported tasks
- Supports structured output via `@Generable` macro
- Guided generation constrains output to match Swift types
- Context window and capabilities are limited compared to frontier cloud models — best suited for on-device tasks like summarization, classification, extraction, and simple generation

### Usage pattern
```swift
import FoundationModels

let session = LanguageModelSession()

// Simple text generation
let response = try await session.respond(to: "Summarize this email: ...")

// Structured output with @Generable
@Generable
struct SentimentResult {
    @Guide(description: "Sentiment: positive, negative, or neutral")
    var sentiment: String
    @Guide(description: "Confidence from 0.0 to 1.0")
    var confidence: Float
}

let result: SentimentResult = try await session.respond(
    to: "Analyze sentiment: 'The product quality is excellent'",
    generating: SentimentResult.self
)
```

### When to use Apple Foundation Models vs. cloud APIs
**Use on-device when:**
- Privacy is critical (data never leaves device)
- Offline capability is required
- Latency sensitivity (no network roundtrip)
- High volume, simple tasks (classification, extraction, short generation)
- Cost sensitivity (no per-token charges)

**Use cloud APIs when:**
- You need frontier-model reasoning quality
- Long or complex generation is required
- Tasks require large context windows
- You need tool use, vision, or capabilities the on-device model doesn't support

### Hybrid pattern
The strongest approach for most apps: use on-device models for real-time, lightweight tasks (autocomplete, classification, quick extraction) and cloud APIs for heavy lifting (complex analysis, long-form generation, multi-step reasoning). Route based on task complexity:

```swift
enum InferenceRoute {
    case onDevice
    case cloud(model: String)

    static func route(for task: AITask) -> InferenceRoute {
        switch task.complexity {
        case .simple where task.requiresPrivacy:
            return .onDevice
        case .simple:
            return task.latencySensitive ? .onDevice : .cloud(model: "claude-haiku-4-5")
        case .moderate:
            return .cloud(model: "claude-sonnet-4-5")
        case .complex:
            return .cloud(model: "claude-sonnet-4-5")
        }
    }
}
```

## MLX for Swift

MLX is Apple's array computation framework, designed for ML on Apple Silicon. `mlx-swift` brings this to Swift.

### Key packages
- **`mlx-swift`:** Core array operations, GPU-accelerated via Metal. The foundation layer
- **`mlx-swift-examples`:** Reference implementations including LLM inference, image generation, speech recognition
- **`mlx-community` (Hugging Face):** Pre-converted models in MLX format, ready to download and run

### Running LLMs with MLX Swift
```swift
import MLX
import MLXLLM

// Load a model from Hugging Face Hub
let model = try await LLMModelFactory.shared.load(
    hub: HubConfiguration(),
    configuration: ModelConfiguration(id: "mlx-community/Qwen2.5-7B-Instruct-4bit")
)

// Generate text
let result = try await model.generate(
    prompt: "Explain quantum computing briefly:",
    parameters: GenerateParameters(temperature: 0.7, maxTokens: 256)
)
```

### MLX vs. CoreML for inference
- **MLX:** More flexible, supports any model architecture, easy to add new models, Python/Swift interop. Better for experimentation and models not in CoreML format. GPU-only (no ANE)
- **CoreML:** Optimized for ANE, better power efficiency on mobile, integrates with Apple's ML pipeline. Requires model conversion. Better for deployment in shipping apps, especially on iPhone/iPad

## CoreML Integration

### Model conversion pipeline
Most models need conversion to CoreML format:
```
PyTorch/Hugging Face → coremltools (Python) → .mlpackage → Xcode → .mlmodelc
```

Key conversion tool: `coremltools` (Python). For LLMs specifically, `apple/ml-stable-diffusion` and `apple/coreml-models` provide pre-converted models and conversion scripts.

### Using CoreML models in Swift
```swift
import CoreML

// Compiled model loaded at runtime
let config = MLModelConfiguration()
config.computeUnits = .all  // Use ANE + GPU + CPU

let model = try await MLModel.load(
    contentsOf: modelURL,
    configuration: config
)

// For NLP models, use the NaturalLanguage framework integration
import NaturalLanguage
let embedding = NLEmbedding.wordEmbedding(for: .english)
let vector = embedding?.vector(for: "hello")
```

### Compute unit selection
- `.all`: Let CoreML decide. Usually the best default
- `.cpuAndNeuralEngine`: Exclude GPU, prioritize ANE. Best power efficiency
- `.cpuAndGPU`: Exclude ANE. Use when ANE doesn't support your model's operations
- `.cpuOnly`: Fallback. Slowest but most compatible

## Embedding and Vector Operations

### On-device embeddings
- **NaturalLanguage framework:** Built-in word and sentence embeddings. Limited but zero-dependency
- **CoreML embedding models:** Convert sentence-transformers models to CoreML. Good quality, ANE-accelerated
- **MLX embeddings:** Run any embedding model via MLX Swift. Most flexible

### Vector search in Swift
For on-device vector search, you have several options:

```swift
// Simple brute-force cosine similarity (fine for <10K vectors)
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    var dot: Float = 0, normA: Float = 0, normB: Float = 0
    // Use Accelerate for SIMD performance
    vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
    vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
    vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))
    return dot / (sqrt(normA) * sqrt(normB))
}
```

**Key:** Always use the `Accelerate` framework for vector math on Apple platforms. It uses SIMD/NEON instructions and is dramatically faster than naive loops.

For larger-scale on-device search, consider SQLite with a vector extension or building a simple HNSW index in Swift.

## SwiftUI + AI Patterns

### Streaming text display
```swift
struct StreamingTextView: View {
    @State private var text = ""
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            Text(text)
                .textSelection(.enabled)
                .animation(.easeIn(duration: 0.05), value: text)
        }
        .task { await generate() }
    }

    func generate() async {
        isGenerating = true
        defer { isGenerating = false }
        for await chunk in client.streamMessage(prompt) {
            await MainActor.run {
                text += chunk.text
            }
        }
    }
}
```

### Conversation state management
```swift
@Observable
class ConversationViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var error: Error?

    private let client: LLMClient
    private var currentTask: Task<Void, Never>?

    func send(_ content: String) {
        let userMessage = ChatMessage(role: .user, content: content)
        messages.append(userMessage)
        currentTask?.cancel()
        currentTask = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let response = try await client.chat(messages: messages)
                guard !Task.isCancelled else { return }
                messages.append(ChatMessage(role: .assistant, content: response))
            } catch {
                self.error = error
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
    }
}
```

### UX patterns for AI features
- **Show generation state:** Use a typing indicator or shimmer while waiting. Stream text as it arrives rather than showing a loading spinner
- **Allow cancellation:** Always let users stop generation. Wire up a cancel button to Task.cancel()
- **Provide context:** Show users what information the AI is working with (selected text, documents, etc.)
- **Handle errors gracefully:** Rate limits, network failures, and content filters should show user-friendly messages, not raw error codes
- **Respect system integration:** Use SF Symbols, system colors, and native controls. AI features should feel like part of the OS, not a chatbot widget bolted on

## Production Patterns

### Network resilience
```swift
actor ResilientLLMClient {
    private var providers: [LLMProvider]
    private var currentIndex = 0

    func complete(_ params: CompletionParams) async throws -> String {
        var lastError: Error?
        for _ in 0..<providers.count {
            do {
                return try await providers[currentIndex].complete(params)
            } catch let error as APIError where error.isRetryable {
                lastError = error
                currentIndex = (currentIndex + 1) % providers.count
            }
        }
        throw lastError ?? LLMError.allProvidersFailed
    }
}
```

### Cost tracking
Track per-user and per-feature costs:
```swift
struct UsageTracker {
    func record(model: String, inputTokens: Int, outputTokens: Int, feature: String) {
        // Log to analytics with feature tag
        // Enables per-feature cost attribution
    }
}
```

### App Store considerations
- Apple's App Store Review Guidelines (section 4.7) require AI-generated content to be moderated and not harmful
- On-device inference avoids data privacy concerns that come with sending user data to cloud APIs
- If using cloud APIs, disclose in your privacy policy what data is sent and to whom
- Content filters: implement client-side checks in addition to any API-side content filtering
- Siri and Shortcuts integration: consider making your AI features available via SiriKit intents for system-level integration
