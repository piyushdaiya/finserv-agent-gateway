# Error and Reason Codes

Codes are stable machine-readable uppercase ASCII strings. Human text may change; code semantics may not change within the same API major version.

## Request/authentication

- `INVALID_REQUEST`
- `DUPLICATE_JSON_KEY`
- `UNKNOWN_JSON_FIELD`
- `REQUEST_BODY_TOO_LARGE`
- `CONTENT_TYPE_NOT_JSON`
- `INVALID_CORRELATION_ID`
- `IDEMPOTENCY_KEY_REQUIRED`
- `IDEMPOTENCY_KEY_REUSE`
- `AUTHENTICATION_REQUIRED`
- `ROLE_NOT_AUTHORIZED`

## Workflow/grant/action

- `WORKFLOW_NOT_FOUND`
- `WORKFLOW_EXPIRED`
- `WORKFLOW_REVOKED`
- `GRANT_NOT_FOUND`
- `GRANT_EXPIRED`
- `GRANT_REVOKED`
- `GRANT_SCOPE_MISMATCH`
- `ACTION_NOT_REGISTERED`
- `ACTION_NOT_IN_GRANT`
- `RESOURCE_SCOPE_MISMATCH`
- `ACTION_SCHEMA_INVALID`
- `FACT_EXTRACTION_FAILED`

## Policy

- `POLICY_NOT_FOUND`
- `POLICY_INVALID`
- `POLICY_DEFAULT_DENY`
- `POLICY_ALLOW`
- `POLICY_DENY`
- `POLICY_REQUIRES_APPROVAL`

A workflow policy may add namespaced reason codes such as `PACK_<NAME>_*` but cannot redefine core codes.

## Approval

- `APPROVAL_REQUIRED`
- `APPROVAL_NOT_FOUND`
- `APPROVAL_EXPIRED`
- `APPROVAL_REJECTED`
- `APPROVAL_ALREADY_CONSUMED`
- `APPROVAL_BINDING_MISMATCH`
- `APPROVAL_REQUESTER_REVIEWER_CONFLICT`
- `APPROVAL_INVALIDATED`

## Execution

- `EXECUTOR_NOT_REGISTERED`
- `EXECUTOR_CONFIG_INVALID`
- `EXECUTION_FAILED_SAFE`
- `EXECUTION_OUTCOME_UNKNOWN`
- `EXECUTION_RESULT_SCHEMA_INVALID`
- `EXECUTION_ALREADY_DISPATCHED`
- `DOWNSTREAM_RESPONSE_TOO_LARGE`
- `DOWNSTREAM_TIMEOUT`

## Audit/evidence

- `AUDIT_PERSISTENCE_FAILED`
- `AUDIT_CHAIN_MISMATCH`
- `EVIDENCE_INCOMPLETE`
- `EVIDENCE_HASH_MISMATCH`
- `REPLAY_MISMATCH`
- `REPLAY_UNSUPPORTED_VERSION`

## API status guidance

- malformed input/auth/scope: 400/401/403 as appropriate;
- missing resource: 404;
- idempotency or state conflict: 409;
- payload too large: 413;
- content type: 415;
- approval-required action submission may return 202 with approval reference rather than an error;
- downstream/core unavailable: 503;
- unexpected internal failure: 500 while preserving stable code where classifiable.
