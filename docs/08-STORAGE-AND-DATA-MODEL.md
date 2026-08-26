# Storage and Data Model

## 1. Storage role

The baseline assumes a transactional relational store for control state. PostgreSQL is the preferred reference implementation but the product contract is expressed in relational invariants rather than a deployment-specific host/version.

## 2. Core relations

### `workflows`

- workflow_id PK
- tenant_id
- workflow_type
- actor_id
- policy_bundle_id
- created_at
- expires_at
- status
- workflow_sha256

### `grants`

- grant_id PK
- workflow_id FK
- tenant_id
- actor_id
- allowed_actions JSON/array
- resource_scope JSON
- issued_by
- issued_at
- expires_at
- revoked_at nullable
- status
- grant_sha256

Grant content is immutable after issuance except revocation/status timestamps.

### `action_definitions`

- action_name + semantic_version composite identity
- pack_id/version
- impact_class
- mutating
- adapter_name
- payload_schema_id
- result_schema_id
- redaction_profile
- definition_sha256
- active

### `policy_bundles`

- policy_id + version
- policy_sha256 unique
- canonical policy JSON bytes/content reference
- activated_at
- retired_at nullable

Historical content remains available while referenced by evidence retention policy.

### `action_requests`

- action_id PK
- request_id
- workflow_id
- tenant_id
- actor_id
- grant_id
- action_name
- action_definition_sha256
- normalized_request_sha256
- facts_sha256
- redacted_request JSON nullable
- correlation_id
- idempotency_key
- received_at
- status

Unique constraint on `(tenant_id, actor_id, workflow_id, idempotency_key)`.

### `policy_decisions`

- decision_id PK
- action_id FK
- effect
- reason_code
- policy_id/version/hash
- evaluated_at
- decision_input_sha256

### `approvals`

- approval_id PK
- action_id FK
- requester_actor_id
- reviewer_actor_id nullable until decision
- state
- decision
- request/grant/action/policy hashes
- requested_at
- decided_at nullable
- expires_at
- consumed_at nullable

### `execution_records`

- execution_id PK
- action_id FK unique for baseline one-dispatch semantics
- adapter_name
- downstream_idempotency_key
- dispatched_at
- completed_at nullable
- outcome
- response_sha256 nullable
- redacted_result nullable
- error_code nullable

### `audit_events`

- workflow_id + sequence composite unique
- event_id unique
- event_type
- occurred_at
- canonical fields
- previous_event_sha256
- event_sha256

No application update/delete path.

### `evidence_bundles`

- bundle_id PK
- workflow_id
- manifest_sha256
- created_at
- storage locator
- verification status nullable

## 3. Transactions

Before any mutating downstream dispatch, the database transaction must durably commit:

- validated action request;
- policy decision;
- approval consumption if applicable;
- `EXECUTION_DISPATCHED` intent record or equivalent unique dispatch guard.

The implementation must prevent two concurrent processes from dispatching the same `action_id` twice.

## 4. Sensitive data

The database is not a raw prompt/payload warehouse. Persist only data required by control/evidence contracts, applying redaction first.

## 5. Tenant isolation

Every control record is tenant-bound. The implementation must enforce tenant predicates in the data-access layer. Database row-level security is recommended for production but is not a baseline portability requirement until a deployment profile freezes it.
