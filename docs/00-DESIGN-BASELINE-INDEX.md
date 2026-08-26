# FinServ Agent Gateway Design Baseline v0.1

Status: **HUMAN-REVIEWED DESIGN CANDIDATE — IMPLEMENTATION INDEPENDENT**

This baseline is the normative product specification for the first implementation of FinServ Agent Gateway. It is deliberately independent of any code-generation tool, engineering platform, CI system, autonomous coding agent, or deployment environment.

## Normative documents

1. `01-PRODUCT-CHARTER.md`
2. `02-ARCHITECTURE.md`
3. `03-SECURITY-AND-TRUST-BOUNDARIES.md`
4. `04-ACTIONS-GRANTS-POLICY-AND-APPROVALS.md`
5. `05-AUDIT-EVIDENCE-AND-REPLAY.md`
6. `06-WORKFLOW-PACK-AND-ADAPTER-MODEL.md`
7. `07-API-CONTRACT.md`
8. `08-STORAGE-AND-DATA-MODEL.md`
9. `09-TEST-AND-ACCEPTANCE.md`
10. `10-OSS-VS-ENTERPRISE.md`
11. `11-ROADMAP.md`
12. `13-ASSUMPTIONS-AND-NON-ASSUMPTIONS.md`
13. `14-IMPLEMENTATION-BLUEPRINT.md`
14. `15-ERROR-AND-REASON-CODES.md`
15. `16-REPOSITORY-AND-PROJECT-BOUNDARY.md`
16. `18-SECURE-CODING-AND-SDLC.md`
17. `19-AGENTIC-AI-SECURITY-REQUIREMENTS.md`
18. `20-SECURITY-VERIFICATION-AND-RELEASE-GATES.md`
19. `21-SENSITIVE-DATA-ACCESS-GOVERNANCE.md`
20. ADRs under `docs/adr/`
21. schemas under `schemas/`
22. `api/openapi.yaml`
23. conformance contract `test/contracts/core-acceptance.yaml`
24. security conformance contract `test/contracts/security-acceptance.yaml`
25. authority/data conformance contract `test/contracts/authority-data-acceptance.yaml`
26. version-pinned security registry `security/standards-baseline.yaml`
27. `CONTRIBUTING.md`

`12-EXTERNAL-DESIGN-LEARNINGS.md` and `17-FUTURE-WORKFLOW-SELECTION.md` are informative unless a later ADR promotes specific statements to normative requirements.

## Precedence

If documents conflict, use this order:

1. accepted ADR that explicitly supersedes an older decision;
2. schemas/OpenAPI for wire-format details;
3. numbered normative design documents;
4. README/examples.

Conflicts are defects. Implementations must not choose whichever interpretation is convenient.

## Frozen first-implementation properties

The first implementation MUST have:

- one canonical enforcement pipeline for all governed actions;
- deterministic policy authority with no LLM authorization role;
- workflow-scoped authorization grants with first-class principal/actor/delegation context;
- deny-by-default behavior;
- explicit action catalog registration;
- parameter-aware authorization over declared resource/fact/purpose/destination inputs;
- quantitative authority and economic/blast-radius bounds;
- independent action-impact (`I0`-`I3`) and data-sensitivity (`D0`-`D3`) classification;
- purpose- and destination-bound sensitive-data access with field/category scope and minimization;
- human approval for actions whose policy result is `REQUIRE_APPROVAL`;
- approval bound to exact action/request/policy/grant state;
- no downstream side effect before required approval;
- idempotent downstream execution with no silent retry of uncertain side effects;
- redaction before durable persistence of sensitive payload material;
- append-only tamper-evident audit events;
- deterministic evidence bundle export;
- offline replay that performs no network or downstream actions;
- a workflow-pack boundary that cannot bypass core enforcement;
- secure coding and SDLC gates as defined in `18-SECURE-CODING-AND-SDLC.md`;
- version-pinned OWASP/NIST/SLSA security applicability and evidence requirements;
- agent/model/tool output treated as untrusted input and never as authority;
- mandatory security acceptance and release gates.

## Explicitly not frozen

The baseline does not select:

- a first business workflow;
- a first financial-institution customer;
- an agent framework;
- a model provider;
- an orchestration platform;
- a deployment topology;
- cloud versus homelab versus on-prem deployment;
- enterprise SSO vendor;
- a specific downstream business system.

Those decisions require later design work.
