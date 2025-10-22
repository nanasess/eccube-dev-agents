# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

このリポジトリは **eccube-dev-agents** Claude Codeプラグインで、EC-CUBE/Symfony開発に最適化されていますが、汎用的な開発プロジェクトにも適用可能です。

## プラグインアーキテクチャ

### コアコンポーネント

1. **Specialized AI Agents** (`agents/`)
   - 各エージェントはYAMLフロントマター付きMarkdown形式で定義
   - `name`, `description`, `tools`, `model`, `color`パラメータを含む
   - エージェント本体は詳細なプロンプト指示で構成

2. **Custom Commands** (`commands/`)
   - スラッシュコマンドとして実行可能なMarkdownファイル
   - `$ARGUMENTS`変数を使用した動的パラメータ置換
   - 外部CLIツール（gemini, gh）との統合
   - 6つのコマンド: gemini-search, gemini, github-check, github-logs-analyze, generate-commit, update-pr-description

3. **Event Hooks** (`hooks/hooks.json`)
   - `Notification`と`Stop`イベントに対応
   - Gemini CLI、jq、curlを組み合わせたSlack通知パイプライン
   - 会話履歴の最新3メッセージを要約して通知

### エージェント設計パターン

各エージェントは以下の構造に従います：

```yaml
---
name: agent-name
description: "When to use this agent..."
tools: [tool1, tool2, ...]
model: sonnet|opus
color: blue|red|green|...
---

# Agent-specific prompt instructions
```

**重要な設計原則**：
- `description`フィールドには使用例を含める（`<example>`タグ）
- プロンプトは段階的な調査手順を明示（番号付きリスト）
- EC-CUBE/Symfony固有の知識を含める
- 常に日本語で結果を報告（全エージェント共通）

### コマンド設計パターン

スラッシュコマンドは以下のパターンを使用：

1. **外部ツール統合** (`gemini-search.md`)
   - Gemini CLIコマンド: `gemini`（PATHに含まれている必要があります）
   - WebSearch機能の活用

2. **GitHub CLI統合** (`github-check.md`)
   - エージェント連携（`implementation-analyzer`, `log-analyzer`）
   - `gh pr view`, `gh issue view`, `gh pr diff`コマンドの使用
   - 番号抽出ロジック（#450, PR #450形式）

3. **パイプライン処理** (`hooks/hooks.json`)
   - `jq`でJSON処理
   - Gemini CLIで要約生成
   - Slack Webhook経由で通知

## 開発ワークフロー

### プラグイン開発

このプラグイン自体を開発する場合：

1. **エージェント追加/変更**
   - `agents/`にMarkdownファイルを作成
   - YAMLフロントマターで設定を定義
   - プロンプトで調査手順を明記

2. **コマンド追加/変更**
   - `commands/`にMarkdownファイルを作成
   - `$ARGUMENTS`で動的パラメータを受け取る
   - 外部ツールのパスは絶対パスで指定

3. **フック設定**
   - `hooks/hooks.json`でイベントハンドラーを定義
   - 環境変数`SLACK_WEBHOOK_URL`が必要

### テストとデバッグ

```bash
# プラグイン構造の確認
ls -la .claude-plugin/
cat .claude-plugin/plugin.json

# Git状態の確認
git status
git log --oneline -5

# エージェント/コマンド定義の確認
cat agents/implementation-analyzer.md
cat commands/github-check.md
```

### 配布とインストール

このプラグインは **ネストされた構造** を使用しています：
- リポジトリルート: `.claude-plugin/marketplace.json` でマーケットプレイス設定
- プラグイン本体: `plugins/eccube-dev-agents/` サブディレクトリ内

```bash
# ローカルマーケットプレイス経由でのテスト
# リポジトリルートディレクトリを指定
claude plugin marketplace add /path/to/eccube-dev-agents
claude plugin install eccube-dev-agents

# GitHub経由での配布
# リポジトリを公開してGitHub URLでインストール可能
# claude plugin marketplace add nanasess/eccube-dev-agents
# claude plugin install eccube-dev-agents
```

## 技術的な重要事項

### 依存関係

- **Gemini CLI**: `gemini`コマンド（PATHに含まれている必要があります）
- **GitHub CLI**: `gh`コマンド（PR/Issue操作、API呼び出し）
- **jq**: JSON処理（フック内で使用）
- **curl**: Slack Webhook通知

### 環境変数

- `SLACK_WEBHOOK_URL`: Slack通知に必須

### ファイル形式

- **エージェント定義**: YAML frontmatter + Markdown本文
- **コマンド定義**: Markdown形式（変数展開対応）
- **フック定義**: JSON形式
- **プラグインメタデータ**: `.claude-plugin/plugin.json`

## Claude Codeとの統合

このプラグインは以下の方法でClaude Codeと統合されます：

1. **エージェント**: Task toolで`subagent_type`として指定
2. **コマンド**: `/command-name`形式でスラッシュコマンドとして実行
3. **フック**: `Notification`と`Stop`イベントで自動実行

プラグインが提供する機能は、ユーザーの`~/.config/claude/`設定に自動的に読み込まれます。
