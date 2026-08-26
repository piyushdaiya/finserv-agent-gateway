# Test and Acceptance Contract

## 1. Purpose

The baseline is complete only when the implementation proves the invariants, including negative cases. Happy-path demonstrations are insufficient.

The machine-readable acceptance contracts are `test/contracts/core-acceptance.yaml`, `test/contracts/security-acceptance.yaml`, and `test/contracts/authority-data-acceptance.yaml`.

## 2. Required test classes

### Unit

- canonical JSON serialization;
- grant expiry/scope/delegation/bound evaluation;
- purpose/destination/data-scope evaluation;
- parameter-aware authorization projection;
- action-name validation;
- policy parse and deterministic ordering;
- every predicate operator;
- approval state machine;
- idempotency-key binding;
- audit hash chain;
- redaction/data-access profiles and keyed sensitive-value commitments.

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

### Authority/data governance

- caller cannot self-assert trusted principal/actor/delegation context;
- each delegation hop is no broader than its parent;
- parameter changes to declared authorization projection are re-evaluated;
- purpose and destination are grant-bound;
- action/economic/data quantitative bounds are enforced transactionally;
- `I1_READ` and `D0`-`D3` sensitivity are independently evaluated;
- field/category scope prevents over-disclosure;
- source-side projection is exercised where supported;
- bulk access defaults to deny;
- raw D2/D3 values are absent from default audit/evidence;
- low-entropy sensitive binding uses keyed commitment, not plain SHA-256;
- disclosure evidence records control facts without requiring cleartext.

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

All normative core, security, and authority/data acceptance cases must pass. There is no percentage-based waiver for security or exactly-once invariants.

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
