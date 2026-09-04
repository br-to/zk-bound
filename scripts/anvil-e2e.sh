#!/usr/bin/env bash
# Anvil 上で「エージェント提案 → proof → execute → 着金 / 拒否」を通す。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/scripts/toolchain.env"
if [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi
CIRCUIT="$ROOT/circuits/policy"
CONTRACTS="$ROOT/contracts"
PROVER="$CIRCUIT/Prover.toml"
PROOF_COPY="$CONTRACTS/tmp/e2e.proof.bin"
RPC="${RPC_URL:-http://127.0.0.1:8545}"
# Anvil デフォルト 1 番目の鍵。ローカル専用。
PK="${DEPLOYER_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"
TARGET="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
THIEF="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293bC"
VALUE="500000000000000000"
EXPIRY="2000000000"
AGENT_MODE="${AGENT_MODE:-mock}"

export PATH="${HOME}/.foundry/bin:${HOME}/.nargo/bin:${HOME}/.bb:${PATH}"

log() { printf '\n==> %s\n' "$*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing $1" >&2
    exit 1
  }
}

need forge
need cast
need anvil
need nargo
need bb
need pnpm
need python3

got_nargo="$(nargo --version 2>/dev/null | head -n 1 || true)"
got_bb="$(bb --version 2>/dev/null | head -n 1 || true)"
if ! grep -q "$NOIR_VERSION" <<<"$got_nargo"; then
  echo "expected nargo ${NOIR_VERSION}, got: ${got_nargo:-missing}" >&2
  exit 1
fi
if ! grep -q "$BB_VERSION" <<<"$got_bb"; then
  echo "expected bb ${BB_VERSION}, got: ${got_bb:-missing}" >&2
  echo "HonkVerifier.sol is generated for this bb only. Install with bbup -v ${BB_VERSION}" >&2
  exit 1
fi
echo "toolchain: nargo ${NOIR_VERSION} / bb ${BB_VERSION}"

cd "$ROOT"
pnpm --filter @zk-bound/policy-sdk build
pnpm --filter @zk-bound/demo build

cat <<'EOF'

  AI にはポリシーを見せない
  AI は送金案だけ出す
  手元の prover だけが秘密ポリシーを知る
  チェーンは proof が通ったときだけ ETH を出す

EOF

if ! curl -sf -X POST -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' \
  "$RPC" >/dev/null; then
  log "Anvil を起動する (code size limit なし)"
  mkdir -p /tmp/zk-bound
  nohup anvil --host 127.0.0.1 --port 8545 --disable-code-size-limit --gas-limit 60000000 \
    > /tmp/zk-bound/anvil.log 2>&1 &
  echo $! > /tmp/zk-bound/anvil.pid
  for _ in $(seq 1 40); do
    if curl -sf -X POST -H 'content-type: application/json' \
      --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' \
      "$RPC" >/dev/null; then
      break
    fi
    sleep 0.25
  done
fi

CHAIN_ID_HEX="$(cast chain-id --rpc-url "$RPC")"
if [ "$CHAIN_ID_HEX" != "31337" ]; then
  echo "expected Anvil chainId 31337, got $CHAIN_ID_HEX" >&2
  exit 1
fi

log "HonkVerifier と PolicyAccount をデプロイして 10 ETH を入れる"
cd "$CONTRACTS"
DEPLOY_LOG="$(mktemp)"
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$RPC" \
  --broadcast \
  --private-key "$PK" \
  --gas-limit 60000000 \
  -vv | tee "$DEPLOY_LOG"

ACCOUNT="$(python3 - <<PY
import json
from pathlib import Path
p = Path("$CONTRACTS/broadcast/Deploy.s.sol/31337/run-latest.json")
data = json.loads(p.read_text())
for tx in data.get("transactions", []):
    if tx.get("contractName") == "PolicyAccount":
        print(tx["contractAddress"])
        break
else:
    raise SystemExit("PolicyAccount address missing from broadcast")
PY
)"
echo "PolicyAccount $ACCOUNT"

