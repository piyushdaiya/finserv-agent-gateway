# ADR 0008 — First-Class Delegated Authority, Parameter Bounds, and Sensitive Data Access

Status: **Accepted for design baseline v0.1**

## Context

Generic tool-level authorization is insufficient for regulated financial workflows. A secure gateway must distinguish the requesting principal from the acting agent, bind delegated authority, evaluate action parameters and quantitative limits, and govern data disclosure independently from mutation impact.

## Decision

Baseline v0.1 freezes four additional design requirements:

1. authenticated principal, acting actor, authority source, and delegation chain are first-class trusted context;
2. authorization is parameter-aware and evaluates declared resource/fact/purpose/destination inputs rather than only the action name;
3. server-issued grants include bounded authority, including action/count/fan-out/data and workflow-defined integer limits;
4. sensitive-data access is independently classified with `D0`-`D3` sensitivity, field/category scope, purpose limitation, destination controls, minimization, bulk limits, and evidence-safe commitments.

Action class `I1_SENSITIVE_READ` is replaced by `I1_READ`; data sensitivity is a separate axis.

Caller-supplied claims do not create or widen authority. Delegation and grant scope can only remain equal or become narrower across delegation hops.

## Consequences

- workflow/grant schemas carry trusted authority context and bounds;
- policy can evaluate principal/authority/data context;
- action definitions declare authorization projections and data-access profiles;
- approval binds authority/data context in addition to request/grant/action/policy state;
- data disclosure becomes auditable without storing raw sensitive values;
- plain SHA-256 of low-entropy sensitive values is not used as a confidentiality mechanism;
- workflow packs must classify sensitive fields and document source-side projection/bulk behavior.
