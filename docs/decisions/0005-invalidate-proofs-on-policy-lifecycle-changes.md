# ADR 0005: Invalidate proofs on policy lifecycle changes

- Status: accepted
- Date: 2026-09-06
- Deciders: maintainers

## Context

A proof is bound to a Safe-specific module nonce. Successful execution consumes
that nonce, so the same proof cannot normally be replayed.

Policy lifecycle transitions did not consume a nonce. Replacing a policy and
later restoring its previous commitment made an outstanding proof for that
commitment valid again. Revoking and reconfiguring the same commitment was more
direct: `configurePolicy` reset the nonce to zero, allowing a previously issued
nonce-zero proof to be submitted again.

Commitment matching alone is therefore insufficient to invalidate proofs across
the complete policy lifecycle.

## Decision

The module nonce is monotonic for the lifetime of each Safe/module pair.

- Initial configuration uses the storage-default nonce of zero.
- Every successful execution increments the nonce.
- `replacePolicy` increments the nonce, including when the new commitment is
  equal to the current commitment.
- `revokePolicy` increments the nonce before marking the policy inactive.
- Reconfiguration after revocation preserves the existing nonce and never resets
  it.

All lifecycle state changes and nonce increments remain atomic. If a Safe
transaction reverts, the nonce change reverts with it.

## Consequences

- Outstanding proofs are invalidated by replacement and revocation and cannot
  become valid again by restoring the same commitment.
- Provers must fetch the current module nonce after any policy lifecycle change.
- The public-input layout, circuit, verifier, commitment domain, and test vectors
  do not change.
- Existing integrations that assumed replacement preserves the nonce must update
  before submitting a proof for the replacement policy.

## Alternatives considered

Resetting the nonce on each configuration was rejected because a repeated
commitment can resurrect old proofs. Relying only on commitment changes was
rejected because commitments can intentionally or accidentally repeat. Adding a
separate policy generation public input was rejected because it would change the
circuit, verifier, SDK, and proof fixtures while providing the same replay
boundary already available through the nonce.

## References

- [Safe Module design](../architecture/safe-module.md)
- [Policy specification](../architecture/policy-spec.md)
- [Safe Module migration plan](../plans/0001-safe-module-migration.md)
- `contracts/src/ZkPolicySafeModule.sol`
- `contracts/test/ZkPolicySafeModule.t.sol`
