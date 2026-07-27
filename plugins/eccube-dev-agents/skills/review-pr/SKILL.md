---
description: Review a GitHub PR and present an inline-comment draft without posting
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob, Write
argument-hint: <PR-URL または PR番号> [追加観点]
---

# PR レビュー（投稿しないドラフト作成）

GitHub PR をレビューし、**個別インラインコメントのドラフト**を作成して提示します。

## 最重要ルール

**この Skill は GitHub へ一切投稿しない。**

- `gh pr review`、`gh api --method POST .../reviews`、`gh api --method POST .../comments`、`gh pr comment` を実行してはならない。
- 読み取り専用の `gh` 呼び出し（`gh pr view` / `gh pr diff` / `gh api` の GET）のみ使用する。
- 投稿は利用者がドラフトを確認したうえで `/post-review` を実行したときにのみ行われる。
- 利用者から「そのまま投稿して」と言われた場合も、この Skill 内では投稿せず `/post-review` に引き継ぐ。

## 引数

`$ARGUMENTS` から以下を解析:

1. **対象 PR**（いずれか）
   - URL: `https://github.com/{owner}/{repo}/pull/{number}`
   - 番号のみ: `6958`（カレントリポジトリの PR とみなす）
   - 省略: `gh pr view --json number,url` でカレントブランチに紐づく PR を特定。特定できなければ利用者に確認して終了
2. **追加観点**（自由記述、省略可）
   - 例: 「セキュリティを重点的に」「個人情報保護法・GDPR との兼ね合いもチェック」
   - 例: 「関連 issue の再現手順を確認して」
   - 例: 「`~/git-repos/stripe-payment-plugin` への影響調査もお願いします」
   - 追加観点は通常のレビュー観点に**上乗せ**する。指定されたものだけを見るのではない

## 手順

### 1. コンテキストの収集

```bash
# PR メタ情報（headRefOid = HEAD コミット SHA。ドラフトの commit_id に使う）
gh pr view {number} --repo {owner}/{repo} \
  --json number,title,body,author,baseRefName,headRefName,headRefOid,state,isDraft,mergeable,additions,deletions,changedFiles,labels,url

# 差分（ローカル git diff ではなくこれを使う）
gh pr diff {number} --repo {owner}/{repo}

# 既存レビュー・既存インラインコメント（重複指摘の回避）
gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[] | {user: .user.login, state, body: (.body[0:200])}'
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate \
  --jq '.[] | {user: .user.login, path, line, body: (.body[0:200])}'

# CI 状況
gh pr checks {number} --repo {owner}/{repo}
```

**関連 issue の確認**: PR 本文の `Closes #N` / `Refs #N` / `Fixes #N` や、利用者が提示した issue URL があれば `gh issue view N --repo {owner}/{repo} --comments` で本文とコメントを読む。issue に再現手順が書かれている場合は、それが PR の変更で解消されるかを差分から追う。

**既出指摘の除外**: CodeRabbit / Gemini Code Assist / 他レビュアーが既に指摘済みの内容は、ドラフトに重複して載せない。既に別 issue 化されているものも同様。

### 2. 差分の読解

差分だけで判断せず、変更されたファイルの前後関係を Read で確認する。以下は毎回見る観点:

- **正確性**: 分岐漏れ、null/未定義、境界値、例外経路、トランザクション境界
- **後方互換性**: 公開 API・エンティティ・テンプレート・イベント・設定キーの削除や意味変更
- **セキュリティ**: 入力検証、権限チェック、CSRF、XSS、SQL/コマンドインジェクション、パストラバーサル、機密情報のログ出力
- **影響範囲**: 変更されたメソッド・定数・設定の呼び出し元を `rg` で洗い出す（1 箇所ずつではなく全件まとめて）
- **テスト**: 変更に対応するテストの有無、テストが実際に退行を検出できるか
- **PR の記述と実装の一致**: 本文の説明どおりの変更になっているか

追加観点が指定されている場合は、その観点の調査もここで行う。

### 3. 検証（任意・必要と判断した場合のみ）

差分読解が主で、検証は必須ではない。ただし以下に該当する場合は実行を検討する:

- 指摘の成否が実行結果に依存する（「このコードは例外になる」等の断定をしたいとき）
- 関連 issue に再現手順があり、修正されたことを確かめたいとき
- CI が失敗しており、原因が PR 由来かベースブランチ由来かを切り分けたいとき

検証する場合の注意:

- **キャッシュを先に消す**。古いキャッシュは偽陽性・偽陰性の両方を生む
  - EC-CUBE 4系: `php bin/console cache:clear --no-warmup`、`rm -rf .phpunit.result.cache`
  - Symfony ルートキャッシュが残っていると、存在しないはずのルートが引ける／新ルートが 404 になる
- 実行コマンドはリポジトリの設定から決める（`composer.json` の scripts、`phpstan.neon*`、`.php-cs-fixer.dist.php`、`phpunit.xml.dist`、`package.json`）
- ベースブランチでも同じエラーが出るかを確認してから「この PR が壊した」と書く

### 4. 指摘の整理

各指摘に必ず次を持たせる:

