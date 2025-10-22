# GitHub PR/Issue確認

  現在、$ARGUMENTSを対応中です。内容を確認してください。

  implementation-analyzerエージェントを使用して以下の手順で確認を行ってください：

  1. まず、引数からPR番号またはIssue番号を抽出する（例: #450, PR #450, Issue #123）
  2. GitHub CLIを使用して、PRまたはIssueの詳細情報を取得する：
     - PR の場合: `gh pr view <番号>`
     - Issue の場合: `gh issue view <番号>`
  3. 以下の情報を整理して表示する：
     - タイトル
     - 作成者
     - 現在の状態（open/closed/merged）
     - 説明/本文
     - ラベル
     - アサインされた人
  4. PRの場合は追加で以下も確認：
     - 変更されたファイルの一覧（`gh pr diff --name-only`）
     - レビューの状態
     - マージ可能かどうか
  5. 関連するコードやファイルがある場合は、それらも確認して要約を提供
  6. TODOリストがある場合は、現在どこまで進んでいて、どんな課題が残っているかを表示

  log-analyzerエージェントを使用してCI/CDの状態（checks）を確認してください:
  1. CI/CDが失敗している場合は、失敗した Job ID の一覧を表示( `gh run view <run-id>`で調査 )

  もし番号が指定されていない場合や、PRとIssueの区別が曖昧な場合は、両方試してみて存在する方を表示してください。
