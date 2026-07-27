---
description: Post a reviewed draft to GitHub as individual inline comments
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write
argument-hint: [approve|comment|request-changes] [投稿する指摘番号 例: 1,3-4]
---

# レビュードラフトの投稿（個別インラインコメント）

`/review-pr` が作成したドラフトを、GitHub へ**個別インラインコメント**として投稿します。

## 最重要ルール

**同一会話内で `/review-pr` を実行して作成されたドラフトのみを投稿対象とする。**

- ドラフトが存在しない場合は「投稿対象のドラフトがありません。先に `/review-pr <PR-URL>` を実行してください」と報告して終了する
- この Skill 内で新たにレビュー内容を考え出して投稿してはならない。投稿するのは、利用者が目にしたドラフトと、利用者が指示した修正のみ
- 利用者が採否を指示していない指摘は、ドラフトに載っていたものをそのまま投稿する（勝手に追加・削除しない）

## 引数

`$ARGUMENTS` から以下を解析（すべて省略可）:

1. **判定**: `approve` / `comment` / `request-changes`
   - 省略時はドラフトの `event`（`/review-pr` の判定案）を使う
2. **投稿する指摘番号**: `1,3-4` のような指定
   - 省略時はドラフトの全件
   - 会話中の「1 は無視、2 だけ」「4 件独立コメントにして」「軽微なのでまとめて 1 コメントに」のような自然言語の指示も、同じ意味に解釈して反映する

## 手順

### 1. ドラフトの読み込み

scratchpad の `review-draft-{owner}-{repo}-{number}.json` を Read する。会話中に対象 PR が複数ある場合は、直近に `/review-pr` を実行したものを対象とし、投稿前の確認でその PR 番号を明示する。

### 2. 採否の反映

利用者の指示に従って `comments` 配列を組み替える:

- **除外**: 指定された番号の要素を削除する
- **まとめる**: 「1 コメントにまとめて」と指示された場合は、`comments` を空にして内容を `body` に統合する
- **分ける**: 「個別コメントにして」と指示された場合は、`body` にまとめていた内容を該当行ごとの `comments` 要素へ分解する
- **本文の修正**: 利用者が表現や結論を変更した場合はそれを反映する

`event` を決定する:

| 指示 | `event` |
|---|---|
| approve / LGTM / 承認 | `APPROVE` |
| change request / 要修正 | `REQUEST_CHANGES` |
| それ以外・指定なし | `COMMENT` |

**`event` は必ず設定する。**省略すると PENDING レビューになり、PR ごとに 1 件しか持てない状態のまま GitHub 上に未送信のレビューが残る。

### 3. 投稿前のセルフチェック

投稿コマンドを実行する前に、以下をすべて確認する:

1. **HEAD SHA が最新か**

   ```bash
   gh pr view {number} --repo {owner}/{repo} --json headRefOid --jq '.headRefOid'
   ```

   ドラフトの `commit_id` と異なる場合は、レビュー中に push されている。差分を取り直して行番号がずれていないか確認し、`commit_id` を最新に更新する。ずれが大きい場合は投稿せず、再レビューが必要な旨を報告する。

2. **各コメントの行が差分に含まれるか**

   `gh pr diff {number} --repo {owner}/{repo}` の hunk ヘッダから、`path` / `line` / `side` の組が差分範囲内にあることを確認する。範囲外の行は 422 で投稿全体が失敗する。

3. **`path` がリポジトリルートからの相対パスか**（先頭に `./` や絶対パスを含めない）

4. **自分自身の PR でないか**

   ```bash
   gh pr view {number} --repo {owner}/{repo} --json author --jq '.author.login'
   gh api user --jq '.login'
   ```

   自分の PR は `APPROVE` / `REQUEST_CHANGES` を投稿できない。一致する場合は `COMMENT` に切り替え、その旨を報告に含める。

5. **未送信の PENDING レビューが残っていないか**

   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[] | select(.state=="PENDING") | {id, user: .user.login}'
   ```

   自分の PENDING レビューがあれば `gh api --method DELETE repos/{owner}/{repo}/pulls/{number}/reviews/{review_id}` で削除してから投稿する。

6. **秘密情報が本文に混入していないか**（トークン、パスワード、`.env` の値、顧客データ）

### 4. 投稿

組み替え後の JSON を scratchpad に書き出し、それを `--input` で渡す。本文に日本語・改行・バッククォートを含むため、`-f body=...` ではなく必ずファイル入力を使う。

```bash
gh api --method POST repos/{owner}/{repo}/pulls/{number}/reviews \
  --input {scratchpad}/review-post-{owner}-{repo}-{number}.json \
  --jq '{id, state, html_url}'
```

追加で 1 件だけインラインコメントを足す場合（レビューを新規に作らない）:

```bash
gh api --method POST repos/{owner}/{repo}/pulls/{number}/comments \
  -f path='src/Foo.php' -F line=65 -f side='RIGHT' \
  -f commit_id='{HEAD SHA}' -f body='...'
```

### 5. 投稿結果の検証

投稿したレビュー ID を使い、意図した位置にコメントが付いたかを取得して確認する。

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '.[] | select(.pull_request_review_id=={review_id}) | {path, line, side, html_url}'
```

- コメント件数がドラフトと一致するか
- `path` / `line` がずれていないか（GitHub 側で近傍行に丸められることがある）
- レビュー本体の `state` が意図した判定になっているか

### 6. 結果報告

```
## 投稿結果

レビュー: {html_url}
判定: APPROVE / COMMENT / REQUEST_CHANGES

### 投稿したインラインコメント（N 件）
- src/Eccube/Service/RefundRequestService.php:65 (RIGHT) → {コメント URL}
- app/config/eccube/packages/eccube.yaml:56 (RIGHT) → {コメント URL}

### 投稿しなかった指摘
- [3] 別 issue で対応済みのため除外

### 検証
- コメント件数: ドラフト N 件 / 実際 N 件（一致）
- HEAD SHA: {sha}（投稿時点で最新）
```

## エラーハンドリング

| 症状 | 原因と対処 |
|---|---|
| `422 Unprocessable Entity` + `pull_request_review_thread.line` 系のメッセージ | 指定行が差分範囲外。`gh pr diff` で差分に含まれる行を確認し、`line` / `side` を修正する。修正できない指摘はサマリ（`body`）へ回す |
| `422` + `user can only have one pending review` | 未送信の PENDING レビューが残っている。手順 3-5 の方法で削除してから再投稿 |
| `422` + `Can not approve your own pull request` | 自分の PR。`event` を `COMMENT` に変更して再投稿 |
| `403` / `404` | 権限不足またはリポジトリ名の誤り。`gh auth status` と `--repo` の値を確認 |
| コメントが意図しない行に付いた | `commit_id` が古い可能性。該当コメントを `gh api --method DELETE repos/{owner}/{repo}/pulls/comments/{comment_id}` で削除し、最新 SHA で投稿し直す |

投稿が途中で失敗した場合は、**何件が投稿済みで何件が未投稿かを必ず報告する**。レビュー作成 API は全件が 1 トランザクションで、失敗時はレビュー自体が作成されないが、`pulls/{number}/comments` を個別に呼んでいた場合は部分投稿になり得る。
