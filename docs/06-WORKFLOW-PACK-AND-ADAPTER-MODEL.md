# Workflow Pack and Adapter Model

## 1. Purpose

The core gateway is intentionally use-case agnostic. Domain behavior enters through versioned workflow packs.

A workflow pack is a declarative/software extension that defines how a specific family of governed actions maps into the generic gateway contract.

## 2. Workflow pack contents

A pack contains:

- pack manifest and version;
- workflow type names;
- action catalog entries;
- request/result JSON schemas;
- deterministic fact extractors;
- resource-scope rules;
- redaction profiles;
- adapter declarations;
- sample/default policies;
- conformance fixtures;
- workflow-specific negative tests;
- documentation of downstream idempotency and recovery behavior.

## 3. Core versus workflow ownership

Core gateway owns:

- authentication;
- grant validity;
- action resolution;
- policy evaluation;
- approval lifecycle;
- executor-broker boundary;
- audit/evidence/replay;
- generic idempotency records.

Workflow pack owns:

- domain action vocabulary;
- payload/result semantics;
- deterministic domain facts;
- resource scoping semantics;
- downstream adapter behavior;
- domain-specific policy examples.

## 4. Adapter interface

Conceptual interface:

```text
ValidateConfig(config) -> error
Prepare(validated ActionRequest) -> PreparedExecution
Execute(context, PreparedExecution, IdempotencyKey) -> ExecutionResult | ExecutionError
ClassifyOutcome(error/result) -> COMPLETED | FAILED_SAFE | OUTCOME_UNKNOWN
RedactRequest(payload) -> redacted payload
RedactResult(result) -> redacted result
```

The broker, not the pack, decides whether `Execute` may be called.

## 5. Adapter requirements

Every mutating adapter documents:

- whether downstream supports native idempotency;
- exact idempotency-key propagation;
- timeout semantics;
- retry semantics;
- how to distinguish definite non-execution from ambiguous execution;
- maximum request/response sizes;
- allowed hosts/endpoints;
- credential source and scope;
- redaction behavior;
- health/readiness behavior.

If the adapter cannot determine whether a timed-out mutating request executed, the outcome is `OUTCOME_UNKNOWN`; the gateway performs no automatic retry.

## 6. Test-only conformance pack

The first implementation may include a **test-only** conformance pack with two fake actions:

- `conformance.read` — deterministic no-side-effect read;
- `conformance.write` — deterministic counter increment supporting an idempotency key.

These names exist only to prove the gateway invariants. They are not a business workflow and must not be marketed as one.

## 7. Example future integration: OpenWatchlist

OpenWatchlist is currently a non-agentic screening/review platform. It does not need FinServ Agent Gateway merely because both projects concern compliance.

If a future automated actor is allowed to invoke an OpenWatchlist operation, a workflow pack could mediate that invocation. The gateway would govern:

- whether that actor may call the operation;
- which tenant/workflow/resource it is scoped to;
- whether human approval is required;
- whether the call executes once;
- which evidence proves the invocation path.

OpenWatchlist would remain authoritative for screening/candidate/scoring semantics. The gateway would not reinterpret a downstream `200` response as a business “clear” decision unless the workflow pack explicitly models the downstream semantic status.

No OpenWatchlist dependency is part of baseline v0.1.
