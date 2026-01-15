# タスクコマンドの作成

このコマンドは、具体的な実装計画を `.claude/commands/active/` にカスタムコマンドとして保存し、`/clear` 後もスラッシュコマンドで即座に呼び出せるようにします。

## 概要

通常の実装計画ファイル（`.ai-agent/plans/`）と異なり、このコマンドで作成されるファイルは **スラッシュコマンドとして直接実行可能** です。`$ARGUMENTS` による分岐処理も組み込まれるため、フェーズごとの作業再開や進捗確認が容易になります。

## 手順

1. **ファイル名の決定**:
   - `$ARGUMENTS` が指定されている場合: そのファイル名を使用
   - `$ARGUMENTS` がない場合: 会話内容から適切な英名を生成
     - Issue対応: `issue-{number}-implement.md`
     - 機能開発: `feature-{name}.md`
     - バグ修正: `fix-{name}.md`

2. **ディレクトリ構造の確認・作成**:
   ```
   .claude/commands/
   ├── active/      # 進行中のタスク（このコマンドの保存先）
   ├── archive/     # 完了したタスク
   └── templates/   # 再利用可能なテンプレート
   ```
   - `.claude/commands/active/` が存在しない場合は作成（`mkdir -p`）

3. **会話内容から実装計画を抽出**:
   - 実装の目的・概要
   - 必要な作業項目（フェーズ分け推奨）
   - 各項目の依存関係や順序
   - 参考となるコミットハッシュやファイルパス

4. **タスクコマンド形式で整形**:

   ```markdown
   # [タスク名] 実装計画

   ## 概要
   [実装の目的と概要を簡潔に記述]

   ## 使用方法

   ```bash
   # 進捗状況の確認
   /active:issue-xxx-implement status

   # Phase 1 から作業開始
   /active:issue-xxx-implement phase1

   # Phase 2 から作業再開
   /active:issue-xxx-implement phase2
   ```

   ## 進捗状況

   | Phase | 状態 | 説明 |
   |-------|------|------|
   | Phase 1 | ⏳ 未着手 | [説明] |
   | Phase 2 | ⏳ 未着手 | [説明] |
   | Phase 3 | ⏳ 未着手 | [説明] |

   ---

   ## 引数による分岐処理

   `$ARGUMENTS` の値に応じて以下の処理を実行:

   ### `status` - 進捗状況の確認
   現在の進捗状況を表示し、次に取り組むべきタスクを提案します。

   ### `phase1` - Phase 1 の実行
   [Phase 1 の詳細な作業手順]

   - [ ] タスク 1.1
   - [ ] タスク 1.2
   - [ ] タスク 1.3

   ### `phase2` - Phase 2 の実行
   [Phase 2 の詳細な作業手順]

   - [ ] タスク 2.1
   - [ ] タスク 2.2

   ### `phase3` - Phase 3 の実行
   [Phase 3 の詳細な作業手順]

   - [ ] タスク 3.1
   - [ ] タスク 3.2

   ---

   ## 参考情報

   - 関連 Issue: #xxx
   - 参考コミット: `git show <hash>`
   - 関連ファイル:
     - `path/to/file1.php`
     - `path/to/file2.php`

   ## 完了条件

   - [ ] 全てのタスクが完了
   - [ ] テストが通過
   - [ ] PR がマージ済み
   ```

5. **ファイルに書き込み**:
   - 保存先: `.claude/commands/active/<ファイル名>`
   - 実行コマンド: `/active:<ファイル名（拡張子なし）>`

6. **保存完了を報告**:
   - 保存したファイルパス
   - 実行コマンドの例
   - 作成されたフェーズ数とタスク数

## 引数

`$ARGUMENTS` (オプション) - ファイル名（例: `issue-123-implement.md`）

## 使用例

```bash
# ファイル名を指定して作成
/create-task-command issue-572-implement.md
# → .claude/commands/active/issue-572-implement.md に保存
# → /active:issue-572-implement で実行可能

# ファイル名を省略（自動生成）
/create-task-command
# 例: .claude/commands/active/feature-oauth-integration.md が生成される
# → /active:feature-oauth-integration で実行可能
```

## 既存の計画ファイルとの違い

| 項目 | `/create-plan` | `/create-task-command` |
|------|----------------|------------------------|
| 保存先 | `.ai-agent/plans/` | `.claude/commands/active/` |
| 実行方法 | `/load-plan` で読み込み | 直接スラッシュコマンドで実行 |
| 引数分岐 | なし | `$ARGUMENTS` で分岐可能 |
| 用途 | 単純な計画管理 | コンテキストクリア後の即座再開 |

## 注意事項

- 既存のファイルが存在する場合は、上書き前に確認します
- 完了したタスクは `/archive-task-command` で `archive/` に移動できます
- このコマンドは新規作成用です。進捗更新には `/update-task-progress` を使用してください
