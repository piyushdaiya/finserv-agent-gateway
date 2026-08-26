# ADR 0009 — OpenAPI 3.1 and JSON Schema Draft 2020-12 Alignment

Status: **Accepted for design baseline v0.1**

## Context

The baseline API contract references standalone schemas under `schemas/`. Those schemas are JSON Schema Draft 2020-12 resources and declare that dialect with `$schema`. The previous `api/openapi.yaml` declared OpenAPI 3.0.3. OpenAPI 3.0 Schema Objects do not provide the same JSON Schema Draft 2020-12 dialect model, creating an avoidable incompatibility when validating the canonical API document together with the canonical standalone schemas.

Maintaining separate OpenAPI-3.0-specific schema projections would duplicate schema authority and create a synchronization risk between API projections and the canonical Draft 2020-12 schemas.

## Decision

Baseline v0.1 uses **OpenAPI 3.1.2** for `api/openapi.yaml`.

The standalone schemas under `schemas/` remain canonical JSON Schema Draft 2020-12 resources and retain their `$schema` declarations. Local OpenAPI references resolve directly to those canonical schema resources.

The baseline does not introduce a second OpenAPI-3.0-specific schema projection set. Validators and implementations must not strip schema-dialect declarations or weaken local-reference validation to accommodate OpenAPI 3.0 behavior.

This is a contract-dialect alignment only. It does not change API endpoints, request/response business semantics, authorization semantics, security controls, acceptance requirements, or the single enforcement path.

## Consequences

- OpenAPI validation tooling must support OpenAPI 3.1.2 and referenced Draft 2020-12 schema resources.
- The canonical API contract and canonical JSON schemas remain directly linked through local `$ref` references.
- Schema changes continue to have one canonical representation rather than dual 3.0/2020-12 projections.
- A future OpenAPI feature-line change requires explicit review and affected contract requalification.
- The existing mandatory acceptance-contract identities and counts are unchanged.
