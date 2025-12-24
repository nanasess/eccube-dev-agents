# 他のテストフレームワークへの応用

PHPUnit のデバッグパターンは、他のテストフレームワークにも応用可能です。

## TypeScript/Jest

### パターン0: 例外の詳細確認

```typescript
// 非効率: エラーメッセージが見えない
test('should throw validation error', () => {
  expect(() => createUser({})).toThrow();
});

// 効率的: 具体的なメッセージを確認
test('should throw validation error', () => {
  expect(() => createUser({})).toThrow('Name is required');
});

// さらに詳細: 完全なエラー情報
test('should throw validation error', () => {
  try {
    createUser({});
    fail('Expected error to be thrown');
  } catch (error) {
    console.error('Full error:', error);  // スタックトレース含む
    expect(error.message).toContain('Name is required');
  }
});
```

### パターン2: DOM エラーの確認（React Testing Library）

```typescript
import { render, screen, fireEvent } from '@testing-library/react';

test('should display form errors', () => {
  render(<UserForm />);
  fireEvent.click(screen.getByText('Submit'));

  // デバッグ出力
  screen.debug();  // DOM全体を出力

  // エラーメッセージを確認
  const errors = screen.getAllByRole('alert');
  console.log('Validation errors:', errors.map(e => e.textContent));

  expect(errors).toHaveLength(1);
  expect(errors[0]).toHaveTextContent('Name is required');
});
```

### パターン5: サイレント失敗の調査（Mock検証）

```typescript
test('should call validation service', () => {
  const mockValidate = jest.fn().mockReturnValue([]);

  const { result } = renderHook(() => useFormValidation(mockValidate));

  // デバッグ出力
  console.log('Mock called:', mockValidate.mock.calls.length);
  console.log('Mock args:', mockValidate.mock.calls);

  // mockValidate が呼ばれていない -> サービスが注入されていない可能性
  expect(mockValidate).toHaveBeenCalledTimes(1);
});
```

### 非同期テストのデバッグ

```typescript
test('async operation', async () => {
  try {
    const result = await fetchData();
    console.log('Result:', result);
  } catch (error) {
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      response: error.response?.data
    });
    throw error;
  }
});
```

## Python/pytest

### パターン0: 例外の詳細確認

```python
import pytest

# 非効率: エラーメッセージが見えない
def test_validation_error():
    with pytest.raises(ValidationError):
        create_user({})

# 効率的: 具体的なメッセージを確認
def test_validation_error():
    with pytest.raises(ValidationError, match="Name is required"):
        create_user({})

# さらに詳細: 完全なエラー情報
def test_validation_error():
    with pytest.raises(ValidationError) as exc_info:
        create_user({})

    print(f"Full error: {exc_info.value}")  # 詳細を出力
    print(f"Traceback: {exc_info.traceback}")
    assert "Name is required" in str(exc_info.value)
```

### パターン2: ログ出力の確認

```python
def test_logging(caplog):
    """pytestのcaplogフィクスチャを使用したログ確認"""
    process_order()

    # デバッグ出力
    print("Captured logs:", caplog.text)
    print("Log records:", [(r.levelname, r.message) for r in caplog.records])

    assert "Order processed" in caplog.text
    assert any(r.levelname == "INFO" for r in caplog.records)
```

### パターン5: サイレント失敗の調査（Fixture確認）

```python
def test_validation_called(mocker):
    """mockライブラリを使用した呼び出し確認"""
    mock_validate = mocker.patch('app.services.validate_user')
    mock_validate.return_value = []

    create_user({'name': 'John'})

    # デバッグ出力
    print(f"Mock called: {mock_validate.call_count} times")
    print(f"Mock args: {mock_validate.call_args_list}")

    # validate_user が呼ばれていない -> DIの問題の可能性
    assert mock_validate.call_count == 1
```

### Django テストのデバッグ

```python
from django.test import TestCase, Client

class MyTestCase(TestCase):
    def test_form_submission(self):
        client = Client()

        # raise_request_exception=True で例外を直接取得
        client.raise_request_exception = True

        try:
            response = client.post('/submit/', {'field': 'value'})
        except Exception as e:
            print(f"Exception: {e}")
            print(f"Traceback: {traceback.format_exc()}")
            raise

        # レスポンス内容のデバッグ
        print(f"Status: {response.status_code}")
        print(f"Content: {response.content.decode()}")

        # フォームエラーの確認
        if hasattr(response, 'context') and response.context:
            form = response.context.get('form')
            if form and form.errors:
                print(f"Form errors: {form.errors}")
```

## フレームワーク比較表

| デバッグパターン | PHPUnit | TypeScript/Jest | Python/pytest |
|----------------|---------|----------------|---------------|
| **例外詳細の取得** | `catchExceptions(false)` | `try-catch` + `console.error()` | `pytest.raises()` + `exc_info` |
| **出力内容の確認** | `error_log($response->getContent())` | `screen.debug()` | `print(response.text)` |
| **デバッグ出力** | `fwrite(STDERR, ...)` | `console.log()` | `print()`, `caplog` |
| **Mock/Spy確認** | DI設定の検証 | `jest.fn().mock.calls` | `mocker.patch()` |

## 共通の原則

1. **まず例外/エラーの詳細を確認** - 推測する前に実際のエラーを取得
2. **段階的にデバッグ** - 侵襲性の低い方法から開始
3. **Mock/Spy を活用** - 処理が呼ばれているか確認
4. **一時的な変更** - デバッグコードは調査完了後に削除
