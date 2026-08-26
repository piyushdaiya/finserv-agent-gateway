# Open Source vs Enterprise Boundary

## Principle

The Community edition must be useful enough to evaluate the actual security/control model. The open-source core must not be a demo shell whose meaningful enforcement is proprietary.

| Capability | Community | Enterprise |
|---|---:|---:|
| Single-path action mediation | Yes | Yes |
| Workflow-scoped grants | Yes | Yes |
| Deterministic policy engine | Yes | Yes |
| Deny-by-default | Yes | Yes |
| Action/workflow pack model | Yes | Yes |
| HTTP adapter SDK | Yes | Yes |
| Basic reviewer API/state machine | Yes | Yes |
| Correlation + idempotency | Yes | Yes |
| Redacted append-only audit events | Yes | Yes |
| Tamper-evident hash chain | Yes | Yes |
| Basic JSON evidence bundle | Yes | Yes |
| Offline replay/verifier CLI/API | Yes | Yes |
| Test-only conformance workflow | Yes | Yes |
| Example workflow packs | Yes | Yes |
| Multi-reviewer/separation-of-duty policies | Limited | Yes |
| SSO/SAML/OIDC enterprise admin integration | No | Yes |
| SCIM provisioning | No | Yes |
| Advanced approval UI/queues/delegation | No | Yes |
| External/WORM evidence anchors | No | Yes |
| Enterprise signing/HSM/KMS integration | No | Yes |
| SIEM/SOC connectors | Basic export | Yes |
| Retention/legal-hold policy management | No | Yes |
| Multi-tenant administrative console | No | Yes |
| Advanced policy simulation/CI packs | Limited | Yes |
| Commercial workflow/control packs | No | Yes |
| Managed implementation/support | No | Yes |

## Commercial thesis

Premium value should concentrate in enterprise identity, operations, evidence assurance, control administration, integration, and support—not in hiding the basic enforcement mechanism.
