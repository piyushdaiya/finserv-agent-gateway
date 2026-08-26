# Implementation Blueprint

This document defines an implementation sequence without assuming who or what writes the code.

## Stage 0 — contract qualification

Before production code:

- parse every JSON/YAML schema;
- validate all committed fixtures;
- parse OpenAPI;
- prove audit hash fixture behavior in a small test harness;
- produce a requirements-to-test mapping;
- identify exact implementation-language/runtime/dependency choices;
- record any proposed deviation as an ADR before coding it.

## Stage 1 — core types and strict decoding

Implement:

- IDs and enums, including independent impact and data-sensitivity classes;
- authority-context types and trusted-context hashing;
- strict JSON decoder with duplicate-key rejection;
- canonical JSON hashing;
- action-name validation;
- normalized request hashing;
- problem/error model.

No network adapter needed.

## Stage 2 — workflow/grant/action catalog

Implement:

- workflow creation;
- principal/acting-actor/delegation context;
- grant issue/revoke/expiry;
- role separation;
- action definition registry;
- definition hashing;
- resource/purpose/destination/data-scope comparison;
- authority/economic/blast-radius bounds and counters.

## Stage 3 — facts and policy engine

Implement:

- typed fact map;
- declared authorization projection and parameter-aware inputs;
- policy schema parser;
- ordered rule evaluator;
- every baseline predicate;
- deterministic reason codes;
- default deny.

## Stage 4 — approval lifecycle

Implement exact state transitions, binding hashes, reviewer separation, expiry, revalidation, single-use consumption.

## Stage 5 — persistence/idempotency/audit

Implement relational persistence, unique constraints, idempotency semantics, audit event chain and redaction.

## Stage 6 — sensitive-data governance

Implement:

- data-access profile validation;
- D0-D3 sensitivity handling independent of impact class;
- field/category scope;
- purpose/destination enforcement;
- source-side projection planning;
- bulk/record/byte bounds;
- keyed sensitive-value commitments;
- disclosure summaries/audit events.

## Stage 7 — executor broker and conformance adapter

Implement the generic adapter interface and test-only read/write adapter. Prove zero/one side-effect semantics and ambiguous outcome behavior.

## Stage 8 — evidence and replay

Implement deterministic bundle export, chain verification, policy replay and network-free replay tests.

## Stage 9 — API delivery

Expose the frozen OpenAPI contract with role-aware authentication hooks and bounded request/response handling.

## Stage 10 — complete acceptance

Run every `CORE-*`, `SEC-*`, `AUTH-*`, and `DATA-*` acceptance case plus race/concurrency/security tests. Produce release evidence.

## Implementation non-permissions

The implementer must not:

- select a real financial workflow and bake it into core;
- add LLM authorization;
- add a second adapter execution path;
- weaken default deny;
- silently add policy scripting;
- make approval optional for a policy result of `REQUIRE_APPROVAL`;
- automatically retry an ambiguous mutating action;
- claim storage is immutable when only hash-chain tamper evidence exists.
