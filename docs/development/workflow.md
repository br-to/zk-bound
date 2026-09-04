# 開発ワークフロー

この手順は人間、Codex、Claude Code、その他の coding agent に共通です。

## 1. 文脈を確認する

- default branch から開始し、作業ツリーを確認する。
- `AGENTS.md`、対象文書、承認済み ADR、関連 plan を読む。
- 結果と、安全境界またはスコープを変えうる仮定を明確にする。

## 2. 変更を分類する

branch 名は `feat/<topic>`、`fix/<topic>`、`docs/<topic>`、`chore/<topic>` のいずれかを使う。実装前に、重要決定なら ADR、複数 component／migration／security risk を含むなら plan が必要かを判断する。

## 3. 小さな単位で実装する

- 挙動、テスト、それにより古くなる文書を同じ変更に含める。
- 関連チェック通過後に、意味のある単位で commit する。
- 無関係な format、dependency 更新、refactor を混ぜない。
- commit subject は Conventional Commit を使う。

## 4. 検証する

repository root で以下を実行する。

```sh
./scripts/check-repo.sh
```

続けて影響範囲の test と build を実行する。authorization 変更では successful path だけでなく、拒否・改ざん・context mismatch の case も確認する。

最終確認:

```sh
git status --short
git diff --check
git log --oneline --decorate -10
```

## 5. PR を作る

PR template に従い、問題、解決策、重要な tradeoff、security/privacy 影響、ADR／文書、実行した検証、既知の制限を記す。review 前に secret、無関係なファイル、debug output、local-only 設定がないことを確認する。
