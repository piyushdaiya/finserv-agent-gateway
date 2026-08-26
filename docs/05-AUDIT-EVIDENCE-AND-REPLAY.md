# Audit, Evidence, and Replay

## 1. Objectives

Evidence must support independent answers to:

- what was requested;
- what authority existed;
- what policy decided;
- whether approval was required and obtained;
- whether execution occurred;
- what downstream result was observed;
- whether stored evidence has been modified;
- whether the event sequence can be replayed without causing new actions.

## 2. Audit events

Control-relevant transitions emit `audit-event/v1` records.

Baseline event types:

- `WORKFLOW_STARTED`
- `GRANT_ISSUED`
- `GRANT_REVOKED`
- `ACTION_RECEIVED`
- `ACTION_VALIDATED`
- `POLICY_DECIDED`
- `APPROVAL_REQUESTED`
- `APPROVAL_APPROVED`
- `APPROVAL_REJECTED`
- `APPROVAL_EXPIRED`
- `APPROVAL_INVALIDATED`
- `APPROVAL_CONSUMED`
- `EXECUTION_DISPATCHED`
- `EXECUTION_COMPLETED`
- `EXECUTION_FAILED`
- `EXECUTION_OUTCOME_UNKNOWN`
- `EVIDENCE_EXPORTED`

## 3. Hash chain

Each event stores:

- `sequence` monotonically increasing within a workflow;
- `previous_event_sha256`;
- `event_sha256`.

The hash material is canonical JSON with UTF-8 encoding, no insignificant whitespace, object keys sorted lexicographically, integers rendered in base-10, timestamps normalized to RFC3339 UTC with `Z`, and no floating-point values.

For the first workflow event:

```text
previous_event_sha256 = 64 lowercase zero hex characters
```

`event_sha256 = SHA256(canonical_hash_material)`.

The fixture `test/fixtures/audit-hash-fixture.json` is normative for serialization behavior.

## 4. Append-only semantics

Application APIs do not expose update/delete operations for audit events.

A database superuser can still tamper with ordinary storage; therefore baseline language is **tamper-evident**, not “immutable.” Stronger WORM/external-anchor guarantees belong to enterprise/deployment profiles and must be separately proven.

## 5. Evidence bundle

An evidence bundle manifest references:

- workflow/grant/action identities and hashes;
- request hash;
- extracted-facts hash;
- action-definition hash;
- policy ID/version/hash;
- policy decision;
- approval record/hash when present;
- execution record/hash when present;
- ordered audit event hashes;
- redaction profile;
- generation timestamp;
- bundle format version.

Raw sensitive payloads are optional artifacts and are excluded by default.

## 6. Replay

Replay inputs:

- evidence bundle manifest;
- referenced policy bytes;
- action definition;
- normalized facts/context;
- audit events.

Replay must:

1. verify bundle file hashes;
2. verify audit chain continuity;
3. reconstruct policy inputs;
4. re-run deterministic policy evaluation;
5. compare computed decision/reason code/policy hash;
6. verify approval binding where present;
7. verify execution lineage references;
8. produce a replay report.

Replay must not:

- open network sockets;
- call downstream adapters;
- modify workflow state;
- consume approvals;
- mint grants;
- generate a second domain side effect.

## 7. Evidence verification result

Replay status is one of:

- `VERIFIED`
- `MISMATCH`
- `INCOMPLETE`
- `UNSUPPORTED_VERSION`

A mismatch is evidence; replay must not “repair” historical records.
