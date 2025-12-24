---
name: test-debug
description: テストでエラーが発生しているが詳細なログが不足している場合に、適切なデバッグ手法を提示します。PHPUnit Webテストを主な対象としていますが、TypeScript/Jest、Python/pytest にも応用可能です。「テストが失敗する」「500エラーが出る」「デバッグ方法がわからない」などの場合に使用してください。
---

# テストデバッグスキル

テストで発生する**エラーメッセージが不明瞭なケース**を効率的にデバッグするための知識ベースです。

## 最重要原則

**テストが失敗したら、原因推測の前にまず例外/エラーの詳細を確認する。**

| フレームワーク | 非効率な方法 | 効率的な方法 |
|------------|------------|------------|
| **PHPUnit/Symfony** | `echo $response->getStatusCode()` | `$this->client->catchExceptions(false)` |
| **TypeScript/Jest** | `expect().toThrow()` | `try-catch` + `console.error()` |
| **Python/pytest** | `with pytest.raises(Error):` | `pytest.raises(Error, match="pattern")` |

## デバッグフローチャート

```
アサーション失敗
    |
    v
+------------------------------------------+
| まず例外/エラーの詳細を確認              |
| PHPUnit: catchExceptions(false)          |
| Jest: try-catch + console.error          |
| pytest: exc_info でスタックトレース取得  |
+------------------------------------------+
    |
    v
例外が発生？
    |
+---+---+
|       |
Yes     No
|       |
v       v
実際の  レスポンス/出力を確認
例外を  |
確認    +-------+-------+-------+
        |       |       |
        v       v       v
    200/3xx   500    期待と異なる
    フォーム  例外   サイレント失敗
    エラー    詳細   -> 処理フロー追跡
```

## 詳細ガイド

フレームワーク別の詳細なデバッグパターンは以下のファイルを参照してください：

- [PHPUNIT_PATTERNS.md](PHPUNIT_PATTERNS.md) - PHPUnit/Symfony 固有のパターン
- [OTHER_FRAMEWORKS.md](OTHER_FRAMEWORKS.md) - TypeScript/Jest, Python/pytest への応用
- [COMMON_ERRORS.md](COMMON_ERRORS.md) - よくあるエラーパターンと対処法

## クイックリファレンス

### PHPUnit/Symfony

```php
// 最初にこれを追加
$this->client->catchExceptions(false);

// テストを実行
$this->client->request('GET', '/some/path');
// -> 例外がスローされれば、実際のメッセージとスタックトレースが表示される
```

### TypeScript/Jest

```typescript
try {
  await someAsyncOperation();
  fail('Expected error to be thrown');
} catch (error) {
  console.error('Full error:', error);
  expect(error.message).toContain('expected message');
}
```

### Python/pytest

```python
with pytest.raises(ValidationError) as exc_info:
    create_user({})

print(f"Full error: {exc_info.value}")
print(f"Traceback: {exc_info.traceback}")
```

## よくある間違い

| やりがちな行動 | 問題点 | 正しい行動 |
|---------------|--------|-----------|
| echo文でステータスコードを確認 | 500と分かっても原因は不明 | 例外詳細を取得 |
| 原因を推測してコードを調査 | 見当違いな方向に時間を浪費 | まず実際のエラーメッセージを取得 |
| テスト失敗メッセージを信じる | 表面的な症状しか分からない | 根本原因を特定 |

## 関連エージェント

デバッグログを取得した後、詳細な分析が必要な場合：

- **bug-investigator** - 根本原因の詳細分析
- **log-analyzer** - CI/CDログの解析
