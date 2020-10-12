# Python 工匠：在邊界處思考

## 前言

> 這是 “Python 工匠”系列的第 15 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/06/jessica-ruscello-DoSDQvzjeH0-unsplash_w1440.jpg" width="100%" />
</div>

2016 年，Linux 作業系統的創造者 Linus Torvalds 參加了一場[ TED 訪談節目](https://www.ted.com/talks/linus_torvalds_the_mind_behind_linux/transcript?language=en)。整個節目的前半部分，主要是他在講如何在家光著膀子寫出 Linux 的故事，沒有涉及太多程式設計相關的事情。

不過在訪談快結束時，突然出現了一個有趣的環節。主持人向 Linus 提問道：“你曾說過更願意和那些有著好的 **程式碼品味** 的人共事，那在你眼裡，什麼才是好的程式碼品味？”

為了解釋這個問題，Linus 在大螢幕上展示了一份程式碼。我把其摘抄如下。

```c
remove_list_entry(entry) {
    prev = NULL;
    walk = head;
    
    // 遍歷連結串列
    while (walk != entry) {
        prev = walk;
        walk = walk->next;
    }
    
    // 關鍵：當要刪除時，判斷當前位置是否在連結串列頭部進行不同的動作
    if (!prev)
        head = entry->next;
    else
        prev->next = entry->next;
}
```

函式 `remove_list_entry` 的主要功能是透過遍歷連結串列，刪除裡面的某個成員。但在這份程式碼中，存在一個 **[邊界情況（Edge Case）](https://en.wikipedia.org/wiki/Edge_case)**。

在程式設計時，“邊界情況”是指那些只在極端情景下出現的情況。比如在上面的程式碼裡，當我們要找的元素剛好處於連結串列頭部時，就是一個邊界情況。為了處理它，函式在刪除前進行了一次 `if / else` 判斷。

Linus 認為這條 if 語句是整段程式碼的“壞味道”來源，寫出它的人程式碼品味不夠好 ☹️。那麼，一個品味更好的人應該怎麼寫呢？很快，螢幕上出現了第二份程式碼。

```c
remove_list_entry(entry) {
    indirect = &head
    
    // 遍歷連結串列過程程式碼已省略
    
    // 當要刪除時，直接進行指標操作刪除
    *indirect = entry->next
}
```

在新程式碼中，`remove_list_entry` 函式利用了 C 語言裡的指標特性，把之前的 `if / else` 完全消除了。無論待刪除的目標是在連結串列頭部還是中間，函式都能一視同仁的完成刪除操作。之前的邊界情況消失了。

看到這你是不是在犯嘀咕：*Python 又沒有指標，你跟我說這麼多指標不指標的幹啥？*雖然 Python 沒有指標，但我覺得這個例子為我們提供了一個很有趣的主題。那就是 **如何充分利用語言特性，更好的處理編碼時的邊界情況。**

我認為，好程式碼在處理邊界情況時應該是簡潔的、“潤物細無聲”的。就像上面的例子一樣，可以做到讓邊界情況消融在程式碼主流程中。在寫 Python 時，有不少編碼技巧和慣例可以幫我們做到這一點，一塊來看看吧。

## 第一課：使用分支還是異常？

今天週末，你計劃參加朋友組織的聚餐，臨出門時突然想起來最近是雨季。於是你掏出手機開啟天氣 App，看看今天是不是會下雨。如果下雨，就帶上一把傘再出門。

假如把“今天下雨”類比成程式設計時的 *邊界情況*，那“看天氣預報 + 帶傘”就是我們的邊界處理程式碼。這種 `if 下雨 then 帶傘` 的分支式判斷，基本是一種來自直覺的思考本能。所以，當我們在程式設計時發現邊界情況時，第一反應往往就是：**“弄個 if 分支把它包起來吧！”**。

比如下面這段程式碼：

```python
def counter_ap(l):
    """計算列表裡面每個元素出現的數量"""
    result = {}
    for key in l:
        # 主流程：累加計數器
        if key in result:
            result[key] += 1
        # **邊界情況：當元素第一次出現時，先初始化值為 1**
        else:
            result[key] = 1
    return result

# 執行結果：
print(counter_ap(['apple', 'banana', 'apple']))
{'apple': 2, 'banana': 1}
```

在上面的迴圈裡，程式碼的主流程是*“對每個 key 的計數器加 1”*。但是，當 result 字典裡還沒有 `key` 元素時，是不能直接進行累加操作的（會丟擲 `KeyError`）。

```python
>>> result = {}
>>> result['foo'] += 1
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
KeyError: 'foo'
```

於是一個邊界情況出現了：當元素第一次出現時，我們需要對值進行初始化。

所以，我專門寫了一條 `if` 語句去處理這個邊界情況。程式碼簡單，無需過多解釋。但你可能不知道的是，其實有一個術語來專門描述這種程式設計風格：**“（LBYL）Look Before You Leap”**。

“LBYL” 這縮寫不太好翻譯。用大白話講，就是在進行操作前，先對可能的邊界情況進行條件判斷。根據結果不同，確定是處理邊界情況，還是執行主流程。

如之前所說，使用 “LBYL” 來處理邊界情況，幾乎是一種直覺式的行為。*“有邊界情況，就加上 if 分支”*和*“如果天氣預報說下雨，我就帶傘出門”*一樣，是一種基本不需要過腦子的操作。

而在 LBYL 之外，有著與其形成鮮明對比的另外一種風格：**“EAFP（Easier to Ask for Forgiveness than Permission）”**。

### 獲取原諒比許可簡單(EAFP)

“EAFP” 通常被翻譯成“獲取原諒比許可簡單”。如果還用下雨舉例，那 EAFP 的做法就類似於 *“出門前不看任何天氣預報，如果淋雨了，就回家後洗澡吃感冒藥 💊”*。

使用 EAFP 風格的程式碼是這樣的：

```python
def counter_af(l):
    result = {}
    for key in l:
        try:
            # 總是直接執行主流程：累加計數器
            result[key] += 1
        except KeyError:
            # 邊界情況：當元素第一次出現時會報錯 KeyError，此時進行初始化
            result[key] = 1
    return result
```

和 LBYL 相比，EAFP 程式設計風格更為簡單粗暴。它總是直奔主流程而去，把邊界情況都放在異常處理 `try except` 塊內消化掉。

如果你問我：“這兩種程式設計風格哪個更好？”，我只能說整個 Python 社群對基於異常捕獲的“請求原諒（EAFP）”型程式設計風格有著明顯的偏愛。其中的原因有很多。

首先，和許多其他程式語言不同，在 Python 裡丟擲異常是一個很輕量的操作，即使程式會大量丟擲、捕獲異常，使用 EAFP 也不會給程式帶來額外的負擔。

其次，“請求原諒”在效能上通常也更有優勢，因為程式總是直奔主流程而去，只有極少數情況下才需要處理邊界情況。拿上面的例子來說，第二段程式碼通常會比第一段更快，因為它不用在每次迴圈時都做一次額外的成員檢查。

> Hint：如果你想了解更多這方面的知識，建議閱讀： [Write Cleaner Python: Use Exceptions](https://jeffknupp.com/blog/2013/02/06/write-cleaner-python-use-exceptions/)

所以，每當你想憑直覺寫下 `if else` 來處理邊界情況時，先考慮下使用 `try` 來捕獲異常是不是更合適。畢竟，Pythonista 們總是喜歡“吃感冒藥 💊”勝過“看天氣預報”。😅

## 當容器內容不存在時

Python 裡有很多內建的容器型別，比如字典、列表、集合等等。在進行容器操作時，經常會出現一些邊界情況。其中“要訪問的內容不存在”，是最為常見的一類：

- 操作字典時，訪問的鍵 `key` 不存在，會丟擲 `KeyError` 異常
- 操作列表、元組時，訪問的下標 `index` 不存在，會丟擲 `IndexError` 異常

對於這類邊界情況，除了針對性的捕獲對應異常外，還有許多其他處理方式。

### 使用 defaultdict 改寫示例

在前面的例子裡，我們使用了 `try except` 語句處理了*“key 第一次出現”*這個邊界情況。雖然我說過，使用 `try` 的程式碼比 `if` 更好，但這不代表它就是一份地道的 Python 程式碼。

為什麼？因為如果你想統計列表元素的話，直接用 `collections.defaultdict` 就可以了：

```python
from collections import defaultdict


def counter_by_collections(l):
    result = defaultdict(int)
    for key in l:
        result[key] += 1
    return result
```

這樣的程式碼既不用“獲取許可”，也無需“請求原諒”。 整個函式只有一個主流程，程式碼更清晰、更自然。 

為什麼 `defaultdict` 可以讓邊界情況消失？因為究其根本，之前的程式碼就是少了針對 *“鍵不存在”* 時的預設處理邏輯。所以，當我們用 `defaultdict` 聲明瞭如何處理這個邊界情況時，原本需要手動判斷的部分就消失了。

> Hint：就上面的例子來說，使用 [collections.Counter](https://docs.python.org/3/library/collections.html#collections.Counter) 也能達到同樣的目的。

### 使用 setdefault 取值並修改

有時候，我們需要操作字典裡的某個值，但它又可能並不存在。比如下面這個例子：

```python
# 往字典的 values 鍵追加新值，假如不存在，先以列表初始化
try:
    d['values'].append(value)
except KeyError:
    d['values'] = [value]
```

針對這種情況，我們可以使用 **`d.setdefault(key, default=None)`** 方法來簡化邊界處理邏輯，直接替換上面的異常捕獲語句：

```python
# 如果 setdefault 指定的 key（此處為 "values"）不存在，以 [] 初始化，否則返回已存在
# 的值。
d.setdefault('values', []).append(value)
```

> Hint：使用 `defaultdict(list)` 同樣可以利索的解決這個問題。

### 使用 dict.pop 刪除不存在的鍵

如果我們要刪除字典的某個 `key`，一般會使用 `del` 關鍵字。但當 `key` 不存在時，刪除操作就會丟擲 `KeyError` 異常。

所以，想要安全刪除某個 `key`，還得加上一段異常捕獲邏輯。

```python
try:
    del d[key]
except KeyError:
    # 忽略 key 不存在的情況
    pass
```

但假設只是單純的想刪除某個 `key`，並不關心它是否存在、有沒有刪成功。使用 `dict.pop(key, default)` 方法就夠了。

只要在呼叫 `dict.pop` 方法時傳入預設值，`key` 不存在時就不會丟擲異常了。

```python
# 使用 pop 方法，指定 default 值為 None，當 key 不存在時，不會報錯
d.pop(key, None)
```

> Hint：嚴格來說，`pop` 方法的主要用途並不是去刪除某個 key，而是 **取出** 某個 key 對應的值。不過我覺得偶爾用它來做刪除也無傷大雅。

### 當列表切片越界時

所有人都知道，當你的列表*（或元組）*只有 3 個元素，而你想要訪問第 4 個時，直譯器會報出 `IndexError` 錯誤。我們通常稱這類錯誤為*“陣列越界”*。

```python
>>> l = [1, 2, 3]
>>> l[2]
3
>>> l[3]
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
IndexError: list index out of range
```

但你可能不知道的是，假如你請求的不是某一個元素，而是一段範圍的切片。那麼無論你指定的範圍是否有效，程式都只會返回一個空列表 `[]`，而不會丟擲任何錯誤：

```python
>>> l = []
>>> l[1000:1001]
[]
```

瞭解了這點後，你會發現像下面這種邊界處理程式碼根本沒有必要：

```python
def sum_list(l, limit):
    """對列表的前 limit 個元素求和
    """
    # 如果 limit 過大，設定為陣列長度避免越界
    if limit > len(l):
        limit = len(l)
    return sum(l[:limit])
```

因為做切片不會丟擲任何錯誤，所以不需要判斷 limit 是否超出範圍，直接做 `sum` 操作即可：

```python
def sum_list(l, limit):
    return sum(l[:limit])
```

利用這個特點，我們還可以簡化一些特定的邊界處理邏輯。比如安全刪除列表的某個元素：

```
# 使用異常捕獲安全刪除列表的第 5 個元素
try:
    l.pop(5)
except IndexError:
    pass

# 刪除從 5 開始的長度為 1 的切片，不需要捕獲任何異常
del l[5:6]
```

## 好用又危險的 “or” 運算子

`or` 是一個幾乎在所有程式語言裡都有的運算子，它在 Python 裡通常被用來和 `and` 一起做布林值邏輯運算。比如:

```python
>>> False or True
True
```

但 `or` 還有一個有趣的特點是短路求值，比如在下面的例子裡，`1 / 0` 永遠不會被執行*（也就意味著不會丟擲 ZeroDivisionError）*：

```python
>>> True or (1 / 0)
True
```

在很多場景下，我們可以利用 `or` 的特點來簡化一些邊界處理邏輯。看看下面這個例子：

```python
context = {}
# 僅當 extra_context 不為 None 時，將其追加進 context 中
if extra_context:
    context.update(extra_context)
```

在這段程式碼裡，`extra_context` 的值一般情況下會是一個字典，但有時也可能是 `None`。所以我加了一個條件判斷語句，當它的值不為 `None` 時才做 `.update` 操作。

如果使用 `or` 運算子，我們可以讓上面的語句更簡練：

```
context.update(extra_context or {})
```

因為 `a or b or c or ...` 這樣的表示式，會返回這些變數裡第一個布林值為真的值，直到最後一個為止。所以 `extra_context or {}` 在 `extra_context` 為 `None` 時其實就等於 `{}`。因此之前的條件判斷就可以被簡化成一個 `or` 表示式了。

使用 `a or b` 來表示*“ a 為空時用 b 代替”*，這種寫法一點也不新鮮。你在各種程式設計語、各類框架原始碼原始碼裡都能發現它的影子。但在這個寫法下，其實也藏有一個陷阱。

因為 `or` 操作計算的是變數的布林真假值。所以，不光是 `None`，所有的 0、[]、{}、set() 以及其他所有會被判斷為布林假的東西，都會在 `or` 運算中被忽略。

```python
# 所有的 0、空列表、空字串等，都是布林假值
>>> bool(None), bool(0), bool([]), bool({}), bool(''), bool(set())
(False, False, False, False, False, False)
```

如果忘記了 `or` 的這個特點，可能會碰到一些很奇怪的問題。比如這段程式碼：

```python
timeout = config.timeout or 60
```

雖然上面程式碼的目的，是想要判斷當 `config.timeout` 為 `None` 時使用 60 做預設值。但假如 `config.timeout` 的值被主動配置成了 `0` 秒，`timeout` 也會因為上面的 `0 or 60 = 60` 運算被重新賦值為 60。正確的配置因此被忽略掉了。

所以，有時使用 `if` 來進行精確的邊界處理會更穩妥一些：

```python
if config.timeout is None:
    timeout = 60
```

## 不要手動去做資料校驗

無數前輩的經驗告訴我們：*“不要信任任何使用者輸入”*。這意味著所有存在使用者輸入的地方，都必須對其進行校驗。那些無效、危險的使用者輸入值，就是需要我們處理的邊界情況。

假如我在寫一個命令列小程式，需要讓使用者輸入一個 0-100 範圍的數字。要是使用者的輸入無效，就要求其重新輸入。

程式大概長這樣：

```python
def input_a_number():
    """要求使用者輸入一個 0-100 的數字，如果無效則重新輸入
    """
    while True:
        number = input('Please input a number (0-100): ')

        #  此處往下的三條 if 語句都是輸入值的邊界校驗程式碼
        if not number:
            print('Input can not be empty!')
            continue
        if not number.isdigit():
            print('Your input is not a valid number!')
            continue
        if not (0 <= int(number) <= 100):
            print('Please input a number between 0 and 100!')
            continue

        number = int(number)
        break

    print(f'Your number is {number}')
```

執行效果如下：

```python
Please input a number (0-100):
Input can not be empty!
Please input a number (0-100): foo
Your input is not a valid number!
Please input a number (0-100): 65
Your number is 65
```

這個函式一共有 14 行有效程式碼。其中有 3 段 if 共 9 行程式碼，都是用於校驗的邊界值檢查程式碼。也許你覺得這樣的檢查很正常，但請想象一下，假如需要校驗的輸入不止一個、校驗邏輯也比這個複雜怎麼辦？那樣的話，**這些邊界值檢查程式碼就會變得又臭又長。**

如何改進這些程式碼呢？把它們抽離出去，作為一個校驗函式和核心邏輯隔離開是個不錯的辦法。但更重要的在於，要把*“輸入資料校驗”*作為一個獨立的職責與領域，用更恰當的模組來完成這項工作。

在資料校驗這塊，[pydantic](https://pydantic-docs.helpmanual.io/) 模組是一個不錯的選擇。如果用它來做校驗，程式碼可以被簡化成這樣:

```python
from pydantic import BaseModel, conint, ValidationError


class NumberInput(BaseModel):
    # 使用型別註解 conint 定義 number 屬性的取值範圍
    number: conint(ge=0, le=100)


def input_a_number_with_pydantic():
    while True:
        number = input('Please input a number (0-100): ')

        # 例項化為 pydantic 模型，捕獲校驗錯誤異常
        try:
            number_input = NumberInput(number=number)
        except ValidationError as e:
            print(e)
            continue

        number = number_input.number
        break

    print(f'Your number is {number}')
```

在日常編碼時，我們應該儘量避免去手動校驗資料。而是應該使用*（或者自己實現）*合適的第三方校驗模組，把這部分邊界處理工作抽象出去，簡化主流程程式碼。

> Hint: 假如你在開發 Web 應用，那麼資料校驗部分通常來說都挺容易。比如 Django 框架有自己的 forms 模組，Flask 也可以使用 WTForms 來進行資料校驗。

## 不要忘記做數學計算

很多年前剛接觸 Web 開發時，我想學著用 JavaScript 來實現一個簡單的文字跑馬燈動畫。如果你不知道啥是“跑馬燈”，我可以稍微解釋一下。“跑馬燈”就是讓一段文字從頁面左邊往右邊不斷迴圈滾動，十幾年前的網站特別流行這個。😬

我記得裡面有一段邏輯是這樣的：*控制文字不斷往右邊移動，當橫座標超過頁面寬度時，重置座標後繼續。*我當時寫出來的程式碼，翻譯成 Python 大概是這樣：

```python
while True:
    if element.position_x > page_width:
        # 邊界情況：當物件位置超過頁面寬度時，重置位置到最左邊
        element.position_x -= page_width
        
    # 元素向右邊滾動一個單位寬度
    element.position_x += width_unit
```

看上去還不錯對不對？我剛寫完它時也是這麼認為的。但後來有一天，我重新看到它時，才發現其中的古怪之處。

在上面的程式碼裡，我需要在主迴圈裡保證 “element.position_x 不會超過頁面寬度 page_width”。所以我寫了一個 if 來處理當 `position_x` 超過頁面寬度的情況。

但如果是要保證某個累加的數字*（position_x）*不超過另一個數字*（page_width）*，直接用 `%` 做取模運算不就好了嗎？

```python
while True:
    # 使用 % page_width 控制不要超過頁面寬度
    element.position_x = (element.position_x + width_unit) % page_width
```

這樣寫的話，程式碼裡的邊界情況就連著那行 `if` 語句一起消失了。

和取模運算類似的操作還有很多，比如 `abs()`、`math.floor()` 等等。我們應該記住，不要寫出 `if value < 0: value = -value` 這種“邊界判斷程式碼”，直接使用 `abs(value)` 就好，不要重新發明絕對值運算。

## 總結

“邊界情況（Edge cases）”是我們在日常編碼時的老朋友。但它不怎麼招人喜歡，畢竟，我們都希望自己的程式碼只有一條主流程貫穿始終，不需要太多的條件判斷、異常捕獲。

但邊界情況同時又是無法避免的，只要有程式碼，邊界情況就會存在。所以，如果能更好的處理它們，我們的程式碼就可以變得更清晰易讀。

除了上面介紹的這些思路外，還有很多東西都可以幫助我們處理邊界情況，比如利用面向物件的多型特性、使用 [空物件模式](https://github.com/piglei/one-python-craftsman/blob/master/zh_CN/5-function-returning-tips.md#5-%E5%90%88%E7%90%86%E4%BD%BF%E7%94%A8%E7%A9%BA%E5%AF%B9%E8%B1%A1%E6%A8%A1%E5%BC%8F) 等等。

最後再總結一下：

- 使用條件判斷和異常捕獲都可以用來處理邊界情況
- 在 Python 裡，我們更傾向於使用基於異常捕獲的 EAFP 風格
- 使用 defaultdict / setdefault / pop 可以巧妙的處理當鍵不存在時的邊界情況
- 對列表進行不存在的範圍切片不會丟擲異常
- 使用 `or` 可以簡化預設值邊界處理邏輯，但也要注意不要掉入陷阱
- 不要手動去做資料校驗，使用 `pydantic` 或其他的資料校驗模組
- 利用取模、絕對值計算等方式，可以簡化一些特定的邊界處理邏輯

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[<<<上一篇【14.寫好面向物件程式碼的原則（下）】](14-write-solid-python-codes-part-3.md)

> 為了避免內容重複，在系列第 4 篇“容器的門道”裡出現的 EAPF 相關內容會被刪除，併入到本文中。

## 附錄

- 題圖來源: Photo by Jessica Ruscello on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：寫好面向物件程式碼的原則（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：讓函式返回結果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)


