# Python 工匠：編寫地道迴圈的兩個建議

## 前言

> 這是 “Python 工匠”系列的第 7 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/04/lai-man-nung-1205465-unsplash_w1280.jpg" width="100%" />
</div>

迴圈是一種常用的程式控制結構。我們常說，機器相比人類的最大優點之一，就是機器可以不眠不休的重複做某件事情，但人卻不行。而**“迴圈”**，則是實現讓機器不斷重複工作的關鍵概念。

在迴圈語法方面，Python 表現的即傳統又不傳統。它雖然拋棄了常見的 `for (init; condition; incrment)` 三段式結構，但還是選擇了 `for` 和 `while` 這兩個經典的關鍵字來表達迴圈。絕大多數情況下，我們的迴圈需求都可以用  `for <item> in <iterable>` 來滿足，`while <condition>` 相比之下用的則更少些。

雖然迴圈的語法很簡單，但是要寫好它確並不容易。在這篇文章裡，我們將探討什麼是“地道”的迴圈程式碼，以及如何編寫它們。

## 什麼是“地道”的迴圈？

“地道”這個詞，通常被用來形容某人做某件事情時，非常符合當地傳統，做的非常好。打個比方，你去參加一個朋友聚會，同桌的有一位廣東人，對方一開口，句句都是標準京腔、完美兒化音。那你可以對她說：“您的北京話說的真**地道**”。

既然“地道”這個詞形容的經常是口音、做菜的口味這類實實在在的東西，那“地道”的迴圈程式碼又是什麼意思呢？讓我拿一個經典的例子來解釋一下。

如果你去問一位剛學習 Python 一個月的人：“*如何在遍歷一個列表的同時獲取當前下標？*”。他可能會交出這樣的程式碼：

```python
index = 0
for name in names:
    print(index, name)
    index += 1
```

上面的迴圈雖然沒錯，但它確一點都不“地道”。一個擁有三年 Python 開發經驗的人會說，程式碼應該這麼寫：

```python
for i, name in enumerate(names):
    print(i, name)
```

