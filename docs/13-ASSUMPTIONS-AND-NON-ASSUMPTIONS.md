# Assumptions and Non-Assumptions

## Stable product assumptions

- The implementation supports exact integer arithmetic, SHA-256, UTF-8, RFC3339 timestamps, and cryptographically secure random identifiers.
- A transactional persistence layer exists.
- Downstream actions are invoked through explicit adapters.
- Authentication yields a trusted actor identity/role context.
- Human approval can be represented as an authenticated reviewer decision.

## Explicit non-assumptions

The product design does not assume:

- any specific coding agent or code-generation platform;
- any engineering automation/orchestrator;
- any agent runtime such as Hermes or ZeroClaw;
- any model provider or model-routing service;
- any specific cloud or homelab topology;
- Kubernetes;
- Docker;
- a particular PostgreSQL patch release;
- any existing Clawbot service;
- OpenWatchlist;
- a first workflow;
- MCP as the first transport;
- a customer identity provider;
- production internet access.

## Dependency/version rule

Implementation dependencies must be pinned or bounded through normal engineering design/release practices. A design consumer must not infer a dependency version from unrelated external projects.

## Portability rule

Host names, ports, database DSNs, credentials, storage paths, and deployment topology belong to deployment configuration, not this product baseline.
