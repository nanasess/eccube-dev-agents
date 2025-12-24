# よくあるエラーパターンと対処法

テストで頻出するエラーパターンとその診断・対処法をまとめています。

## PHP 8.3 型安全性エラー

PHP 8.3 では型チェックが厳格化され、以下のようなエラーが発生しやすくなっています。

### 典型的なメッセージ

| メッセージ | 原因 |
|-----------|------|
| `Expected argument of type "int", "null" given` | フォームで空文字送信 -> null 変換 |
| `Argument #1 ($id) must be of type int, null given` | Entity setter の型不一致 |
| `must be of type string, null given` | 非nullableなstring型に null |

### 診断方法

```php
// catchExceptions(false) で実際のエラーを確認
$this->client->catchExceptions(false);
$this->client->request('POST', $url, $formData);

// -> TypeError: Customer::setName01(): Argument #1 ($name01) must be of type string, null given
```

### 対処パターン

**パターン1: フォームデータの修正**

```php
// NG: 空文字を送信
'id' => '',

// OK: 正しい値を送信（編集時）
'id' => $Entity->getId(),

// OK: フィールド自体を削除（新規作成時）
// 'id' => '',  <- 削除
```

**パターン2: Entity の型宣言を修正**

```php
// Before: null を許容しない
public function setId(int $id): self

// After: null を許容する
public function setId(?int $id): self
```

## オブジェクトと配列の型不整合

### 症状

テストでオブジェクトをセッション等にセットしているが、実装は配列を期待している。

### 典型例

```php
// テストコード
$session->set(OrderHelper::SESSION_NON_MEMBER, new Customer());

// 実装コード (OrderHelper::getNonMember)
$data = $this->session->get($session_key);  // Customer オブジェクト
$Customer->setName01($data['name01']);       // オブジェクトに配列アクセス -> null
```

### PHP 8.x の挙動

- `$object['key']` のようなアクセスは `null` を返す
- Entity の setter が非 nullable 型を要求して TypeError

### 対処法

1. OSS版との Entity 型定義の差異を確認
2. setter を nullable に変更（例: `string` -> `?string`）
3. テストデータの形式を実装に合わせる

## DI バインディング不一致

### 症状

- エラーは発生しないが、期待した動作をしない
- バリデーションがスキップされる
- 処理が空振りする

### 典型例

```
Tests: 50, Assertions: 48, Errors: 3, Failures: 22
InvalidArgumentException: The current node list is empty.
```

### 診断方法

```php
// 処理フローにデバッグ出力を埋め込む
fwrite(STDERR, sprintf(
    "[DEBUG] flowType=%s, validatorsCount=%d\n",
    $this->flowType,
    $this->itemValidators->count()
));

// 出力例:
// [DEBUG] flowType=, validatorsCount=0
// -> バリデータが0個 = DI バインディングの問題
```

### 確認コマンド

```bash
# services.yaml のバインド定義を確認
grep -A 5 'bind:' app/config/eccube/services.yaml

# コントローラーの引数名を確認
grep -r 'PurchaseFlow \$' src/Eccube/Controller/
```

### 対処法

```php
// Before: バインド名と引数名が不一致
public function __construct(
    protected PurchaseFlow $purchaseFlow,
) {}

// After: バインド名に合わせる
public function __construct(
    protected PurchaseFlow $cartPurchaseFlow,
) {
    $this->purchaseFlow = $cartPurchaseFlow;
}
```

## 「システムエラーが発生しました」

### 症状

- Webテストが「システムエラーが発生しました」で失敗
- アサーションは「期待する文字列が含まれない」という形で報告される

```
Failed asserting that 'システムエラーが発生しました。...' contains "__RENDERED__"
```

### 診断方法

1. `$this->client->catchExceptions(false);` を追加
2. テストを再実行
3. 実際の例外を確認

### よくある原因

| エラータイプ | 原因例 |
|-------------|--------|
| TypeError | 型宣言の不一致（Union型の一部欠落など） |
| ArgumentCountError | 必須引数の不足 |
| RuntimeError | Twig レンダリング中の例外 |

### 実例

```
# 表面上のエラー
Failed asserting that 'システムエラーが発生しました...' contains "__RENDERED__"

# 実際の原因
TypeError: IgnoreTwigSandboxErrorExtension::twig_include():
Argument #3 ($template) must be of type array|string, Twig\TemplateWrapper given

# 原因: 型宣言から TemplateWrapper が削除されていた
# 修正: array|string|TemplateWrapper $template
```

## Doctrine 関連エラー

### UniqueConstraintViolationException

```
SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry
```

**原因**: 一意制約に違反するデータを挿入しようとした

**対処**:
- テストデータの重複を確認
- `setUp()` でのデータクリーンアップを確認

### ForeignKeyConstraintViolationException

```
SQLSTATE[23000]: Integrity constraint violation: 1451 Cannot delete or update a parent row
```

**原因**: 外部キー制約に違反する削除/更新

**対処**:
- 関連エンティティの削除順序を確認
- カスケード設定を確認

## テストの分離問題

### 症状

- 単体で実行すると成功するが、全体実行で失敗する
- 実行順序によって結果が変わる

### 診断方法

```bash
# 特定のテストだけ実行
vendor/bin/phpunit --filter "TestClassName::testMethodName"

# 順序を変えて実行
vendor/bin/phpunit --order-by=random
```

### 対処法

1. `setUp()` / `tearDown()` でのデータクリーンアップを確認
2. 静的変数やシングルトンの状態リセット
3. トランザクションロールバックの確認

## デバッグ出力のチェックリスト

| 確認項目 | 確認方法 | 期待値 |
|---------|---------|--------|
| 例外の詳細 | `catchExceptions(false)` | スタックトレース表示 |
| バリデータ数 | `$this->itemValidators->count()` | > 0 |
| フロータイプ | `$this->flowType` | `cart`, `shopping`, `order` |
| DI バインド名 | services.yaml vs コンストラクタ引数 | 一致 |
| 処理の到達 | `fwrite(STDERR, ...)` | 出力あり |
| フォームデータ | `error_log(print_r($form, true))` | 期待するデータ |
