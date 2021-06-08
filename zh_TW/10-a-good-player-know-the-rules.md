# Python 工匠：做一個精通規則的玩家

## 前言

> 這是 “Python 工匠”系列的第 10 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/05/jeshoots-com-632498-unsplash_w1280.jpg" width="100%" />
</div>

程式設計，其實和玩電子遊戲有一些相似之處。你在玩不同遊戲前，需要先學習每個遊戲的不同規則，只有熟悉和靈活運用遊戲規則，才更有可能在遊戲中獲勝。

而程式設計也是一樣，不同程式語言同樣有著不一樣的“規則”。大到是否支援面向物件，小到是否可以定義常量，程式語言的規則比絕大多數電子遊戲要複雜的多。

當我們程式設計時，如果直接拿一種語言的經驗套用到另外一種語言上，很多時候並不能取得最佳結果。這就好像一個 CS（反恐精英） 高手在不瞭解規則的情況下去玩 PUBG（絕地求生），雖然他的槍法可能萬中無一，但是極有可能在發現第一個敵人前，他就會倒在某個窩在草叢裡的敵人的伏擊下。

### Python 裡的規則

Python 是一門初見簡單、深入後愈覺複雜的語言。拿 Python 裡最重要的“物件”概念來說，Python 為其定義了多到讓你記不全的規則，比如：

- 定義了 `__str__` 方法的物件，就可以使用 `str()` 函式來返回可讀名稱
- 定義了 `__next__` 和 `__iter__` 方法的物件，就可以被迴圈迭代
- 定義了 `__bool__` 方法的物件，在進行布林判斷時就會使用自定義的邏輯
- ... ...

**熟悉規則，並讓自己的程式碼適應這些規則，可以幫助我們寫出更地道的程式碼，事半功倍的完成工作。**下面，讓我們來看一個有關適應規則的故事。

## 案例：從兩份旅遊資料中獲取人員名單

某日，在一個主打紐西蘭出境遊的旅遊公司裡，商務同事突然興沖沖的跑過來找到我，說他從某合作伙伴那裡，要到了兩份重要的資料：

1. 所有去過“泰國普吉島”的人員及聯絡方式
2. 所有去過“紐西蘭”的人員及聯絡方式

資料採用了 JSON 格式，如下所示：

```python
# 去過普吉島的人員資料
users_visited_phuket = [
    {"first_name": "Sirena", "last_name": "Gross", "phone_number": "650-568-0388", "date_visited": "2018-03-14"},
    {"first_name": "James", "last_name": "Ashcraft", "phone_number": "412-334-4380", "date_visited": "2014-09-16"},
    ... ...
]

# 去過紐西蘭的人員資料
users_visited_nz = [
    {"first_name": "Justin", "last_name": "Malcom", "phone_number": "267-282-1964", "date_visited": "2011-03-13"},
    {"first_name": "Albert", "last_name": "Potter", "phone_number": "702-249-3714", "date_visited": "2013-09-11"},
    ... ...
]
```

每份資料裡面都有著`姓`、`名`、`手機號碼`、`旅遊時間` 四個欄位。基於這份資料，商務同學提出了一個*（聽上去毫無道理）*的假設：“去過普吉島的人，應該對去紐西蘭旅遊也很有興趣。我們需要從這份資料裡，找出那些**去過普吉島但沒有去過紐西蘭的人**，針對性的賣產品給他們。

### 第一次蠻力嘗試

有了原始資料和明確的需求，接下來的問題就是如何寫程式碼了。依靠蠻力，我很快就寫出了第一個方案：

```python
def find_potential_customers_v1():
    """找到去過普吉島但是沒去過紐西蘭的人
    """
    for phuket_record in users_visited_phuket:
        is_potential = True
        for nz_record in users_visited_nz:
            if phuket_record['first_name'] == nz_record['first_name'] and \
                    phuket_record['last_name'] == nz_record['last_name'] and \
                    phuket_record['phone_number'] == nz_record['phone_number']:
                is_potential = False
                break

        if is_potential:
            yield phuket_record
```

因為原始資料裡沒有*“使用者 ID”*之類的唯一標示，所以我們只能把“姓名和電話號碼完全相同”作為判斷是不是同一個人的標準。

`find_potential_customers_v1` 函式透過迴圈的方式，先遍歷所有去過普吉島的人，然後再遍歷紐西蘭的人，如果在紐西蘭的記錄中找不到完全匹配的記錄，就把它當做“潛在客戶”返回。

