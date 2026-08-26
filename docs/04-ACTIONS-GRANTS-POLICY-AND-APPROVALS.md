# Actions, Grants, Policy, and Approvals

## 1. Canonical action naming

Action names use:

```text
<namespace>.<verb>[.<qualifier>]
```

Constraints:

- lowercase ASCII letters, digits, `_` and `-` inside segments;
- dot-separated segments;
- 3 to 128 characters;
- no wildcard action may be submitted by a caller;
- wildcards may appear only in administrator-authored grant/policy patterns if explicitly supported by the schema.

Examples are illustrative only: `customer.read`, `case.update`, `payment.release`, `screening.execute`.

## 2. Impact classes

Every action definition has one immutable impact class per version:

| Class | Meaning |
|---|---|
| `I0_METADATA` | no domain read/write; metadata/status only |
| `I1_READ` | reads domain data but does not mutate domain state |
| `I2_REVERSIBLE_WRITE` | mutates domain state with a documented compensating/reversal path |
| `I3_HIGH_IMPACT` | material, irreversible, externally consequential, regulated, or explicitly high-risk action |

Impact class does not itself authorize execution. Policy consumes it as an input.

Data sensitivity is a separate, independent axis:

| Class | Meaning |
|---|---|
| `D0_PUBLIC` | intentionally public data |
| `D1_INTERNAL` | non-public internal/operational data |
| `D2_CUSTOMER_CONFIDENTIAL` | non-public customer/account/case/transaction data |
| `D3_RESTRICTED` | highly sensitive identifiers, authentication/secrets, full financial-account identifiers, or workflow-defined restricted data |

A non-mutating `I1_READ` may still be high-risk because of `D2`/`D3` disclosure.

## 3. Workflow start and grant issuance

The trusted grant issuer creates a workflow and grant using `workflow-start/v1`.

Required fields include:

- tenant ID;
- workflow type;
- trusted authority context: requesting principal, acting actor, authority source, and delegation chain;
- allowed actions;
- resource scope;
- allowed purposes;
- allowed destinations;
- data scope;
- quantitative authority bounds;
- policy bundle ID;
- expiry.

The server computes immutable hashes of normalized workflow/grant content.

## 4. Delegation and bounded authority

The trusted issuer, not the automated caller, establishes the authority context.

Delegation is intersection-only. A child grant/delegation may never broaden parent authority across tenant, workflow, action, resource, purpose, destination, data scope, numeric bounds, delegation depth, fan-out, or expiry.

Authority bounds include baseline counters/limits and a bounded map of workflow-defined integer limits. Monetary limits are represented in exact integer minor units or another workflow-defined integer unit; floating-point values are not security-authoritative.

## 5. Resource, purpose, destination, and data scope

Resource scope is a map of string keys to exact string values or arrays of strings. It is compared by the action/workflow pack's declared authorization projection.

Purpose and destination are explicit request dimensions and must fall within grant allowlists. Data scope independently constrains field/category entitlement, maximum sensitivity, record/byte bounds, and bulk-access permission.

Examples: `case_id`, `customer_id`, `account_id`, `region`.

Unknown required scope keys cause deny, not ignore.

## 6. Parameter-aware authorization and deterministic facts

A fact extractor produces a flat map with keys matching:

```text
^[a-z][a-z0-9_.-]{0,127}$
```

Values are string, boolean, signed integer, or unique string array.

Each action definition declares an `authorization_projection`: the resource keys and fact keys that are security-relevant, plus whether purpose and destination are required. Authorization of the action name alone is insufficient.

Facts are hashed and may be persisted if not classified sensitive. Sensitive low-entropy values use the keyed-commitment rules in `21-SENSITIVE-DATA-ACCESS-GOVERNANCE.md`; plain unsalted SHA-256 is not a confidentiality mechanism.

## 7. Policy grammar

A policy bundle contains ordered rules.

Each rule has:

- `rule_id`;
- `priority` integer;
- optional action pattern;
- optional impact-class set;
- optional data-sensitivity set;
- zero or more predicates over approved metadata/facts;
- effect;
- stable reason code.

Allowed effects:

- `ALLOW`;
- `DENY`;
- `REQUIRE_APPROVAL`.

Allowed predicate operators in v0.1:

- `EQ`;
- `NEQ`;
- `IN`;
- `NOT_IN`;
- `PRESENT`;
- `ABSENT`;
- `INT_GTE`;
- `INT_LTE`;
- `CONTAINS` for string arrays.

No regex, arbitrary scripting, code execution, network lookup, date arithmetic, or floating-point comparison in v0.1 policy predicates.

## 8. Rule evaluation

Rules are sorted by:

1. descending `priority`;
2. ascending `rule_id` lexical order as deterministic tie-breaker.

The first matching rule determines the effect.

If no rule matches:

```text
DENY / POLICY_DEFAULT_DENY
```

A malformed policy bundle is not partially evaluated; it is rejected at activation.

## 9. Approval lifecycle

```text
PENDING
  -> APPROVED
  -> CONSUMED

PENDING -> REJECTED
PENDING -> EXPIRED
APPROVED -> INVALIDATED   (bound state changed before consumption)
```

Only `APPROVED` may transition to `CONSUMED`, and only through successful enforcement immediately before one executor dispatch.

## 10. Revalidation after approval

Before consuming approval, the gateway must re-read and compare:

- grant active/expiry status;
- action-definition digest;
- policy digest;
- normalized request digest;
- tenant/workflow/principal/actor/delegation binding;
- authority-bound counters/limits;
- security-relevant resource/fact parameters;
- purpose/destination/data-access context;
- approval expiry and non-consumed state.

Any mismatch produces `APPROVAL_BINDING_MISMATCH` or a more specific deny code and performs zero downstream execution.

## 11. Human separation

Baseline invariant:

```text
reviewer_actor_id != requesting_actor_id
```

Future enterprise packs may require two-person approval or role separation beyond this minimum.
