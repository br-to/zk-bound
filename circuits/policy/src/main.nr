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
    account: pub Field,
    target: pub Field,
    value: pub Field,
    calldata_hash: pub Field,
    nonce: pub Field,
    expiry: pub Field,
) {
    assert(compute_policy_commitment(max_value, allowed_target, policy_salt) == policy_commitment);
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
