# ADR-0004: Deterministic Policy Authority

Status: Accepted

## Decision

Authorization policy uses a closed deterministic grammar. LLM/model output is never itself authorization or approval authority.

## Consequence

Model-assisted suggestions may be workflow data, but permission is resolved only from trusted identity/context, deterministic facts and policy.
