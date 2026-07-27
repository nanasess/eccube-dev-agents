# eccube-dev-agents

Git ワークフロー自動化、GitHub レビュー管理、CI ログ分析の Skills を提供する Claude Code プラグイン。

## Skills

| Skill | 説明 | 使い方 |
|-------|------|--------|
| **commit** | Conventional Commits 形式の日本語コミットメッセージ自動生成 | `/commit` |
| **commit-push-pr** | コミット + Push + PR作成（PRテンプレート対応） | `/commit-push-pr` |
| **review-pr** | PR をレビューし、投稿せずにドラフトを提示 | `/review-pr <PR-URL> [追加観点]` |
| **post-review** | 確認済みドラフトを個別インラインコメントとして投稿 | `/post-review [approve] [1,3]` |
| **validate-review** | レビューコメントの妥当性検証 | `/validate-review <URL>` |
| **reply-review** | レビューコメントへの一括返信 | `/reply-review <URL> [@user]` |
| **github-logs-analyze** | GitHub Actions 失敗ログの解析 | `/github-logs-analyze <job-URL>` |
| **plan** | Issue/PR からチェックリスト形式の実装計画を生成 | `/plan [issue-URL]` |

### 特徴

- **複数リポジトリ対応**: 親ディレクトリから実行すると変更のあるサブリポジトリを自動検出
- **PRテンプレート対応**: `.github/pull_request_template.md` を自動検出・適用
- **ブランチ自動作成**: デフォルトブランチにいる場合に自動でフィーチャーブランチを作成
- **投稿ゲートの構造化**: レビュー（`review-pr`）と投稿（`post-review`）を別 Skill に分離し、確認前の投稿が起こらないようにする
- **個別インラインコメント**: 指摘は該当行ごとのインラインコメントとして投稿

### PR レビューの流れ

```
/review-pr https://github.com/EC-CUBE/ec-cube/pull/6958
  → 差分読解・（必要なら）検証 → ドラフトを提示（投稿しない）
     [1] 高 src/Eccube/Service/Foo.php:65 (RIGHT)
     [2] 中 app/config/eccube/packages/eccube.yaml:56 (RIGHT)
     判定案: COMMENT

「1 は別 issue 済みなので除外、2 だけで approve」

/post-review approve 2
  → gh api POST .../pulls/6958/reviews --input draft.json
  → 投稿結果を検証して報告
```

- 各指摘には `file:line` の根拠と `[VERIFIED]` / `[ASSUMED]` の検証状態を付ける
- 根拠のない指摘はドラフトに載せない
- `review-pr` は GitHub への POST を一切行わない

## 必要要件

- **GitHub CLI (gh)** - GitHub 統合に必須

## インストール

```bash
# GitHub からインストール
claude plugin marketplace add nanasess/eccube-dev-agents
claude plugin install eccube-dev-agents
```

### ローカル開発

```bash
git clone https://github.com/nanasess/eccube-dev-agents.git
claude plugin marketplace add /path/to/eccube-dev-agents
claude plugin install eccube-dev-agents
```

## 構造

```
eccube-dev-agents/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/eccube-dev-agents/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── commit/SKILL.md
│       ├── commit-push-pr/SKILL.md
│       ├── review-pr/SKILL.md
│       ├── post-review/SKILL.md
│       ├── validate-review/SKILL.md
│       ├── reply-review/SKILL.md
│       ├── github-logs-analyze/SKILL.md
│       └── plan/SKILL.md
├── CLAUDE.md
└── README.md
```

## ライセンス

MIT

## 作者

nanasess
