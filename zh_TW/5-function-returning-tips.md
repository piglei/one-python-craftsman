# Python 工匠：讓函式返回結果的技巧

## 序言

> 這是 “Python 工匠”系列的第 5 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/03/dominik-scythe-283337-unsplash-w1280.jpg" width="100%" />
</div>

毫無疑問，函式是 Python 語言裡最重要的概念之一。在程式設計時，我們將真實世界裡的大問題分解為小問題，然後透過一個個函式交出答案。函式即是重複程式碼的剋星，也是對抗程式碼複雜度的最佳武器。

如同大部分故事都會有結局，絕大多數函式也都是以**返回結果**作為結束。函式返回結果的手法，決定了呼叫它時的體驗。所以，瞭解如何優雅的讓函式返回結果，是編寫好函式的必備知識。

### Python 的函式返回方式

Python 函式透過呼叫 `return` 語句來返回結果。使用 `return value` 可以返回單個值，用 `return value1, value2` 則能讓函式同時返回多個值。

如果一個函式體內沒有任何 `return` 語句，那麼這個函式的返回值預設為 `None`。除了透過 `return` 語句返回內容，在函式內還可以使用丟擲異常*（raise Exception）*的方式來“返回結果”。

接下來，我將列舉一些與函式返回相關的常用程式設計建議。

### 內容目錄

