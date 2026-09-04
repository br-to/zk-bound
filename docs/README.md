# ドキュメント

リポジトリ内の文書を、将来の作業に必要なプロジェクト文脈の正本とします。issue、PR、会話、agent session で決まった持続的な事項は、必ずここへ反映します。

## 構成

| 領域 | 内容 |
| --- | --- |
| [`product/`](product/project-brief.md) | プロダクトの意図、範囲、成功条件 |
| [`architecture/`](architecture/README.md) | system boundary、制約、未決事項 |
| [`decisions/`](decisions/README.md) | 承認済み・置換済み ADR |
| [`plans/`](plans/README.md) | 複数工程のアクティブな実行計画 |
| [`development/`](development/workflow.md) | 開発とレビューの手順 |
| [`security/`](security/threat-model.md) | 脅威モデルと security assumption |

## 文書のルール

1. 現在の事実を、該当する topic document に記載する。
2. 将来の実装を縛る決定と tradeoff は ADR に残す。
3. 複数 component、migration、security risk を含む作業は plan を作る。
4. 文書を古くした変更は、同じ PR で更新または削除する。
5. 同じ規約を複製せず、リポジトリ内の正本へリンクする。