這個函式雖然可以完成任務，但是相信不用我說你也能發現。**它有著非常嚴重的效能問題。**對於每一條去過普吉島的記錄，我們都需要遍歷所有紐西蘭訪問記錄，嘗試找到匹配。整個演算法的時間複雜度是可怕的 `O(n*m)`，如果紐西蘭的訪問條目數很多的話，那麼執行它將耗費非常長的時間。

為了最佳化內層迴圈效能，我們需要減少線性查詢匹配部分的開銷。

### 嘗試使用集合最佳化函式

如果你對 Python 有所瞭解的話，那麼你肯定知道，Python 裡的字典和集合物件都是基於 [雜湊表（Hash Table）](https://en.wikipedia.org/wiki/Hash_table) 實現的。判斷一個東西是不是在集合裡的平均時間複雜度是 `O(1)`，非常快。

所以，對於上面的函式，我們可以先嚐試針對紐西蘭訪問記錄初始化一個集合，之後的查詢匹配部分就可以變得很快，函式整體時間複雜度就能變為 `O(n+m)`。

讓我們看看新的函式：

```python
def find_potential_customers_v2():
    """找到去過普吉島但是沒去過紐西蘭的人，效能改進版
    """
    # 首先，遍歷所有紐西蘭訪問記錄，建立查詢索引
    nz_records_idx = {
        (rec['first_name'], rec['last_name'], rec['phone_number'])
        for rec in users_visited_nz
    }

    for rec in users_visited_phuket:
        key = (rec['first_name'], rec['last_name'], rec['phone_number'])
        if key not in nz_records_idx:
            yield rec
```

使用了集合物件後，新函式在速度上相比舊版本有了飛躍性的突破。但是，對這個問題的最佳化並不是到此為止，不然文章標題就應該改成：“如何使用集合提高程式效能” 了。

### 對問題的重新思考

讓我們來嘗試重新抽象思考一下問題的本質。首先，我們有一份裝了很多東西的容器 A*（普吉島訪問記錄）*，然後給我們另一個裝了很多東西的容器 B*（紐西蘭訪問記錄）*，之後定義相等規則：“姓名與電話一致”。最後基於這個相等規則，求 A 和 B 之間的**“差集”**。

如果你對 Python 裡的集合不是特別熟悉，我就稍微多介紹一點。假如我們擁有兩個集合 A 和 B，那麼我們可以直接使用 `A - B` 這樣的數學運算表示式來計算二者之間的 **差集**。

```python
>>> a = {1, 3, 5, 7}
>>> b = {3, 5, 8}
# 產生新集合：所有在 a 但是不在 b 裡的元素
>>> a - b
{1, 7}
```
 
所以，計算“所有去過普吉島但沒去過紐西蘭的人”，其實就是一次集合的求差值操作。那麼要怎麼做，才能把我們的問題套入到集合的遊戲規則裡去呢?
 
### 利用集合的遊戲規則
 
在 Python 中，如果要把某個東西裝到集合或字典裡，一定要滿足一個基本條件：**“這個東西必須是可以被雜湊（Hashable）的”** 。什麼是 “Hashable”？

舉個例子，Python 裡面的所有可變物件，比如字典，就 **不是** Hashable 的。當你嘗試把字典放入集合中時，會發生這樣的錯誤：

```python
>>> s = set()
>>> s.add({'foo': 'bar'})
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'dict'
```

所以，如果要利用集合解決我們的問題，就首先得定義我們自己的 “Hashable” 物件：`VisitRecord`。而要讓一個自定義物件變得 Hashable，唯一要做的事情就是定義物件的 `__hash__` 方法。

```python
class VisitRecord:
    """旅遊記錄
    """
    def __init__(self, first_name, last_name, phone_number, date_visited):
        self.first_name = first_name
        self.last_name = last_name
        self.phone_number = phone_number
        self.date_visited = date_visited
```

一個好的雜湊演算法，應該讓不同物件之間的值儘可能的唯一，這樣可以最大程度減少[“雜湊碰撞”](https://en.wikipedia.org/wiki/Collision_(computer_science))發生的概率，預設情況下，所有 Python 物件的雜湊值來自它的記憶體地址。

在這個問題裡，我們需要自定義物件的 `__hash__` 方法，讓它利用 `（姓，名，電話）`元組作為 `VisitRecord` 類的雜湊值來源。

```python
def __hash__(self):
    return hash(
        (self.first_name, self.last_name, self.phone_number)
    )
```

自定義完 `__hash__` 方法後，`VisitRecord` 例項就可以正常的被放入集合中了。但這還不夠，為了讓前面提到的求差值演算法正常工作，我們還需要實現 `__eq__` 特殊方法。

`__eq__` 是 Python 在判斷兩個物件是否相等時呼叫的特殊方法。預設情況下，它只有在自己和另一個物件的記憶體地址完全一致時，才會返回 `True`。但是在這裡，我們複用了 `VisitRecord` 物件的雜湊值，當二者相等時，就認為它們一樣。

```python
def __eq__(self, other):
    # 當兩條訪問記錄的名字與電話號相等時，判定二者相等。
    if isinstance(other, VisitRecord) and hash(other) == hash(self):
        return True
    return False
```

完成了恰當的資料建模後，之後的求差值運算便算是水到渠成了。新版本的函式只需要一行程式碼就能完成操作：

```python
def find_potential_customers_v3():
    return set(VisitRecord(**r) for r in users_visited_phuket) - \
        set(VisitRecord(**r) for r in users_visited_nz)
```

> Hint：如果你使用的是 Python 2，那麼除了 `__eq__` 方法外，你還需要自定義類的 `__ne__`（判斷不相等時使用） 方法。

### 使用 dataclass 簡化程式碼

故事到這裡並沒有結束。在上面的程式碼裡，我們手動定義了自己的 **資料類** `VisitRecord`，實現了 `__init__`、`__eq__` 等初始化方法。但其實還有更簡單的做法。

因為定義資料類這種需求在 Python 中實在太常見了，所以在 3.7 版本中，標準庫中新增了 [dataclasses](https://docs.python.org/3/library/dataclasses.html) 模組，專門幫你簡化這類工作。

如果使用 dataclasses 提供的特性，我們的程式碼可以最終簡化成下面這樣：

```python
@dataclass(unsafe_hash=True)
class VisitRecordDC:
    first_name: str
    last_name: str
    phone_number: str
    # 跳過“訪問時間”欄位，不作為任何對比條件
    date_visited: str = field(hash=False, compare=False)


def find_potential_customers_v4():
    return set(VisitRecordDC(**r) for r in users_visited_phuket) - \
        set(VisitRecordDC(**r) for r in users_visited_nz)
```

不用幹任何髒活累活，只要不到十行程式碼就完成了工作。

### 案例總結

問題解決以後，讓我們再做一點小小的總結。在處理這個問題時，我們一共使用了三種方案：

1. 使用普通的兩層迴圈篩選符合規則的結果集
2. 利用雜湊表結構（set 物件）建立索引，提升處理效率
3. 將資料轉換為自定義物件，利用規則，直接使用集合運算

為什麼第三種方式會比前面兩種好呢？

首先，第一個方案的效能問題過於明顯，所以很快就會被放棄。那麼第二個方案呢？仔細想想看，方案二其實並沒有什麼明顯的缺點。甚至和第三個方案相比，因為少了自定義物件的過程，它在效能與記憶體佔用上，甚至有可能會微微強於後者。

但請再思考一下，如果你把方案二的程式碼換成另外一種語言，比如 Java，它是不是基本可以做到 1:1 的完全翻譯？換句話說，**它雖然效率高、程式碼直接，但是它沒有完全利用好 Python 世界提供的規則，最大化的從中受益。**

如果要具體化這個問題裡的“規則”，那就是 **“Python 擁有內建結構集合，集合之間可以進行差值等四則運算”** 這個事實本身。匹配規則後編寫的方案三程式碼擁有下面這些優勢：

- 為資料建模後，可以更方便的定義其他方法
- 如果需求變更，做反向差值運算、求交集運算都很簡單
- 理解集合與 dataclasses 邏輯後，程式碼遠比其他版本更簡潔清晰
- 如果要修改相等規則，比如“只擁有相同姓的記錄就算作一樣”，只需要繼承`VisitRecord` 覆蓋 `__eq__` 方法即可

## 其他規則如何影響我們

在前面，我們花了很大的篇幅講了如何利用“集合的規則”來編寫事半功倍的程式碼。除此之外，Python 世界中還有著很多其他規則。如果能熟練掌握這些規則，就可以設計出符合 Python 慣例的 API，讓程式碼更簡潔精煉。

下面是兩個具體的例子。

### 使用 `__format__` 做物件字串格式化

如果你的自定義物件需要定義多種字串表示方式，就像下面這樣：

```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def get_simple_display(self):
        return f'{self.name}({self.age})'

    def get_long_display(self):
        return f'{self.name} is {self.age} years old.'


piglei = Student('piglei', '18')
# OUTPUT: piglei(18)
print(piglei.get_simple_display())
# OUTPUT: piglei is 18 years old.
print(piglei.get_long_display())
```

那麼除了增加這種 `get_xxx_display()` 額外方法外，你還可以嘗試自定義 `Student` 類的 `__format__` 方法，因為那才是將物件變為字串的標準規則。

```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __format__(self, format_spec):
        if format_spec == 'long':
            return f'{self.name} is {self.age} years old.'
        elif format_spec == 'simple':
            return f'{self.name}({self.age})'
        raise ValueError('invalid format spec')


piglei = Student('piglei', '18')
print('{0:simple}'.format(piglei))
print('{0:long}'.format(piglei))
```

### 使用 `__getitem__` 定義物件切片操作

如果你要設計某個可以裝東西的容器型別，那麼你很可能會為它定義“是否為空”、“獲取第 N 個物件”等方法：

```python
class Events:
    def __init__(self, events):
        self.events = events

    def is_empty(self):
        return not bool(self.events)

    def list_events_by_range(self, start, end):
        return self.events[start:end]

events = Events([
    'computer started',
    'os launched',
    'docker started',
    'os stopped',
])

# 判斷是否有內容，列印第二個和第三個物件
if not events.is_empty():
    print(events.list_events_by_range(1, 3))
```

但是，這樣並非最好的做法。因為 Python 已經為我們提供了一套物件規則，所以我們不需要像寫其他語言的 OO*（面向物件）* 程式碼那樣去自己定義額外方法。我們有更好的選擇：

```python

class Events:
    def __init__(self, events):
        self.events = events

    def __len__(self):
        """自定義長度，將會被用來做布林判斷"""
        return len(self.events)

    def __getitem__(self, index):
        """自定義切片方法"""
        # 直接將 slice 切片物件透傳給 events 處理
        return self.events[index]

# 判斷是否有內容，列印第二個和第三個物件
if events:
    print(events[1:3])
```

新的寫法相比舊程式碼，更能適配進 Python 世界的規則，API 也更為簡潔。

關於如何適配規則、寫出更好的 Python 程式碼。Raymond Hettinger 在 PyCon  2015 上有過一次非常精彩的演講 [“Beyond PEP8 - Best practices for beautiful intelligible code”](https://www.youtube.com/watch?v=wf-BqAjZb8M)。這次演講長期排在我個人的 *“PyCon 影片 TOP5”*  名單上，如果你還沒有看過，我強烈建議你現在就去看一遍 :)

> Hint：更全面的 Python 物件模型規則可以在 [官方文件](https://docs.python.org/3/reference/datamodel.html) 找到，有點難讀，但值得一讀。

## 總結

Python 世界有著一套非常複雜的規則，這些規則的涵蓋範圍包括“物件與物件是否相等“、”物件與物件誰大誰小”等等。它們大部分都需要透過重新定義“雙下劃線方法 `__xxx__`” 去實現。

如果熟悉這些規則，並在日常編碼中活用它們，有助於我們更高效的解決問題、設計出更符合 Python 哲學的 API。下面是本文的一些要點總結：

- **永遠記得對原始需求做抽象分析，比如問題是否能用集合求差集解決**
- 如果要把物件放入集合，需要自定義物件的 `__hash__` 與 `__eq__` 方法
- `__hash__` 方法決定效能（碰撞出現概率），`__eq__` 決定物件間相等邏輯
- 使用 dataclasses 模組可以讓你少寫很多程式碼
- 使用 `__format__` 方法替代自己定義的字串格式化方法
- 在容器類物件上使用 `__len__`、`__getitem__` 方法，而不是自己實現

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【11.高效操作檔案的三個建議】](11-three-tips-on-writing-file-related-codes.md)

[<<<上一篇【9.一個關於模組的小故事】](9-a-story-on-cyclic-imports.md)

## 附錄

- 題圖來源: Photo by JESHOOTS.COM on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：異常處理的三個好習慣](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：編寫地道迴圈的兩個建議](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


