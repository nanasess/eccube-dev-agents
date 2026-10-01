# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

このリポジトリは **eccube-dev-agents** Claude Codeプラグインです。Git ワークフロー自動化、GitHub レビュー管理、CI ログ分析の Skills を提供します。

## プラグインアーキテクチャ

### Skills (`plugins/eccube-dev-agents/skills/`)

各 Skill は `skills/<name>/SKILL.md` 形式で定義。YAML フロントマターに `description`, `allowed-tools`, `argument-hint` を含む。

提供する Skills:
1. **commit** - Conventional Commits 形式の日本語コミットメッセージ自動生成。複数リポジトリ対応
2. **commit-push-pr** - コミット + Push + PR作成の一括実行。PRテンプレート自動適用対応
3. **review-pr** - PR をレビューし、投稿せずにインラインコメントのドラフトを提示
4. **post-review** - 確認済みドラフトを個別インラインコメントとして投稿
5. **validate-review** - GitHub レビューコメントの妥当性検証（引数なし = 現在ブランチの PR の全コメント、PR URL 指定 = その PR の全コメント、コメント URL 指定 = 単一）。修正が妥当と確定できる指摘は修正・コミット・push・返信まで自動で進める
6. **reply-review** - 確認済み GitHub レビューコメントへの一括返信
7. **github-logs-analyze** - GitHub Actions 失敗ログの解析
8. **plan** - Issue/PR からチェックリスト形式の実装計画を生成

### レビュー系 Skill の設計原則

`review-pr` と `post-review` は「確認前に投稿しない」ことを構造で担保するために分離されている。統合や、`review-pr` への投稿処理の追加はこの担保を壊すため行わない。

- `review-pr`: GitHub への POST を一切行わない（読み取り専用の `gh` のみ）
- `post-review`: 同一会話内で `review-pr` が作成したドラフトのみを投稿対象とする
- 指摘には `file:line` の根拠と `[VERIFIED]` / `[ASSUMED]` を付け、根拠のないものはドラフトに載せない

`validate-review` → `reply-review` は、確認の要否で経路を分ける。

- `validate-review`: 引数なし / PR URL 指定では対象 PR のレビューコメントを全件検証し、判定と対応方針を一覧報告する。判定が「妥当」`[VERIFIED]` で修正方針が一意、かつ PR スコープ内の非破壊的な修正に限り、確認を待たずに修正 → 検証 → コミット → push → スレッドごとの返信まで自動で進める。それ以外（非妥当・部分的に妥当・判定保留・設計判断を伴うもの等）は手を付けず「要確認」として理由を報告する
- `reply-review`: 同一会話内で `validate-review` が確認したコメントのうち、自動対応で返信済みのものを除いた要確認コメントに、ユーザー確認後スレッドごと個別に返信する
- 「非妥当」への反論返信はレビュアーとの議論になるため自動投稿しない。自動対応の条件を緩める変更はこの担保を壊すので慎重に扱う

### Skill 設計パターン

```yaml
---
description: Skill の説明（/help に表示）
allowed-tools: Bash(git:*), Bash(gh:*), Read
argument-hint: [引数の説明]
---

# Skill のプロンプト本文
```

## 開発ワークフロー

### Skill の追加/変更

1. `plugins/eccube-dev-agents/skills/<name>/SKILL.md` を作成
2. YAML フロントマターで `description`, `allowed-tools` を定義
3. プロンプト本文に手順を記述

### テストとデバッグ

```bash
# プラグイン構造の確認
ls plugins/eccube-dev-agents/skills/*/SKILL.md
cat plugins/eccube-dev-agents/.claude-plugin/plugin.json

# プラグインの再インストール
claude plugin marketplace add /path/to/eccube-dev-agents
claude plugin install eccube-dev-agents
```

### 配布とインストール

ネストされた構造を使用:
- リポジトリルート: `.claude-plugin/marketplace.json` でマーケットプレイス設定
- プラグイン本体: `plugins/eccube-dev-agents/` サブディレクトリ内

```bash
# GitHub経由でインストール
claude plugin marketplace add nanasess/eccube-dev-agents
claude plugin install eccube-dev-agents

# ローカル開発
claude plugin marketplace add /path/to/eccube-dev-agents
claude plugin install eccube-dev-agents
```

## 技術的な重要事項

### 依存関係

- **GitHub CLI**: `gh` コマンド（PR/Issue操作、API呼び出し、CI ログ取得）

### ファイル形式

- **Skill 定義**: YAML frontmatter + Markdown 本文 (`skills/<name>/SKILL.md`)
- **プラグインメタデータ**: `.claude-plugin/plugin.json`
- **マーケットプレイス設定**: `.claude-plugin/marketplace.json`
