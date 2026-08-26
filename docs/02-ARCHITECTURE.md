# Architecture

## 1. Architecture objective

FinServ Agent Gateway is a policy-enforced action mediation service. It separates the caller from downstream tools and makes the gateway the mandatory control point for governed actions.

## 2. Logical architecture

```text
                         TRUSTED HUMAN / ADMIN PLANE
                       policy + approval administration
                                  |
                                  v
+----------------+       +-----------------------------+
| Agent/service  | ----> | FinServ Agent Gateway       |
| authenticated  |       |                             |
| caller         |       | 1. Ingress/Authn            |
+----------------+       | 2. Workflow/Grant           |
                         | 3. Action Catalog            |
                         | 4. Fact Extraction           |
                         | 5. Policy Decision           |
                         | 6. Approval Gate             |
                         | 7. Executor Broker           |
                         | 8. Audit/Evidence            |
                         +-----------------------------+
                                      |
                                      v
                         +-----------------------------+
                         | Downstream adapter/system   |
                         +-----------------------------+
```

## 3. Core components

### 3.1 Ingress and authentication

Responsibilities:

- authenticate caller identity;
- validate exact JSON schema;
- reject duplicate JSON object keys;
- reject unknown fields in normative request objects;
- enforce request-size limits;
- establish correlation and idempotency identifiers;
- pass only validated typed data to the enforcement pipeline.

Ingress does not authorize the action merely because authentication succeeds.

### 3.2 Workflow and grant service

A `Workflow` is the transaction/context boundary for action authority.

A `Grant` binds:

- tenant;
- workflow;
- actor;
- allowed action names;
- resource scope;
- issuance identity;
- issuance/expiry time;
- status (`ACTIVE`, `REVOKED`, `EXPIRED`).

The caller cannot mint, widen, extend, or revoke its own grant unless a future explicit administration role authorizes that operation outside the normal action path.

### 3.3 Action catalog

Every governed action must be registered before it can execute.

An action definition identifies:

- canonical action name;
- semantic version;
- impact class;
- mutating/non-mutating nature;
- adapter/executor name;
- payload schema ID;
- result schema ID;
- fact-extractor contract;
- whether idempotency is mandatory;
- redaction profile.

Unknown actions fail closed.

### 3.4 Fact extraction

Core policy does not interpret arbitrary domain payloads directly. Instead, a workflow pack supplies a deterministic fact extractor that produces a bounded typed `facts` map from a validated payload and known context.

Allowed fact types in baseline v0.1:

- string;
- boolean;
- signed integer;
- array of unique strings.

No floating-point facts. No arbitrary nested JSON. No LLM-derived policy facts in the authorization path.

### 3.5 Policy decision point

The policy engine consumes only:

- authenticated actor metadata;
- workflow/grant metadata;
- action catalog metadata;
- deterministic extracted facts;
- approval state where applicable;
- immutable policy bundle content.

It returns exactly one of:

- `ALLOW`;
- `DENY`;
- `REQUIRE_APPROVAL`.

Every decision includes a stable reason code and the SHA-256 digest of the policy bundle.

### 3.6 Approval service

When policy returns `REQUIRE_APPROVAL`:

- no downstream executor is invoked;
- a pending approval record is created;
- the approval binds to exact hashes of the normalized request, action definition, policy bundle, and grant;
- approval has an expiration time;
- the approving identity must be distinct from the caller identity in baseline v0.1;
- approval is single-use.

Execution after approval revalidates current grant/policy/action state. Material drift invalidates the approval and requires a new decision.

### 3.7 Executor broker

The broker is the only component permitted to invoke a governed adapter after an `ALLOW` decision.

It enforces:

- exact adapter/action binding;
- idempotency key propagation;
- timeout and response-size limits;
- request/result schema validation;
- no unapproved redirect to a different adapter;
- no automatic retry after an ambiguous mutating result;
- redaction before durable result persistence.

### 3.8 Audit/evidence/replay

The gateway emits append-only events for control-relevant transitions and forms a tamper-evident hash chain. Evidence bundles reference the exact policy/action/grant/request/approval/execution identities needed to reconstruct the control path.

Replay is offline and cannot invoke adapters.

## 4. Single enforcement path invariant

Every governed action must pass this exact logical sequence:

```text
AUTHENTICATE
 -> VALIDATE_REQUEST
 -> LOAD_WORKFLOW_AND_GRANT
 -> RESOLVE_ACTION
 -> EXTRACT_FACTS
 -> EVALUATE_POLICY
 -> [DENY | REQUIRE_APPROVAL | ALLOW]
 -> REVALIDATE_IF_APPROVED
 -> EXECUTOR_BROKER
 -> VALIDATE_RESULT
 -> AUDIT_AND_EVIDENCE
```

Workflow packs may extend action definitions, schemas, facts, adapters, and policies. They may not replace or bypass this sequence.

## 5. Failure model

The gateway fails closed on:

- unknown action;
- missing/invalid/expired/revoked grant;
- tenant/workflow/actor scope mismatch;
- action-schema mismatch;
- fact-extraction failure;
- missing policy;
- policy parse/evaluation error;
- approval mismatch/expiry/replay;
- adapter configuration mismatch;
- result-schema mismatch;
- evidence persistence failure before a mutating action is dispatched;
- uncertain post-dispatch state according to the execution rules.

## 6. LLM boundary

LLMs may exist elsewhere in a product workflow, but the gateway's authorization decision is deterministic. An LLM output can be data supplied by a workflow pack only if the pack explicitly validates and classifies it; the LLM itself is never the authority to grant a permission or approve a regulated action.

## 7. Deployment neutrality

The product architecture does not assume a specific cloud, host, container runtime, coding platform, model router, or engineering system. Deployment profiles are separate artifacts produced after implementation requirements are known.
