# ML Review Checklist

Systematic checklist for reviewing traditional ML code: data handling, feature engineering, model training, evaluation, and reproducibility. For LLM-specific review standards, see `llm-integration-standards.md`.

## Table of Contents
1. [Data Handling](#data-handling)
2. [Feature Engineering](#feature-engineering)
3. [Model Training](#model-training)
4. [Evaluation Methodology](#evaluation-methodology)
5. [Experiment Tracking](#experiment-tracking)
6. [Reproducibility Standards](#reproducibility-standards)
7. [Embedding and Vector Pipeline](#embedding-and-vector-pipeline)

---

## Data Handling

### Validation
- [ ] Input data validated against an explicit schema (types, ranges, nullability, cardinality)
- [ ] Assertions on expected data shape at pipeline boundaries (row count, column count, dtypes)
- [ ] Null/NaN handling is explicit — not silent propagation through defaults or imputation without documentation
- [ ] String values validated against expected patterns or enums — no silent acceptance of unexpected categories
- [ ] Numeric values range-checked — no silent acceptance of physically impossible or out-of-distribution values

### Leakage detection
- [ ] Preprocessing (scaling, encoding, imputation) fitted on training data only, applied to validation/test
- [ ] No temporal leakage: features computed using only past data relative to the prediction timestamp
- [ ] No target leakage: no features that directly or indirectly encode the label (correlation analysis done)
- [ ] Train/validation/test sets have no overlapping records (deduplicated before splitting)
- [ ] For time-series: gap period between train and validation to account for autocorrelation

### Versioning and lineage
- [ ] Training datasets are versioned with immutable snapshots — you can recreate exactly what data was used for any past experiment
- [ ] Data source and transformation lineage documented — you can trace any feature value back to its raw source
- [ ] Schema changes tracked and documented — what columns were added, removed, or modified and when

### Sampling and distribution
- [ ] Training distribution is representative of production distribution (or differences are documented and addressed)
- [ ] Class imbalance acknowledged and handled explicitly (sampling strategy, class weights, or appropriate metrics)
- [ ] Data freshness requirements defined — how stale can training data be before model quality degrades

### Privacy and compliance
- [ ] PII stripped or anonymized before training. Review for names, emails, phone numbers, addresses, IDs
- [ ] Compliance requirements (GDPR, CCPA, HIPAA) identified and implemented
- [ ] Data retention policy defined and enforced — how long is training data kept, and who has access

## Feature Engineering

### Leakage checklist
- [ ] No features computed from future data (relative to prediction time)
- [ ] No features that directly or indirectly encode the target variable
- [ ] No features derived from the test set (e.g., population statistics that include test data)
- [ ] Aggregation windows clearly defined and temporally correct

### Documentation
- [ ] Every feature documented: source, transformation, rationale for inclusion, expected value range
- [ ] Feature dependencies documented — which features depend on which data sources or other features
- [ ] Known limitations or caveats documented (e.g., "this feature is unreliable for users with <30 days of history")

### Drift and stability
- [ ] Features assessed for production stability — will this feature's distribution change over time?
- [ ] Drift detection implemented or planned for high-risk features
- [ ] Expensive features (requiring real-time API calls, heavy computation) identified with cost/latency analysis
- [ ] Missing value strategy documented and tested — what happens when a feature is unavailable at inference time

## Model Training

### Reproducibility
- [ ] Random seeds set for all sources of randomness (data shuffling, weight initialization, dropout, augmentation)
- [ ] Deterministic operations used where available (or non-determinism documented)
- [ ] Dependencies version-pinned (exact versions, not ranges). Ideally reproducible environment (Docker, Nix)
- [ ] Training invocable from a single command with all parameters specified (not a notebook with manual cell execution)

### Data splits
- [ ] Train/validation/test split ratios appropriate for dataset size
- [ ] For time-series: temporal split with appropriate gap period
- [ ] For grouped data (e.g., multiple records per user): groups don't span splits
- [ ] Split logic is deterministic and reproducible
- [ ] Test set is truly held out — never used for any decision during development except final evaluation

### Training configuration
- [ ] Hyperparameters tracked, versioned, and configurable (not hardcoded in training scripts)
- [ ] Loss function appropriate for the task and aligned with the business objective
- [ ] Regularization present and tuned (dropout, weight decay, early stopping, data augmentation)
- [ ] Learning rate schedule defined (not just a fixed learning rate for complex tasks)
- [ ] Batch size chosen deliberately (not just copied from a tutorial)

### Resource management
- [ ] GPU memory requirements estimated before launching training
- [ ] Training time estimated and budgeted
- [ ] Checkpointing enabled — training can be resumed from a checkpoint after interruption
- [ ] Gradient health monitored (clipping configured, logging of gradient norms)

## Evaluation Methodology

### Metric selection
- [ ] Primary metric is appropriate for the task (not just accuracy — consider precision, recall, F1, AUC, MRR, NDCG, etc.)
- [ ] Primary metric correlates with the business objective (validated, not assumed)
- [ ] Multiple complementary metrics reported (a single number hides failure modes)
- [ ] Metric computed correctly — no off-by-one errors in ranking metrics, no micro/macro confusion in multi-class

### Baselines
- [ ] Performance compared against at least one baseline: random, majority class, simple heuristic, or previous model version
- [ ] Baseline is appropriate and non-trivial — "random" baseline for an imbalanced binary task is 50%, not informative
- [ ] Improvement over baseline is stated clearly with both absolute and relative numbers

### Statistical rigor
- [ ] Improvements are statistically significant — confidence intervals or significance tests reported, not just point estimates
- [ ] For small improvements (<2% relative): extra scrutiny on whether the difference is real or noise
- [ ] Multiple evaluation runs (different seeds) to assess variance, unless training is prohibitively expensive
- [ ] Effect size reported alongside p-values — statistical significance without practical significance is misleading

### Slice analysis
- [ ] Performance reported per relevant segment (demographic groups, data sources, content types, difficulty levels)
- [ ] Aggregate metrics do not hide segment-level regressions
- [ ] Worst-performing segments identified and assessed for business impact
- [ ] Fairness metrics computed if the model affects people differently across protected attributes

### Failure analysis
- [ ] Sample of model failures manually reviewed to identify patterns
- [ ] Common failure modes categorized and documented
- [ ] Error distribution analyzed — are errors random or systematic?
- [ ] Edge cases and adversarial inputs tested

## Experiment Tracking

### Logging requirements
- [ ] Every experiment logged with: parameters, metrics, data version, code version (git commit), model artifacts
- [ ] Experiments are uniquely identified and searchable
- [ ] Training loss curves and validation metrics saved for post-hoc analysis
- [ ] Results easily comparable across experiments (consistent metrics, consistent evaluation sets)

### Record keeping
- [ ] Negative results recorded — what was tried and didn't work, and why
- [ ] Experiment rationale documented — what hypothesis does this experiment test?
- [ ] Key decisions (architecture, hyperparameter choices, data changes) tracked with reasoning
- [ ] Someone can reproduce any experiment from the logged information alone, 6 months from now

## Reproducibility Standards

### Environment
- [ ] Exact dependency versions pinned (pip freeze, go.sum, package-lock.json — not version ranges)
- [ ] Environment reproducible: Docker, Nix, or equivalent. "It works on my machine" is not a standard
- [ ] Hardware documented: GPU type, memory, number of GPUs (results can differ across hardware)
- [ ] Software versions documented: CUDA, cuDNN, OS version (these affect numerical results)

### Seed discipline
- [ ] Random seeds set for all random operations: data shuffling, train/test splitting, weight initialization, dropout, data augmentation
- [ ] Seeds configured as parameters, not hardcoded magic numbers
- [ ] Documented that specific operations may be non-deterministic even with seeds (e.g., certain CUDA operations)

### Code and data versioning
- [ ] Every experiment tied to a specific git commit
- [ ] Every experiment tied to a specific data version/snapshot
- [ ] Model artifacts tagged with both code and data versions
- [ ] Ability to check out the exact code and data that produced any past model

## Embedding and Vector Pipeline

### Model selection
- [ ] Embedding model appropriate for the domain (general-purpose vs. domain-specific, evaluated on domain data)
- [ ] Embedding dimensionality justified — higher dimensions aren't always better and increase storage and search cost
- [ ] Multilingual support evaluated if the corpus contains non-English content

### Chunking strategy
- [ ] Chunk size appropriate for the embedding model's training window
- [ ] Chunks don't break mid-sentence or mid-concept (use overlap or semantic-aware splitting)
- [ ] Chunk metadata preserved: source document, section, page, timestamp
- [ ] Chunk overlap configured to prevent information loss at boundaries

### Index configuration
- [ ] Distance metric appropriate for the embedding model (cosine, L2, dot product — check model documentation)
- [ ] Index type appropriate for scale (flat for <10K, HNSW for 10K-10M, specialized for >10M)
- [ ] HNSW parameters (M, ef_construction, ef_search) tuned based on recall/latency tradeoff, not left at defaults
- [ ] Index build time and memory requirements estimated

### Retrieval evaluation
- [ ] Evaluation set of (query, expected_relevant_documents) pairs exists
- [ ] Precision@k and recall@k measured on the evaluation set
- [ ] Retrieval compared against a baseline (BM25, different embedding model, different chunk size)
- [ ] Retrieval quality monitored in production — not just measured once during development
- [ ] End-to-end RAG quality measured separately from retrieval quality (generation can compensate for or amplify retrieval issues)
