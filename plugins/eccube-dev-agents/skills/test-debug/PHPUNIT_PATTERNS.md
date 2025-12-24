# PHPUnit/Symfony デバッグパターン

EC-CUBE/Symfony の PHPUnit Webテストに特化したデバッグパターン集です。

## パターン0: 例外詳細の取得（最重要）

**使用タイミング**: テスト失敗時の最初のステップ

```php
public function testSomething()
{
    // 最初にこれを追加
    $this->client->catchExceptions(false);

    // テストコード
    $this->client->request('GET', '/some/path');
    $this->assertTrue($this->client->getResponse()->isRedirect('/expected'));
}
```

**実例**:

```php
// 非効率: Status Code しか分からない
$this->client->request('GET', '/shopping');
$response = $this->client->getResponse();
echo "Status: " . $response->getStatusCode();  // "Status: 500"
// -> 500 と分かっても原因は不明

// 効率的: 実際のエラーが即座に判明
$this->client->catchExceptions(false);
$this->client->request('GET', '/shopping');
// -> TypeError: Customer::setName01(): Argument #1 ($name01) must be of type string, null given
//   at /var/ec-cube/src/Eccube/Service/OrderHelper.php:190
```

## パターン1: 500エラーの詳細調査（try-catch）

**使用タイミング**: catchExceptions(false)だけでは情報が不足する場合

```php
$this->client->catchExceptions(false);
try {
    $crawler = $this->client->request(
        'POST',
        $this->generateUrl('admin_product_edit', ['id' => $Product->getId()]),
        ['product' => $form]
    );
} catch (\Exception $e) {
    error_log("=== Exception ===");
    error_log("Message: ".$e->getMessage());
    error_log("File: ".$e->getFile().":".$e->getLine());
    error_log("Trace: ".$e->getTraceAsString());
    throw $e;
} finally {
    $this->client->catchExceptions(true);
}
```

## パターン2: フォームエラーの確認

**使用タイミング**: リダイレクトが期待されるがされない場合

```php
$response = $this->client->getResponse();
error_log("=== Response Status: ".$response->getStatusCode()." ===");

if ($response->isRedirect()) {
    error_log("Redirected to: ".$response->headers->get('Location'));
} else {
    // バリデーションエラー
    $errors = $crawler->filter('.invalid-feedback')->each(fn($node) => $node->text());
    if (!empty($errors)) {
        error_log("Form errors: ".print_r($errors, true));
    }

    // アラートメッセージ
    $alerts = $crawler->filter('.alert-danger')->each(fn($node) => $node->text());
    if (!empty($alerts)) {
        error_log("Alert messages: ".print_r($alerts, true));
    }

    // レスポンス全体の内容（最終手段）
    error_log("Response content: ".$response->getContent());
}
```

## パターン3: PHP 8.3 型安全性エラーの診断

**使用タイミング**: TypeError が発生している場合

**典型的なメッセージ**:
- `Expected argument of type "int", "null" given`
- `Argument #1 ($id) must be of type int, null given`

**調査ポイント**:

```php
// フォームデータを確認
error_log("Form data: ".print_r($form, true));

// Entity の setter 型宣言を確認
// 例: public function setId(int $id)  <- int は null を許容しない
// 修正: public function setId(?int $id)  <- ?int は null を許容する
```

**修正パターン**:

```php
// 修正前: TypeError発生
$this->client->request('POST', $url, [
    'block' => [
        'name' => 'test',
        'id' => '',  // <- Block::setId(int $id) に null が渡される
    ],
]);

// 修正後: 正常動作
$this->client->request('POST', $url, [
    'block' => [
        'name' => 'test',
        'id' => $Block->getId(),  // 編集時は正しいIDを渡す
    ],
]);
```

## パターン4: 「システムエラーが発生しました」の深掘り

**症状**: アサーションが「期待する文字列が含まれない」という形で報告される

```
Failed asserting that 'システムエラーが発生しました...' contains "__RENDERED__"
```

**対応手順**:

1. `catchExceptions(false)` を追加
2. テストを再実行: `vendor/bin/phpunit --filter "失敗したテスト名"`
3. 実際の例外を確認

**よくある原因（PHP 8.3）**:

| エラータイプ | 原因例 |
|-------------|--------|
| TypeError | 型宣言の不一致（Union型の一部欠落など） |
| ArgumentCountError | 必須引数の不足 |
| RuntimeError | Twig レンダリング中の例外 |

**実例**:

```
# 表面上のエラー
Failed asserting that 'システムエラーが発生しました...' contains "__RENDERED__"

# catchExceptions(false) で判明した実際の原因
TypeError: IgnoreTwigSandboxErrorExtension::twig_include():
Argument #3 ($template) must be of type array|string, Twig\TemplateWrapper given

# 原因: 型宣言から TemplateWrapper が削除されていた
# 修正: array|string|TemplateWrapper $template
```

## パターン5: サイレント失敗の根本原因特定

**使用タイミング**: エラーは発生しないが、期待した動作をしない場合

### PHPUnit でのデバッグ出力

```php
// 出力されない可能性
log_info('debug message');

// 確実に出力される
fwrite(STDERR, "[DEBUG] message\n");

// ファイルに出力
file_put_contents('/tmp/debug.log', $message, FILE_APPEND);
```

### 段階的デバッグの実施

```php
// PurchaseFlow::validate() に追加
fwrite(STDERR, sprintf(
    "[DEBUG] flowType=%s, validatorsCount=%d\n",
    $this->flowType,
    $this->itemValidators->count()
));

// 実行結果:
// [DEBUG] flowType=, validatorsCount=0
// -> 重要な発見: バリデータが0個！
```

### DI バインディングの整合性確認

```bash
# services.yaml のバインド定義を確認
grep -A 5 'bind:' app/config/eccube/services.yaml

# コントローラーの引数名を確認
grep -r 'PurchaseFlow \$' src/Eccube/Controller/
```

**チェックポイント**:
- `services.yaml` の `$xxxPurchaseFlow` と
- コンストラクタの引数名 `$xxxPurchaseFlow` が一致しているか

**修正パターン**:

```php
// Before（問題あり）
public function __construct(
    protected PurchaseFlow $purchaseFlow,  // <- バインド名と不一致
) {}

// After（正しい）
public function __construct(
    protected PurchaseFlow $cartPurchaseFlow,  // バインド名に合わせる
) {
    $this->purchaseFlow = $cartPurchaseFlow;
}
```

## Symfony WebTestCase の動作原理

- デフォルトで `catchExceptions(true)` が有効
- 例外がキャッチされて、エラーページがレンダリングされる
- `catchExceptions(false)` で実際の例外が取得可能

## EC-CUBE のフォームバリデーション

- バリデーションエラーは `.invalid-feedback` クラスで表示
- アラートメッセージは `.alert-danger` クラス
- リダイレクトしない場合、フォームが再表示される

## Doctrine ORM の例外パターン

- `UniqueConstraintViolationException`: 一意制約違反
- `ForeignKeyConstraintViolationException`: 外部キー制約違反
- `ConnectionException`: データベース接続エラー
