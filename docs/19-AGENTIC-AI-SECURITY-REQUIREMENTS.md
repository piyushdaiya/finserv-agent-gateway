# Agentic AI Security Requirements

Status: **NORMATIVE FOR AGENT/GENAI INTEGRATIONS**

## 1. Scope and responsibility boundary

FinServ Agent Gateway is not an LLM runtime and is not a prompt firewall. It is a deterministic enforcement boundary intended to constrain automated and agentic actions.

Therefore:

- the gateway MUST implement the agentic controls that belong at the authorization/execution boundary;
- an integrating agent runtime or workflow MUST implement controls that belong inside the model, memory, retrieval, or orchestration layer;
- a deployment MUST NOT claim that the gateway alone makes an agentic system secure;
- every production workflow pack MUST document which party owns each applicable agentic control.

The external-risk registry is version-pinned in `security/standards-baseline.yaml`.

## 2. Fundamental agentic trust rules

1. Model or agent output is **untrusted input**, never authority.
2. Natural language never creates, widens, or revives a grant.
3. The agent cannot select its effective policy, reviewer, downstream credential, or unregistered executor.
4. Tool descriptions, MCP metadata, RAG content, memory, peer-agent messages, and retrieved documents cannot override deterministic gateway controls.
5. Delegation can only preserve or narrow authority; it can never widen tenant, workflow, resource, action, expiry, or impact scope.
6. Unknown principals, actions, tools, workflow packs, policies, adapters, or message shapes fail closed.
7. High-impact execution must be independently reviewable from the model's narrative.
8. Stop/revoke controls must remain effective even when the agent continues requesting actions.

## 3. OWASP Top 10 for Agentic Applications 2026 mapping

### ASI01 — Agent Goal Hijack

Gateway controls:

- bind actions to server-issued workflow/grant scope;
- reject action/resource substitution;
- do not accept caller-supplied policy or authority claims;
- require approval for policy-designated high-impact actions;
- record the exact normalized request and binding hashes.

Integration controls:

- treat retrieved/tool/user content as untrusted;
- detect or contain unexpected goal changes;
- preserve original user/workflow intent provenance.

### ASI02 — Tool Misuse & Exploitation

Gateway controls:

- explicit allowlisted action catalog;
- strict request schemas;
- one executor broker path;
- least-privilege server-side adapter credentials;
- approval and idempotency barriers for mutating/high-impact actions.

Tool discovery or a model deciding that a tool is useful never authorizes its execution.

### ASI03 — Identity & Privilege Abuse

Gateway controls:

- authenticated principals;
- workflow/actor/resource-bound grants;
- distinct issuer/reviewer/caller credential purposes;
- no self-issued or self-widened authority;
- delegation intersection only;
- auditable principal and delegation chain when delegation is supported.

### ASI04 — Agentic Supply Chain Vulnerabilities

Gateway controls and release requirements:

- workflow packs, policies, schemas, adapters, and releases are versioned and digest-bound;
- dependencies and build inputs are inventoried;
- SBOM and build provenance are release artifacts;
- dynamic executable plugins/scripts are not part of the baseline workflow-pack model;
- third-party MCP/tool integration, if introduced later, requires a dedicated threat model and ADR.

### ASI05 — Unexpected Code Execution

- Core policy and workflow-pack formats are data, not executable code.
- No shell command may be constructed from model/tool/request content.
- No dynamic `eval`, user-provided templates with code execution, or executable workflow-pack script is allowed.
- Any future subprocess/runtime extension requires isolation, an explicit allowlist, resource limits, and a new security ADR.

### ASI06 — Memory & Context Poisoning

The gateway MUST NOT treat agent memory, RAG output, conversation history, or model context as durable authority.

If a workflow pack converts external/contextual material into policy facts:

- extraction must be deterministic;
- source/provenance must be preserved where required;
- facts must be schema validated;
- untrusted context cannot write policy, grant, action-definition, approval, or reviewer state;
- cross-workflow/tenant memory is prohibited unless explicitly designed and authorized.

### ASI07 — Insecure Inter-Agent Communication

If requests can be delegated or originate from multiple agents:

- each principal/hop must be authenticated;
- messages are untrusted until schema and authorization checks pass;
- delegation scope is the intersection of parent authority and requested child scope across action, resource, purpose, destination, data scope, quantitative bounds, and expiry;
- tenant/workflow/resource boundaries cannot be crossed through delegation;
- replay protection and correlation/causation identifiers are required;
- internal network location does not establish trust.

