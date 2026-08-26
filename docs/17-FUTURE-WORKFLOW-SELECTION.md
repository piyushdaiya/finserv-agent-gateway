# Future Workflow Selection Criteria

Status: **INFORMATIVE PRODUCT PLANNING**

The first real workflow should be selected after the generic governance kernel is implemented and independently assessed.

## Selection criteria

Score candidate workflows on:

1. **Agentic reality** — is there a genuine automated/agent action to govern, rather than forcing a gateway into a non-agentic system?
2. **Control value** — is unauthorized or duplicate execution meaningfully risky?
3. **Approval value** — is there a credible human approval boundary for some actions?
4. **Evidence value** — would audit/replay materially reduce investigation or compliance burden?
5. **Integration tractability** — can a bounded adapter be built without recreating the downstream product?
6. **Synthetic-testability** — can the workflow be proven with non-customer data?
7. **Commercial relevance** — would a bank/fintech platform, security, risk, or compliance team pay to govern this class of action?
8. **Generality** — does it exercise reusable gateway capabilities rather than one-off domain logic?

## Candidate examples

### Watchlist/sanctions review

Potentially strong where an agent is actually allowed to propose/commit case actions or invoke screening. Weak if the only system is non-agentic and the integration is invented solely to demonstrate the gateway.

### Customer onboarding/KYC

Potentially strong because agents may gather data, call vendors, update cases, request EDD, and submit recommendations. Must avoid becoming a full onboarding platform.

### Fraud investigation/case actions

Potentially strong if agents retrieve transaction context, enrich cases, update disposition fields, or request holds. Requires clear separation from the fraud engine itself.

### Payments/high-impact operations

Commercially strong but should come after the kernel is mature because ambiguity, duplicate execution, and approval failures can have direct financial impact.

## Decision rule

Do not select a workflow because an adjacent repository already exists. Select the workflow only when the automated action and governance value are real.
