# Python 工匠：編寫條件分支程式碼的技巧

## 序言

> 這是 “Python 工匠”系列的第 2 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

編寫條件分支程式碼是編碼過程中不可或缺的一部分。

如果用道路來做比喻，現實世界中的程式碼從來都不是一條筆直的高速公路，而更像是由無數個岔路口組成的某個市區地圖。我們編碼者就像是駕駛員，需要告訴我們的程式，下個路口需要往左還是往右。

編寫優秀的條件分支程式碼非常重要，因為糟糕、複雜的分支處理非常容易讓人困惑，從而降低程式碼質量。所以，這篇文章將會種重點談談在 Python 中編寫分支程式碼應該注意的地方。

### 內容目錄

* [最佳實踐](#最佳實踐)
    * [1. 避免多層分支巢狀](#1-避免多層分支巢狀)
    * [2. 封裝那些過於複雜的邏輯判斷](#2-封裝那些過於複雜的邏輯判斷)
    * [3. 留意不同分支下的重複程式碼](#3-留意不同分支下的重複程式碼)
    * [4. 謹慎使用三元表示式](#4-謹慎使用三元表示式)
* [常見技巧](#常見技巧)
    * [1. 使用“德摩根定律”](#1-使用德摩根定律)
    * [2. 自定義物件的“布林真假”](#2-自定義物件的布林真假)
    * [3. 在條件判斷中使用 all() / any()](#3-在條件判斷中使用-all--any)
    * [4. 使用 try/while/for 中 else 分支](#4-使用-trywhilefor-中-else-分支)
* [常見陷阱](#常見陷阱)
    * [1. 與 None 值的比較](#1-與-none-值的比較)
    * [2. 留意 and 和 or 的運算優先順序](#2-留意-and-和-or-的運算優先順序)
* [結語](#結語)
* [註解](#註解)

### Python 裡的分支程式碼

Python 支援最為常見的 `if/else` 條件分支語句，不過它缺少在其他程式語言中常見的 `switch/case` 語句。

除此之外，Python 還為 `for/while` 迴圈以及 `try/except` 語句提供了 else 分支，在一些特殊的場景下，它們可以大顯身手。

下面我會從 `最佳實踐`、`常見技巧`、`常見陷阱` 三個方面講一下如果編寫優秀的條件分支程式碼。

## 最佳實踐

### 1. 避免多層分支巢狀

如果這篇文章只能刪減成一句話就結束，那麼那句話一定是**“要竭盡所能的避免分支巢狀”**。

過深的分支巢狀是很多程式設計新手最容易犯的錯誤之一。假如有一位新手 JavaScript 程式設計師寫了很多層分支巢狀，那麼你可能會看到一層又一層的大括號：`if { if { if { ... }}}`。俗稱*“巢狀 if 地獄（Nested If Statement Hell）”*。

但是因為 Python 使用了縮排來代替 `{}`，所以過深的巢狀分支會產生比其他語言下更為嚴重的後果。比如過多的縮排層次很容易就會讓程式碼超過 [PEP8](https://www.python.org/dev/peps/pep-0008/) 中規定的每行字數限制。讓我們看看這段程式碼：

```Python
def buy_fruit(nerd, store):
    """去水果店買蘋果
    
    - 先得看看店是不是在營業
    - 如果有蘋果的話，就買 1 個
    - 如果錢不夠，就回家取錢再來
    """
    if store.is_open():
        if store.has_stocks("apple"):
            if nerd.can_afford(store.price("apple", amount=1)):
                nerd.buy(store, "apple", amount=1)
                return
            else:
                nerd.go_home_and_get_money()
                return buy_fruit(nerd, store)
        else:
            raise MadAtNoFruit("no apple in store!")
    else:
        raise MadAtNoFruit("store is closed!")
```

上面這段程式碼最大的問題，就是過於直接翻譯了原始的條件分支要求，導致短短十幾行程式碼包含了有三層巢狀分支。

這樣的程式碼可讀性和維護性都很差。不過我們可以用一個很簡單的技巧：**“提前結束”** 來最佳化這段程式碼：

```python
def buy_fruit(nerd, store):
    if not store.is_open():
        raise MadAtNoFruit("store is closed!")

    if not store.has_stocks("apple"):
        raise MadAtNoFruit("no apple in store!")

    if nerd.can_afford(store.price("apple", amount=1)):
        nerd.buy(store, "apple", amount=1)
        return
    else:
        nerd.go_home_and_get_money()
        return buy_fruit(nerd, store)
```

“提前結束”指：**在函式內使用 `return` 或 `raise` 等語句提前在分支內結束函式。**比如，在新的 `buy_fruit` 函式裡，當分支條件不滿足時，我們直接丟擲異常，結束這段這程式碼分支。這樣的程式碼沒有巢狀分支，更直接也更易讀。

### 2. 封裝那些過於複雜的邏輯判斷

如果條件分支裡的表示式過於複雜，出現了太多的 `not/and/or`，那麼這段程式碼的可讀性就會大打折扣，比如下面這段程式碼：

```
# 如果活動還在開放，並且活動剩餘名額大於 10，為所有性別為女性，或者級別大於 3
# 的活躍使用者發放 10000 個金幣
if activity.is_active and activity.remaining > 10 and \
        user.is_active and (user.sex == 'female' or user.level > 3):
    user.add_coins(10000)
    return
```

對於這樣的程式碼，我們可以考慮將具體的分支邏輯封裝成函式或者方法，來達到簡化程式碼的目的：

```
if activity.allow_new_user() and user.match_activity_condition():
    user.add_coins(10000)
    return
```

事實上，將程式碼改寫後，之前的註釋文字其實也可以去掉了。**因為後面這段程式碼已經達到了自說明的目的。**至於具體的 *什麼樣的使用者滿足活動條件？* 這種問題，就應由具體的 `match_activity_condition()` 方法來回答了。

> **Hint:** 恰當的封裝不光直接改善了程式碼的可讀性，事實上，如果上面的活動判斷邏輯在程式碼中出現了不止一次的話，封裝更是必須的。不然重複程式碼會極大的破壞這段邏輯的可維護性。

### 3. 留意不同分支下的重複程式碼

重複程式碼是程式碼質量的天敵，而條件分支語句又非常容易成為重複程式碼的重災區。所以，當我們編寫條件分支語句時，需要特別留意，不要生產不必要的重複程式碼。

讓我們看下這個例子：

```python
# 對於新使用者，建立新的使用者資料，否則更新舊資料
if user.no_profile_exists:
    create_user_profile(
        username=user.username,
        email=user.email,
        age=user.age,
        address=user.address,
        # 對於新建使用者，將使用者的積分置為 0
        points=0,
        created=now(),
    )
else:
    update_user_profile(
        username=user.username,
        email=user.email,
        age=user.age,
        address=user.address,
        updated=now(),
    )
```

在上面的程式碼中，我們可以一眼看出，在不同的分支下，程式呼叫了不同的函式，做了不一樣的事情。但是，因為那些重複程式碼的存在，**我們卻很難簡單的區分出，二者的不同點到底在哪。**

其實，得益於 Python 的動態特性，我們可以簡單的改寫一下上面的程式碼，讓可讀性可以得到顯著的提升：

```python
if user.no_profile_exists:
    profile_func = create_user_profile
    extra_args = {'points': 0, 'created': now()}
else:
    profile_func = update_user_profile
    extra_args = {'updated': now()}

profile_func(
    username=user.username,
    email=user.email,
    age=user.age,
    address=user.address,
    **extra_args
)
```

當你編寫分支程式碼時，請額外關注**由分支產生的重複程式碼塊**，如果可以簡單的消滅它們，那就不要遲疑。

### 4. 謹慎使用三元表示式

三元表示式是 Python 2.5 版本後才支援的語法。在那之前，Python 社群一度認為三元表示式沒有必要，我們需要使用 `x and a or b` 的方式來模擬它。[[注]](#annot1)

事實是，在很多情況下，使用普通的 `if/else` 語句的程式碼可讀性確實更好。盲目追求三元表示式很容易誘惑你寫出複雜、可讀性差的程式碼。

所以，請記得只用三元表示式處理簡單的邏輯分支。

```python
language = "python" if you.favor("dynamic") else "golang"
```

對於絕大多數情況，還是使用普通的 `if/else` 語句吧。

## 常見技巧

### 1. 使用“德摩根定律”

在做分支判斷時，我們有時候會寫成這樣的程式碼：

```python
# 如果使用者沒有登入或者使用者沒有使用 chrome，拒絕提供服務
if not user.has_logged_in or not user.is_from_chrome:
    return "our service is only available for chrome logged in user"
```

第一眼看到程式碼時，是不是需要思考一會才能理解它想幹嘛？這是因為上面的邏輯表示式裡面出現了 2 個 `not` 和 1 個 `or`。而我們人類恰好不擅長處理過多的“否定”以及“或”這種邏輯關係。

這個時候，就該 [德摩根定律](https://zh.wikipedia.org/wiki/%E5%BE%B7%E6%91%A9%E6%A0%B9%E5%AE%9A%E5%BE%8B) 出場了。通俗的說，德摩根定律就是 `not A or not B` 等價於 `not (A and B)`。透過這樣的轉換，上面的程式碼可以改寫成這樣：

```python
if not (user.has_logged_in and user.is_from_chrome):
    return "our service is only available for chrome logged in user"
```

怎麼樣，程式碼是不是易讀了很多？記住德摩根定律，很多時候它對於簡化條件分支裡的程式碼邏輯非常有用。

### 2. 自定義物件的“布林真假”

我們常說，在 Python 裡，“萬物皆物件”。其實，不光“萬物皆物件”，我們還可以利用很多魔法方法*（文件中稱為：[user-defined method](https://docs.python.org/3/reference/datamodel.html)）*，來自定義物件的各種行為。我們可以用很多在別的語言裡面無法做到、有些魔法的方式來影響程式碼的執行。

比如，Python 的所有物件都有自己的“布林真假”：

- 布林值為假的物件：`None`, `0`, `False`, `[]`, `()`, `{}`, `set()`, `frozenset()`, ... ...
- 布林值為真的物件：非 `0` 的數值、`True`，非空的序列、元組，普通的使用者類例項，... ...

透過內建函式 `bool()`，你可以很方便的檢視某個物件的布林真假。而 Python 進行條件分支判斷時用到的也是這個值：

```python
>>> bool(object())
True
```

重點來了，雖然所有使用者類例項的布林值都是真。但是 Python 提供了改變這個行為的辦法：**自定義類的 `__bool__` 魔法方法** *（在 Python 2.X 版本中為 `__nonzero__`）*。當類定義了 `__bool__` 方法後，它的返回值將會被當作類例項的布林值。

另外，`__bool__` 不是影響例項布林真假的唯一方法。如果類沒有定義 `__bool__` 方法，Python 還會嘗試呼叫 `__len__` 方法*（也就是對任何序列物件呼叫 `len` 函式）*，透過結果是否為 `0` 判斷例項真假。

那麼這個特性有什麼用呢？看看下面這段程式碼：

```python
class UserCollection(object):

    def __init__(self, users):
        self._users = users


users = UserCollection([piglei, raymond])

if len(users._users) > 0:
    print("There's some users in collection!")
```

上面的程式碼裡，判斷 `UserCollection` 是否有內容時用到了 `users._users` 的長度。其實，透過為 `UserCollection` 新增 `__len__` 魔法方法，上面的分支可以變得更簡單：

```python
class UserCollection:

    def __init__(self, users):
        self._users = users

    def __len__(self):
        return len(self._users)


users = UserCollection([piglei, raymond])

# 定義了 __len__ 方法後，UserCollection 物件本身就可以被用於布林判斷了
if users:
    print("There's some users in collection!")
```

透過定義魔法方法 `__len__` 和 `__bool__` ，我們可以讓類自己控制想要表現出的布林真假值，讓程式碼變得更 pythonic。

### 3. 在條件判斷中使用 all() / any()

`all()` 和 `any()` 兩個函式非常適合在條件判斷中使用。這兩個函式接受一個可迭代物件，返回一個布林值，其中：

- `all(seq)`：僅當 `seq` 中所有物件都為布林真時返回 `True`，否則返回 `False`
- `any(seq)`：只要 `seq` 中任何一個物件為布林真就返回 `True`，否則返回 `False`

假如我們有下面這段程式碼：

```python
def all_numbers_gt_10(numbers):
    """僅當序列中所有數字大於 10 時，返回 True
    """
    if not numbers:
        return False

    for n in numbers:
        if n <= 10:
            return False
    return True
```

如果使用 `all()` 內建函式，再配合一個簡單的生成器表示式，上面的程式碼可以寫成這樣：

```python
def all_numbers_gt_10_2(numbers):
    return bool(numbers) and all(n > 10 for n in numbers)
```

簡單、高效，同時也沒有損失可用性。

### 4. 使用 try/while/for 中 else 分支

讓我們看看這個函式：

```python
def do_stuff():
    first_thing_successed = False
    try:
        do_the_first_thing()
        first_thing_successed = True
    except Exception as e:
        print("Error while calling do_some_thing")
        return

    # 僅當 first_thing 成功完成時，做第二件事
    if first_thing_successed:
        return do_the_second_thing()
```

在函式 `do_stuff` 中，我們希望只有當 `do_the_first_thing()` 成功呼叫後*（也就是不丟擲任何異常）*，才繼續做第二個函式呼叫。為了做到這一點，我們需要定義一個額外的變數 `first_thing_successed` 來作為標記。

其實，我們可以用更簡單的方法達到同樣的效果：

```python
def do_stuff():
    try:
        do_the_first_thing()
    except Exception as e:
        print("Error while calling do_some_thing")
        return
    else:
        return do_the_second_thing()
```

在 `try` 語句塊最後追加上 `else` 分支後，分支下的`do_the_second_thing()` 便只會在 **try 下面的所有語句正常執行（也就是沒有異常，沒有 return、break 等）完成後執行**。

類似的，Python 裡的 `for/while` 迴圈也支援新增 `else` 分支，它們表示：當迴圈使用的迭代物件被正常耗盡、或 while 迴圈使用的條件變數變為 False 後才執行 else 分支下的程式碼。

## 常見陷阱

### 1. 與 None 值的比較

在 Python 中，有兩種比較變數的方法：`==` 和 `is`，二者在含義上有著根本的區別：

- `==`：表示二者所指向的的**值**是否一致
- `is`：表示二者是否指向記憶體中的同一份內容，也就是 `id(x)` 是否等於 `id(y)`

`None` 在 Python 語言中是一個單例物件，如果你要判斷某個變數是否為 None 時，記得使用 `is` 而不是 `==`，因為只有 `is` 才能在嚴格意義上表示某個變數是否是 None。

否則，可能出現下面這樣的情況：

```python
>>> class Foo(object):
...     def __eq__(self, other):
...         return True
...
>>> foo = Foo()
>>> foo == None
True
```

在上面程式碼中，Foo 這個類透過自定義 `__eq__` 魔法方法的方式，很容易就滿足了 `== None` 這個條件。

**所以，當你要判斷某個變數是否為 None 時，請使用 `is` 而不是 `==`。**

### 2. 留意 and 和 or 的運算優先順序

看看下面這兩個表示式，猜猜它們的值一樣嗎？

```python
>>> (True or False) and False
>>> True or False and False
```

答案是：不一樣，它們的值分別是 `False` 和 `True`，你猜對了嗎？

問題的關鍵在於：**`and` 運算子的優先順序大於 `or`**。因此上面的第二個表示式在 Python 看來實際上是 `True or (False and False)`。所以結果是 `True` 而不是 `False`。

在編寫包含多個 `and` 和 `or` 的表示式時，請額外注意 `and` 和 `or` 的運算優先順序。即使執行優先順序正好是你需要的那樣，你也可以加上額外的括號來讓程式碼更清晰。

## 結語

以上就是『Python 工匠』系列文章的第二篇。不知道文章的內容是否對你的胃口。

程式碼內的分支語句不可避免，我們在編寫程式碼時，需要尤其注意它的可讀性，避免對其他看到程式碼的人造成困擾。

看完文章的你，有沒有什麼想吐槽的？請留言告訴我吧。

[>>>下一篇【3.使用數字與字串的技巧】](3-tips-on-numbers-and-strings.md)

[<<<上一篇【1.善用變數來改善程式碼質量】](1-using-variables-well.md)

## 註解

1. <a id="annot1"></a>事實上 `x and a or b` 不是總能給你正確的結果，只有當 a 與 b 的布林值為真時，這個表示式才能正常工作，這是由邏輯運算的短路特性決定的。你可以在命令列中執行 `True and None or 0` 試試看，結果是 0 而非 None。

> 文章更新記錄：
> 
> - 2018.04.08：在與 @geishu 的討論後，調整了“運算優先符”使用的程式碼樣例
> - 2018.04.10：根據 @dongweiming 的建議，添加註解說明 "x and y or c" 表示式的陷阱


