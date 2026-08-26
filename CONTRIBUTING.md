# Contributing to FinServ Agent Gateway

All contributions are governed by the design baseline, especially:

- `docs/18-SECURE-CODING-AND-SDLC.md`
- `docs/19-AGENTIC-AI-SECURITY-REQUIREMENTS.md`
- `docs/20-SECURITY-VERIFICATION-AND-RELEASE-GATES.md`
- `security/standards-baseline.yaml`

## Required development behavior

- Do not commit feature/implementation changes directly to protected `main`.
- Use a pull request and obtain human review after the final source change.
- Treat all external/model/tool/generated content as untrusted.
- Do not weaken default deny, approval binding, single-broker execution, idempotency, audit/evidence, redaction, or zero-side-effect replay.
- Do not add dynamic policy scripting, shell execution, arbitrary caller-selected adapter URLs, or executable workflow-pack plugins without a new accepted ADR and security review.
- Run all required quality/security gates before requesting merge.
- Never commit credentials or sensitive production data.

AI coding assistants and autonomous coding agents may propose code, tests, or documentation, but they do not receive authority to approve their own changes, waive findings, alter security requirements, or bypass required checks.