| 項目 | 内容 |
|---|---|
| 重要度 | 高（マージ前に要対応） / 中（対応が望ましい） / 低（任意・好みの範囲） |
| 位置 | `path` と `line`、`side`（`RIGHT`=変更後 / `LEFT`=変更前） |
| 根拠 | `file:line` の引用、またはコマンド出力 |
| 検証状態 | `[VERIFIED]`（コマンド出力や実コードで確認済み） / `[ASSUMED]`（推論。要確認と明示） |

**根拠のない指摘はドラフトに載せない。** 「〜の可能性がある」で止まる推論は、`[ASSUMED]` を付けたうえで提示欄には出すが、投稿本文では断定形にしない。ファイル名・行番号・シンボル名は推測せず、実際に Read / `rg` で確認したものだけを書く。

### 5. コメント位置の決定

GitHub のレビュー API は**差分に含まれる行にしかインラインコメントを付けられない**。範囲外の行を指定すると投稿が 422 で失敗する。

`gh pr diff` の hunk ヘッダ `@@ -{旧開始},{旧行数} +{新開始},{新行数} @@` から、コメント可能な行を割り出す:

- **追加行 (`+`) / 文脈行 (空白始まり)** → `side: "RIGHT"`、`line` は**変更後ファイル**の行番号
- **削除行 (`-`)** → `side: "LEFT"`、`line` は**変更前ファイル**の行番号
- **複数行にまたがる指摘** → `start_line` + `start_side` と `line` + `side` を併用（同一 hunk 内に収める）
- **差分に現れない行への指摘** → インラインにできない。最も近い差分行に付けて本文中でその行に言及するか、サマリ（`body`）側に回す

行番号は目視で数えず、`gh pr diff` の hunk ヘッダから機械的に算出して確認する。

### 6. ドラフトの保存

scratchpad ディレクトリに `review-draft-{owner}-{repo}-{number}.json` として保存する（scratchpad が未設定なら `/tmp` 配下）。形式は GitHub のレビュー作成 API のリクエストボディそのもの:

```json
{
  "commit_id": "<PR の HEAD SHA>",
  "event": "COMMENT",
  "body": "レビュー全体のサマリ。何を見たか、全体評価、重点確認した観点を書く。",
  "comments": [
    {
      "path": "src/Eccube/Service/RefundRequestService.php",
      "line": 65,
      "side": "RIGHT",
      "body": "指摘本文（Markdown 可）"
    },
    {
      "path": "app/config/eccube/packages/eccube.yaml",
      "start_line": 56,
      "start_side": "RIGHT",
      "line": 59,
      "side": "RIGHT",
      "body": "複数行にまたがる指摘"
    }
  ]
}
```

`event` は判定案を入れる（`COMMENT` / `APPROVE` / `REQUEST_CHANGES`）。**`event` を省略すると PENDING レビューになり、PR ごとに 1 件しか持てない状態になるため、必ず設定する。**

指摘本文の書き方:

- 日本語。「何が」「なぜ問題か」「どう直すか」を順に書く
- 修正案があるコードは fenced code block または GitHub の `suggestion` ブロックで示す
- 断定できないことは「〜という認識ですが、いかがでしょうか」と質問形にする
- 相手の対応を確認したうえでの再レビューなら、冒頭に `@{author}` を付ける

### 7. 提示（投稿しない）

以下の形式で報告する:

```
## レビュー結果（未投稿）

対象: {owner}/{repo}#{number}「{title}」
      {author} / {base} ← {head} / {changedFiles} files +{additions} -{deletions}
CI: {pass/fail の要約}
既存レビュー: {重複を除外した件数など}

### 判定案: COMMENT（理由: 高 1 件・中 2 件のため要対応）

### インラインコメント案

**[1] 高 `src/Eccube/Service/RefundRequestService.php:65` (RIGHT)**
拡張子がクライアント申告値にフォールバックしている
- 根拠: [VERIFIED] `RefundRequestService.php:65` で `guessExtension() ?: $file->getClientOriginalExtension()`
- 本文案: （投稿する本文）

**[2] 中 `app/config/eccube/packages/eccube.yaml:56` (RIGHT)**
...

### サマリ（body）案
（投稿する body 本文）

### 除外した指摘
- CodeRabbit が #6529 で指摘済みのため除外: ...
- 根拠が取れなかったため除外: ...

### ドラフト
{ドラフト JSON のパス}

### 投稿するには
- そのまま全件: `/post-review`
- 判定を変える: `/post-review approve`
- 一部だけ: `/post-review approve 1,3`
- 「1 は無視して 2 だけ、approve で」のような自然言語の指示でも可
```

## 補足

- PR が draft / closed / merged の場合は、その旨を先に報告してから続行するか確認する
- 差分が巨大な場合はファイル単位で優先順位を付け、見ていない範囲を報告に明記する（黙って打ち切らない）
- ローカルの他リポジトリへの影響調査を指示された場合は、そのパスを Read / `rg` で確認し、影響の有無を根拠付きで報告する

## エラーハンドリング

- PR が特定できない: URL か番号の指定を促す
- `gh` 未認証: `gh auth login` を案内
- 対象リポジトリが手元に無く差分だけで判断が付かない: その旨を明記し、判断できた範囲のみをドラフトにする
