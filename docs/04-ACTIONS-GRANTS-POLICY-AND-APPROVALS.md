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
| `I1_SENSITIVE_READ` | reads non-public/sensitive domain data but does not mutate domain state |
| `I2_REVERSIBLE_WRITE` | mutates domain state with a documented compensating/reversal path |
| `I3_HIGH_IMPACT` | material, irreversible, externally consequential, regulated, or explicitly high-risk action |

Impact class does not itself authorize execution. Policy consumes it as an input.

## 3. Workflow start and grant issuance

The trusted grant issuer creates a workflow and grant using `workflow-start/v1`.

Required fields include:

- tenant ID;
- workflow type;
- actor ID;
- allowed actions;
- resource scope;
- policy bundle ID;
- expiry.

The server computes immutable hashes of normalized workflow/grant content.

## 4. Resource scope

Baseline scope is a map of string keys to exact string values or arrays of strings. It is compared by the action/workflow pack's declared scope keys.

Examples: `case_id`, `customer_id`, `account_id`, `region`.

Unknown required scope keys cause deny, not ignore.

## 5. Deterministic facts

A fact extractor produces a flat map with keys matching:

```text
^[a-z][a-z0-9_.-]{0,127}$
```

Values are string, boolean, signed integer, or unique string array.

Facts are hashed and may be persisted if not classified sensitive. Sensitive fact values may be redacted while their normalized digest remains part of evidence.

## 6. Policy grammar

A policy bundle contains ordered rules.

Each rule has:

- `rule_id`;
- `priority` integer;
- optional action pattern;
- optional impact-class set;
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

## 7. Rule evaluation

Rules are sorted by:

1. descending `priority`;
2. ascending `rule_id` lexical order as deterministic tie-breaker.

The first matching rule determines the effect.

If no rule matches:

```text
DENY / POLICY_DEFAULT_DENY
```

A malformed policy bundle is not partially evaluated; it is rejected at activation.

## 8. Approval lifecycle

```text
PENDING
  -> APPROVED
  -> CONSUMED

PENDING -> REJECTED
PENDING -> EXPIRED
APPROVED -> INVALIDATED   (bound state changed before consumption)
```

Only `APPROVED` may transition to `CONSUMED`, and only through successful enforcement immediately before one executor dispatch.

## 9. Revalidation after approval

Before consuming approval, the gateway must re-read and compare:

- grant active/expiry status;
- action-definition digest;
- policy digest;
- normalized request digest;
- tenant/workflow/actor binding;
- approval expiry and non-consumed state.

Any mismatch produces `APPROVAL_BINDING_MISMATCH` or a more specific deny code and performs zero downstream execution.

## 10. Human separation

Baseline invariant:

```text
reviewer_actor_id != requesting_actor_id
```

Future enterprise packs may require two-person approval or role separation beyond this minimum.
