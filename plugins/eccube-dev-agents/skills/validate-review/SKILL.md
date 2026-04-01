---
description: Validate a GitHub review comment for correctness
allowed-tools: Bash(gh:*), Bash(git:*), Read
argument-hint: <review-comment-URL>
---

# レビューコメントの妥当性検証

GitHub PRのレビューコメントURLからコメント内容を取得し、対象コードを確認して指摘の妥当性を判断します。

## 手順

### 1. URL解析

`$ARGUMENTS` からレビューコメントURLを取得し、以下を抽出:
- URL形式: `https://github.com/{owner}/{repo}/pull/{pr_number}#discussion_r{comment_id}`
- `owner`, `repo`, `pr_number`, `comment_id` を正規表現で抽出
- `#discussion_r` 以降の数字がコメントID

### 2. コメント詳細の取得

`gh api repos/{owner}/{repo}/pulls/comments/{comment_id}` でコメント詳細を取得。

レスポンスから以下を抽出:
- `body`: コメント本文（指摘内容）
- `path`: 対象ファイルパス
- `diff_hunk`: 対象コードの差分
- `line` / `original_line`: 行番号
- `user.login`: コメント投稿者

### 3. 対象コードの理解

1. `path` から対象ファイルを特定
2. `diff_hunk` からコードの変更内容を把握
3. ローカルに対象ファイルが存在する場合は Read ツールで前後のコンテキストを確認
4. ファイルがローカルにない場合は `gh api repos/{owner}/{repo}/contents/{path}?ref={branch}` で取得
5. PR全体の変更内容も確認: `gh pr diff {pr_number} --repo {owner}/{repo}`

### 4. 妥当性判断

レビューコメントの指摘内容を以下の観点で評価:

- **コードの正確性**: 指摘されたコードに実際にバグや問題があるか
- **ベストプラクティス**: 指摘がコーディング規約やベストプラクティスに基づいているか
- **コンテキストの理解**: レビュアーがコードの文脈を正しく理解しているか
- **代替案の妥当性**: 提案された修正方法が適切か

### 5. 結果報告

以下の形式で日本語で報告:

```
## 判定: [妥当 / 非妥当 / 部分的に妥当]

### 指摘内容
<コメントの要約>

### 判定理由
<根拠の詳細な説明>

### 対応方針
<修正が必要な場合は具体的な方針を提案>
```

## エラーハンドリング

- URLが不正な形式の場合: 正しい形式を案内
- コメントが見つからない場合: コメントIDの確認を促す
- リポジトリへのアクセス権がない場合: `gh auth login` を案内