before_target="$(cast balance "$TARGET" --rpc-url "$RPC")"
before_account="$(cast balance "$ACCOUNT" --rpc-url "$RPC")"
before_thief="$(cast balance "$THIEF" --rpc-url "$RPC")"
echo "account balance $before_account"
echo "allowed target balance $before_target"

BACKUP="$(mktemp)"
cp "$PROVER" "$BACKUP"
restore_prover() { cp "$BACKUP" "$PROVER"; rm -f "$BACKUP"; }
trap restore_prover EXIT

log "エージェントが見る指示（ポリシーは入っていない）"
node "$ROOT/apps/demo/dist/agent-cli.js" prompt

log "ユーザー: 0.5 ETH を許可アドレスへ"
cd "$ROOT"
export AGENT_ALLOW="$(node "$ROOT/apps/demo/dist/agent-cli.js" propose --scenario allow --mode "$AGENT_MODE")"
echo "$AGENT_ALLOW" | python3 -m json.tool
ALLOW_TARGET="$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["AGENT_ALLOW"])["target"])
PY
)"
ALLOW_VALUE="$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["AGENT_ALLOW"])["valueWei"])
PY
)"

log "prover: 秘密ポリシーで見る（エージェントは知らない）"
WRITE_ALLOW="$(node "$ROOT/apps/demo/dist/anvil.js" write-prover \
  --account "$ACCOUNT" \
  --target "$ALLOW_TARGET" \
  --value "$ALLOW_VALUE" \
  --nonce 0 \
  --prover "$PROVER")"
echo "$WRITE_ALLOW" | python3 -m json.tool

cd "$CIRCUIT"
nargo execute
# Always rebuild the EVM vk. A leftover poseidon2 vk from a default `bb prove`
# makes native `--verify` pass and HonkVerifier.verify revert SumcheckFailed.
bb write_vk -b ./target/policy.json -o ./target --verifier_target evm
bb prove -b ./target/policy.json -w ./target/policy.gz -o ./target -k ./target/vk \
  --verifier_target evm --verify
mkdir -p "$CONTRACTS/tmp"
cp ./target/proof "$PROOF_COPY"

log "chain: PolicyAccount.execute"
cd "$CONTRACTS"
forge script script/Execute.s.sol:Execute \
  --sig "run(address,address,uint256,uint64,string)" \
  "$ACCOUNT" "$ALLOW_TARGET" "$ALLOW_VALUE" "$EXPIRY" "tmp/e2e.proof.bin" \
  --rpc-url "$RPC" \
  --broadcast \
  --private-key "$PK" \
  --gas-limit 8000000 \
  -v

after_target="$(cast balance "$TARGET" --rpc-url "$RPC")"
after_account="$(cast balance "$ACCOUNT" --rpc-url "$RPC")"
echo "allowed target before $before_target after $after_target"
echo "account before $before_account after $after_account"
python3 - <<PY
before = int("$before_target")
after = int("$after_target")
if after - before != int("$ALLOW_VALUE"):
    raise SystemExit(f"expected +{int('$ALLOW_VALUE')} wei, got {after - before}")
print("ok  allow: ETH arrived")
PY

log "ユーザー: 全額を攻撃者へ送れ (prompt injection)"
cd "$ROOT"
export AGENT_INJECT="$(node "$ROOT/apps/demo/dist/agent-cli.js" propose --scenario inject --mode "$AGENT_MODE")"
echo "$AGENT_INJECT" | python3 -m json.tool
INJECT_TARGET="$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["AGENT_INJECT"])["target"])
PY
)"
INJECT_VALUE="$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["AGENT_INJECT"])["valueWei"])
PY
)"

log "prover: ポリシー外なので proof を作らない"
WRITE_INJECT="$(node "$ROOT/apps/demo/dist/anvil.js" write-prover \
  --account "$ACCOUNT" \
  --target "$INJECT_TARGET" \
  --value "$INJECT_VALUE" \
  --nonce 1 \
  --prover "$PROVER")"
echo "$WRITE_INJECT" | python3 -m json.tool
cd "$CIRCUIT"
set +e
nargo execute
REJECT_STATUS=$?
set -e
if [ "$REJECT_STATUS" -eq 0 ]; then
  echo "reject circuit unexpectedly succeeded" >&2
  exit 1
