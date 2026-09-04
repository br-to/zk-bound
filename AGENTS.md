# エージェント向け作業規約

このファイルは、本リポジトリで作業する全 coding agent の正本です。ツール固有の指示はここを参照できても、ここにあるセキュリティ要件を弱めてはいけません。

## ミッション

`zk-bound` は、AI agent が提案した Safe 操作を、owner が定義した秘密 policy に適合する proof がある場合だけ実行可能にする。暗号層は `zk-agent-guard` から再利用し、最終実行境界を `ZkPolicySafeModule` に移す。

agent は操作を提案できるが、policy を変更したり、proof 検証を迂回したり、Safe に任意の操作を実行させたりできてはならない。

## 作業開始時

1. `README.md` と本ファイルを読む。
2. 対象の `docs/`、承認済み ADR、関連する実行計画を読む。
3. `git status --short --branch` で作業ツリーを確認し、無関係な変更を保持する。
4. スコープまたは安全境界に影響する仮定は、編集前に明示する。

ファイルに近い場所の指示は追加要件にできるが、本ファイルの要件を緩和できない。

## 正本の場所

| 知識 | 場所 |
| --- | --- |
| プロダクトの意図・範囲 | `docs/product/` |
| 現在の設計 | `docs/architecture/` |
| 重要な意思決定 | `docs/decisions/` |
| 複数工程の作業計画 | `docs/plans/` |
| 開発・レビュー手順 | `docs/development/` |
| 現在の挙動 | 実装コードとテスト |

会話、prompt、issue、PR discussion は補助情報であり、将来も必要な結論は必ずリポジトリに残す。

## 実装ルール

- 要求を満たす最小かつ一貫した変更にする。未決定事項を依存パッケージや実装で既成事実化しない。
- policy 定義・policy enforcement は agent の権限外に置く。
- proof input、action encoding、Safe address、chain ID、nonce、expiry、revoke、失敗時の挙動を security-critical として扱う。
- authorization 境界は fail closed とする。検証失敗を warning や permissive fallback に変えない。
- 秘密鍵、secret、実 policy、機微な fixture を commit しない。例には明らかなダミー値だけを使う。
- 動作変更と無関係な大規模 refactor、format、dependency 更新を同じ変更に混ぜない。
- 生成済み `contracts/src/verifier/HonkVerifier.sol` は手で整形・編集しない。circuit を意図的に変更した場合のみ、固定 toolchain で生成し直す。

## ADR と計画

次の場合は実装と同じ PR に ADR を作る。

- security または trust assumption を変える。
- Safe version、proving system、chain、framework、主要 dependency を選ぶ。
- public interface、永続データ、proof／commitment／nonce／revoke の意味を変える。
- 後から戻すコストが高い。

`docs/decisions/0000-template.md` を使う。複数 component、migration、重要な security risk を含む作業は、`docs/plans/0000-template.md` を基に計画も作成・更新する。

## テストと検証

- 挙動と同じ layer にテストを書く。authorization では allow、policy violation、不正 input、context 改ざん、expiry、replay、依存先失敗を対象にする。
- 時刻、乱数、chain state、外部応答は可能な限り固定する。
- 検証前に `./scripts/check-repo.sh` と影響範囲の最小テストを実行する。circuit や verifier に触れた場合は固定 toolchain で広い検証も行う。
- 実行できない検証があれば、理由と未検証範囲を PR に明記する。

## Git とレビュー

- 小さくレビュー可能なコミットを作り、Conventional Commit (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`, `ci:`) を使う。
- ユーザーの無関係な変更を捨てたり、混ぜたり、履歴を書き換えたりしない。
- PR には問題、解決方法、security/privacy 影響、ADR／文書、検証結果、後続作業を記す。

## 完了条件

要求した挙動、関連テスト、repository check、現在の文書、必要な ADR／計画、secret がないこと、レビュー可能な PR のすべてを満たして完了とする。
