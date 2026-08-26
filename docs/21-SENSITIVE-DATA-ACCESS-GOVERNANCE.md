# Sensitive Data Access Governance

Status: **NORMATIVE**

## 1. Objective

FinServ Agent Gateway governs whether an automated actor may receive sensitive data, not merely whether sensitive values are masked after retrieval.

The core invariant is:

```text
AUTHORIZATION TO CALL A READ ACTION
    !=
AUTHORIZATION TO RECEIVE EVERY FIELD RETURNED BY THAT ACTION

DECLARED PURPOSE
    !=
AUTHORIZED PURPOSE

AUTHORIZED FOR DESTINATION_A
    !=
AUTHORIZED FOR DESTINATION_B
```

The gateway treats disclosure of sensitive information as a governed action even when no downstream system state is mutated.

## 2. Data-sensitivity axis

Action impact and data sensitivity are independent dimensions.

### Action impact

- `I0_METADATA` — metadata/status only; no domain read/write.
- `I1_READ` — reads domain data but does not mutate domain state.
- `I2_REVERSIBLE_WRITE` — mutates domain state with a documented compensating/reversal path.
- `I3_HIGH_IMPACT` — material, irreversible, externally consequential, regulated, or explicitly high-risk mutation.

### Data sensitivity

- `D0_PUBLIC` — intentionally public data.
- `D1_INTERNAL` — non-public operational or internal data.
- `D2_CUSTOMER_CONFIDENTIAL` — customer/account/case/transaction information that is non-public and requires business-purpose controls.
- `D3_RESTRICTED` — highly sensitive identifiers, authentication material, secrets, full financial-account identifiers, or workflow-defined restricted data.

A read may therefore be `I1_READ + D3_RESTRICTED`. Policy may require approval or deny that disclosure even though the action is non-mutating.

## 3. Trusted authority versus caller claims

Purpose, destination, resource, field, and quantitative access requests may be submitted by a caller, but they never create authority.

Trusted authority comes from server-issued grant state and authenticated identity/delegation context.

The gateway MUST verify:

- requesting principal;
- acting actor;
- delegation chain;
- allowed action;
- resource scope;
- allowed purpose;
- allowed destination;
- data scope;
- quantitative authority bounds;
- active policy and action definition.

Natural-language rationale, model output, tool output, RAG content, memory, or peer-agent messages cannot widen those values.

## 4. Field- and category-level scope

A grant's data scope can constrain:

- exact allowed fields;
- exact denied fields;
- allowed data categories;
- maximum sensitivity;
- maximum records per action;
- maximum bytes per action;
- whether bulk access is permitted.

Workflow packs map downstream schema fields to deterministic data categories and sensitivity classes.

Unknown fields or unknown classifications fail closed for governed disclosure.

For `D2` and `D3`, an empty field/category entitlement does not mean unrestricted access.

## 5. Purpose limitation

A workflow/grant declares an allowlist of purposes. Examples may include `fraud_case_review`, `customer_support`, or `compliance_review`, but the baseline defines no business-purpose vocabulary.

The submitted purpose:

- must be a canonical identifier;
- must be allowed by the active grant;
- must be available to deterministic policy;
- is included in request/approval/evidence binding;
- cannot be changed after approval without invalidating that approval.

Reuse for a different purpose requires a new authorized request.

## 6. Destination-aware disclosure

A grant and data-access profile can constrain destinations:

- `HUMAN_REVIEW_UI`
- `INTERNAL_SERVICE`
- `INTERNAL_AGENT_RUNTIME`
- `LOCAL_MODEL`
- `APPROVED_EXTERNAL_MODEL`
- `EXTERNAL_SERVICE`

Authorization to release data to one destination does not authorize another destination.

A workflow that sends customer-confidential or restricted data to an external model or service must explicitly authorize that destination and satisfy any workflow/deployment privacy controls.

## 7. Minimize before retrieval

The preferred enforcement order is:

```text
authorize requested fields/categories
 -> compute minimum required projection
 -> request only that projection from the source
 -> validate returned fields
 -> transform/mask/tokenize as required
 -> disclose only authorized result
```

Adapters MUST declare source projection capability:

- `REQUIRED`
- `PREFERRED`
- `UNAVAILABLE`
- `NOT_APPLICABLE`

When source-side projection is supported, a sensitive-data read MUST NOT use broad retrieval such as `SELECT *` or an equivalent full-record API request merely to redact after retrieval.

If a source requires overfetch for `D2` or `D3`, that behavior is explicit adapter/workflow risk and must be covered by tests and policy.

## 8. Bulk-access controls

Bulk access is denied by default unless a grant/profile explicitly permits it.

Quantitative controls may include:

- max records per action;
- max records per workflow;
- max bytes per action/workflow;
- max action count;
- max fan-out;
- domain-specific integer limits declared under authority bounds.

A broad action name never implies unbounded enumeration of tenant/customer data.

## 9. Sensitive-value commitments

Plain unsalted SHA-256 is not an adequate confidentiality mechanism for low-entropy sensitive values such as SSNs, dates of birth, ZIP codes, routing numbers, small enumerations, or predictable identifiers.

When evidence must prove equality/binding without retaining a sensitive value, the baseline uses a keyed commitment such as:

```text
HMAC-SHA-256(protected_evidence_key, canonical_sensitive_value)
```

The evidence key is not stored in ordinary audit events or exported bundles unless a separately designed protected verification profile requires it.

This does not replace encryption where retained sensitive data is necessary.

## 10. Audit without data leakage

Sensitive-data evidence SHOULD record control facts rather than raw values, including:

- principal and acting actor identities;
- delegation/authority-context digest;
- action/resource identifiers;
- requested/released/denied field counts and categories;
- maximum sensitivity;
- purpose;
- destination;
- records/bytes disclosed;
- source-side projection status;
- masking/tokenization/redaction indicators;
- grant, action-definition, policy, approval, and request digests.

Raw `D2`/`D3` payloads are excluded from audit events and evidence bundles by default.

A `DATA_DISCLOSED` event records that disclosure occurred without requiring storage of the disclosed value.

## 11. Storage and logs

- Logs never contain raw credentials or unredacted `D3` values.
- Durable control storage retains only data required for authorization, accounting, recovery, and evidence.
- Sensitive values are redacted, tokenized, encrypted, or represented by keyed commitments according to the workflow's data-access profile.
- Evidence export cannot be less restrictive than durable storage.
- Debug/trace modes cannot silently disable these rules.

## 12. Privacy-framework reference

The generic product does not claim blanket compliance with GLBA, GDPR, CCPA/CPRA, PCI DSS, or other jurisdiction/sector regimes.

The stable NIST Privacy Framework 1.0 is used as a privacy-risk design reference. NIST Privacy Framework 1.1 remains an Initial Public Draft as of the baseline date and is tracked but not treated as a final normative version.

Workflow/deployment profiles must perform their own legal/regulatory applicability analysis.
