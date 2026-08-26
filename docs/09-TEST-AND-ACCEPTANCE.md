# Test and Acceptance Contract

## 1. Purpose

The baseline is complete only when the implementation proves the invariants, including negative cases. Happy-path demonstrations are insufficient.

The machine-readable acceptance list is `test/contracts/core-acceptance.yaml`.

## 2. Required test classes

### Unit

- canonical JSON serialization;
- grant expiry/scope evaluation;
- action-name validation;
- policy parse and deterministic ordering;
- every predicate operator;
- approval state machine;
- idempotency-key binding;
- audit hash chain;
- redaction profiles.

### Contract/schema

- every committed JSON fixture validates;
- malformed/unknown fields fail;
- duplicate JSON keys fail;
- OpenAPI parses and references existing schemas;
- policy schema rejects unsupported effects/operators.

### Integration

Using only the test-only conformance pack:

- `conformance.read` executes when scoped/allowed;
- unknown action denied;
- out-of-scope action denied;
- expired/revoked grant denied;
- `conformance.write` can require approval;
- zero counter increments before approval;
- exactly one increment after approval;
- approval replay causes no additional increment;
- same idempotency key/same request replays recorded result;
- same key/different request returns conflict;
- ambiguous write timeout produces `OUTCOME_UNKNOWN` with no automatic retry.

### Security/negative

- caller cannot use grant-issuer endpoint;
- caller cannot use reviewer endpoint;
- reviewer cannot approve own requesting identity under baseline rule;
- changing payload after approval invalidates approval;
- changing policy/action definition/grant after approval invalidates approval;
- workflow-pack action cannot invoke adapter directly outside broker;
- evidence replay opens no outbound socket and performs zero writes.

### Persistence/concurrency

- two concurrent execution attempts for one action yield at most one adapter dispatch;
- audit workflow sequence cannot duplicate;
- idempotency conflict is deterministic;
- application role cannot update/delete audit events.

## 3. Acceptance threshold

All normative core acceptance cases must pass. There is no percentage-based waiver for security or exactly-once invariants.

A workflow-specific pack adds tests but cannot weaken or skip core acceptance.

## 4. Evidence expected from implementation

A release candidate should produce:

- test results;
- schema validation results;
- static analysis/lint results appropriate to implementation language;
- dependency inventory/SBOM where available;
- threat-model review against `03-SECURITY-AND-TRUST-BOUNDARIES.md`;
- reproducible conformance-run evidence bundle;
- negative proof that replay performs no network calls.
