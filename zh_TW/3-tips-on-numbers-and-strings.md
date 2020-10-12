# Python 工匠：使用數字與字串的技巧


## 序言

> 這是 “Python 工匠”系列的第 3 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

數字是幾乎所有程式語言裡最基本的資料型別，它是我們透過程式碼連線現實世界的基礎。在 Python 裡有三種數值型別：整型（int）、浮點型（float）和複數（complex）。絕大多數情況下，我們只需要和前兩種打交道。

整型在 Python 中比較讓人省心，因為它不區分有無符號並且永不溢位。但浮點型仍和絕大多數其他程式語言一樣，依然有著精度問題，經常讓很多剛進入程式設計世界大門的新人們感到困惑：["Why Are Floating Point Numbers Inaccurate?"](https://stackoverflow.com/questions/21895756/why-are-floating-point-numbers-inaccurate)。

相比數字，Python 裡的字串要複雜的多。要掌握它，你得先弄清楚 bytes 和 str 的區別。如果更不巧，你還是位 Python2 使用者的話，光 unicode 和字元編碼問題就夠你喝上好幾壺了*（趕快遷移到 Python3 吧，就在今天！）*。

不過，上面提到的這些都不是這篇文章的主題，如果感興趣，你可以在網上找到成堆的相關資料。在這篇文章裡，我們將討論一些 **更細微、更不常見** 的程式設計實踐。來幫助你寫出更好的 Python 程式碼。

### 內容目錄

* [最佳實踐](#最佳實踐)
    * [1. 少寫數字字面量](#1-少寫數字字面量)
        * [使用 enum 列舉型別改善程式碼](#使用-enum-列舉型別改善程式碼)
    * [2. 別在裸字串處理上走太遠](#2-別在裸字串處理上走太遠)
    * [3. 不必預計算字面量表達式](#3-不必預計算字面量表達式)
* [實用技巧](#實用技巧)
    * [1. 布林值其實也是“數字”](#1-布林值其實也是數字)
    * [2. 改善超長字串的可讀性](#2-改善超長字串的可讀性)
        * [當多級縮排裡出現多行字串時](#當多級縮排裡出現多行字串時)
    * [3. 別忘了那些 “r” 開頭的內建字串函式](#3-別忘了那些-r-開頭的內建字串函式)
    * [4. 使用“無窮大” float("inf")](#4-使用無窮大-floatinf)
* [常見誤區](#常見誤區)
    * [1. “value  = 1” 並非執行緒安全](#1-value--1-並非執行緒安全)
    * [2. 字串拼接並不慢](#2-字串拼接並不慢)
* [結語](#結語)

## 最佳實踐

### 1. 少寫數字字面量

“數字字面量（integer literal）” 是指那些直接出現在程式碼裡的數字。它們分佈在程式碼裡的各個角落，比如程式碼 `del users[0]` 裡的 `0` 就是一個數字字面量。它們簡單、實用，每個人每天都在寫。**但是，當你的程式碼裡不斷重複出現一些特定字面量時，你的“程式碼質量告警燈”就應該亮起黃燈 🚥 了。**

舉個例子，假如你剛加入一家心儀已久的新公司，同事轉交給你的專案裡有這麼一個函式：

```python
def mark_trip_as_featured(trip):
    """將某個旅程新增到推薦欄目
    """
    if trip.source == 11:
        do_some_thing(trip)
    elif trip.source == 12:
        do_some_other_thing(trip)
    ... ...
    return
```

這個函式做了什麼事？你努力想搞懂它的意思，不過 `trip.source == 11` 是什麼情況？那 `== 12` 呢？這兩行程式碼很簡單，沒有用到任何魔法特性。但初次接觸程式碼的你可能需要花費**一整個下午**，才能弄懂它們的含義。

**問題就出在那幾個數字字面量上。** 最初寫下這個函式的人，可能是在公司成立之初加入的那位元老程式設計師。而他對那幾個數字的含義非常清楚。但如果你是一位剛接觸這段程式碼的新人，就完全是另外一碼事了。

#### 使用 enum 列舉型別改善程式碼

那麼，怎麼改善這段程式碼？最直接的方式，就是為這兩個條件分支添加註釋。不過在這裡，“添加註釋”顯然不是提升程式碼可讀性的最佳辦法*（其實在絕大多數其他情況下都不是）*。我們需要用有意義的名稱來代替這些字面量，而`列舉型別（enum）`用在這裡最合適不過了。

`enum` 是 Python 自 3.4 版本引入的內建模組，如果你使用的是更早的版本，可以透過 `pip install enum34` 來安裝它。下面是使用 enum 的樣例程式碼：

```python
# -*- coding: utf-8 -*-
from enum import IntEnum

class TripSource(IntEnum):
    FROM_WEBSITE = 11
    FROM_IOS_CLIENT = 12


def mark_trip_as_featured(trip):
    if trip.source == TripSource.FROM_WEBSITE:
        do_some_thing(trip)
    elif trip.source == TripSource.FROM_IOS_CLIENT:
        do_some_other_thing(trip)
    ... ...
    return
```

將重複出現的數字字面量定義成列舉型別，不光可以改善程式碼的可讀性，程式碼出現 Bug 的機率也會降低。

試想一下，如果你在某個分支判斷時將 `11` 錯打成了 `111` 會怎麼樣？我們時常會犯這種錯，而這類錯誤在早期特別難被發現。將這些數字字面量全部放入列舉型別中可以比較好的規避這類問題。類似的，將字串字面量改寫成列舉也可以獲得同樣的好處。

使用列舉型別代替字面量的好處：

- **提升程式碼可讀性**：所有人都不需要記憶某個神奇的數字代表什麼
- **提升程式碼正確性**：減少打錯數字或字母產生 bug 的可能性

當然，你完全沒有必要把程式碼裡的所有字面量都改成列舉型別。 **程式碼裡出現的字面量，只要在它所處的上下文裡面容易理解，就可以使用它。** 比如那些經常作為數字下標出現的 `0` 和 `-1` 就完全沒有問題，因為所有人都知道它們的意思。

### 2. 別在裸字串處理上走太遠

什麼是“裸字串處理”？在這篇文章裡，它指**只使用基本的加減乘除和迴圈、配合內建函式/方法來操作字串，獲得我們需要的結果。**

所有人都寫過這樣的程式碼。有時候我們需要拼接一大段發給使用者的告警資訊，有時我們需要構造一大段傳送給資料庫的 SQL 查詢語句，就像下面這樣：

```python
def fetch_users(conn, min_level=None, gender=None, has_membership=False, sort_field="created"):
    """獲取使用者列表
   
    :param int min_level: 要求的最低使用者級別，預設為所有級別
    :param int gender: 篩選使用者性別，預設為所有性別
    :param int has_membership: 篩選所有會員/非會員使用者，預設非會員
    :param str sort_field: 排序欄位，預設為按 created "使用者建立日期"
    :returns: 列表：[(User ID, User Name), ...]
    """
    # 一種古老的 SQL 拼接技巧，使用 "WHERE 1=1" 來簡化字串拼接操作
    # 區分查詢 params 來避免 SQL 注入問題
    statement = "SELECT id, name FROM users WHERE 1=1"
    params = []
    if min_level is not None:
        statement += " AND level >= ?"
        params.append(min_level)
    if gender is not None:
        statement += " AND gender >= ?"
        params.append(gender)
    if has_membership:
        statement += " AND has_membership == true"
    else:
        statement += " AND has_membership == false"
    
    statement += " ORDER BY ?"
    params.append(sort_field)
    return list(conn.execute(statement, params))
```

我們之所以用這種方式拼接出需要的字串 - *在這裡是 SQL 語句* - 是因為這樣做簡單、直接，符合直覺。但是這樣做最大的問題在於：**隨著函式邏輯變得更復雜，這段拼接程式碼會變得容易出錯、難以擴充套件。**事實上，上面這段 Demo 程式碼也只是僅僅做到**看上去**沒有明顯的 bug 而已 *（誰知道有沒有其他隱藏問題）*。

其實，對於 SQL 語句這種結構化、有規則的字串，用物件化的方式構建和編輯它才是更好的做法。下面這段程式碼用 [SQLAlchemy](https://www.sqlalchemy.org/) 模組完成了同樣的功能：

```python
def fetch_users_v2(conn, min_level=None, gender=None, has_membership=False, sort_field="created"):
    """獲取使用者列表
    """
    query = select([users.c.id, users.c.name])
    if min_level is not None:
        query = query.where(users.c.level >= min_level)
    if gender is not None:
        query = query.where(users.c.gender == gender)
    query = query.where(users.c.has_membership == has_membership).order_by(users.c[sort_field])
    return list(conn.execute(query))
```

上面的 `fetch_users_v2` 函式更短也更好維護，而且根本不需要擔心 SQL 注入問題。所以，當你的程式碼中出現複雜的裸字串處理邏輯時，請試著用下面的方式替代它：

`Q: 目標/源字串是結構化的，遵循某種格式嗎？`

- 是：找找是否已經有開源的物件化模組操作它們，或是自己寫一個
    - SQL：SQLAlchemy
    - XML：lxml
    - JSON、YAML ...
- 否：嘗試使用模板引擎而不是複雜字串處理邏輯來達到目的
    - Jinja2
    - Mako
    - Mustache

### 3. 不必預計算字面量表達式

我們的程式碼裡偶爾會出現一些比較複雜的數字，就像下面這樣：

```python
def f1(delta_seconds):
    # 如果時間已經過去了超過 11 天，不做任何事
    if delta_seconds > 950400:
        return 
    ...
```

話說在前頭，上面的程式碼沒有任何毛病。

首先，我們在小本子（當然，和我一樣的聰明人會用 IPython）上算了算：`11天一共包含多少秒？`。然後再把結果 `950400` 這個神奇的數字填進我們的程式碼裡，最後心滿意足的在上面補上一行註釋：告訴所有人這個神奇的數字是怎麼來的。

我想問的是：*“為什麼我們不直接把程式碼寫成 `if delta_seconds < 11 * 24 * 3600:` 呢？”*

**“效能”，答案一定會是“效能”**。我們都知道 Python 是一門~~（速度欠佳的）~~解釋型語言，所以預先計算出 `950400` 正是因為我們不想讓每次對函式 `f1` 的呼叫都帶上這部分的計算開銷。不過事實是：**即使我們把程式碼改成 `if delta_seconds < 11 * 24 * 3600:`，函式也不會多出任何額外的開銷。**

Python 程式碼在執行時會被直譯器編譯成位元組碼，而真相就藏在位元組碼裡。讓我們用 dis 模組看看：

```python
def f1(delta_seconds):
    if delta_seconds < 11 * 24 * 3600:
        return

import dis
dis.dis(f1)

# dis 執行結果
  5           0 LOAD_FAST                0 (delta_seconds)
              2 LOAD_CONST               1 (950400)
              4 COMPARE_OP               0 (<)
              6 POP_JUMP_IF_FALSE       12

  6           8 LOAD_CONST               0 (None)
             10 RETURN_VALUE
        >>   12 LOAD_CONST               0 (None)
             14 RETURN_VALUE
```

看見上面的 `2 LOAD_CONST               1 (950400)` 了嗎？這表示 Python 直譯器在將原始碼編譯成成位元組碼時，會計算 `11 * 24 * 3600` 這段整表示式，並用 `950400` 替換它。

所以，**當我們的程式碼中需要出現複雜計算的字面量時，請保留整個算式吧。它對效能沒有任何影響，而且會增加程式碼的可讀性。**

> Hint：Python 直譯器除了會預計算數值字面量表達式以外，還會對字串、列表做類似的操作。一切都是為了效能。誰讓你們老吐槽 Python 慢呢？

## 實用技巧

### 1. 布林值其實也是“數字”

Python 裡的兩個布林值 `True` 和 `False` 在絕大多數情況下都可以直接等價於 `1`  和 `0` 兩個整數來使用，就像這樣：

```python
>>> True + 1
2
>>> 1 / False
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ZeroDivisionError: division by zero
```

那麼記住這點有什麼用呢？首先，它們可以配合 `sum` 函式在需要計算總數時簡化操作：

```python
>>> l = [1, 2, 4, 5, 7]
>>> sum(i % 2 == 0 for i in l)
2
```

此外，如果將某個布林值表示式作為列表的下標使用，可以實現類似三元表示式的目的：

```python
# 類似的三元表示式："Javascript" if 2 > 1 else "Python"
>>> ["Python", "Javascript"][2 > 1]
'Javascript'
```

### 2. 改善超長字串的可讀性

單行程式碼的長度不宜太長。比如 PEP8 裡就建議每行字元數不得超過 **79**。現實世界裡，大部分人遵循的單行最大字元數在 79 到 119 之間。如果只是程式碼，這樣的要求是比較容易達到的，但假設程式碼裡需要出現一段超長的字串呢？

這時，除了使用斜槓 `\` 和加號 `+` 將長字串拆分為好幾段以外，還有一種更簡單的辦法：**使用括號將長字串包起來，然後就可以隨意折行了**：

```python
def main():
    logger.info(("There is something really bad happened during the process. "
                 "Please contact your administrator."))
```

#### 當多級縮排裡出現多行字串時

日常編碼時，還有一種比較麻煩的情況。就是需要在已經有縮排層級的程式碼裡，插入多行字串字面量。因為多行字串不能包含當前的縮排空格，所以，我們需要把程式碼寫成這樣：

```python
def main():
    if user.is_active:
        message = """Welcome, today's movie list:
- Jaw (1975)
- The Shining (1980)
- Saw (2004)"""
```

但是這樣寫會破壞整段程式碼的縮排視覺效果，顯得非常突兀。要改善它有很多種辦法，比如我們可以把這段多行字串作為變數提取到模組的最外層。不過，如果在你的程式碼邏輯裡更適合用字面量的話，你也可以用標準庫 `textwrap` 來解決這個問題：

```
from textwrap import dedent

def main():
    if user.is_active:
        # dedent 將會縮排掉整段文字最左邊的空字串
        message = dedent("""\
            Welcome, today's movie list:
            - Jaw (1975)
            - The Shining (1980)
            - Saw (2004)""")
```

#### 大數字也可以變得更加可讀

> 該小節內容由 [@laixintao](https://github.com/laixintao) 提供。

對那些特別大的數字，可以透過在中間新增下劃線來提高可讀性
([PEP515](https://www.python.org/dev/peps/pep-0515/)，需要 Python3.6+)。

比如：

```
>>> 10_000_000.0  # 以“千”為單位劃分數字
10000000.0
>>> 0xCAFE_F00D  # 16進位制數字同樣有效，4個一組更易讀
3405705229
>>> 0b_0011_1111_0100_1110  # 二進位制也有效
16206
>>> int('0b_1111_0000', 2)  # 處理字串的時候也會正確處理下劃線
240
```

### 3. 別忘了那些 “r” 開頭的內建字串函式

Python 的字串有著非常多實用的內建方法，最常用的有 `.strip()`、`.split()` 等。這些內建方法裡的大多數，處理起來的順序都是從左往右。但是其中也包含了部分以 `r` 打頭的**從右至左處理**的映象方法。在處理特定邏輯時，使用它們可以讓你事半功倍。

假設我們需要解析一些訪問日誌，日誌格式為："{user_agent}" {content_length}：

    >>> log_line = '"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36" 47632'


如果使用 `.split()` 將日誌拆分為 `(user_agent, content_length) `，我們需要這麼寫：

```python
>>> l = log_line.split()
>>> " ".join(l[:-1]), l[-1]
('"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"', '47632')
```

但是如果使用 `.rsplit()` 的話，處理邏輯就更直接了：

```python
>>> log_line.rsplit(None, 1)
['"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"', '47632']
```


### 4. 使用“無窮大” float("inf")

如果有人問你：*“Python 裡什麼數字最大/最小？”*。你應該怎麼回答？有這樣的東西存在嗎？

答案是：“有的，它們就是：`float("inf")` 和 `float("-inf")`”。它們倆分別對應著數學世界裡的正負無窮大。當它們和任意數值進行比較時，滿足這樣的規律：`float("-inf") < 任意數值 < float("inf")`。

因為它們有著這樣的特點，我們可以在某些場景用上它們：

```python
# A. 根據年齡升序排序，沒有提供年齡放在最後邊
>>> users = {"tom": 19, "jenny": 13, "jack": None, "andrew": 43}
>>> sorted(users.keys(), key=lambda user: users.get(user) or float('inf'))
['jenny', 'tom', 'andrew', 'jack']

# B. 作為迴圈初始值，簡化第一次判斷邏輯
>>> max_num = float('-inf')
>>> # 找到列表中最大的數字
>>> for i in [23, 71, 3, 21, 8]:
...:    if i > max_num:
...:         max_num = i
...:
>>> max_num
71
```

## 常見誤區

### 1. “value += 1” 並非執行緒安全

當我們編寫多執行緒程式時，經常需要處理複雜的共享變數和競態等問題。

“執行緒安全”，通常被用來形容 **某個行為或者某類資料結構，可以在多執行緒環境下被共享使用併產生預期內的結果。**一個典型的滿足“執行緒安全”的模組就是 [queue 佇列模組](https://docs.python.org/3/library/queue.html)。

而我們常做的 `value += 1` 操作，很容易被想當然的認為是“執行緒安全”的。因為它看上去就是一個原子操作 *（指一個最小的操作單位，執行途中不會插入任何其他操作）*。然而真相併非如此，雖然從 Python 程式碼上來看，`value += 1` 這個操作像是原子的。但它最終被 Python 直譯器執行的時候，早就不再 *“原子”* 了。

我們可以用前面提到的 `dis` 模組來驗證一下：

```
def incr(value):
    value += 1


# 使用 dis 模組檢視位元組碼
import dis

dis.dis(incr)
      0 LOAD_FAST                0 (value)
      2 LOAD_CONST               1 (1)
      4 INPLACE_ADD
      6 STORE_FAST               0 (value)
      8 LOAD_CONST               0 (None)
     10 RETURN_VALUE
```

在上面輸出結果中，可以看到這個簡單的累加語句，會被編譯成包括取值和儲存在內的好幾個不同步驟，而在多執行緒環境下，任意一個其他執行緒都有可能在其中某個步驟切入進來，阻礙你獲得正確的結果。

**因此，請不要憑藉自己的直覺來判斷某個行為是否“執行緒安全”，不然等程式在高併發環境下出現奇怪的 bug 時，你將為自己的直覺付出慘痛的代價。**

### 2. 字串拼接並不慢

我剛接觸 Python 不久時，在某個網站看到這樣一個說法： *“Python 裡的字串是不可變的，所以每一次對字串進行拼接都會生成一個新物件，導致新的記憶體分配，效率非常低”。* 我對此深信不疑。

所以，一直以來，我儘量都在避免使用 `+=` 的方式去拼接字串，而是用 `"".join(str_list)` 之類的方式來替代。

但是，在某個偶然的機會下，我對 Python 的字串拼接做了一次簡單的效能測試後發現： **Python 的字串拼接根本就不慢！** 在查閱了一些資料後，最終發現了真相。

Python 的字串拼接在 2.2 以及之前的版本確實很慢，和我最早看到的說法行為一致。但是因為這個操作太常用了，所以之後的版本里專門針對它做了效能最佳化。大大提升了執行效率。

如今使用 `+=` 的方式來拼接字串，效率已經非常接近 `"".join(str_list)` 了。所以，該拼接時就拼接吧，不必擔心任何效能問題。

> Hint: 如果你想了解更詳細的相關內容，可以讀一下這篇文章：[Python - Efficient String Concatenation in Python (2016 edition) - smcl](http://blog.mclemon.io/python-efficient-string-concatenation-in-python-2016-edition)

## 結語

以上就是『Python 工匠』系列文章的第三篇，內容比較零碎。由於篇幅原因，一些常用的操作比如字串格式化等，文章裡並沒有涵蓋到。以後有機會再寫吧。

讓我們最後再總結一下要點：

- 編寫程式碼時，請考慮閱讀者的感受，不要出現太多神奇的字面量
- 當操作結構化字串時，使用物件化模組比直接處理更有優勢
- dis 模組非常有用，請多多使用它驗證你的猜測
- 多執行緒環境下的編碼非常複雜，要足夠謹慎，不要相信自己的直覺
- Python 語言的更新非常快，不要被別人的經驗所左右

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【4.容器的門道】](4-mastering-container-types.md)

[<<<上一篇【2.編寫條件分支程式碼的技巧】](2-if-else-block-secrets.md)


