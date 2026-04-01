---
description: Reply to GitHub review comments with optional @mention
allowed-tools: Bash(gh:*), Bash(git:*), Read
argument-hint: <review-comment-URL> [@mention-user]
---

# レビューコメントへの返信

GitHub PRのレビューコメントに対して適切な返信を作成・投稿します。
複数の未返信コメントがある場合はまとめて一括処理します。

## 引数

`$ARGUMENTS` から以下を解析:
- レビューコメントURL: `https://github.com/{owner}/{repo}/pull/{pr_number}#discussion_r{comment_id}`
- メンションユーザーID（オプション）: `@gemini-code-assist` 等

## 手順

### 1. URL・引数解析

1. URLから `owner`, `repo`, `pr_number`, `comment_id` を抽出
2. `@` で始まる文字列をメンションユーザーIDとして抽出

### 2. コメント情報の取得

1. 指定されたコメントの詳細を取得:
   `gh api repos/{owner}/{repo}/pulls/comments/{comment_id}`
2. PR内の全コメントを取得:
   `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate`
3. PR内の全レビューを取得:
   `gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews`

### 3. 未返信コメントの特定

1. `in_reply_to_id` フィールドでスレッド構造を構築
2. メンションユーザーが指定されている場合:
   - そのユーザーのトップレベルコメント（`in_reply_to_id` が null）を全て取得
   - 各コメントのスレッドを確認し、まだ返信がないものを対象とする
3. メンションユーザーが指定されていない場合:
   - 指定された `comment_id` のコメント単体を対象とする

### 4. 対象コードの確認

各コメントについて:
1. `path` から対象ファイルを特定
2. `diff_hunk` から変更内容を把握
3. ローカルにファイルがあれば Read ツールで確認
4. コメントの指摘内容を理解

### 5. 返信内容の生成

各コメントに対して:
1. 指摘内容を分析（validate-review と同様の妥当性評価）
2. 適切な返信を日本語で作成:
   - 妥当な指摘の場合: 修正する旨を記載、修正内容を説明
   - 非妥当な指摘の場合: 理由を丁寧に説明
   - 部分的に妥当な場合: 同意する部分と異なる見解を説明
3. メンションユーザーが指定されている場合は返信本文の先頭に `@user` を含める

### 6. 返信投稿

各コメントに対して返信を投稿:
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -X POST \
  -f body="返信内容" \
  -F in_reply_to={comment_id}
```

複数コメントがある場合はそれぞれに返信を投稿し、処理結果を一覧で報告。

### 7. 結果報告

```
## 返信結果

- [コメント1のファイル:行番号] → 返信済み
- [コメント2のファイル:行番号] → 返信済み
...

合計: N件の返信を投稿しました
```

## エラーハンドリング

- URLが不正な場合: 正しい形式を案内
- コメントが見つからない場合: コメントIDの確認を促す
- 返信投稿に失敗した場合: エラーメッセージを表示し、権限を確認
- `positioning` エラーが出た場合: `in_reply_to` パラメータの使用を確認
