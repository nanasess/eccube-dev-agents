# GitHub Actions ログ解析

GitHub Actions の指定された job のログを解析し、失敗したテストを一覧表示します。

log-analyzerエージェントを使用して以下の手順でエラー解析を行ってください：

1. まず、引数から job ID を抽出する（例: 12345678910）
2. GitHub CLI を使用して job の詳細情報とログを取得する：
   - `gh api repos/:owner/:repo/actions/jobs/$ARGUMENTS`
   - `gh api repos/:owner/:repo/actions/jobs/$ARGUMENTS/logs`
3. 以下の情報を整理して表示する：
   - Job 名
   - 実行時間
   - 失敗した step
   - 全体的な実行ステータス
4. ログを解析して以下を抽出：
   - 失敗したテストケース（PHPUnit, Codeception, Jest など）
   - エラーメッセージ
   - 失敗理由（assertion failure, timeout, syntax error など）
5. 失敗したテストを以下の形式で一覧表示：
   ```
   ❌ テストクラス::テストメソッド
      エラーメッセージ
      ファイル:行番号
   ```
6. 可能であれば、エラーの原因と修正の提案も表示

job ID が指定されていない場合は、最新の failed workflow run の job 一覧を表示してください。
