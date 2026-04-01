---
description: Create an implementation plan as a checklist
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob
argument-hint: [issue-or-PR-URL]
---

# 実装計画の立案

現在のIssue/PRの内容やコードベースを分析し、実装計画をチェックリスト形式で生成します。

## 手順

### 1. コンテキスト収集

#### 引数に Issue/PR URL がある場合:
- `gh issue view <number> --repo {owner}/{repo}` または `gh pr view <number> --repo {owner}/{repo}` で内容を取得
- コメントも取得: `gh issue view <number> --comments` / `gh pr view <number> --comments`
- PRの場合は差分も確認: `gh pr diff <number> --repo {owner}/{repo}`

#### 引数がない場合:
- `git branch --show-current` で現在のブランチを確認
- ブランチ名からIssue番号を推定（例: `feat/123-xxx` → #123）
- `gh pr list --head <branch>` で関連PRを検索
- 会話のコンテキストから作業対象を推定

### 2. コードベース分析

1. プロジェクト構造の把握:
   - CLAUDE.md があれば Read で確認
   - 主要ディレクトリ構成を確認
2. 影響範囲の特定:
   - Issue/PRの要件から変更が必要なファイル/モジュールを特定
   - Grep/Glob で関連コードを検索
3. 既存パターンの確認:
   - 類似の実装がないか確認
   - 使用しているフレームワークの慣例を確認
4. 依存関係の分析:
   - 変更が他のコンポーネントに与える影響を評価

### 3. 計画生成

以下の形式で日本語の実装計画を生成:

```markdown
## 実装計画: <タイトル>

### 背景
<Issue/PRの要約、なぜこの変更が必要か>

### 実装手順
- [ ] Step 1: <具体的な作業内容> (`path/to/file`)
- [ ] Step 2: <具体的な作業内容> (`path/to/file`)
- [ ] Step 3: <具体的な作業内容> (`path/to/file`)
...

### テスト
- [ ] <テスト項目1>
- [ ] <テスト項目2>
...

### 考慮事項
- <注意点や潜在的なリスク>
- <依存関係や前提条件>
```

### 4. 計画の品質基準

- 各ステップは1つの明確なアクションに限定
- ファイルパスを必ず付記
- 依存関係の順序を考慮した並び
- テスト項目は具体的で実行可能な形式
- 既存の実装パターンを尊重した提案

## エラーハンドリング

- Issue/PRが見つからない場合: 番号やURLの確認を促す
- リポジトリ情報が取得できない場合: カレントディレクトリの確認を促す
- 要件が不明確な場合: ユーザーに追加情報を求める
