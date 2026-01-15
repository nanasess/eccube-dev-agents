# タスクコマンドのアーカイブ

このコマンドは、完了したタスクコマンドファイルを `.claude/commands/active/` から `.claude/commands/archive/` に移動します。

## 概要

タスクが完全に完了した後、`active/` ディレクトリを整理するために使用します。アーカイブされたファイルは日付プレフィックス付きで保存され、後から参照可能です。

## 手順

1. **対象ファイルの特定**:
   - `$ARGUMENTS` が指定されている場合: そのファイル名を使用
   - `$ARGUMENTS` がない場合:
     - `.claude/commands/active/` 内のファイル一覧を表示
     - 進捗が100%のファイルをハイライト表示
     - ユーザーに選択を促す

2. **完了状態の確認**:
   - ファイル内のチェックボックスを解析
   - 全タスクが完了しているか確認
   - 未完了タスクがある場合は警告を表示し、確認を求める

3. **アーカイブディレクトリの準備**:
   - `.claude/commands/archive/` が存在しない場合は作成（`mkdir -p`）

4. **ファイルの移動**:
   - ファイル名に年月プレフィックスを追加
   - 例: `issue-572-implement.md` → `2026-01-issue-572-implement.md`
   - `active/` から `archive/` に移動

5. **アーカイブ完了を報告**:
   - 移動前のパス
   - 移動後のパス
   - アーカイブ後の参照コマンド（例: `/archive:2026-01-issue-572-implement`）

## 引数

`$ARGUMENTS` (オプション) - アーカイブするファイル名（例: `issue-572-implement.md`）

## 使用例

```bash
# ファイル名を指定してアーカイブ
/archive-task-command issue-572-implement.md
# → .claude/commands/archive/2026-01-issue-572-implement.md に移動

# ファイル名を省略（一覧から選択）
/archive-task-command
```

## 出力例

```
## アーカイブ完了

タスクコマンドをアーカイブしました:

| 項目 | 内容 |
|------|------|
| 移動前 | `.claude/commands/active/issue-572-implement.md` |
| 移動後 | `.claude/commands/archive/2026-01-issue-572-implement.md` |
| 参照コマンド | `/archive:2026-01-issue-572-implement` |

### アーカイブ時点の進捗
- 総タスク数: 15
- 完了: 15 (100%)

### active/ の残りファイル
- `feature-oauth-integration.md` (進捗: 60%)
- `fix-cart-calculation.md` (進捗: 80%)
```

## アーカイブされたファイルの参照

アーカイブ後も、以下のコマンドで参照可能です:

```bash
# アーカイブされたタスクを表示
/archive:2026-01-issue-572-implement status

# アーカイブ一覧を表示
ls .claude/commands/archive/
```

## 注意事項

- 未完了タスクがある場合でも強制アーカイブは可能ですが、確認を求めます
- アーカイブ後のファイルは編集可能ですが、通常は読み取り専用として扱います
- 誤ってアーカイブした場合は、手動で `archive/` から `active/` に戻すことができます
