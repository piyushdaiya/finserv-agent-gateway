# FinServ Agent Gateway

**Use-case-agnostic governance gateway for agent and automated actions in financial services.**

FinServ Agent Gateway is a control boundary between an automated actor and the tools, APIs, data services, and workflows it wants to use. The gateway makes every governed action explicit, policy-evaluated, scoped, reviewable, and evidentiary before downstream execution occurs.

The baseline is intentionally **workflow-neutral**. It does not assume sanctions screening, customer onboarding, fraud, payments, case management, or any other specific financial-services workflow. Domain workflows are added later as independently versioned workflow packs and adapters.

## Core product promise

For every governed action, the gateway must be able to answer:

- Which principal requested it, which agent/service acted, and through which delegation chain?
- Under which workflow and bounded authorization grant?
- What exact action, resource, security-relevant parameters, purpose, destination, and data scope were requested?
- Which policy version evaluated it?
- Was it allowed, denied, or held for human approval?
- If executed, which adapter performed the side effect and exactly once under which idempotency key?
- What evidence exists to reconstruct and independently verify the sequence?

The product principle is:

> **Constrain first. Execute second. Preserve evidence always.**

## Baseline design status

This repository baseline is a **design and contract release**, not a production implementation. It freezes the initial product boundary, security model, core APIs, schemas, policy grammar, approval semantics, audit/replay rules, storage model, adapter contract, conformance tests, and open-core boundary.

No implementation framework, coding agent, orchestration platform, or engineering system is part of the product architecture or runtime contract.

## Product boundaries

FinServ Agent Gateway owns:

- action mediation;
- workflow-scoped grants with delegated-authority context and quantitative bounds;
- deterministic parameter-aware authorization policy evaluation;
- sensitive-data access governance with independent D0-D3 classification, purpose/destination/field scope, and minimization;
- approval state management;
- executor/adaptor dispatch through a single enforcement path;
- idempotency and side-effect protection;
- redaction before durable evidence persistence;
- append-only audit events;
- tamper-evident event chaining;
- evidence bundle generation;
- deterministic offline replay and verification;
- workflow-pack registration and validation.

FinServ Agent Gateway does **not** own:

- the business decision logic of downstream systems;
- LLM reasoning or model routing;
- sanctions/watchlist matching;
- KYC/KYB identity verification;
- fraud scoring;
- payment execution networks;
- case-management semantics;
- customer master data;
- a generic autonomous-agent runtime.

## Architecture at a glance

```text
Automated actor / agent / service
              |
              | authenticated ActionRequest
              v
+----------------------------------------------+
|             FinServ Agent Gateway            |
|                                              |
|  Ingress -> Grant -> Action Catalog -> Policy|
|                |                    |         |
|                |               DENY/ALLOW    |
|                |               / APPROVAL    |
|                v                    |         |
|          Approval State <-----------+         |
|                |                              |
|                v                              |
|         Executor Broker / Adapter             |
|                |                              |
|   Audit + Evidence + Replay + Redaction       |
+----------------------------------------------+
              |
              v
     Downstream system/tool/API
```

All governed adapters execute only through the gateway's single enforcement path. A workflow pack may describe domain-specific actions and schemas, but it may not bypass the core grant, policy, approval, idempotency, audit, and evidence sequence.

## Baseline repository layout

```text
finserv-agent-gateway/
├── README.md
├── CONTRIBUTING.md
├── api/
│   └── openapi.yaml
├── schemas/
├── policies/
│   └── examples/
├── workflow-packs/
│   └── README.md
├── security/
│   └── standards-baseline.yaml
├── test/
│   ├── contracts/   # core, security, authority/data acceptance
│   └── fixtures/
├── docs/
│   ├── 00-DESIGN-BASELINE-INDEX.md
│   ├── 01-PRODUCT-CHARTER.md
│   ├── 02-ARCHITECTURE.md
│   ├── 03-SECURITY-AND-TRUST-BOUNDARIES.md
│   ├── 04-ACTIONS-GRANTS-POLICY-AND-APPROVALS.md
│   ├── 05-AUDIT-EVIDENCE-AND-REPLAY.md
│   ├── 06-WORKFLOW-PACK-AND-ADAPTER-MODEL.md
│   ├── 07-API-CONTRACT.md
│   ├── 08-STORAGE-AND-DATA-MODEL.md
│   ├── 09-TEST-AND-ACCEPTANCE.md
│   ├── 10-OSS-VS-ENTERPRISE.md
│   ├── 11-ROADMAP.md
│   ├── 12-EXTERNAL-DESIGN-LEARNINGS.md
│   ├── 13-ASSUMPTIONS-AND-NON-ASSUMPTIONS.md
│   ├── 14-IMPLEMENTATION-BLUEPRINT.md
│   ├── 15-ERROR-AND-REASON-CODES.md
│   ├── 16-REPOSITORY-AND-PROJECT-BOUNDARY.md
│   ├── 17-FUTURE-WORKFLOW-SELECTION.md
│   ├── 18-SECURE-CODING-AND-SDLC.md
│   ├── 19-AGENTIC-AI-SECURITY-REQUIREMENTS.md
│   ├── 20-SECURITY-VERIFICATION-AND-RELEASE-GATES.md
│   ├── 21-SENSITIVE-DATA-ACCESS-GOVERNANCE.md
│   └── adr/
└── MANIFEST.json
```

## Future workflow packs

A future workflow pack can define, for example:

- sanctions/watchlist review actions;
- customer onboarding/KYC actions;
- fraud-investigation actions;
- payment initiation or release actions;
- case-disposition actions;
- sensitive customer-data access actions.

Those are examples only. No workflow is selected by this baseline.

A platform such as `openwatchlist-labs/watchlist-platform` could later be governed through an adapter if an automated actor is ever allowed to invoke screening or review-related operations. The gateway would govern the actor's **permission to invoke the operation**; it would not replace or reinterpret OpenWatchlist's own screening/scoring semantics.

## Licensing direction

The intended open-core model is:

- Community/core: Apache-2.0 target;
- enterprise modules: separate commercial/source-available terms.

The included `LICENSE-NOTE.md` is a design-stage placeholder and is not legal advice.

## Design rule

If an implementation choice is not defined by these contracts, the implementation must fail design review rather than silently invent product behavior. New behavior belongs in a reviewed ADR or a later version of the baseline.
