# LLM Internals Reference

Deep technical reference on how large language models work, store information, and generate outputs. Use this to ground explanations and debug model behavior.

## Table of Contents
1. [Transformer Architecture](#transformer-architecture)
2. [How Models Store Knowledge](#how-models-store-knowledge)
3. [Attention Mechanisms](#attention-mechanisms)
4. [Tokenization and Embeddings](#tokenization-and-embeddings)
5. [Context Windows and KV-Cache](#context-windows-and-kv-cache)
6. [Decoding and Generation](#decoding-and-generation)
7. [Quantization and Optimization](#quantization-and-optimization)
8. [Common Failure Modes](#common-failure-modes)

---

## Transformer Architecture

The transformer is a sequence-to-sequence architecture built on self-attention. Modern LLMs are decoder-only transformers (GPT-style) that process text autoregressively — generating one token at a time, conditioned on all previous tokens.

**Core components of each layer:**
- Multi-head self-attention: Computes relationships between all tokens in the sequence
- Feed-forward network (FFN/MLP): Two linear transformations with a nonlinearity (typically SwiGLU in modern models). This is where most parametric knowledge is stored
- Layer normalization: Stabilizes training, typically pre-norm (RMSNorm) in modern architectures
- Residual connections: Each sublayer adds its output to its input, enabling gradient flow and information preservation

**Scale reference (approximate):**
- 7B parameter model: ~32 layers, ~4096 hidden dimension, ~32 attention heads
- 70B parameter model: ~80 layers, ~8192 hidden dimension, ~64 attention heads
- The FFN typically contains ~2/3 of total parameters

## How Models Store Knowledge

This is one of the most misunderstood aspects of LLMs. Models do not have a "database" or "memory bank." Knowledge is distributed across the network in two primary mechanisms:

### Parametric knowledge (in weights)
- **FFN layers act as key-value memories.** The first linear layer maps the input to a high-dimensional space (the "key"), and the second maps back (the "value"). When an input activates a specific pattern in the first layer, the corresponding output pattern encodes factual associations. Research (Geva et al., 2021; Meng et al., 2022) has shown that specific factual associations ("The Eiffel Tower is in [Paris]") can be localized to specific FFN neurons
- **Knowledge is superposed.** The same neurons participate in storing many different facts through superposition — the model exploits the high dimensionality to pack far more concepts than there are neurons, at the cost of occasional interference (which manifests as hallucination or confusion between similar facts)
- **Earlier layers tend to store syntactic and low-level patterns; later layers store more abstract and factual knowledge.** This is a gradient, not a hard boundary

### In-context knowledge (in activations)
- Information provided in the prompt is available through attention. The model attends to the relevant tokens when generating each output token
- This is fundamentally different from parametric knowledge: it's temporary (only exists during this forward pass), explicit (the model can "read" it directly), and reliable (less prone to hallucination than parametric recall)
- RAG exploits this by moving knowledge from unreliable parametric storage to reliable in-context storage

### The retrieval process
When the model needs a fact to continue generation:
1. The current hidden state encodes "what am I looking for"
2. Attention heads scan the context for relevant tokens (in-context retrieval)
3. FFN layers contribute parametric associations (weight-based retrieval)
4. These signals combine through the residual stream
5. If in-context evidence is strong and unambiguous, it typically overrides parametric knowledge (this is why RAG works and why you can correct models in-context)

### Why models hallucinate
- **Weak signal:** The parametric association exists but is drowned out by noise from other superposed concepts
- **Training distribution:** The model learned to produce plausible-sounding text, and sometimes plausibility wins over accuracy in the internal competition
- **No abstention training:** Models aren't strongly trained to say "I don't know" — the pretraining objective rewards always continuing
- **Frequency bias:** Common patterns in training data can override rare but correct facts

## Attention Mechanisms

### Multi-head attention
Each attention head independently computes Q (query), K (key), V (value) projections and produces an attention pattern. Different heads learn to track different relationships — some attend to syntactic structure, some to semantic similarity, some to positional proximity, some to specific entity types.

**The attention computation:**
```
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k)) V
```
The softmax creates a probability distribution over all positions — this is how the model "decides" what to attend to. The scaling by sqrt(d_k) prevents the dot products from growing too large with dimension.

### Grouped Query Attention (GQA)
Modern models (Llama 2 70B+, Mistral, Claude) use GQA: multiple query heads share a single key-value head. This dramatically reduces the KV-cache memory footprint with minimal quality loss. Typical ratio: 8 query heads per KV head.

### Multi-Query Attention (MQA)
The extreme version: all query heads share one KV head pair. Used in some inference-optimized models. Reduces KV-cache by the number of heads but can slightly degrade quality.

### Rotary Positional Embeddings (RoPE)
Most modern LLMs encode position through RoPE, which rotates the query and key vectors based on their position. This gives the model a sense of "distance" between tokens and supports length extrapolation (with extensions like YaRN, NTK-aware scaling, or dynamic NTK).

### Sliding window / local attention
Some architectures (Mistral, Phi) use sliding window attention in some layers — each token only attends to the last N tokens, reducing compute from O(n²) to O(n). Global attention layers are interspersed to maintain long-range dependencies.

## Tokenization and Embeddings

### Tokenization
Modern LLMs use BPE (Byte-Pair Encoding) or SentencePiece variants. Key properties:
- Tokens are NOT words. Common words get single tokens; rare words split into subwords; code and non-English text often split heavily
- Typical vocabulary: 32K-128K tokens (Llama: 32K, GPT-4: ~100K, Claude: ~100K)
- Token count ≈ 0.75× word count for English prose; significantly higher for code, structured data, non-Latin scripts
- Tokenization is deterministic — the same input always produces the same tokens
- Adjacent characters may merge or split differently depending on surrounding context ("tokenization" may tokenize differently when preceded by different characters)

**Practical implications:**
- Exact character counting and string manipulation is unreliable because the model doesn't see characters, it sees tokens
- JSON, XML, and structured formats consume more tokens than natural language for the same semantic content
- Asking the model to produce output of an exact length is imprecise

### Embeddings
The embedding layer maps token IDs to dense vectors (typically 4096-8192 dimensions). These vectors live in a continuous space where similar concepts cluster together — not by design, but as an emergent property of training. The embedding space is the model's "language" for representing meaning, and it's shared between input processing and output prediction (weight tying in some architectures).

## Context Windows and KV-Cache

### Context window fundamentals
The context window is the maximum number of tokens the model can process in a single forward pass. It includes everything: system prompt, user message, assistant response, any tool outputs.

- Attention is O(n²) in sequence length without optimizations
- With FlashAttention and similar kernels, the compute is still O(n²) but memory is O(n)
- Longer context doesn't mean the model uses it equally well — there's a well-documented "lost in the middle" effect where information in the middle of long contexts gets less attention than information at the beginning or end (though this is improving with better training)

### KV-Cache
During autoregressive generation, the model recomputes attention at each step. The KV-cache stores the key and value projections from all previous tokens so they don't need to be recomputed.

**Memory footprint per token:**
```
bytes_per_token = 2 × n_layers × n_kv_heads × head_dim × bytes_per_element
```

For a 70B model with GQA (8 KV heads, 128 head dim, fp16):
```
2 × 80 × 8 × 128 × 2 = 327,680 bytes ≈ 320 KB per token
```

At 128K context: ~40 GB just for KV-cache. This is why KV-cache management is critical for inference serving.

**Optimization techniques:**
- **PagedAttention (vLLM):** Manages KV-cache like virtual memory pages, eliminating fragmentation
- **Prefix caching:** Shared system prompts can reuse KV-cache across requests
- **KV-cache quantization:** Reducing KV-cache precision from fp16 to fp8/int8 halves memory with minimal quality loss
- **Token pruning/eviction:** Removing less-important tokens from cache for very long contexts

### Prefill vs. decode phases
- **Prefill:** Processing the entire input prompt. Compute-bound (matrix multiplications on the full sequence). Parallelizable
- **Decode:** Generating tokens one at a time. Memory-bandwidth-bound (reading the full KV-cache for each token). Sequential
- Time to first token (TTFT) is dominated by prefill; tokens per second is dominated by decode

## Decoding and Generation

### Decoding strategies
The model outputs logits (unnormalized probabilities) over the vocabulary for each position. How you convert these to text matters enormously:

- **Greedy:** Always pick the highest-probability token. Deterministic but often repetitive and low-quality for creative tasks
- **Temperature sampling:** Scale logits by 1/T before softmax. T<1 sharpens (more deterministic), T>1 flattens (more random). T=0 is equivalent to greedy
- **Top-k:** Sample only from the k highest-probability tokens
- **Top-p (nucleus):** Sample from the smallest set of tokens whose cumulative probability exceeds p. Adapts to the model's uncertainty — when the model is confident, fewer tokens are considered
- **Min-p:** Discard tokens whose probability is less than min_p × max_probability. More stable than top-k across varying confidence levels
- **Repetition penalty:** Reduce probability of recently generated tokens. Helps prevent loops

**Practical guidance:**
- For factual/code tasks: low temperature (0.0-0.3), or greedy
- For creative writing: moderate temperature (0.7-1.0) with top-p 0.9-0.95
- For brainstorming: higher temperature (1.0-1.5) with top-p
- Structured output (JSON): use low temperature + constrained decoding (grammar-based sampling) when available

### Structured output / constrained decoding
Modern inference engines (vLLM, llama.cpp, Outlines) support constraining generation to match a JSON schema or grammar by masking logits at each step. This guarantees valid output format without relying on prompt instructions alone.

## Quantization and Optimization

### Quantization basics
Reducing the numerical precision of model weights to use less memory and compute:

- **FP16/BF16:** Standard training precision. 2 bytes per parameter. A 70B model needs ~140 GB
- **INT8 (W8A8):** 8-bit weights and activations. ~70 GB for 70B. Minimal quality loss for most models
- **INT4 (W4A16):** 4-bit weights, 16-bit activations. ~35 GB for 70B. Noticeable but manageable quality loss. The sweet spot for consumer hardware
- **GGUF format:** llama.cpp's quantization format. Supports Q4_K_M, Q5_K_M, Q6_K, Q8_0, etc. The K_M variants use mixed quantization (more important layers keep higher precision)
- **GPTQ, AWQ, EXL2:** Various 4-bit quantization schemes with different quality/speed tradeoffs. AWQ tends to perform well; GPTQ is widely supported; EXL2 is flexible on bits-per-weight
- **FP4/NF4 (QLoRA):** 4-bit quantization specifically designed for fine-tuning with LoRA adapters

**Quality impact rule of thumb:**
- FP16 → INT8: <1% degradation on benchmarks
- FP16 → INT4 (good method): 1-3% degradation
- FP16 → INT4 (naive): 5-10% degradation
- Below 4-bit: quality drops rapidly, useful mainly for experimentation

### Inference optimization techniques
- **Speculative decoding:** Use a small draft model to propose multiple tokens, then verify in parallel with the large model. Can provide 2-3x speedup when draft acceptance rate is high
- **Continuous batching:** Process multiple requests simultaneously, adding new requests to the batch as old ones complete, maximizing GPU utilization
- **Tensor parallelism:** Split model layers across multiple GPUs. Essential for models that don't fit in single-GPU memory
- **Pipeline parallelism:** Different layers on different GPUs. Higher latency per request but can improve throughput
- **Flash Attention:** Fused attention kernel that reduces memory from O(n²) to O(n) and improves speed through better memory access patterns

## Common Failure Modes

When debugging model behavior, consider these root causes:

### Hallucination
- **Cause:** Weak parametric signal, distribution mismatch, or the model's fluency objective overriding accuracy
- **Mitigation:** RAG to provide in-context evidence, lower temperature, structured prompting ("cite your sources"), fine-tuning for abstention

### Instruction non-compliance
- **Cause:** Competing objectives in the prompt, instruction buried in long context, format not seen in training
- **Mitigation:** Move critical instructions to beginning or end of prompt, use structured delimiters, provide examples of desired format

### Context window overflow
- **Cause:** Prompt + context + expected output exceed the model's window
- **Mitigation:** Summarization, chunking strategies, selecting only relevant context, using models with larger windows

### Inconsistency across runs
- **Cause:** Temperature > 0 introduces randomness; even at T=0, batching implementation details can cause floating-point non-determinism
- **Mitigation:** Set temperature to 0 for deterministic tasks, use seed parameters when available, design systems to be robust to variation

### Sycophancy and anchoring
- **Cause:** RLHF training incentivizes agreement with the user; strong priors in the prompt can anchor the model's "reasoning"
- **Mitigation:** Ask the model to consider counterarguments, use structured debate patterns, avoid leading questions in prompts

### Prompt injection
- **Cause:** Untrusted user input is included in the prompt without sanitization, and the model follows the injected instructions
- **Mitigation:** Separate system/user content structurally (not just with text delimiters), use input validation, sandwich important instructions after untrusted content, monitor for injection patterns
