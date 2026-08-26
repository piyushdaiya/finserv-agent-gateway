# Product Charter

## Product identity

**Product:** FinServ Agent Gateway  
**Repository:** `finserv-agent-gateway`  
**Category:** finance-first governed action mediation  
**Baseline:** use-case agnostic

## Problem

Financial-services teams increasingly allow automated systems and agents to call tools, internal APIs, data stores, workflow engines, and external services. Traditional API authentication answers whether a principal can authenticate; it does not by itself prove that one particular automated action was appropriately scoped, policy-approved, human-reviewed when required, executed exactly once, and preserved as audit-ready evidence.

FinServ Agent Gateway provides that missing action-control boundary.

## Product promise

The gateway makes automated financial-service actions:

- **constrained** — no grant means no action;
- **transaction-scoped** — authority is bound to one workflow/transaction context;
- **deterministic at the control boundary** — authorization is not delegated to an LLM;
- **reviewable** — high-impact actions can pause for explicit human approval;
- **evidentiary** — decisions, approvals, execution lineage, hashes, and redacted artifacts can be reconstructed;
- **replayable** — offline verification can reproduce control decisions without repeating side effects.

## Target users

Initial target organizations:

- bank and fintech AI/platform engineering teams;
- security engineering and application security;
- model/AI risk and governance teams;
- compliance technology teams;
- internal audit and control-testing teams.

## Baseline non-goals

The baseline is not:

- an agent framework;
- an LLM router;
- an identity-resolution service;
- a sanctions engine;
- a KYC platform;
- a fraud engine;
- a payment processor;
- a case-management product;
- a no-code workflow builder;
- an SIEM.

## Product boundary

The gateway controls *whether and under what conditions an automated actor may invoke a downstream operation*. It does not become the system of record for the downstream business decision itself.

A downstream screening platform, payment service, onboarding system, or case platform remains authoritative for its domain semantics. The gateway is authoritative for its own mediation decision and evidence about that invocation.

## First-release objective

The first release is a **generic governance kernel**, not a domain product demonstration. It proves the invariant control path against a test-only conformance adapter. A finance workflow is selected only after the generic baseline is implemented and independently assessed.

## Success criteria

The product baseline is successful when an implementation can prove:

1. an unknown or out-of-scope action cannot execute;
2. a grant cannot widen its own authority;
3. a policy decision is deterministic and version-bound;
4. an approval-required action causes zero downstream writes before approval;
5. an approval cannot be replayed for a second write;
6. uncertain downstream execution does not trigger an automatic retry;
7. evidence can reconstruct the complete control sequence;
8. replay performs no downstream action;
9. adding a workflow pack does not weaken the core enforcement pipeline.
