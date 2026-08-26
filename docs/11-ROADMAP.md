# Roadmap

This roadmap is product-oriented and use-case agnostic until a workflow is explicitly selected.

## R0 — Design Baseline v0.1

Deliver and review:

- product charter;
- architecture/trust boundaries;
- action/grant/policy/approval contracts;
- audit/evidence/replay contract;
- workflow-pack/adapter model;
- schemas/OpenAPI;
- storage model;
- conformance acceptance contract;
- OSS/enterprise boundary.

No domain workflow dependency.

## M1 — Governance Kernel

Implement the generic gateway core:

- ingress/auth verifier abstraction;
- workflow/grant service;
- action catalog;
- deterministic fact/policy engine;
- approval state machine;
- executor broker;
- idempotency store;
- audit/evidence/replay;
- test-only conformance pack;
- full core acceptance suite.

Definition of done: all `CORE-*` acceptance cases pass without any real financial-services system.

## M2 — Extension and Operational Foundation

- stable adapter/workflow-pack SDK;
- pack registration/validation;
- policy simulation tooling;
- admin/reviewer minimal UI or CLI;
- metrics/health/operational runbooks;
- signed release/provenance/SBOM pipeline;
- threat-model and security test hardening;
- optional MCP transport adapter only if it preserves the same enforcement path.

## M3 — First Finance Workflow

Select the first real workflow using `17-FUTURE-WORKFLOW-SELECTION.md`.

Only then add domain action names, schemas, adapters, facts, policies, and acceptance cases.

Candidates may include watchlist review, onboarding/KYC, fraud investigation, customer-data access, or another workflow. Selection is based on product value and suitability, not on which adjacent repository already exists.

## M4 — Enterprise Control Plane

- enterprise identity/SSO;
- multi-party approvals;
- external evidence anchoring;
- SIEM integration;
- retention/legal hold;
- admin tenancy controls;
- policy deployment workflows.

## M5 — Additional High-Impact Workflow Packs

Add workflows only after the generic kernel and first real workflow demonstrate a stable extension boundary.