### ASI08 — Cascading Failures

The system design MUST bound blast radius.

Core controls include:

- no automatic retry for ambiguous mutating outcomes;
- idempotency binding;
- grant expiry and revocation;
- bounded request/response/concurrency behavior;
- downstream timeout and circuit-breaker behavior that fails closed.

Before a real agentic workflow is production-enabled, its workflow pack/deployment MUST additionally define action-rate limits, fan-out/delegation limits where applicable, recovery behavior, and an emergency disable/revocation path.

### ASI09 — Human-Agent Trust Exploitation

Human approval must be a security control, not a model persuasion surface.

Approval presentation/API contracts MUST allow the reviewer to inspect canonical action identity, resource, impact class, normalized request summary, policy/reason, grant scope, and relevant evidence independently of free-form model rationale.

The system MUST NOT:

- auto-approve because the model is confident;
- treat model-generated justification as proof;
- hide material action changes in prose;
- let the requesting agent select or impersonate its reviewer.

### ASI10 — Rogue Agents

- default deny remains authoritative even if an agent repeatedly retries or changes wording;
- grant revocation/expiry must stop future authorization;
- an agent cannot alter security policy, action definitions, approval state, or audit history using its caller grant;
- anomalous repeated denied requests and repeated high-impact attempts must be observable;
- production deployments require an operational mechanism to disable a compromised principal/workflow without trusting that principal to cooperate.

## 4. OWASP GenAI LLM Top 10 2026 integration requirements

Where an LLM/GenAI component participates in creating requests or context, the integration threat model MUST assess the current OWASP GenAI LLM Top 10.

At the gateway boundary specifically:

- prompt injection cannot become authorization because natural language has no authority;
- sensitive information disclosure is limited through trusted data entitlement, purpose/destination binding, minimization, field/category scope, source projection, secret isolation, and redaction/tokenization;
- excessive agency is constrained by explicit grants/action catalog/policy/approval;
- supply-chain risk is addressed through workflow-pack/dependency/provenance controls;
- poisoned or misleading context cannot mutate authoritative control state;
- unbounded consumption is addressed with bounded inputs/time/concurrency and workflow-specific budgets before production;
- misinformation cannot substitute for deterministic policy evidence;
- hidden context is not used as a secret store or permission source;
- vector/embedding content is untrusted if a workflow introduces RAG;
- model/tool output must satisfy strict schemas before it can reach an executor.

## 5. MCP and dynamic tool ecosystems

MCP is not part of baseline v0.1. If introduced later, the design MUST first address OWASP's current secure MCP guidance and at minimum define:

- server/tool identity and provenance;
- transport authentication and authorization;
- tool-schema integrity and change detection;
- protection against tool poisoning/rug-pull behavior;
- credential isolation;
- per-tool least privilege;
- strict output validation;
- no automatic trust in tool descriptions;
- approval treatment for mutating/high-impact tool calls;
- egress and SSRF controls;
- auditability of tool selection and invocation.

MCP tool visibility/discovery is not equivalent to execution authorization.

## 6. Agentic red-team requirements

Before any real agentic workflow is production-enabled, adversarial testing MUST include at least:

- direct and indirect prompt injection attempting to change the requested action;
- malicious tool/downstream output;
- agent request substitution after approval;
- privilege escalation and scope-widening attempts;
- repeated denied requests and wording changes;
- malicious or poisoned memory/context where applicable;
- spoofed/replayed inter-agent messages where applicable;
- tool/adapter registry tampering;
- unexpected code-execution attempts;
- cascading retry/fan-out scenarios;
- reviewer social-engineering / misleading-rationale scenarios;
- kill/revoke behavior while the agent continues operating.

Findings must map to the pinned standards registry and produce remediation evidence. A production workflow cannot pass solely because no classical CVE is present.

## 7. Agentic data-access invariant

Model or agent context can request data but cannot authorize its disclosure. A tool/RAG/memory result containing a value does not prove that the acting agent is entitled to receive, retain, forward, or reuse that value. Governed data access uses the trusted grant/data-access context defined in `21-SENSITIVE-DATA-ACCESS-GOVERNANCE.md`.