[`enumerate()`](https://docs.python.org/3/library/functions.html#enumerate) 是 Python 的一個內建函式，它接收一個“可迭代”物件作為引數，然後返回一個不斷生成 `(當前下標, 當前元素)` 的新可迭代物件。這個場景使用它最適合不過。

所以，在上面的例子裡，我們會認為第二段迴圈程式碼比第一段更“地道”。因為它用更直觀的程式碼，更聰明的完成了工作。

### enumerate() 所代表的程式設計思路

不過，判斷某段迴圈程式碼是否地道，並不僅僅是以知道或不知道某個內建方法作為標準。我們可以從上面的例子挖掘出更深層的東西。

如你所見，Python 的 `for` 迴圈只有 `for <item> in <iterable>` 這一種結構，而結構裡的前半部分 - *賦值給 item* - 沒有太多花樣可玩。所以後半部分的 **可迭代物件** 是我們唯一能夠大做文章的東西。而以 `enumerate()` 函式為代表的*“修飾函式”*，剛好提供了一種思路：**透過修飾可迭代物件來最佳化迴圈本身。**

這就引出了我的第一個建議。

## 建議1：使用函式修飾被迭代物件來最佳化迴圈

使用修飾函式處理可迭代物件，可以在各種方面影響迴圈程式碼。而要找到合適的例子來演示這個方法，並不用去太遠，內建模組 [itertools](https://docs.python.org/3.6/library/itertools.html) 就是一個絕佳的例子。

簡單來說，itertools 是一個包含很多面向可迭代物件的工具函式集。我在之前的系列文章[《容器的門道》](https://www.zlovezl.cn/articles/mastering-container-types/)裡提到過它。

如果要學習 itertools，那麼 [Python 官方文件](https://docs.python.org/3.6/library/itertools.html) 是你的首選，裡面有非常詳細的模組相關資料。但在這篇文章裡，側重點將和官方文件稍有不同。我會透過一些常見的程式碼場景，來詳細解釋它是如何改善迴圈程式碼的。

### 1. 使用 product 扁平化多層巢狀迴圈

雖然我們都知道*“扁平的程式碼比巢狀的好”*。但有時針對某類需求，似乎一定得寫多層巢狀迴圈才行。比如下面這段：

```python
def find_twelve(num_list1, num_list2, num_list3):
    """從 3 個數字列表中，尋找是否存在和為 12 的 3 個數
    """
    for num1 in num_list1:
        for num2 in num_list2:
            for num3 in num_list3:
                if num1 + num2 + num3 == 12:
                    return num1, num2, num3
```

對於這種需要巢狀遍歷多個物件的多層迴圈程式碼，我們可以使用 [product()](https://docs.python.org/3.6/library/itertools.html#itertools.product) 函式來最佳化它。`product()` 可以接收多個可迭代物件，然後根據它們的笛卡爾積不斷生成結果。


```python
from itertools import product


def find_twelve_v2(num_list1, num_list2, num_list3):
    for num1, num2, num3 in product(num_list1, num_list2, num_list3):
        if num1 + num2 + num3 == 12:
            return num1, num2, num3
```

相比之前的程式碼，使用 `product()` 的函式只用了一層 for 迴圈就完成了任務，程式碼變得更精煉了。

### 2. 使用 islice 實現迴圈內隔行處理

有一份包含 Reddit 帖子標題的外部資料檔案，裡面的內容格式是這樣的：

```
python-guide: Python best practices guidebook, written for humans.
---
Python 2 Death Clock
---
Run any Python Script with an Alexa Voice Command
---
<... ...>
```

可能是為了美觀，在這份檔案裡的每兩個標題之間，都有一個 `"---"` 分隔符。現在，我們需要獲取檔案裡所有的標題列表，所以在遍歷檔案內容的過程中，必須跳過這些無意義的分隔符。

參考之前對 `enumerate()` 函式的瞭解，我們可以透過在迴圈內加一段基於當前迴圈序號的 `if` 判斷來做到這一點：

```python
def parse_titles(filename):
    """從隔行資料檔案中讀取 reddit 主題名稱
    """
    with open(filename, 'r') as fp:
        for i, line in enumerate(fp):
            # 跳過無意義的 '---' 分隔符
            if i % 2 == 0:
                yield line.strip()
```

但對於這類在迴圈內進行隔行處理的需求來說，如果使用 itertools 裡的 [islice()](https://docs.python.org/3.6/library/itertools.html#itertools.islice) 函式修飾被迴圈物件，可以讓迴圈體程式碼變得更簡單直接。

`islice(seq, start, end, step)` 函式和陣列切片操作*（ list[start:stop:step] ）*有著幾乎一模一樣的引數。如果需要在迴圈內部進行隔行處理的話，只要設定第三個遞進步長引數 step 值為 2 即可*（預設為 1）*。

```python
from itertools import islice

def parse_titles_v2(filename):
    with open(filename, 'r') as fp:
        # 設定 step=2，跳過無意義的 '---' 分隔符
        for line in islice(fp, 0, None, 2):
            yield line.strip()
```

### 3. 使用 takewhile 替代 break 語句

有時，我們需要在每次迴圈開始時，判斷迴圈是否需要提前結束。比如下面這樣：

```python
for user in users:
    # 當第一個不合格的使用者出現後，不再進行後面的處理
    if not is_qualified(user):
        break

    # 進行處理 ... ...
```

對於這類需要提前中斷的迴圈，我們可以使用 [takewhile()](https://docs.python.org/3.6/library/itertools.html#itertools.takewhile) 函式來簡化它。`takewhile(predicate, iterable)` 會在迭代 `iterable` 的過程中不斷使用當前物件作為引數呼叫 `predicate` 函式並測試返回結果，如果函式返回值為真，則生成當前物件，迴圈繼續。否則立即中斷當前迴圈。

使用 `takewhile` 的程式碼樣例：

```
from itertools import takewhile

for user in takewhile(is_qualified, users):
    # 進行處理 ... ...
```

itertools 裡面還有一些其他有意思的工具函式，他們都可以用來和迴圈搭配使用，比如使用 chain 函式扁平化雙層巢狀迴圈、使用 zip_longest 函式一次同時迴圈多個物件等等。

篇幅有限，我在這裡不再一一介紹。如果有興趣，可以自行去官方文件詳細瞭解。

### 4. 使用生成器編寫自己的修飾函式

除了 itertools 提供的那些函式外，我們還可以非常方便的使用生成器來定義自己的迴圈修飾函式。

讓我們拿一個簡單的函式舉例：

```python
def sum_even_only(numbers):
    """對 numbers 裡面所有的偶數求和"""
    result = 0
    for num in numbers:
        if num % 2 == 0:
            result += num
    return result
```

在上面的函式裡，迴圈體內為了過濾掉所有奇數，引入了一條額外的 `if` 判斷語句。如果要簡化迴圈體內容，我們可以定義一個生成器函式來專門進行偶數過濾：

```python
def even_only(numbers):
    for num in numbers:
        if num % 2 == 0:
            yield num


def sum_even_only_v2(numbers):
    """對 numbers 裡面所有的偶數求和"""
    result = 0
    for num in even_only(numbers):
        result += num
    return result
```

將 `numbers` 變數使用 `even_only` 函式裝飾後，`sum_even_only_v2` 函式內部便不用繼續關注“偶數過濾”邏輯了，只需要簡單完成求和即可。

> Hint：當然，上面的這個函式其實並不實用。在現實世界裡，這種簡單需求最適合直接用生成器/列表表示式搞定：`sum(num for num in numbers if num % 2 == 0)`

## 建議2：按職責拆解迴圈體內複雜程式碼塊

我一直覺得迴圈是一個比較神奇的東西，每當你寫下一個新的迴圈程式碼塊，就好像開闢了一片黑魔法陣，陣內的所有內容都會開始無休止的重複執行。

但我同時發現，這片黑魔法陣除了能帶來好處，**它還會引誘你不斷往陣內塞入越來越多的程式碼，包括過濾掉無效元素、預處理資料、列印日誌等等。甚至一些原本不屬於同一抽象的內容，也會被塞入到同一片黑魔法陣內。**

你可能會覺得這一切理所當然，我們就是迫切需要陣內的魔法效果。如果不把這一大堆邏輯塞滿到迴圈體內，還能把它們放哪去呢？

讓我們來看看下面這個業務場景。在網站中，有一個每 30 天執行一次的週期指令碼，它的任務是是查詢過去 30 天內，在每週末特定時間段登入過的使用者，然後為其傳送獎勵積分。

程式碼如下：

```python
import time
import datetime


def award_active_users_in_last_30days():
    """獲取所有在過去 30 天週末晚上 8 點到 10 點登入過的使用者，為其傳送獎勵積分
    """
    days = 30
    for days_delta in range(days):
        dt = datetime.date.today() - datetime.timedelta(days=days_delta)
        # 5: Saturday, 6: Sunday
        if dt.weekday() not in (5, 6):
            continue

        time_start = datetime.datetime(dt.year, dt.month, dt.day, 20, 0)
        time_end = datetime.datetime(dt.year, dt.month, dt.day, 23, 0)

        # 轉換為 unix 時間戳，之後的 ORM 查詢需要
        ts_start = time.mktime(time_start.timetuple())
        ts_end = time.mktime(time_end.timetuple())

        # 查詢使用者並挨個傳送 1000 獎勵積分
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            # 這裡可以新增複雜邏輯
            send_awarding_points(record.user_id, 1000)
```

上面這個函式主要由兩層迴圈構成。外層迴圈的職責，主要是獲取過去 30 天內符合要求的時間，並將其轉換為 UNIX 時間戳。之後由內層迴圈使用這兩個時間戳進行積分發送。

如之前所說，外層迴圈所開闢的黑魔法陣內被塞的滿滿當當。但透過觀察後，我們可以發現 **整個迴圈體其實是由兩個完全無關的任務構成的：“挑選日期與準備時間戳” 以及 “傳送獎勵積分”**。

### 複雜迴圈體如何應對新需求

這樣的程式碼有什麼壞處呢？讓我來告訴你。

某日，產品找過來說，有一些使用者週末半夜不睡覺，還在刷我們的網站，我們得給他們發通知讓他們以後早點睡覺。於是新需求出現了：**“給過去 30 天內在週末凌晨 3 點到 5 點登入過的使用者傳送一條通知”**。

新問題也隨之而來。敏銳如你，肯定一眼可以發現，這個新需求在使用者篩選部分的要求，和之前的需求非常非常相似。但是，如果你再開啟之前那團迴圈體看看，你會發現程式碼根本沒法複用，因為在迴圈內部，不同的邏輯完全被 **耦合** 在一起了。☹️

在計算機的世界裡，我們經常用**“耦合”**這個詞來表示事物之間的關聯關係。上面的例子中，*“挑選時間”*和*“傳送積分”*這兩件事情身處同一個迴圈體內，建立了非常強的耦合關係。

為了更好的進行程式碼複用，我們需要把函式裡的*“挑選時間”*部分從迴圈體中解耦出來。而我們的老朋友，**“生成器函式”**是進行這項工作的不二之選。

### 使用生成器函式解耦迴圈體

要把 *“挑選時間”* 部分從迴圈內解耦出來，我們需要定義新的生成器函式 `gen_weekend_ts_ranges()`，專門用來生成需要的 UNIX 時間戳：

```python
def gen_weekend_ts_ranges(days_ago, hour_start, hour_end):
    """生成過去一段時間內週六日特定時間段範圍，並以 UNIX 時間戳返回
    """
    for days_delta in range(days_ago):
        dt = datetime.date.today() - datetime.timedelta(days=days_delta)
        # 5: Saturday, 6: Sunday
        if dt.weekday() not in (5, 6):
            continue

        time_start = datetime.datetime(dt.year, dt.month, dt.day, hour_start, 0)
        time_end = datetime.datetime(dt.year, dt.month, dt.day, hour_end, 0)

        # 轉換為 unix 時間戳，之後的 ORM 查詢需要
        ts_start = time.mktime(time_start.timetuple())
        ts_end = time.mktime(time_end.timetuple())
        yield ts_start, ts_end
```

有了這個生成器函式後，舊需求“傳送獎勵積分”和新需求“傳送通知”，就都可以在迴圈體內複用它來完成任務了：

```python
def award_active_users_in_last_30days_v2():
    """傳送獎勵積分"""
    for ts_start, ts_end in gen_weekend_ts_ranges(30, hour_start=20, hour_end=23):
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            send_awarding_points(record.user_id, 1000)


def notify_nonsleep_users_in_last_30days():
    """傳送通知"""
    for ts_start, ts_end in gen_weekend_ts_range(30, hour_start=3, hour_end=6):
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            notify_user(record.user_id, 'You should sleep more')
```

## 總結

在這篇文章裡，我們首先簡單解釋了“地道”迴圈程式碼的定義。然後提出了第一個建議：使用修飾函式來改善迴圈。之後我虛擬了一個業務場景，描述了按職責拆解迴圈內程式碼的重要性。

一些要點總結：

- 使用函式修飾被迴圈物件本身，可以改善迴圈體內的程式碼
- itertools 裡面有很多工具函式都可以用來改善迴圈
- 使用生成器函式可以輕鬆定義自己的修飾函式
- 迴圈內部，是一個極易發生“程式碼膨脹”的場地
- 請使用生成器函式將迴圈內不同職責的程式碼塊解耦出來，獲得更好的靈活性

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【8.使用裝飾器的技巧】](8-tips-on-decorators.md)

[<<<上一篇【6.異常處理的三個好習慣】](6-three-rituals-of-exceptions-handling.md)

## 附錄

- 題圖來源: Photo by Lai man nung on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：容器的門道](https://www.zlovezl.cn/articles/mastering-container-types/)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：異常處理的三個好習慣](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)



