---
description: Create a git commit with Conventional Commits message (Japanese)
allowed-tools: Bash(git:*), Bash(find:*)
argument-hint: [追加のコンテキスト]
---

# 自動コミットメッセージ生成

Conventional Commits v1.0.0 形式の日本語コミットメッセージを自動生成してコミットします。
複数リポジトリの親ディレクトリから実行した場合、変更のあるリポジトリを自動検出します。

## 手順

### 1. リポジトリ検出

1. `git rev-parse --is-inside-work-tree` でカレントディレクトリが git リポジトリか確認
2. git リポジトリの場合:
   - `git status --porcelain` で変更を確認
   - 変更がある場合はそのリポジトリで作業を続行
3. git リポジトリでない場合、または変更がない場合:
   - `find . -maxdepth 2 -name ".git" -type d` でサブディレクトリ内の git リポジトリを走査し、その親ディレクトリ（リポジトリルート）を特定
   - 各リポジトリルートで `git -C <dir> status --porcelain` を実行して変更の有無を確認
   - 変更のあるリポジトリをリストアップ
4. 変更のあるリポジトリが複数の場合:
   - 一覧を表示してユーザーに選択を求める
5. 変更のあるリポジトリがない場合:
   - 「変更のあるリポジトリが見つかりません」と報告して終了

### 2. ステージング確認

1. 対象リポジトリで `git -C <dir> status` を実行
2. `git -C <dir> diff --staged` でステージング済みの変更を確認
3. ステージングされたファイルがない場合:
   - `git -C <dir> diff` と `git -C <dir> status --porcelain` で未ステージの変更を表示
   - ユーザーに追加するファイルを確認
   - 承認後 `git -C <dir> add <files>` でステージング

### 3. 変更分析とコミットメッセージ生成

1. `git -C <dir> diff --staged` で変更内容を分析
2. Conventional Commits タイプを判定:
   - 新規ファイル追加: `feat:`
   - バグ修正: `fix:`
   - ドキュメント: `docs:`
   - リファクタリング: `refactor:`
   - テスト: `test:`
   - パフォーマンス改善: `perf:`
   - ビルド・依存関係: `build:`
   - その他: `chore:`
3. スコープを判定（影響を受けるファイル/ディレクトリから括弧付きで追加）
4. 破壊的変更がある場合は `!` を追加
5. 日本語でメッセージ本文を作成
6. `$ARGUMENTS` に追加コンテキストがあれば考慮する

### 4. コミット実行

HEREDOC 形式でコミットメッセージを渡す:
```bash
git -C <dir> commit -m "$(cat <<'EOF'
feat(scope): メッセージ本文

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 5. 結果確認

`git -C <dir> log --oneline -1` でコミット結果を表示して成功を確認。

## エラーハンドリング

- ステージングされたファイルがない場合: ユーザーに通知してファイルのステージングを提案
- コミットが失敗した場合: エラーメッセージを表示して解決策を提案
- pre-commit hook が失敗した場合: エラー内容を表示し、修正後に新しいコミットを作成（amend しない）