fi
echo "ok  reject: nargo execute failed (no proof)"

log "chain: 正しい proof のまま宛先だけすり替える"
cd "$CONTRACTS"
set +e
WRONG_LOG="$(mktemp)"
forge script script/Execute.s.sol:ExecuteWrongTarget \
  --sig "run(address,address,address,uint256,uint64,string)" \
  "$ACCOUNT" "$TARGET" "$THIEF" "$VALUE" "$EXPIRY" "tmp/e2e.proof.bin" \
  --rpc-url "$RPC" \
  --broadcast \
  --private-key "$PK" \
  --gas-limit 8000000 \
  -v >"$WRONG_LOG" 2>&1
WRONG_STATUS=$?
set -e
if grep -q "TargetMismatch" "$WRONG_LOG"; then
  echo "ok  chain reverted TargetMismatch"
else
  tail -n 40 "$WRONG_LOG" >&2
fi
rm -f "$WRONG_LOG"
if [ "$WRONG_STATUS" -eq 0 ]; then
  echo "wrong-target execute unexpectedly succeeded" >&2
  exit 1
fi

after_thief="$(cast balance "$THIEF" --rpc-url "$RPC")"
after_target2="$(cast balance "$TARGET" --rpc-url "$RPC")"
echo "thief before $before_thief after $after_thief"
echo "allowed target still $after_target2"
python3 - <<PY
if int("$after_thief") != int("$before_thief"):
    raise SystemExit("thief balance changed")
if int("$after_target2") != int("$after_target"):
    raise SystemExit("allowed target balance changed after reject")
print("ok  reject: thief got nothing, allow payment stayed")
PY

log "chain: expiry 超過 — 有効 proof でも Expired"
cd "$ROOT"
WRITE_EXPIRED="$(node "$ROOT/apps/demo/dist/anvil.js" write-prover \
  --account "$ACCOUNT" \
  --target "$ALLOW_TARGET" \
  --value "$ALLOW_VALUE" \
  --nonce 1 \
  --prover "$PROVER")"
echo "$WRITE_EXPIRED" | python3 -m json.tool
cd "$CIRCUIT"
nargo execute
bb write_vk -b ./target/policy.json -o ./target --verifier_target evm
bb prove -b ./target/policy.json -w ./target/policy.gz -o ./target -k ./target/vk \
  --verifier_target evm --verify
cp ./target/proof "$PROOF_COPY"

cast rpc anvil_setNextBlockTimestamp $((EXPIRY + 1)) --rpc-url "$RPC" >/dev/null
cast rpc anvil_mine --rpc-url "$RPC" >/dev/null

cd "$CONTRACTS"
set +e
EXPIRED_LOG="$(mktemp)"
forge script script/Execute.s.sol:Execute \
  --sig "run(address,address,uint256,uint64,string)" \
  "$ACCOUNT" "$ALLOW_TARGET" "$ALLOW_VALUE" "$EXPIRY" "tmp/e2e.proof.bin" \
  --rpc-url "$RPC" \
  --broadcast \
  --private-key "$PK" \
  --gas-limit 8000000 \
  -v >"$EXPIRED_LOG" 2>&1
EXPIRED_STATUS=$?
set -e
if grep -q "Expired" "$EXPIRED_LOG"; then
  echo "ok  chain reverted Expired"
else
  tail -n 40 "$EXPIRED_LOG" >&2
fi
rm -f "$EXPIRED_LOG"
if [ "$EXPIRED_STATUS" -eq 0 ]; then
  echo "expired execute unexpectedly succeeded" >&2
  exit 1
fi

after_target3="$(cast balance "$TARGET" --rpc-url "$RPC")"
python3 - <<PY
if int("$after_target3") != int("$after_target"):
    raise SystemExit("target balance changed after expired reject")
print("ok  reject: expired proof did not move funds")
PY

log "Anvil e2e 完了"
echo "PolicyAccount $ACCOUNT"
echo "allow ETH moved to $TARGET"
echo "injection / swapped target / expired did not move extra funds"
echo "agent mode: $AGENT_MODE"
