---
description: Analyze GitHub Actions failure logs
allowed-tools: Bash(gh:*), Bash(git:*)
argument-hint: <job-URL-or-job-ID>
---

# GitHub Actions ログ解析

GitHub Actions の失敗ログを解析し、失敗したテストとエラー原因を特定します。

## 手順

### 1. 引数解析

`$ARGUMENTS` から job 情報を抽出:
- URL形式の場合: `https://github.com/{owner}/{repo}/actions/runs/{run_id}/job/{job_id}` から `owner`, `repo`, `job_id` を抽出
- 数字のみの場合: job ID として扱う
- owner/repo の特定:
  - URLから抽出できる場合はそれを使用
  - できない場合は `gh repo view --json nameWithOwner -q .nameWithOwner` でカレントリポジトリから取得

### 2. ジョブ情報取得

`gh api repos/{owner}/{repo}/actions/jobs/{job_id}` でジョブ詳細を取得:
- Job名
- 実行時間（started_at, completed_at）
- ステータス（conclusion）
- 各 step の名前とステータス
- 失敗した step を特定

### 3. ログ取得と解析

`gh api repos/{owner}/{repo}/actions/jobs/{job_id}/logs` でログを取得し解析:

#### テストフレームワーク別の失敗パターン検出:

**PHPUnit**:
- `FAILURES!` / `ERRORS!`
- `Tests: X, Assertions: Y, Failures: Z`
- `1) TestClass::testMethod`
- `Failed asserting that ...`

**Codeception**:
- `FAILURES!`
- `Couldn't ...` / `Failed ...`

**Jest**:
- `FAIL src/...`
- `● Test Suite > test name`
- `Expected ... Received ...`

**pytest**:
- `FAILED tests/...`
- `E       assert ...`

**一般的なエラーパターン**:
- `Error:` / `Exception:`
- `fatal:` / `panic:`
- タイムアウト: `timeout` / `exceeded`
- メモリ不足: `out of memory` / `Allowed memory size`

### 4. 結果表示

```
## Job 概要
- Job名: <name>
- 実行時間: <duration>
- 失敗 Step: <step name>

## 失敗テスト一覧

❌ TestClass::testMethod
   エラー: <エラーメッセージ>
   ファイル: <path>:<line>

❌ TestClass::testMethod2
   エラー: <エラーメッセージ>
   ファイル: <path>:<line>

## エラー原因の推定
<原因の分析と修正提案>
```

### 5. job ID 未指定の場合

1. `gh run list --status=failure --limit=5` で最新の失敗 run を表示
2. ユーザーに調査対象を選択してもらう
3. 選択された run の jobs を `gh run view {run_id} --json jobs` で取得
4. 失敗した job のログを解析

## エラーハンドリング

- job ID が見つからない場合: 正しい URL/ID 形式を案内
- ログが空または取得できない場合: run レベルのログ取得を試行
- リポジトリへのアクセス権がない場合: `gh auth login` を案内
