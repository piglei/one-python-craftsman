# Python 工匠：使用裝飾器的技巧

## 前言

> 這是 “Python 工匠”系列的第 8 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/05/clem-onojeghuo-142120-unsplash_w1280.jpg" width="100%" />
</div>

裝飾器*（Decorator）* 是 Python 裡的一種特殊工具，它為我們提供了一種在函式外部修改函式的靈活能力。它有點像一頂畫著獨一無二 `@` 符號的神奇帽子，只要將它戴在函式頭頂上，就能悄無聲息的改變函式本身的行為。

你可能已經和裝飾器打過不少交道了。在做面向物件程式設計時，我們就經常會用到 `@staticmethod` 和 `@classmethod` 兩個內建裝飾器。此外，如果你接觸過 [click](https://click.palletsprojects.com/en/7.x/) 模組，就更不會對裝飾器感到陌生。click 最為人所稱道的引數定義介面 `@click.option(...)` 就是利用裝飾器實現的。

除了用裝飾器，我們也經常需要自己寫一些裝飾器。在這篇文章裡，我將從 `最佳實踐` 和 `常見錯誤` 兩個方面，來與你分享有關裝飾器的一些小知識。

## 最佳實踐

### 1. 嘗試用類來實現裝飾器

絕大多數裝飾器都是基於函式和 [閉包](https://en.wikipedia.org/wiki/Closure_(computer_programming)) 實現的，但這並非製造裝飾器的唯一方式。事實上，Python 對某個物件是否能透過裝飾器（`@decorator`）形式使用只有一個要求：**decorator 必須是一個“可被呼叫（callable）的物件**。

```python
# 使用 callable 可以檢測某個物件是否“可被呼叫”
>>> def foo(): pass
...
>>> type(foo)
<class 'function'>
>>> callable(foo)
True
```

函式自然是“可被呼叫”的物件。但除了函式外，我們也可以讓任何一個類（class）變得“可被呼叫”（callable）。辦法很簡單，只要自定義類的 `__call__` 魔法方法即可。

```
class Foo:
    def __call__(self):
        print("Hello, __call___")

foo = Foo()

# OUTPUT: True
print(callable(foo))
# 呼叫 foo 例項
# OUTPUT: Hello, __call__
foo()
```

基於這個特性，我們可以很方便的使用類來實現裝飾器。

下面這段程式碼，會定義一個名為 `@delay(duration)` 的裝飾器，使用它裝飾過的函式在每次執行前，都會等待額外的 `duration` 秒。同時，我們也希望為使用者提供無需等待馬上執行的 `eager_call` 介面。

```python
import time
import functools


class DelayFunc:
    def __init__(self,  duration, func):
        self.duration = duration
        self.func = func

    def __call__(self, *args, **kwargs):
        print(f'Wait for {self.duration} seconds...')
        time.sleep(self.duration)
        return self.func(*args, **kwargs)

    def eager_call(self, *args, **kwargs):
        print('Call without delay')
        return self.func(*args, **kwargs)


def delay(duration):
    """裝飾器：推遲某個函式的執行。同時提供 .eager_call 方法立即執行
    """
    # 此處為了避免定義額外函式，直接使用 functools.partial 幫助構造
    # DelayFunc 例項
    return functools.partial(DelayFunc, duration)
```

如何使用裝飾器的樣例程式碼：

```
@delay(duration=2)
def add(a, b):
    return a + b


# 這次呼叫將會延遲 2 秒
add(1, 2)
# 這次呼叫將會立即執行
add.eager_call(1, 2)
```

`@delay(duration)` 就是一個基於類來實現的裝飾器。當然，如果你非常熟悉 Python 裡的函式和閉包，上面的 `delay` 裝飾器其實也完全可以只用函式來實現。所以，為什麼我們要用類來做這件事呢？

與純函式相比，我覺得使用類實現的裝飾器在**特定場景**下有幾個優勢：

- 實現有狀態的裝飾器時，操作類屬性比操作閉包內變數更符合直覺、不易出錯
- 實現為函式擴充介面的裝飾器時，使用類包裝函式，比直接為函式物件追加屬性更易於維護
- 更容易實現一個同時相容裝飾器與上下文管理器協議的物件（參考 [unitest.mock.patch](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.patch)）

### 2. 使用 wrapt 模組編寫更扁平的裝飾器

在寫裝飾器的過程中，你有沒有碰到過什麼不爽的事情？不管你有沒有，反正我有。我經常在寫程式碼的時候，被下面兩件事情搞得特別難受：

1. 實現帶引數的裝飾器時，層層巢狀的函式程式碼特別難寫、難讀
2. 因為函式和類方法的不同，為前者寫的裝飾器經常沒法直接套用在後者上

比如，在下面的例子裡，我實現了一個生成隨機數並注入為函式引數的裝飾器。

```python
import random


def provide_number(min_num, max_num):
    """裝飾器：隨機生成一個在 [min_num, max_num] 範圍的整數，追加為函式的第一個位置引數
    """
    def wrapper(func):
        def decorated(*args, **kwargs):
            num = random.randint(min_num, max_num)
            # 將 num 作為第一個引數追加後呼叫函式
            return func(num, *args, **kwargs)
        return decorated
    return wrapper
    


@provide_number(1, 100)
def print_random_number(num):
    print(num)

# 輸出 1-100 的隨機整數
# OUTPUT: 72
print_random_number()
```

`@provide_number` 裝飾器功能看上去很不錯，但它有著我在前面提到的兩個問題：**巢狀層級深、無法在類方法上使用。**如果直接用它去裝飾類方法，會出現下面的情況：

```
class Foo:
    @provide_number(1, 100)
    def print_random_number(self, num):
        print(num)

# OUTPUT: <__main__.Foo object at 0x104047278>
Foo().print_random_number()
```

`Foo` 類例項中的 `print_random_number` 方法將會輸出類例項 `self` ，而不是我們期望的隨機數 `num`。

之所以會出現這個結果，是因為類方法*（method）*和函式*（function）*二者在工作機制上有著細微不同。如果要修復這個問題，`provider_number` 裝飾器在修改類方法的位置引數時，必須聰明的跳過藏在 `*args` 裡面的類例項 `self` 變數，才能正確的將 `num` 作為第一個引數注入。

這時，就應該是 [wrapt](https://pypi.org/project/wrapt/) 模組閃亮登場的時候了。`wrapt` 模組是一個專門幫助你編寫裝飾器的工具庫。利用它，我們可以非常方便的改造 `provide_number` 裝飾器，完美解決*“巢狀層級深”*和*“無法通用”*兩個問題，

```python
import wrapt

def provide_number(min_num, max_num):
    @wrapt.decorator
    def wrapper(wrapped, instance, args, kwargs):
        # 引數含義：
        #
        # - wrapped：被裝飾的函式或類方法
        # - instance：
        #   - 如果被裝飾者為普通類方法，該值為類例項
        #   - 如果被裝飾者為 classmethod 類方法，該值為類
        #   - 如果被裝飾者為類/函式/靜態方法，該值為 None
        #
        # - args：呼叫時的位置引數（注意沒有 * 符號）
        # - kwargs：呼叫時的關鍵字引數（注意沒有 ** 符號）
        #
        num = random.randint(min_num, max_num)
        # 無需關注 wrapped 是類方法或普通函式，直接在頭部追加引數
        args = (num,) + args
        return wrapped(*args, **kwargs)
    return wrapper
    
<... 應用裝飾器部分程式碼省略 ...>
    
# OUTPUT: 48
Foo().print_random_number()
```

使用 `wrapt` 模組編寫的裝飾器，相比原來擁有下面這些優勢：

- 巢狀層級少：使用 `@wrapt.decorator` 可以將兩層巢狀減少為一層
- 更簡單：處理位置與關鍵字引數時，可以忽略類例項等特殊情況
- 更靈活：針對 `instance` 值進行條件判斷後，更容易讓裝飾器變得通用

## 常見錯誤

### 1. “裝飾器”並不是“裝飾器模式”

[“設計模式”](https://en.wikipedia.org/wiki/Software_design_pattern)是一個在計算機世界裡鼎鼎大名的詞。假如你是一名 Java 程式設計師，而你一點設計模式都不懂，那麼我打賭你找工作的面試過程一定會度過的相當艱難。

但寫 Python 時，我們極少談起“設計模式”。雖然 Python 也是一門支援面向物件的程式語言，但它的 [鴨子型別](https://en.wikipedia.org/wiki/Duck_typing) 設計以及出色的動態特性決定了，大部分設計模式對我們來說並不是必需品。所以，很多 Python 程式設計師在工作很長一段時間後，可能並沒有真正應用過幾種設計模式。

不過 [*“裝飾器模式（Decorator Pattern）”*](https://en.wikipedia.org/wiki/Decorator_pattern) 是個例外。因為 Python 的“裝飾器”和“裝飾器模式”有著一模一樣的名字，我不止一次聽到有人把它們倆當成一回事，認為使用“裝飾器”就是在實踐“裝飾器模式”。但事實上，**它們是兩個完全不同的東西。**

“裝飾器模式”是一個完全基於“面向物件”衍生出的程式設計手法。它擁有幾個關鍵組成：**一個統一的介面定義**、**若干個遵循該介面的類**、**類與類之間一層一層的包裝**。最終由它們共同形成一種*“裝飾”*的效果。

而 Python 裡的“裝飾器”和“面向物件”沒有任何直接聯絡，**它完全可以只是發生在函式和函式間的把戲。**事實上，“裝飾器”並沒有提供某種無法替代的功能，它僅僅就是一顆[“語法糖”](https://en.wikipedia.org/wiki/Syntactic_sugar)而已。下面這段使用了裝飾器的程式碼：

```python
@log_time
@cache_result
def foo(): pass
```

基本完全等同於下面這樣：

```
def foo(): pass

foo = log_time(cache_result(foo))
```

**裝飾器最大的功勞，在於讓我們在某些特定場景時，可以寫出更符合直覺、易於閱讀的程式碼**。它只是一顆“糖”，並不是某個面向物件領域的複雜程式設計模式。

> Hint: 在 Python 官網上有一個 [實現了裝飾器模式的例子](https://wiki.python.org/moin/DecoratorPattern)，你可以讀讀這個例子來更好的瞭解它。

### 2. 記得用 functools.wraps() 裝飾內層函式

下面是一個簡單的裝飾器，專門用來列印函式呼叫耗時：

```python
import time


def timer(wrapped):
    """裝飾器：記錄並列印函式耗時"""
    def decorated(*args, **kwargs):
        st = time.time()
        ret = wrapped(*args, **kwargs)
        print('execution take: {} seconds'.format(time.time() - st))
        return ret
    return decorated


@timer
def random_sleep():
    """隨機睡眠一小會"""
    time.sleep(random.random())
```

`timer` 裝飾器雖然沒有錯誤，但是使用它裝飾函式後，函式的原始簽名就會被破壞。也就是說你再也沒辦法正確拿到 `random_sleep` 函式的名稱、文件內容了，所有簽名都會變成內層函式 `decorated` 的值：

```python
print(random_sleep.__name__)
# 輸出 'decorated'
print(random_sleep.__doc__)
# 輸出 None
```

這雖然只是個小問題，但在某些時候也可能會導致難以察覺的 bug。幸運的是，標準庫 `functools` 為它提供瞭解決方案，你只需要在定義裝飾器時，用另外一個裝飾器再裝飾一下內層 `decorated` 函式就行。

聽上去有點繞，但其實就是新增一行程式碼而已：

```python
def timer(wrapped):
    # 將 wrapper 函式的真實簽名賦值到 decorated 上
    @functools.wraps(wrapped)
    def decorated(*args, **kwargs):
        # <...> 已省略
    return decorated
```

這樣處理後，`timer` 裝飾器就不會影響它所裝飾的函數了。

```python
print(random_sleep.__name__)
# 輸出 'random_sleep'
print(random_sleep.__doc__)
# 輸出 '隨機睡眠一小會'
```

### 3. 修改外層變數時記得使用 nonlocal

裝飾器是對函式物件的一個高階應用。在編寫裝飾器的過程中，你會經常碰到內層函式需要修改外層函式變數的情況。就像下面這個裝飾器一樣：

```python
import functools

def counter(func):
    """裝飾器：記錄並列印呼叫次數"""
    count = 0
    @functools.wraps(func)
    def decorated(*args, **kwargs):
        # 次數累加
        count += 1
        print(f"Count: {count}")
        return func(*args, **kwargs)
    return decorated

@counter
def foo():
    pass

foo()
```

為了統計函式呼叫次數，我們需要在 `decorated` 函式內部修改外層函式定義的 `count` 變數的值。但是，上面這段程式碼是有問題的，在執行它時直譯器會報錯:

```raw
Traceback (most recent call last):
  File "counter.py", line 22, in <module>
    foo()
  File "counter.py", line 11, in decorated
    count += 1
UnboundLocalError: local variable 'count' referenced before assignment
```

這個錯誤是由 `counter` 與 `decorated` 函式互相巢狀的作用域引起的。

當直譯器執行到 `count += 1` 時，並不知道 `count` 是一個在外層作用域定義的變數，它把 `count` 當做一個區域性變數，並在當前作用域內查詢。最終卻沒有找到有關 `count` 變數的任何定義，然後丟擲錯誤。

為了解決這個問題，我們需要透過 `nonlocal` 關鍵字告訴直譯器：**“count 變數並不屬於當前的 local 作用域，去外面找找吧”**，之前的錯誤就可以得到解決。

```python
def decorated(*args, **kwargs):
    nonlocal count
    count += 1
    # <... 已省略 ...>
```

> Hint：如果要了解更多有關 nonlocal 關鍵字的歷史，可以查閱 [PEP-3104](https://www.python.org/dev/peps/pep-3104/)

## 總結

在這篇文章裡，我與你分享了有關裝飾器的一些技巧與小知識。

一些要點總結：

- 一切 callable 的物件都可以被用來實現裝飾器
- 混合使用函式與類，可以更好的實現裝飾器
- wrapt 模組很有用，用它可以幫助我們用更簡單的程式碼寫出複雜裝飾器
- “裝飾器”只是語法糖，它不是“裝飾器模式”
- 裝飾器會改變函式的原始簽名，你需要 `functools.wraps`
- 在內層函式修改外層函式的變數時，需要使用 `nonlocal` 關鍵字

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【9.一個關於模組的小故事】](9-a-story-on-cyclic-imports.md)

[<<<上一篇【7.編寫地道迴圈的兩個建議】](7-two-tips-on-loop-writing.md)


## 附錄

- 題圖來源: Photo by Clem Onojeghuo on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：異常處理的三個好習慣](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：編寫地道迴圈的兩個建議](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