* [程式設計建議](#程式設計建議)
   * [1. 單個函式不要返回多種型別](#1-單個函式不要返回多種型別)
   * [2. 使用 partial 構造新函式](#2-使用-partial-構造新函式)
   * [3. 丟擲異常，而不是返回結果與錯誤](#3-丟擲異常而不是返回結果與錯誤)
   * [4. 謹慎使用 None 返回值](#4-謹慎使用-none-返回值)
      * [1. 作為操作類函式的預設返回值](#1-作為操作類函式的預設返回值)
      * [2. 作為某些“意料之中”的可能沒有的值](#2-作為某些意料之中的可能沒有的值)
      * [3. 作為呼叫失敗時代表“錯誤結果”的值](#3-作為呼叫失敗時代表錯誤結果的值)
   * [5. 合理使用“空物件模式”](#5-合理使用空物件模式)
   * [6. 使用生成器函式代替返回列表](#6-使用生成器函式代替返回列表)
   * [7. 限制遞迴的使用](#7-限制遞迴的使用)
* [總結](#總結)
* [附錄](#附錄)

## 程式設計建議

### 1. 單個函式不要返回多種型別

Python 語言非常靈活，我們能用它輕鬆完成一些在其他語言裡很難做到的事情。比如：*讓一個函式同時返回不同型別的結果。*從而實現一種看起來非常實用的“多功能函式”。

就像下面這樣：

```python
def get_users(user_id=None):
    if user_id is not None:
        return User.get(user_id)
    else:
        return User.filter(is_active=True)


# 返回單個使用者
get_users(user_id=1)
# 返回多個使用者
get_users()
```

當我們需要獲取單個使用者時，就傳遞 `user_id` 引數，否則就不傳引數拿到所有活躍使用者列表。一切都由一個函式 `get_users` 來搞定。這樣的設計似乎很合理。

然而在函式的世界裡，以編寫具備“多功能”的瑞士軍刀型函式為榮不是一件好事。這是因為好的函式一定是 [“單一職責（Single responsibility）”](https://en.wikipedia.org/wiki/Single_responsibility_principle) 的。**單一職責意味著一個函式只做好一件事，目的明確。**這樣的函式也更不容易在未來因為需求變更而被修改。

而返回多種型別的函式一定是違反“單一職責”原則的，**好的函式應該總是提供穩定的返回值，把呼叫方的處理成本降到最低。**像上面的例子，我們應該編寫兩個獨立的函式 `get_user_by_id(user_id)`、`get_active_users()` 來替代。

### 2. 使用 partial 構造新函式

假設這麼一個場景，在你的程式碼裡有一個引數很多的函式 `A`，適用性很強。而另一個函式 `B` 則是完全透過呼叫 `A` 來完成工作，是一種類似快捷方式的存在。

比方在這個例子裡， `double` 函式就是完全透過 `multiply` 來完成計算的：

```python
def multiply(x, y):
    return x * y


def double(value):
    # 返回另一個函式呼叫結果
    return multiply(2, value)
```

對於上面這種場景，我們可以使用 `functools` 模組裡的 [`partial()`](https://docs.python.org/3.6/library/functools.html#functools.partial) 函式來簡化它。

`partial(func, *args, **kwargs)` 基於傳入的函式與可變（位置/關鍵字）引數來構造一個新函式。**所有對新函式的呼叫，都會在合併了當前呼叫引數與構造引數後，代理給原始函式處理。**

利用 `partial` 函式，上面的 `double` 函式定義可以被修改為單行表示式，更簡潔也更直接。

```python
import functools

double = functools.partial(multiply, 2)
```

> 建議閱讀：[partial 函式官方文件](https://docs.python.org/3.6/library/functools.html#functools.partial)

### 3. 丟擲異常，而不是返回結果與錯誤

我在前面提過，Python 裡的函式可以返回多個值。基於這個能力，我們可以編寫一類特殊的函式：**同時返回結果與錯誤資訊的函式。**

```python
def create_item(name):
    if len(name) > MAX_LENGTH_OF_NAME:
        return None, 'name of item is too long'
    if len(CURRENT_ITEMS) > MAX_ITEMS_QUOTA:
        return None, 'items is full'
    return Item(name=name), ''


def create_from_input():
    name = input()
    item, err_msg = create_item(name)
    if err_msg:
        print(f'create item failed: {err_msg}')
    else:
        print(f'item<{name}> created')
```

在示例中，`create_item` 函式的作用是建立新的 Item 物件。同時，為了在出錯時給呼叫方提供錯誤詳情，它利用了多返回值特性，把錯誤資訊作為第二個結果返回。

乍看上去，這樣的做法很自然。尤其是對那些有 `Go` 語言程式設計經驗的人來說更是如此。但是在 Python 世界裡，這並非解決此類問題的最佳辦法。因為這種做法會增加呼叫方進行錯誤處理的成本，尤其是當很多函式都遵循這個規範而且存在多層呼叫時。

Python 具備完善的*異常（Exception）*機制，並且在某種程度上鼓勵我們使用異常（[官方文件關於 EAFP 的說明](https://docs.python.org/3/glossary.html#term-eafp)）。所以，**使用異常來進行錯誤流程處理才是更地道的做法。**

引入自定義異常後，上面的程式碼可以被改寫成這樣：

```python
class CreateItemError(Exception):
    """建立 Item 失敗時丟擲的異常"""

def create_item(name):
    """建立一個新的 Item
    
    :raises: 當無法建立時丟擲 CreateItemError
    """
    if len(name) > MAX_LENGTH_OF_NAME:
        raise CreateItemError('name of item is too long')
    if len(CURRENT_ITEMS) > MAX_ITEMS_QUOTA:
        raise CreateItemError('items is full')
    return Item(name=name)


def create_for_input():
    name = input()
    try:
        item = create_item(name)
    except CreateItemError as e:
        print(f'create item failed: {err_msg}')
    else:
        print(f'item<{name}> created')

```

使用“丟擲異常”替代“返回 (結果, 錯誤資訊)”後，整個錯誤流程處理乍看上去變化不大，但實際上有著非常多不同，一些細節：

- 新版本函式擁有更穩定的返回值型別，它永遠只會返回 `Item` 型別或是丟擲異常
- 雖然我在這裡鼓勵使用異常，但“異常”總是會無法避免的讓人 **感到驚訝**，所以，最好在函式文件裡說明可能丟擲的異常型別
- 異常不同於返回值，它在被捕獲前會不斷往呼叫棧上層彙報。所以 `create_item` 的一級呼叫方完全可以省略異常處理，交由上層處理。這個特點給了我們更多的靈活性，但同時也帶來了更大的風險。


> Hint：如何在程式語言裡處理錯誤，是一個至今仍然存在爭議的主題。比如像上面不推薦的多返回值方式，正是缺乏異常的 Go 語言中最核心的錯誤處理機制。另外，即使是異常機制本身，不同程式語言之間也存在著差別。
> 
> 異常，或是不異常，都是由語言設計者進行多方取捨後的結果，更多時候不存在絕對性的優劣之分。**但是，單就 Python 語言而言，使用異常來表達錯誤無疑是更符合 Python 哲學，更應該受到推崇的。**


### 4. 謹慎使用 None 返回值

`None` 值通常被用來表示**“某個應該存在但是缺失的東西”**，它在 Python 裡是獨一無二的存在。很多程式語言裡都有與 None 類似的設計，比如 JavaScript 裡的 `null`、Go 裡的 `nil` 等。因為 None 所擁有的獨特 *虛無* 氣質，它經常被作為函式返回值使用。

當我們使用 None 作為函式返回值時，通常是下面 3 種情況。

#### 1. 作為操作類函式的預設返回值

當某個操作類函式不需要任何返回值時，通常就會返回 None。同時，None 也是不帶任何 `return` 語句函式的預設返回值。

對於這種函式，使用 None 是沒有任何問題的，標準庫裡的 `list.append()`、`os.chdir()` 均屬此類。

#### 2. 作為某些“意料之中”的可能沒有的值

有一些函式，它們的目的通常是去嘗試性的做某件事情。視情況不同，最終可能有結果，也可能沒有結果。**而對呼叫方來說，“沒有結果”完全是意料之中的事情**。對這類函式來說，使用 None 作為“沒結果”時的返回值也是合理的。

在 Python 標準庫裡，正則表示式模組 `re` 下的 `re.search`、`re.match` 函式均屬於此類，這兩個函式在可以找到匹配結果時返回 `re.Match` 物件，找不到時則返回 `None`。

#### 3. 作為呼叫失敗時代表“錯誤結果”的值

有時，`None` 也會經常被我們用來作為函式呼叫失敗時的預設返回值，比如下面這個函式：

```python
def create_user_from_name(username):
    """透過使用者名稱建立一個 User 例項"""
    if validate_username(username):
        return User.from_username(username)
    else:
        return None


user = create_user_from_name(username)
if user:
    user.do_something()
```

當 username 不合法時，函式 `create_user_from_name` 將會返回 None。但在這個場景下，這樣做其實並不好。

不過你也許會覺得這個函式完全合情合理，甚至你會覺得它和我們提到的上一個“沒有結果”時的用法非常相似。那麼如何區分這兩種不同情形呢？關鍵在於：**函式簽名（名稱與引數）與 None 返回值之間是否存在一種“意料之中”的暗示。**

讓我解釋一下，每當你讓函式返回 None 值時，請**仔細閱讀函式名**，然後問自己一個問題：*假如我是該函式的使用者，從這個名字來看，“拿不到任何結果”是否是該函式名稱含義裡的一部分？*

分別用這兩個函式來舉例：

- `re.search()`：從函式名來看，`search`，代表著從目標字串裡去**搜尋**匹配結果，而搜尋行為，一向是可能有也可能沒有結果的，所以該函式適合返回 None
- `create_user_from_name()`：從函式名來看，代表基於一個名字來構建使用者，並不能讀出一種`可能返回、可能不返回`的含義。所以不適合返回 None

對於那些不能從函式名裡讀出 None 值暗示的函式來說，有兩種修改方式。第一種，如果你堅持使用 None 返回值，那麼請修改函式的名稱。比如可以將函式 `create_user_from_name()` 改名為 `create_user_or_none()`。

第二種方式則更常見的多：用丟擲異常*（raise Exception）*來代替 None 返回值。因為，如果返回不了正常結果並非函式意義裡的一部分，這就代表著函數出現了*“意料以外的狀況”*，而這正是 **Exceptions 異常** 所掌管的領域。

使用異常改寫後的例子：

```python
class UnableToCreateUser(Exception):
    """當無法建立使用者時丟擲"""


def create_user_from_name(username):
    ""透過使用者名稱建立一個 User 例項"
    
    :raises: 當無法建立使用者時丟擲 UnableToCreateUser
    """
    if validate_username(username):
        return User.from_username(username)
    else:
        raise UnableToCreateUser(f'unable to create user from {username}')


try:
    user = create_user_from_name(username)
except UnableToCreateUser:
    # Error handling
else:
    user.do_something()
```

與 None 返回值相比，丟擲異常除了擁有我們在上個場景提到的那些特點外，還有一個額外的優勢：**可以在異常資訊裡提供出現意料之外結果的原因**，這是隻返回一個 None 值做不到的。

### 5. 合理使用“空物件模式”

我在前面提到函式可以用 `None` 值或異常來返回錯誤結果，但這兩種方式都有一個共同的缺點。那就是所有需要使用函式返回值的地方，都必須加上一個 `if` 或 `try/except` 防禦語句，來判斷結果是否正常。

讓我們看一個可執行的完整示例：

```python
import decimal


class CreateAccountError(Exception):
    """Unable to create a account error"""


class Account:
    """一個虛擬的銀行賬號"""

    def __init__(self, username, balance):
        self.username = username
        self.balance = balance

    @classmethod
    def from_string(cls, s):
        """從字串初始化一個賬號"""
        try:
            username, balance = s.split()
            balance = decimal.Decimal(float(balance))
        except ValueError:
            raise CreateAccountError('input must follow pattern "{ACCOUNT_NAME} {BALANCE}"')

        if balance < 0:
            raise CreateAccountError('balance can not be negative')
        return cls(username=username, balance=balance)


def caculate_total_balance(accounts_data):
    """計算所有賬號的總餘額
    """
    result = 0
    for account_string in accounts_data:
        try:
            user = Account.from_string(account_string)
        except CreateAccountError:
            pass
        else:
            result += user.balance
    return result


accounts_data = [
    'piglei 96.5',
    'cotton 21',
    'invalid_data',
    'roland $invalid_balance',
    'alfred -3',
]

print(caculate_total_balance(accounts_data))
```

在這個例子裡，每當我們呼叫 `Account.from_string` 時，都必須使用 `try/except` 來捕獲可能發生的異常。如果專案裡需要呼叫很多次該函式，這部分工作就變得非常繁瑣了。針對這種情況，可以使用[“空物件模式（Null object pattern）”](https://en.wikipedia.org/wiki/Null_object_pattern)來改善這個控制流。

Martin Fowler 在他的經典著作[《重構》](https://martinfowler.com/books/refactoring.html) 中用一個章節詳細說明過這個模式。簡單來說，**就是使用一個符合正常結果介面的“空型別”來替代空值返回/丟擲異常，以此來降低呼叫方處理結果的成本。**

引入“空物件模式”後，上面的示例可以被修改成這樣：

```python
class Account:
    # def __init__ 已省略... ...
    
    @classmethod
    def from_string(cls, s):
        """從字串初始化一個賬號

        :returns: 如果輸入合法，返回 Account object，否則返回 NullAccount
        """
        try:
            username, balance = s.split()
            balance = decimal.Decimal(float(balance))
        except ValueError:
            return NullAccount()

        if balance < 0:
            return NullAccount()
        return cls(username=username, balance=balance)


class NullAccount:
    username = ''
    balance = 0

    @classmethod
    def from_string(cls, s):
        raise NotImplementedError
```

在新版程式碼裡，我定義了 `NullAccount` 這個新型別，用來作為 `from_string` 失敗時的錯誤結果返回。這樣修改後的最大變化體現在 `caculate_total_balance` 部分：

```python
def caculate_total_balance(accounts_data):
    """計算所有賬號的總餘額
    """
    return sum(Account.from_string(s).balance for s in accounts_data)
```

調整之後，呼叫方不必再顯式使用 try 語句來處理錯誤，而是可以假設 `Account.from_string` 函式總是會返回一個合法的 Account 物件，從而大大簡化整個計算邏輯。

> Hint：在 Python 世界裡，“空物件模式”並不少見，比如大名鼎鼎的 Django 框架裡的 [AnonymousUser](https://docs.djangoproject.com/en/2.1/ref/contrib/auth/#anonymoususer-object) 就是一個典型的 null object。

### 6. 使用生成器函式代替返回列表

在函式裡返回列表特別常見，通常，我們會先初始化一個列表 `results = []`，然後在迴圈體內使用 `results.append(item)` 函式填充它，最後在函式的末尾返回。

對於這類模式，我們可以用生成器函式來簡化它。粗暴點說，就是用 `yield item` 替代 `append` 語句。使用生成器的函式通常更簡潔、也更具通用性。

```python
def foo_func(items):
    for item in items:
        # ... 處理 item 後直接使用 yield 返回
        yield item
```

我在 [系列第 4 篇文章“容器的門道”](https://www.zlovezl.cn/articles/mastering-container-types/) 裡詳細分析過這個模式，更多細節可以訪問文章，搜尋 “寫擴充套件性更好的程式碼” 檢視。

### 7. 限制遞迴的使用

當函式返回自身呼叫時，也就是 `遞迴` 發生時。遞迴是一種在特定場景下非常有用的程式設計技巧，但壞訊息是：Python 語言對遞迴支援的非常有限。

這份“有限的支援”體現在很多方面。首先，Python 語言不支援[“尾遞迴最佳化”](https://en.wikipedia.org/wiki/Tail_call)。另外 Python 對最大遞迴層級數也有著嚴格的限制。

所以我建議：**儘量少寫遞迴**。如果你想用遞迴解決問題，先想想它是不是能方便的用迴圈來替代。如果答案是肯定的，那麼就用迴圈來改寫吧。如果迫不得已，一定需要使用遞迴時，請考慮下面幾個點：

- 函式輸入資料規模是否穩定，是否一定不會超過 `sys.getrecursionlimit()` 規定的最大層數限制
- 是否可以透過使用類似 [functools.lru_cache](https://docs.python.org/3/library/functools.html#functools.lru_cache) 的快取工具函式來降低遞迴層數

## 總結

在這篇文章中，我虛擬了一些與 Python 函式返回有關的場景，並針對每個場景提供了我的最佳化建議。最後再總結一下要點：

- 讓函式擁有穩定的返回值，一個函式只做好一件事
- 使用 `functools.partial` 定義快捷函式
- 丟擲異常也是返回結果的一種方式，使用它來替代返回錯誤資訊
- 函式是否適合返回 None，由函式簽名的“含義”所決定
- 使用“空物件模式”可以簡化呼叫方的錯誤處理邏輯
- 多使用生成器函式，儘量用迴圈替代遞迴

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【6.異常處理的三個好習慣】](6-three-rituals-of-exceptions-handling.md)

[<<<上一篇【4.容器的門道】](4-mastering-container-types.md)

## 附錄

- 題圖來源: Dominik Scythe on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：善用變數改善程式碼質量](https://www.zlovezl.cn/articles/python-using-variables-well/)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：使用數字與字串的技巧](https://www.zlovezl.cn/articles/tips-on-numbers-and-strings/)



