# Security and Trust Boundaries

## 1. Security objective

The gateway must prevent an automated caller from converting authentication or model autonomy into unrestricted downstream authority.

The core rule is:

```text
AUTHENTICATED != AUTHORIZED
AUTHORIZED_FOR_ACTION_A != AUTHORIZED_FOR_ACTION_B
APPROVED_ONCE != APPROVED_FOREVER
```

## 2. Trust zones

### Zone A — automated caller

Examples: agent runtime, workflow service, automation job.

Assumed potentially compromised or behaviorally incorrect.

Must never be trusted to:

- choose its own effective policy;
- mint or widen its grant;
- mark an approval complete;
- select an unregistered executor;
- suppress audit events;
- rewrite durable evidence;
- directly receive administrative gateway credentials.

### Zone B — gateway enforcement boundary

Trusted to enforce the product contract, but still designed to fail closed and preserve evidence.

Contains:

- authentication verifier;
- grant evaluator;
- action catalog;
- deterministic policy engine;
- approval verifier;
- executor broker;
- audit/evidence writer.

### Zone C — trusted administrative/reviewer plane

Contains identities permitted to:

- publish policy bundles;
- register workflow packs/action definitions;
- issue or revoke workflow grants;
- approve pending actions;
- administer retention and enterprise settings.

Baseline v0.1 requires a reviewer identity to be distinct from the automated caller. Policy publisher, grant issuer, and reviewer may be separate identities in production deployments; the exact enterprise role model is deferred.

### Zone D — downstream systems

Downstream systems remain separate trust domains. The gateway does not assume their responses are truthful, safe, or idempotent unless their adapter contract establishes those properties.

## 3. Credential separation

At minimum, the system models distinct credential purposes:

1. caller credential — authenticates an actor to submit governed action requests;
2. grant-issuer credential — creates/revokes workflow grants;
3. reviewer credential — approves/rejects pending actions;
4. downstream adapter credential — held server-side for calls to one downstream target;
5. evidence-signing credential — optional/premium, never exposed to callers.

One secret must not automatically imply all roles.

## 4. Grant security

A grant is server-issued authority. Baseline constraints:

- random 128-bit-or-greater grant identifier;
- immutable after issuance except status/revocation metadata;
- tenant, workflow and actor bound;
- explicit allowed action set;
- explicit resource scope;
- issuance and expiration timestamps;
- empty allowed-action set means **deny all**;
- default lifetime 15 minutes;
- maximum lifetime 60 minutes unless a later ADR changes it;
- expired grants cannot be revived;
- widening requires a new grant.

## 5. Approval binding

An approval record binds to:

- `approval_id`;
- tenant/workflow/actor/action IDs;
- normalized request SHA-256;
- grant SHA-256;
- action-definition SHA-256;
- policy SHA-256;
- reviewer identity;
- decision;
- decision timestamp;
- expiry timestamp;
- consumption state.

Changing any bound input invalidates the approval.

## 6. Side-effect safety

For mutating actions:

- evidence preconditions must be durably recorded before downstream dispatch;
- one idempotency key is bound to one normalized request;
- key reuse with a different request is rejected;
- no automatic retry after timeout/connection loss once downstream execution might have occurred;
- an ambiguous result becomes `EXECUTION_OUTCOME_UNKNOWN` and requires explicit recovery logic defined by the workflow pack or human operator;
- the gateway must never invent a new idempotency key to force a second attempt.

## 7. Data minimization and redaction

The gateway persists control evidence, not uncontrolled payload archives.

Baseline rules:

- raw secrets are never written to audit events;
- authorization headers are never persisted;
- sensitive payload fields identified by the action's redaction profile are replaced before durable storage;
- request/result SHA-256 values may bind evidence without preserving cleartext;
- logs must not contain raw credentials or full sensitive request bodies;
- evidence exports use the same or stricter redaction profile as durable storage.

## 8. Policy security

Policy bundles are immutable-by-digest. The active pointer can change, but a recorded historical decision always references exact policy bytes by SHA-256.

The baseline policy engine:

- accepts only the closed grammar in `schemas/policy.schema.json`;
- rejects unknown operators/effects/fields;
- has no embedded scripting;
- has no network access;
- performs no model inference;
- is deterministic for identical inputs and policy bytes.

## 9. Workflow-pack security

A workflow pack is not trusted merely because it is installed.

Registration must validate:

- unique action names;
- schemas are resolvable;
- declared adapters exist;
- impact classes are valid;
- fact extraction is deterministic;
- redaction profiles are declared;
- no workflow pack can configure an alternate execution path around the broker.

## 10. Threats explicitly covered

- prompt/tool abuse causing unauthorized tool invocation;
- confused-deputy use of broad service credentials;
- actor self-escalation;
- approval replay;
- request substitution after approval;
- policy drift after approval;
- action-definition drift;
- idempotency-key abuse;
- silent downstream retry;
- audit-event deletion/modification detection;
- evidence replay causing side effects;
- workflow-pack bypass of the enforcement path.

## 11. Threats not solved by the baseline alone

- compromise of the host/OS running the gateway;
- compromise of the downstream service itself;
- malicious privileged database administrator with unrestricted storage access;
- hardware-root-of-trust guarantees;
- enterprise identity lifecycle/SCIM;
- jurisdiction-specific record-retention compliance.

Those require deployment and enterprise controls beyond the core design.
