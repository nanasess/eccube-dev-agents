# PR作成コマンド

このコマンドは、現在のブランチからPull Requestを作成します。
PRテンプレートが存在する場合は自動的に適用し、remoteとの同期状態を確認してからPRを作成します。

## 手順

1. 現在のブランチとgit状態を確認
2. remoteとの比較を行い、pushが必要な場合は確認
3. PRテンプレートの存在を確認（.github/pull_request_template.md など）
4. $ARGUMENTSからリポジトリ、ベースブランチを解析
5. ブランチの変更履歴を分析してPR説明を生成
6. PRテンプレートがある場合は、テンプレートの構造に沿って説明を生成
7. `gh pr create`でPRを作成

## 引数

$ARGUMENTS (オプション) - 以下の形式で指定可能：
- `--repo owner/repo` または `-R owner/repo`: フォーク先リポジトリを指定
- `--base branch` または `-B branch`: ベースブランチを指定（デフォルト: main/master）
- `--draft`: ドラフトPRとして作成
- その他のテキスト: PR作成の追加コンテキストとして使用

例:
- `--repo upstream/repo --base develop`
- `--draft`
- `-R upstream/repo -B main`

## 実装詳細

### 1. 初期確認

1. `git status` で現在の状態を確認
2. `git branch --show-current` で現在のブランチ名を取得
3. ブランチ名からベースブランチを推測（main/master/develop など）

### 2. Remote同期確認

1. `git rev-parse HEAD` でローカルの最新コミットを取得
2. `git fetch origin <branch>` でリモートの情報を更新し、`git rev-parse origin/<branch>` でリモートの最新コミットを取得（`git ls-remote origin <branch>` でも取得可能だが、出力からSHAを抽出する必要があるため、`git rev-parse`の方が直接的）
3. `git rev-list HEAD...origin/<branch>` でpush待ちのコミット数を確認
4. push待ちのコミットがある場合：
   - コミット一覧を表示
   - AskUserQuestion ツールでpushの確認を求める
   - 承認された場合のみ `git push -u origin <branch>` を実行

### 3. PRテンプレート確認

以下の場所を順番に確認：
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/PULL_REQUEST_TEMPLATE/` ディレクトリ内の各ファイル
4. `docs/pull_request_template.md`

テンプレートが見つかった場合：
- テンプレートの内容を読み込む
- テンプレートのセクション構造を解析（## で始まる見出し）
- 各セクションに適切な内容を生成して埋める

### 4. $ARGUMENTS解析

1. `--repo` または `-R` フラグからリポジトリを抽出
2. `--base` または `-B` フラグからベースブランチを抽出
3. `--draft` フラグの有無を確認
4. その他のテキストは追加コンテキストとして保持

### 5. 変更内容の分析

1. ベースブランチを特定（引数 > mainブランチの検出）
2. `git log <base>..HEAD --oneline` でコミット履歴を取得
3. `git diff <base>...HEAD` で変更内容を分析
4. `git diff <base>...HEAD --name-only` で変更ファイル一覧を取得

### 6. PR説明の生成

#### テンプレートがない場合：

デフォルトの構造で生成：
```markdown
## Summary
<変更内容の要約を箇条書きで記述>

## Changes
<主要な変更点を詳細に記述>

## Test plan
<テスト方法のチェックリスト>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

#### テンプレートがある場合：

テンプレートのセクション構造を保持し、各セクションに適切な内容を生成：
- **## Summary** / **## 概要**: コミット履歴から変更の要約を生成
- **## Changes** / **## 変更内容**: 主要な変更点を箇条書きで記述
- **## Test plan** / **## テスト計画**: テスト項目のチェックリストを生成
- **## Related Issues**: 関連するIssue番号を検出（コミットメッセージから）
- **## Screenshots**: 必要に応じて画像追加を促す
- その他のセクション: テンプレートの指示に従って記述

### 7. PR作成

1. タイトル生成：
   - 最新のコミットメッセージをベースにする
   - 複数コミットの場合は、変更内容を要約したタイトルを生成
   - Conventional Commits形式を尊重

2. `gh pr create` コマンド実行：
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

3. PR URLを表示

## エラーハンドリング

- **ブランチが存在しない**: エラーメッセージを表示し、`git branch -a`で利用可能なブランチを表示
- **コミットがない**: ベースブランチとの差分がない場合は警告
- **push失敗**: エラーメッセージを表示し、権限やネットワークを確認するよう促す
- **PR作成失敗**: GitHub CLIのエラーメッセージを表示
  - 認証エラー: `gh auth login` を案内
  - すでにPRが存在: 既存のPR URLを表示
  - リポジトリが見つからない: リポジトリ名を確認するよう促す

## 注意事項

- PRテンプレートは自動的に検出・適用されますが、カスタマイズが必要な場合は手動で編集してください
- ドラフトPRとして作成する場合は `--draft` フラグを使用してください
- フォークからのPRの場合は `--repo` フラグで上流リポジトリを指定してください
- ベースブランチが main/master 以外の場合は `--base` フラグで明示的に指定してください
