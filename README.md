# eccube-dev-agents

Git ワークフロー自動化、GitHub レビュー管理、CI ログ分析の Skills を提供する Claude Code プラグイン。

## Skills

| Skill | 説明 | 使い方 |
|-------|------|--------|
| **commit** | Conventional Commits 形式の日本語コミットメッセージ自動生成 | `/commit` |
| **commit-push-pr** | コミット + Push + PR作成（PRテンプレート対応） | `/commit-push-pr` |
| **validate-review** | レビューコメントの妥当性検証 | `/validate-review <URL>` |
| **reply-review** | レビューコメントへの一括返信 | `/reply-review <URL> [@user]` |
| **github-logs-analyze** | GitHub Actions 失敗ログの解析 | `/github-logs-analyze <job-URL>` |
| **plan** | Issue/PR からチェックリスト形式の実装計画を生成 | `/plan [issue-URL]` |

### 特徴

- **複数リポジトリ対応**: 親ディレクトリから実行すると変更のあるサブリポジトリを自動検出
- **PRテンプレート対応**: `.github/pull_request_template.md` を自動検出・適用
- **ブランチ自動作成**: デフォルトブランチにいる場合に自動でフィーチャーブランチを作成
- **レビュー管理**: レビューコメントの妥当性検証と一括返信

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
