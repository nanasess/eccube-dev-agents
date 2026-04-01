---
description: Commit, push, and create a PR with template support
allowed-tools: Bash(git:*), Bash(gh:*), Bash(find:*), Read
argument-hint: [--repo owner/repo] [--base branch] [--draft]
---

# コミット・Push・PR作成

変更のコミット、リモートへのPush、Pull Request作成を一括で実行します。
PRテンプレートの自動検出・適用に対応。複数リポジトリの親ディレクトリからも実行可能です。

## 引数

`$ARGUMENTS` から以下を解析:
- `--repo` / `-R`: フォーク先リポジトリ（例: `upstream/repo`）
- `--base` / `-B`: ベースブランチ（デフォルト: main/master の自動検出）
- `--draft`: ドラフトPRとして作成
- その他のテキスト: PR作成の追加コンテキスト

## 手順

### 1. リポジトリ検出

1. `git rev-parse --is-inside-work-tree` でカレントディレクトリが git リポジトリか確認
2. git リポジトリの場合:
   - `git status --porcelain` で変更を確認
   - 変更がある場合はそのリポジトリで作業を続行
3. git リポジトリでない場合、または変更がない場合:
   - `find . -maxdepth 2 -name ".git" -type d` でサブディレクトリ内の git リポジトリを走査
   - 各リポジトリで `git -C <dir> status --porcelain` を実行して変更の有無を確認
   - 変更のあるリポジトリをリストアップ
4. 変更のあるリポジトリが複数の場合: 一覧を表示してユーザーに選択を求める
5. 変更のあるリポジトリがない場合: 「変更のあるリポジトリが見つかりません」と報告して終了

### 2. ブランチ確認・自動作成

1. `git -C <dir> branch --show-current` で現在のブランチを取得
2. デフォルトブランチ（main/master/develop）にいる場合:
   - 変更内容を分析してブランチ名を自動生成
   - Conventional Commits タイプとスコープから `feat/add-xxx`, `fix/resolve-yyy` 形式
   - `git -C <dir> checkout -b <branch-name>` で新ブランチ作成
3. 既にフィーチャーブランチにいる場合: そのまま続行

### 3. コミット

1. `git -C <dir> status` でステージング状態を確認
2. `git -C <dir> diff --staged` で変更内容を分析（ステージングがない場合は `git diff` を確認して追加を提案）
3. Conventional Commits v1.0.0 形式で日本語コミットメッセージを生成
4. HEREDOC 形式でコミット:
   ```bash
   git -C <dir> commit -m "$(cat <<'EOF'
   feat(scope): メッセージ本文

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

### 4. Push

1. `git -C <dir> push -u origin <branch>` でリモートにPush
2. Push失敗時はエラーメッセージを表示

### 5. PRテンプレート検出

対象リポジトリで以下の順に探索:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/PULL_REQUEST_TEMPLATE/` ディレクトリ内のファイル
4. `docs/pull_request_template.md`

テンプレートが見つかった場合:
- Read ツールでテンプレート内容を読み込む
- `##` 見出しでセクション構造を解析
- 各セクションに適切な内容を生成して埋める

### 6. PR説明の生成

#### テンプレートがある場合:
テンプレートのセクション構造を保持し、各セクションに適切な内容を生成:
- **Summary / 概要**: コミット履歴から変更の要約を生成
- **Changes / 変更内容**: 主要な変更点を箇条書きで記述
- **Test plan / テスト計画**: テスト項目のチェックリストを生成
- **Related issues**: コミットメッセージから関連Issue番号を検出
- その他のセクション: テンプレートの指示に従って記述

#### テンプレートがない場合:
```markdown
## Summary
<変更内容の要約を箇条書き>

## Changes
<主要な変更点の詳細>

## Test plan
<テスト方法のチェックリスト>
```

### 7. PR作成

1. ベースブランチの特定（引数 > リモートのデフォルトブランチ検出）
2. タイトル生成: コミットメッセージをベースに、Conventional Commits 形式を尊重
3. `gh pr create` を実行:
   ```bash
   gh pr create \
     --title "タイトル" \
     --body "$(cat <<'EOF'
   生成されたPR説明
   EOF
   )" \
     [--repo owner/repo] \
     [--base branch] \
     [--draft]
   ```
4. PR URLを表示

## エラーハンドリング

- **コミットがない**: ベースブランチとの差分がない場合は警告
- **Push失敗**: エラーメッセージを表示し、権限やネットワークの確認を促す
- **PR作成失敗**:
  - 認証エラー: `gh auth login` を案内
  - 既にPRが存在: 既存のPR URLを表示
  - リポジトリが見つからない: リポジトリ名の確認を促す
- **pre-commit hook 失敗**: 修正後に新しいコミットを作成（amend しない）
