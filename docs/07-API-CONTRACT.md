# API Contract

The normative wire contract is `api/openapi.yaml` plus JSON schemas in `schemas/`.

## 1. Baseline endpoints

- `GET /healthz` — process liveness only.
- `GET /readyz` — readiness of core storage/policy/catalog dependencies.
- `POST /v1/workflows` — trusted grant issuer starts workflow and creates initial grant.
- `POST /v1/workflows/{workflow_id}/revoke` — trusted issuer/admin revokes workflow grant(s).
- `POST /v1/actions` — automated caller submits one governed action.
- `POST /v1/approvals/{approval_id}/decisions` — reviewer approves/rejects.
- `GET /v1/actions/{action_id}` — retrieve redacted action/control status.
- `POST /v1/evidence/exports` — request deterministic evidence bundle generation.

## 2. Authentication classes

Normative logical roles:

- `caller`
- `grant_issuer`
- `reviewer`
- `admin`

The baseline does not freeze JWT versus mTLS versus another authentication mechanism. The implementation must expose a verifier abstraction and preserve authenticated identity/role as trusted context rather than accepting caller-supplied role fields.

`POST /v1/workflows` is issuer-only and establishes the trusted authority context (requesting principal, acting actor, authority source, delegation chain), purpose/destination allowlists, data scope, and quantitative authority bounds. `POST /v1/actions` cannot replace those trusted values; its `purpose`, `destination`, `resource`, and optional `requested_data` are requests to be validated against them.

## 3. Correlation IDs

Every non-health request has a correlation ID. If supplied, it must match:

```text
^[A-Za-z0-9._:-]{1,128}$
```

Otherwise the gateway generates one.

## 4. Idempotency

`POST /v1/actions` requires `Idempotency-Key`:

- 1–128 visible ASCII characters excluding whitespace/control characters;
- key is scoped to tenant + acting actor + workflow;
- identical key + identical normalized request returns the stored action/control result;
- identical key + different normalized request returns HTTP 409 with `IDEMPOTENCY_KEY_REUSE`;
- no generated replacement key on conflict or timeout.

## 5. Errors

All non-2xx API errors use `problem/v1` with stable machine-readable `code` values from `docs/15-ERROR-AND-REASON-CODES.md`.

## 6. Strict JSON

Normative requests:

- `Content-Type: application/json`;
- duplicate keys rejected;
- unknown fields rejected unless a schema explicitly permits extension fields;
- trailing non-whitespace content rejected;
- request-size cap enforced before decode.
