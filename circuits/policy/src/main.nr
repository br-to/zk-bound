use std::hash::poseidon2_permutation;

/// keccak256("zk-agent-guard.policy.v1") mod BN254_Fr. Keep in sync with policy-sdk.
global POLICY_DOMAIN: Field = 0x07f63415ec1973fe9426f5373c7b20728b4867a4169844a224ba3e03c72ac95a;

/// Poseidon2 hashFixedLength matching `@zkpassport/poseidon2` / Aztec.
/// iv = (N << 64), rate = 3, t = 4.
fn poseidon2_hash<let N: u32>(input: [Field; N]) -> Field {
    let rate: u32 = 3;
    let iv: Field = (N as Field) * 18446744073709551616;
    let mut state: [Field; 4] = [0, 0, 0, iv];
    let mut cache: [Field; 3] = [0; 3];
    let mut cache_size: u32 = 0;

    for i in 0..N {
        if cache_size == rate {
            state[0] += cache[0];
            state[1] += cache[1];
            state[2] += cache[2];
            state = poseidon2_permutation(state);
            cache = [0; 3];
            cache[0] = input[i];
            cache_size = 1;
        } else {
            cache[cache_size] = input[i];
            cache_size += 1;
        }
    }

    state[0] += cache[0];
    state[1] += cache[1];
    state[2] += cache[2];
    state = poseidon2_permutation(state);
    state[0]
}

pub fn compute_policy_commitment(
    max_value: Field,
    allowed_target: Field,
    policy_salt: Field,
) -> Field {
    poseidon2_hash([POLICY_DOMAIN, max_value, allowed_target, policy_salt])
}

fn main(
    max_value: Field,
    allowed_target: Field,
    policy_salt: Field,
    policy_commitment: pub Field,
    chain_id: pub Field,
    account: pub Field, // Safe address (account == safe); name kept for compatibility
    target: pub Field,
    value: pub Field,
    calldata_hash: pub Field,
    nonce: pub Field,
    expiry: pub Field,
) {
    assert(compute_policy_commitment(max_value, allowed_target, policy_salt) == policy_commitment);
    // `as u128` truncates to the low 128 bits without constraining the high
    // bits away, so a Field >= 2^128 (e.g. `2^128 + x`) would silently compare
    // as `x`. Constrain both operands into u128 range first so the cast is
    // lossless and the comparison below is a true unsigned range check.
    value.assert_max_bit_size::<128>();
    max_value.assert_max_bit_size::<128>();
    assert((value as u128) <= (max_value as u128));
    assert(target == allowed_target);

    // Binding fields are public so the verifier can match execution args.
    // expiry is checked on-chain against block.timestamp, not here.
    let _ = chain_id;
    let _ = account;
    let _ = calldata_hash;
    let _ = nonce;
    let _ = expiry;
}

#[test]
fn poseidon2_matches_stdlib_five_inputs() {
    assert(
        poseidon2_hash([1, 2, 3, 4, 5])
            == 0x2247be7014a54d17342a7ef677f58d28877780d203860396967f5d0a18d259db,
    );
}

#[test]
fn poseidon2_three_inputs_locked() {
    assert(
        poseidon2_hash([1, 2, 3])
            == 0x23864adb160dddf590f1d3303683ebcb914f828e2635f6e85a32f0a1aecd3dd8,
    );
}

#[test]
fn allow_vector_commitment() {
    let max_value: Field = 1000000000000000000;
    let allowed_target: Field = 0x70997970c51812dc3a010c7d01b50e0d17dc79c8;
    let policy_salt: Field = 42;
    assert(
        compute_policy_commitment(max_value, allowed_target, policy_salt)
            == 0x10ab3b74faac7b7dbead3e6901e341220f41a0130935d19b3604b680eadd3026,
    );
}

#[test]
fn accepts_value_at_u128_max_boundary() {
    // u128::MAX. The largest value the range check may still accept.
    let max_value: Field = 340282366920938463463374607431768211455;
    let allowed_target: Field = 0x70997970c51812dc3a010c7d01b50e0d17dc79c8;
    let policy_salt: Field = 42;
    let policy_commitment = compute_policy_commitment(max_value, allowed_target, policy_salt);
    main(
        max_value, allowed_target, policy_salt, policy_commitment, 31337, 0x1, allowed_target,
        max_value, 0, 0, 2000000000,
    );
}

#[test(should_fail)]
fn rejects_value_at_two_pow_128() {
    // u128::MAX, i.e. 2^128 - 1.
    let max_value: Field = 340282366920938463463374607431768211455;
    let allowed_target: Field = 0x70997970c51812dc3a010c7d01b50e0d17dc79c8;
    let policy_salt: Field = 42;
    let policy_commitment = compute_policy_commitment(max_value, allowed_target, policy_salt);
    // 2^128. Under the old `(value as u128) <= (max_value as u128)` cast this
    // truncated to 0 and wrongly satisfied `value <= max_value`.
    let value: Field = 340282366920938463463374607431768211456;
    main(
        max_value, allowed_target, policy_salt, policy_commitment, 31337, 0x1, allowed_target,
        value, 0, 0, 2000000000,
    );
}

#[test(should_fail)]
fn rejects_max_value_at_two_pow_128() {
    // 2^128. A malicious policy commitment could not use this as max_value
    // without the explicit range constraint, since the truncating cast would
    // silently accept any value up to 2^128 - 1 on top of the real bound.
    let max_value: Field = 340282366920938463463374607431768211456;
    let allowed_target: Field = 0x70997970c51812dc3a010c7d01b50e0d17dc79c8;
    let policy_salt: Field = 42;
    let policy_commitment = compute_policy_commitment(max_value, allowed_target, policy_salt);
    let value: Field = 1;
    main(
        max_value, allowed_target, policy_salt, policy_commitment, 31337, 0x1, allowed_target,
        value, 0, 0, 2000000000,
    );
}
