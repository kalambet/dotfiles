# Production Readiness Standards

Standards for evaluating whether an ML/AI system is ready for production deployment. Use this reference when reviewing code headed for production or assessing deployment readiness. Every section represents a category of risk — gaps in any category are review findings.

## Table of Contents
1. [Monitoring and Observability](#monitoring-and-observability)
2. [Deployment Strategy](#deployment-strategy)
3. [Model Versioning and Artifacts](#model-versioning-and-artifacts)
4. [Incident Response](#incident-response)
5. [Cost and Capacity Planning](#cost-and-capacity-planning)
6. [Data Privacy and Compliance](#data-privacy-and-compliance)
7. [Testing Requirements](#testing-requirements)

---

## Monitoring and Observability

### Model quality metrics
- **Output quality monitoring is mandatory.** If there is no mechanism to detect model quality degradation in production, that is a CRITICAL finding. Models degrade silently — data drift, prompt regression, and API changes all cause quality loss without triggering errors
- **Automated evaluation:** Sample production requests and evaluate outputs using automated metrics (exact match, schema compliance, LLM-as-judge) on a regular cadence. Daily minimum, hourly for high-traffic systems
- **Human evaluation:** Regular sampling of outputs for human review. Automated metrics miss subtle quality issues. Weekly minimum for production systems
- **Output distribution monitoring:** Track the distribution of model outputs (classification labels, confidence scores, response lengths, refusal rates). Alert on statistically significant distribution shifts — these indicate model behavior change even when individual outputs look fine
- **Embedding drift:** For RAG systems, monitor the distribution of retrieval similarity scores. Declining average similarity indicates either query distribution shift or index staleness

### Operational metrics
- **Latency:** Track p50, p95, p99 for end-to-end and broken down by component (retrieval, LLM call, parsing). Alert on p95 exceeding SLA
- **Throughput:** Requests per second/minute, tokens per second. Track capacity headroom
- **Error rates:** By error type (rate limit, timeout, content filter, parse failure, provider error). Alert on rate exceeding baseline by >2x
- **Token usage:** Input and output tokens per request, tracked separately. Track trends — increasing token usage means increasing cost
- **Availability:** Uptime of each component. The AI feature's availability is the product of all component availabilities

### Data pipeline monitoring
- **Data freshness:** For systems that depend on training data, embeddings, or index updates — alert when data is staler than the defined threshold
- **Schema drift:** Monitor for changes in input data schema. New columns, removed columns, type changes — all can break pipelines silently
- **Volume anomalies:** Track data volume (records/day, requests/day). Sudden drops or spikes indicate upstream issues or abuse
- **Feature availability:** Monitor that all required features are available at inference time. Missing features handled by fallbacks should be tracked

### Alerting
- **Alert thresholds defined and documented** for every metric above. Not "we'll monitor it" — specific numbers that trigger specific actions
- **Alert routing:** Who gets paged? For what severity? At what time of day? This must be documented and tested
- **Alert fatigue prevention:** Alerts must be actionable. If an alert fires and the response is "ignore it," the alert needs tuning, not ignoring
- **Dashboards:** Three dashboards minimum — operational (is it running?), quality (is it working?), cost (are we spending as expected?)

## Deployment Strategy

### Canary and shadow deployment
- **New models must be validated in production before taking full traffic.** No exceptions. Shadow mode (process real traffic, discard results, compare against current model) or canary (serve a small percentage of traffic) are both acceptable
- **Shadow mode:** Run the new model on production traffic in parallel with the current model. Compare outputs. This catches issues that offline evaluation misses (data distribution differences, latency requirements, edge cases in production data)
- **Canary deployment:** Route 1-5% of traffic to the new model. Monitor quality and operational metrics. Expand gradually. Automated rollback if metrics degrade

### A/B testing
- **Statistical framework:** Sample size calculations done before the test starts, not after. Significance thresholds defined in advance. No peeking and stopping early because results look good
- **Metric definition:** Primary metric defined before the test. Secondary metrics identified. Guardrail metrics (must not degrade) specified
- **Duration:** Run until statistical power is achieved, not until someone gets impatient. Factor in weekly/monthly seasonality if relevant
- **Segmentation:** Check for heterogeneous treatment effects. The new model might be better overall but worse for specific user segments

### Rollback
- **Instant rollback:** Ability to revert to the previous model version within minutes, not hours. This must be a single operation (feature flag flip, config change), not a redeployment
- **Rollback testing:** The rollback procedure must be tested before the deployment. An untested rollback is not a rollback — it's a hope
- **Rollback criteria:** Specific, measurable conditions that trigger a rollback. Documented and agreed upon before deployment. Not "if things look bad"
- **Data continuity:** Rollback must not corrupt state. If the new model writes to a database in a different format, the old model must still be able to read it

### Gradual rollout
- **Percentage-based traffic shifting:** Deploy to 1% -> 5% -> 25% -> 50% -> 100% with monitoring at each stage
- **Automated rollback triggers:** If quality metrics drop below threshold at any stage, automatically roll back to the previous stage
- **Feature flags:** Model version behind a feature flag for instant switching without redeployment

## Model Versioning and Artifacts

### Model registry
- **Every deployed model registered** with: version ID, training data version, hyperparameters, evaluation metrics (on held-out test set), training date, owner/team, deployment history
- **Immutable artifacts:** Model weights and configs stored immutably. A model version, once registered, cannot be modified — only superseded by a new version
- **Metadata searchable:** Can you answer "which model was serving traffic on March 15th?" and "what data was it trained on?" quickly?

### Artifact storage
- **Durable storage:** Model artifacts in a durable, redundant storage system (S3, GCS, etc.). Not on a single machine. Not in /tmp
- **Retention policy:** Defined and enforced. Keep the last N versions and all versions deployed in the last M months. Clean up the rest
- **Access control:** Who can deploy a model? Who can register a new version? Who can delete artifacts? This must be restricted

### Lineage tracking
- **Prediction to model:** Every prediction can be traced back to the model version that produced it
- **Model to training:** Every model version can be traced back to its training configuration, code commit, and data version
- **Data to source:** Every training data version can be traced back to the raw data sources and transformation pipeline
- **Full lineage:** From a production prediction, you can trace the full chain: prediction -> model version -> training config -> code commit -> data version -> raw data

### Deprecation
- **Deprecation policy:** How long are old model versions kept available? When are they cleaned up?
- **Deprecation process:** Owners notified. Dependency check (is anything still using this version?). Grace period. Cleanup
- **End-of-life for providers:** If using a hosted model (GPT-4, Claude), monitor provider deprecation announcements. Have a migration plan before the deprecation deadline

## Incident Response

### ML incident types
- **Silent degradation:** Model quality drops without errors. The hardest to detect and often the most damaging. Requires quality monitoring (see Monitoring section)
- **Latency spike:** Model or infrastructure becomes slow. Impact: timeout errors, poor UX, downstream service degradation
- **Cost spike:** Runaway agent, retry avalanche, or traffic spike causes unexpectedly high API costs
- **Offensive/harmful output:** Model produces content that violates content policies or causes harm. Impact: reputational damage, legal risk
- **Data leak:** Model outputs contain training data, PII, or confidential information that shouldn't be exposed
- **Complete failure:** Model endpoint is down or returning errors. The most obvious but often the easiest to handle (because the system clearly isn't working, not silently producing garbage)

### Incident playbook
- **Specific to ML:** Generic "check the logs" incident playbooks are insufficient. ML incidents require ML-specific steps: check model quality metrics, check data pipeline freshness, compare current model output distribution to historical baseline, check for provider-side changes
- **Decision tree:** Is the model returning errors? -> Check infrastructure. Is the model returning wrong answers? -> Check quality metrics, data freshness, recent prompt changes. Is the model slow? -> Check provider status, context size, batch configuration
- **Documented and accessible:** The playbook must be findable during a 2 AM incident, not buried in a wiki nobody reads

### Kill switch
- **Feature-level kill switch:** Ability to disable the ML feature entirely and fall back to a non-ML path (cached results, static responses, manual queue). This must be a single toggle, not a code change and deploy
- **Kill switch tested:** Has the kill switch been tested? Does the fallback path actually work? When was it last tested?
- **Partial kill switches:** Ability to disable specific sub-features (e.g., disable the agent loop but keep simple completion, disable RAG but keep direct generation)

### Post-incident
- **Root cause analysis required** for any ML incident. "The model was wrong" is not a root cause. Why was it wrong? What changed? How do we prevent it?
- **New test case:** Every incident becomes at least one new test case in the evaluation suite
- **Monitoring improvement:** Every incident should improve monitoring — if the incident wasn't detected by monitoring, that's a monitoring gap to fix

### SLA definition
- **Availability SLA:** What uptime is committed? 99.9%? 99.5%? Is the AI feature subject to the same SLA as the rest of the application, or does it have a separate (often lower) SLA?
- **Latency SLA:** p95 or p99 latency target. Measured end-to-end, not just the LLM call
- **Quality SLA:** What quality level is committed? This is harder to define but essential — "the model will be right X% of the time" or "quality will not degrade more than Y% from baseline"

## Cost and Capacity Planning

### Cost model
- **Per-request cost calculated:** model API cost (input + output tokens at current pricing) + embedding cost + vector search cost + infrastructure cost. This should be a formula, not a guess
- **Cost per user/feature:** Costs attributable to specific users and features for business analysis and abuse detection
- **Cost trend tracking:** Monthly cost trend. Alert when cost grows faster than usage growth (indicates inefficiency) or faster than revenue growth (indicates unsustainable economics)

### Capacity limits
- **Maximum concurrent requests:** Defined and tested. What happens when you hit the limit? Queuing with backpressure, not crash
- **Maximum context size:** The largest input the system can handle. Requests exceeding this are rejected gracefully, not allowed to fail at the API level
- **Rate limit headroom:** How much of your provider rate limit are you using at peak? If the answer is >80%, you need to plan for growth or negotiate higher limits

### Auto-scaling
- **For self-hosted inference:** Auto-scaling policy defined and tested. Scale-up trigger (GPU utilization, request queue depth). Scale-down policy (cool-down period to avoid thrashing)
- **For API-based:** Rate limit management. What happens when you approach provider rate limits? Queuing, load shedding, or provider failover?
- **Cost caps:** Maximum daily/monthly spend defined with automatic alerts and optional hard caps that stop spending

### Budget alerts
- **Threshold alerts:** Alert when daily cost exceeds projected daily cost by >20%. Alert when monthly cost is on track to exceed budget by >10%
- **Anomaly detection:** Detect unusual cost patterns (sudden spike from a single user, gradual increase from context growth)
- **Cost review cadence:** Monthly or quarterly review of cost efficiency. Right-sizing model selection, optimizing prompts, evaluating caching effectiveness

## Data Privacy and Compliance

### Data classification
- **Input data classification:** What sensitivity level are model inputs? Public, internal, confidential, restricted? This determines handling requirements
- **Output data classification:** Model outputs may contain or infer sensitive information not explicitly in the input. Classify outputs independently
- **Intermediate artifacts:** Embeddings, cached responses, logs — all must be classified and handled according to their sensitivity level

### Data retention
- **Retention policy for LLM logs:** How long are request/response logs kept? Who has access? Are they encrypted at rest?
- **Retention policy for embeddings:** Embeddings can encode sensitive information from the source text. They require the same retention and access controls as the source data
- **Retention policy for model artifacts:** Training data snapshots, model weights, evaluation results — all have retention and access control requirements

### Right to deletion
- **Data subject deletion:** If a user requests deletion (GDPR right to erasure), can you identify and delete: their data in training sets, their embeddings in vector stores, their requests in logs, model artifacts trained on their data?
- **Deletion verification:** After deletion, can you verify the data is actually gone? Cached copies, replicas, and backups all need to be addressed

### Audit trail
- **Deployment audit:** Who deployed what model, when, with what approval? This must be logged and immutable
- **Access audit:** Who accessed model logs, training data, or evaluation results? Especially important for data containing PII
- **Decision audit:** For high-stakes applications (credit, hiring, medical), individual model decisions must be auditable: what input produced what output, using which model version

### Compliance verification
- **Provider data usage policy:** Does your LLM provider use your data for training? Are you opted out? Is this documented and verified? This matters especially for sensitive data
- **Cross-border data transfer:** If using cloud LLM APIs, where is the data processed? Does this comply with data residency requirements?
- **Regulatory requirements:** Industry-specific regulations (HIPAA for health, SOX for finance, etc.) identified, requirements documented, compliance verified

## Testing Requirements

### Unit tests
- **Data transformation logic:** Every preprocessing function, feature engineering function, and data validation function has unit tests
- **Output parsing:** LLM output parsing, schema validation, and error handling code has unit tests with both valid and invalid inputs
- **Configuration loading:** Model configuration, prompt templates, and parameter loading code has tests

### Integration tests
- **End-to-end pipeline:** Test the full path from input to output with a real (or realistic mock) model. Cover: happy path, error paths, edge cases
- **Provider integration:** Test against the actual LLM provider API (in a test account/environment) periodically. Mock-only testing misses API changes, rate limit behavior, and provider-specific error formats
- **Data pipeline integration:** Test the full data pipeline from raw data to model-ready format. Verify output shape, types, and value ranges

### Load tests
- **Peak traffic simulation:** Verify latency SLAs under expected peak load. Identify the throughput ceiling
- **Sustained load:** Run at expected average load for an extended period (hours, not minutes). Check for resource leaks, connection pool exhaustion, memory growth
- **Burst handling:** Simulate sudden traffic spikes. Verify queuing, backpressure, and graceful degradation behavior

### Chaos tests
- **Provider failure:** What happens when the LLM API returns errors for 5 minutes? 30 minutes? Permanently?
- **Slow provider:** What happens when the LLM API latency doubles? Quadruples? Does the system timeout gracefully or cascade failures?
- **Data pipeline failure:** What happens when the data pipeline is stale? When the vector database is unavailable? When an upstream feature source is down?
- **Resource exhaustion:** What happens at memory limits? At disk limits? At connection limits?

### Evaluation suite
- **Curated test set:** A representative set of (input, expected_output) pairs, covering normal cases, edge cases, and known failure modes
- **Automated execution:** Run the evaluation suite before every deployment. No deployment without passing evaluation
- **Regression tracking:** Track evaluation metrics over time. Alert on regression from the previous version
- **Living test set:** Every production bug, customer complaint, and edge case discovered becomes a new entry in the evaluation suite

### Security tests
- **Prompt injection:** Test with known injection patterns: instruction override, role-play attacks, encoding tricks, delimiter injection
- **Adversarial inputs:** Test with inputs designed to produce harmful, incorrect, or unexpected outputs
- **PII detection:** Verify that PII in outputs is detected and handled (masked, filtered, or flagged)
- **Tool use security:** If the model can call tools, test that tool calls are validated and scoped. Test what happens when the model hallucinates a tool that doesn't exist or passes malicious parameters
- **Output injection:** Verify that model output rendered in a UI doesn't execute (XSS) and model output used in database queries doesn't inject (SQLi)
