# ADR-0002: Single Enforcement Path

Status: Accepted

## Decision

Every governed adapter execution passes through authentication, grant, action catalog, deterministic facts/policy, approval where required, executor broker, and audit/evidence. Workflow packs cannot bypass that path.

## Reason

A second execution path becomes an authorization bypass and destroys evidence completeness.
