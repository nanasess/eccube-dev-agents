# 会話コンテキストの保存

このコマンドは、現在の会話内容と作業状況を指定ファイルにMarkdown形式で保存します。
コンテキストが限界に達した際に、`/clear` 前に使用することで作業の継続性を保ちます。

## 手順

1. **ファイル名の決定**:
   - `$ARGUMENTS` が指定されている場合: そのファイル名を使用
   - `$ARGUMENTS` がない場合:
     a. 現在の会話内容から作業内容を分析し、簡潔な英語のキーワード（2-4単語）を抽出
        例: "authentication-feature", "bug-fix-order", "refactor-payment"
     b. 現在時刻のタイムスタンプ（YYYYMMDDhhmm形式）を生成
     c. ファイル名を `<キーワード>-<YYYYMMDDhhmm>.md` の形式で生成
        例: `authentication-feature-202510301730.md`

2. **最近の会話から以下を抽出**:
   - **作業の目的・背景**: なぜこの作業を始めたのか
   - **現在の進捗状況**: どこまで進んでいるか
   - **発見事項・課題**: 実装中に判明した問題点や注意事項
   - **技術的な決定事項**: 採用した技術やアプローチ
   - **次のアクション**: これから何をする必要があるか

3. **Markdown形式で整形**:
   ```markdown
   # 作業コンテキスト

   保存日時: YYYY-MM-DD HH:MM:SS

   ## 作業概要
   [作業の目的と背景]

   ## 現在の状況
   [進捗状況と完了した内容]

   ## 発見事項
   [実装中に判明した問題点や注意事項]

   ## 技術的決定事項
   [採用した技術やアプローチ]

   ## 残りのタスク
   [未完了の作業と次に取り組むべきこと]

   ## 参考情報
   [関連ファイル、URL、その他の参考情報]
   ```

4. **ファイルに書き込み**:
   - `.ai-agent/sessions/` ディレクトリが存在しない場合は作成（`mkdir -p .ai-agent/sessions`）
   - 指定されたファイル名で `.ai-agent/sessions/` 以下に保存
   - 保存先: `.ai-agent/sessions/<ファイル名>`

5. **保存完了を報告**:
   - 保存したファイル名
   - 保存した内容の概要
   - 次のステップ（`/clear` の使用を提案）

## 引数

`$ARGUMENTS` (オプション) - 保存先ファイル名（例: `current-work.md`）

指定がない場合は、会話内容から作業を推測し、`<作業内容>-<YYYYMMDDhhmm>.md` 形式で自動生成されます。
例: `authentication-feature-202510301730.md`

## 使用例

```bash
# ファイル名を指定して保存
/save-context current-work.md
# → .ai-agent/sessions/current-work.md に保存

# ファイル名を省略（自動生成: 作業内容-タイムスタンプ.md）
/save-context
# 例: .ai-agent/sessions/authentication-feature-202510301730.md が生成される
```

## 実際のユースケース

```
1. コンテキストが残り少ない → `/save-context`
   → 自動生成: `.ai-agent/sessions/authentication-feature-202510301730.md`
2. `/clear` でコンテキストクリア
3. 新セッションで `/load-context authentication-feature-202510301730.md` で状況把握
4. 作業継続

または、明示的にファイル名を指定:
1. `/save-context my-important-work.md`
   → `.ai-agent/sessions/my-important-work.md` に保存
2. `/clear`
3. `/load-context my-important-work.md`
```

## 注意事項

- 既存のファイルが存在する場合は上書きされます
- 機密情報（パスワード、APIキーなど）は保存しないよう注意してください
- コンテキストファイルは定期的に整理することを推奨します
