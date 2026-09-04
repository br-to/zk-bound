# Architecture notes

This document describes the expected system boundaries without selecting a
technology prematurely.

## Conceptual flow

1. The owner defines a permission policy outside the agent's control.
2. The system commits to that policy and makes the commitment available to the
   execution boundary.
3. The agent proposes a wallet action.
4. A prover produces evidence that the action satisfies the committed policy.
5. The verifier checks the evidence and binds it to the exact execution context.
6. The wallet executes only after successful verification.

## Candidate components

- **Policy representation** — the constraints the owner delegates.
- **Policy commitment** — a stable reference to the policy without necessarily
  exposing all policy data.
- **Action representation** — the normalized operation to authorize.
- **Prover** — produces the policy-compliance proof.
- **Verifier** — validates the proof and its public inputs.
- **Execution adapter** — enforces verification before wallet execution.
- **Owner controls** — create, replace, revoke, or expire permissions.

These are logical boundaries, not a required package layout.

## Security invariants to preserve

- The agent cannot change the policy commitment accepted by the wallet.
- A proof for one action, account, chain, policy, or validity window cannot be
  reused for another.
- The system fails closed when proof verification or context validation fails.
- Policy updates and revocations require owner authority.
- Private policy data is not leaked through public inputs, logs, errors, or test
  fixtures beyond the privacy guarantee the project explicitly chooses.
- No off-chain success response can bypass the on-chain or execution-boundary
  check.

## Open architecture decisions

- target chain and account abstraction model;
- first supported action and policy shape;
- proving system and circuit language;
- policy commitment construction;
- nonce and replay-protection design;
- policy update and emergency revocation path;
- boundary between on-chain and off-chain validation;
- development, test, and demo environments; and
- monorepo or multi-repository layout.

Each selection must state its threat-model assumptions and be captured in
[`docs/decisions`](../decisions/README.md).
