# Security Verification and Release Gates

Status: **NORMATIVE**

## 1. Principle

A FinServ Agent Gateway release is secure only to the extent that required controls have current evidence. Security checks are gates, not advisory dashboards.

`test/contracts/security-acceptance.yaml` and `test/contracts/authority-data-acceptance.yaml` define machine-readable security/authority/data baseline cases. `security/standards-baseline.yaml` pins external reference versions.

## 2. Gate S0 — design and threat model

Before implementation of a security-sensitive feature:

- trust boundaries and data flows are documented;
- abuse/misuse cases are identified;
- applicable OWASP ASVS/API/Web/Agentic/GenAI risks are mapped;
- new credential, execution, network, persistence, or plugin boundaries require explicit design review;
- unresolved conflict between design documents is a blocker.

## 3. Gate S1 — local/source quality

Required on proposed source revisions:

- formatting/lint/static checks pass;
- unit and negative tests pass;
- secret scanning reports no committed credential;
- generated artifacts are reproducible or their generation provenance is documented;
- dependency manifests are consistent and verified.

Agent-generated source is treated as untrusted contribution and must pass the same gates.

## 4. Gate S2 — pull-request security

Before merge of implementation code:

- exact PR head passes required CI;
- human review occurs after the final code change;
- `go vet`, `staticcheck`, `gosec` (or approved equivalent), `govulncheck`, unit tests, race tests, and relevant fuzz smoke tests pass;
- dependency review identifies newly introduced packages;
- no unreviewed security waiver is present;
- changes to security-critical components receive security-focused review;
- branch protection prevents bypass by direct push or force-push to protected release branches.

## 5. Gate S3 — adversarial and invariant verification

For a release candidate:

- every `CORE-*` acceptance case passes;
- every applicable `SEC-*` security acceptance case passes;
- every `AUTH-*` and `DATA-*` authority/data-governance acceptance case passes;
- authorization, approval, broker, audit, replay, injection, SSRF, redaction, race, timeout, and malformed-input negative tests pass;
- fuzz targets run for a documented minimum corpus/time budget determined by the implementation release process;
- any agentic workflow additionally passes the adversarial cases in `19-AGENTIC-AI-SECURITY-REQUIREMENTS.md`.

A percentage score cannot substitute for a failed mandatory case.

## 6. Gate S4 — vulnerability and supply-chain release gate

A releasable artifact requires:

- no unwaived known reachable vulnerability that security review classifies as release-blocking;
- no unwaived Critical or High SAST/dependency finding;
- an SBOM (SPDX or CycloneDX);
- exact source revision identifier;
- reproducible build instructions;
- cryptographic artifact checksums;
- build provenance targeting SLSA v1.2 Build L2 or better for public/production releases;
- dependency/license inventory;
- evidence of the security tool versions used.

A finding can be waived only under `18-SECURE-CODING-AND-SDLC.md`; non-waivable product invariants remain blocking.

## 7. Gate S5 — pre-production security review

Before a real financial-services workflow processes production data or can perform a production side effect:

- ASVS v5.0.0 applicability/crosswalk is reviewed, with Level 2 as the minimum gateway verification target;
- any high-impact (`I3`) production workflow must assess applicable ASVS Level 3 requirements and document which are satisfied, not applicable, or blocked;
- OWASP Top 10:2025 and API Security Top 10:2023 threat review is current;
- agentic workflows have a current OWASP Agentic Top 10 2026 crosswalk;
- production sensitive-data workflows have a current privacy/data-flow review against `21-SENSITIVE-DATA-ACCESS-GOVERNANCE.md` and the pinned NIST Privacy Framework reference;
- workflows involving LLM/GenAI have a current OWASP GenAI LLM Top 10 2026 assessment;
- penetration/adversarial testing has no unresolved release-blocking finding;
- operational kill/revoke, incident response, secret rotation, backup/recovery, and audit export procedures are exercised;
- production configuration is reviewed separately from development defaults.

## 8. Required release evidence

The release evidence record MUST identify:

- source commit/tag;
- toolchain versions;
- CI run identifiers;
- test/acceptance results;
- static-analysis results;
- vulnerability/dependency scan results;
- SBOM digest;
- provenance/attestation location and digest;
- security crosswalk version;
- open waivers and expirations;
- reviewer identity/approval record;
- known residual risks.

## 9. No blanket compliance language

The project MUST NOT advertise "OWASP compliant", "NIST compliant", "SLSA compliant", "agent-safe", or equivalent blanket claims without a versioned scope, control mapping, and evidence.

Preferred language is specific, for example:

> "Assessed against OWASP ASVS v5.0.0 Level 2 applicable requirements; evidence record `<id>`; exceptions `<list>`."

or:

> "Agentic workflow threat model mapped to OWASP Top 10 for Agentic Applications 2026; gateway-owned and integration-owned controls documented separately."
