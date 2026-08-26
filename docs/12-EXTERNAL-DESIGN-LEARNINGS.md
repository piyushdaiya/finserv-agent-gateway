# External Design Learnings

Status: **INFORMATIVE — NOT A RUNTIME DEPENDENCY LIST**

This document records architectural lessons that informed the baseline. The named projects are not required dependencies of FinServ Agent Gateway.

## ZeroClaw

Useful concepts incorporated at the design level:

- treat tool/action discovery separately from authorization;
- narrow capabilities rather than allowing downstream layers to broaden them;
- keep one runtime-owned enforcement decision path;
- fail closed on unknown actions;
- revalidate state close to execution;
- use explicit/single-use authorization concepts for sensitive actions.

FinServ differs by making empty action scope deny-all and by treating finance-grade audit/evidence as a primary product contract.

## Hermes

Useful concepts:

- explicit approval experiences;
- hard deny floors;
- credential filtering/separation;
- isolation around tool execution;
- progressive tool exposure.

FinServ does not use model-based “smart approval” as authorization authority and has no mode equivalent to bypassing controls for governed production actions.

## Existing Clawbot projects

Useful lessons include:

- deterministic evidence should remain authoritative for scored/regression claims;
- reasoning/model outputs are reviewable artifacts rather than silent replacements for deterministic controls;
- execution privilege should be explicit and auditable;
- reviewer actions and hash-chained governance events are useful control primitives;
- domain-specific services should remain separate from generic control-plane concerns.

Those projects remain independent repositories and are not imported into this product by architecture.

## OpenWatchlist

OpenWatchlist demonstrates useful downstream-system design principles such as explicit semantic statuses, idempotency, correlation, policy lineage, tenant boundaries, and careful distinction between retrieval/scoring and review logic.

However, OpenWatchlist is not currently an agentic runtime and is not selected as the first FinServ workflow merely because it exists. If an automated actor later invokes OpenWatchlist, the integration should be through a normal FinServ workflow pack/adapter while OpenWatchlist retains its domain authority.
