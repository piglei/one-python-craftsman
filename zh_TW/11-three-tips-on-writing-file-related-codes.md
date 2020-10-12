#  Python 工匠：高效操作檔案的三個建議

## 前言

> 這是 “Python 工匠”系列的第 11 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/devon-divine-1348025-unsplash_1280.jpg" width="100%" />
</div>

在這個世界上，人們每天都在用 Python 完成著不同的工作。而檔案操作，則是大家最常需要解決的任務之一。使用 Python，你可以輕鬆為他人生成精美的報表，也可以用短短几行程式碼快速解析、整理上萬份資料檔案。

當我們編寫與檔案相關的程式碼時，通常會關注這些事情：**我的程式碼是不是足夠快？我的程式碼有沒有事半功倍的完成任務？** 在這篇文章中，我會與你分享與之相關的幾個程式設計建議。我會向你推薦一個被低估的 Python 標準庫模組、演示一個讀取大檔案的最佳方式、最後再分享我對函式設計的一點思考。

下面，讓我們進入第一個“模組安利”時間吧。

> **注意：**因為不同作業系統的檔案系統大不相同，本文的主要編寫環境為 Mac OS/Linux 系統，其中一些程式碼可能並不適用於 Windows 系統。

## 建議一：使用 pathlib 模組

如果你需要在 Python 裡進行檔案處理，那麼標準庫中的 `os` 和 `os.path` 兄弟倆一定是你無法避開的兩個模組。在這兩個模組裡，有著非常多與檔案路徑處理、檔案讀寫、檔案狀態檢視相關的工具函式。

讓我用一個例子來展示一下它們的使用場景。有一個目錄裡裝了很多資料檔案，但是它們的字尾名並不統一，既有 `.txt`，又有 `.csv`。我們需要把其中以 `.txt` 結尾的檔案都修改為 `.csv` 字尾名。

我們可以寫出這樣一個函式：

```python
import os
import os.path


def unify_ext_with_os_path(path):
    """統一目錄下的 .txt 檔名字尾為 .csv
    """
    for filename in os.listdir(path):
        basename, ext = os.path.splitext(filename)
        if ext == '.txt':
            abs_filepath = os.path.join(path, filename)
            os.rename(abs_filepath, os.path.join(path, f'{basename}.csv'))
```

讓我們看看，上面的程式碼一共用到了哪些與檔案處理相關的函式：
  
- [`os.listdir(path)`](https://docs.python.org/3/library/os.html#os.listdir)：列出 path 目錄下的所有檔案*（含資料夾）*
- [`os.path.splitext(filename)`](https://docs.python.org/3/library/os.path.html#os.path.splitext)：切分檔名裡面的基礎名稱和字尾部分
- [`os.path.join(path, filename)`](https://docs.python.org/3/library/os.path.html#os.path.join)：組合需要操作的檔名為絕對路徑
- [`os.rename(...)`](https://docs.python.org/3/library/os.html#os.rename)：重新命名某個檔案

上面的函式雖然可以完成需求，但說句實話，即使在寫了很多年 Python 程式碼後，我依然覺得：**這些函式不光很難記，而且最終的成品程式碼也不怎麼討人喜歡。** 

### 使用 pathlib 模組改寫程式碼

為了讓檔案處理變得更簡單，Python 在 3.4 版本引入了一個新的標準庫模組：[pathlib](https://docs.python.org/3/library/pathlib.html)。它基於面向物件思想設計，封裝了非常多與檔案操作相關的功能。如果使用它來改寫上面的程式碼，結果會大不相同。

使用 pathlib 模組後的程式碼：

```python
from pathlib import Path

def unify_ext_with_pathlib(path):
    for fpath in Path(path).glob('*.txt'):
        fpath.rename(fpath.with_suffix('.csv'))
```

和舊程式碼相比，新函式只需要兩行程式碼就完成了工作。而這兩行程式碼主要做了這麼幾件事：

1. 首先使用 [Path(path)](https://docs.python.org/3/library/pathlib.html#pathlib.Path) 將字串路徑轉換為 `Path` 物件
2. 呼叫 [.glob('*.txt')](https://docs.python.org/3/library/pathlib.html#pathlib.Path.glob) 對路徑下所有內容進行模式匹配並以生成器方式返回，結果仍然是 `Path` 物件，所以我們可以接著做後面的操作
3. 使用 [.with_suffix('.csv')](https://docs.python.org/3/library/pathlib.html#pathlib.PurePath.with_suffix) 直接獲取使用新字尾名的檔案全路徑
4. 呼叫 [.rename(target)](https://docs.python.org/3/library/pathlib.html#pathlib.Path.rename) 完成重新命名

相比 `os` 和 `os.path`，引入 `pathlib` 模組後的程式碼明顯更精簡，也更有整體統一感。所有檔案相關的操作都是一站式完成。

### 其他用法

除此之外，pathlib 模組還提供了很多有趣的用法。比如使用 `/` 運算子來組合檔案路徑：

```python
# 😑 舊朋友：使用 os.path 模組
>>> import os.path
>>> os.path.join('/tmp', 'foo.txt')
'/tmp/foo.txt'

# ✨ 新潮流：使用 / 運算子
>>> from pathlib import Path
>>> Path('/tmp') / 'foo.txt'
PosixPath('/tmp/foo.txt')
```

或者使用 `.read_text()` 來快速讀取檔案內容：

```python
# 標準做法，使用 with open(...) 開啟檔案
>>> with open('foo.txt') as file:
...     print(file.read())
...
foo

# 使用 pathlib 可以讓這件事情變得更簡單
>>> from pathlib import Path
>>> print(Path('foo.txt').read_text())
foo

```

除了我在文章裡介紹的這些，pathlib 模組還提供了非常多有用的方法，強烈建議去 [官方文件]((https://docs.python.org/3/library/pathlib.html#module-pathlib)) 詳細瞭解一下。

如果上面這些都不足以讓你動心，那麼我再多給你一個使用 pathlib 的理由：[PEP-519](https://www.python.org/dev/peps/pep-0519/) 裡定義了一個專門用於“檔案路徑”的新物件協議，這意味著從該 PEP 生效後的 Python 3.6 版本起，pathlib 裡的 Path 物件，可以和以前絕大多數只接受字串路徑的標準庫函式相容使用：

```python
>>> p = Path('/tmp')
# 可以直接對 Path 型別物件 p 進行 join
>>> os.path.join(p, 'foo.txt')
'/tmp/foo.txt'
```

所以，無需猶豫，趕緊把 pathlib 模組用起來吧。

> **Hint:** 如果你使用的是更早的 Python 版本，可以嘗試安裝 [pathlib2](https://pypi.org/project/pathlib2/) 模組 。

## 建議二：掌握如何流式讀取大檔案

幾乎所有人都知道，在 Python 裡讀取檔案有一種“標準做法”：首先使用 `with open(fine_name)` 上下文管理器的方式獲得一個檔案物件，然後使用 `for` 迴圈迭代它，逐行獲取檔案裡的內容。

下面是一個使用這種“標準做法”的簡單示例函式：

```python
def count_nine(fname):
    """計算檔案裡包含多少個數字 '9'
    """
    count = 0
    with open(fname) as file:
        for line in file:
            count += line.count('9')
    return count
```

假如我們有一個檔案 `small_file.txt`，那麼使用這個函式可以輕鬆計算出 9 的數量。

```python
# small_file.txt
feiowe9322nasd9233rl
aoeijfiowejf8322kaf9a

# OUTPUT: 3
print(count_nine('small_file.txt'))
```

為什麼這種檔案讀取方式會成為標準？這是因為它有兩個好處：

1. `with` 上下文管理器會自動關閉開啟的檔案描述符
2. 在迭代檔案物件時，內容是一行一行返回的，不會佔用太多記憶體

### 標準做法的缺點

但這套標準做法並非沒有缺點。如果被讀取的檔案裡，根本就沒有任何換行符，那麼上面的第二個好處就不成立了。**當代碼執行到 `for line in file` 時，line 將會變成一個非常巨大的字串物件，消耗掉非常可觀的記憶體。**

讓我們來做個試驗：有一個 **5GB** 大的檔案 `big_file.txt`，它裡面裝滿了和 `small_file.txt` 一樣的隨機字串。只不過它儲存內容的方式稍有不同，所有的文字都被放在了同一行裡：

```raw
# FILE: big_file.txt
df2if283rkwefh... <剩餘 5GB 大小> ...
```

如果我們繼續使用前面的 `count_nine` 函式去統計這個大檔案裡 `9` 的個數。那麼在我的筆記本上，這個過程會足足花掉 **65** 秒，並在執行過程中吃掉機器 **2GB** 記憶體 [[注1]]((#annot1))。

### 使用 read 方法分塊讀取

為了解決這個問題，我們需要暫時把這個“標準做法”放到一邊，使用更底層的 `file.read()` 方法。與直接迴圈迭代檔案物件不同，每次呼叫 `file.read(chunk_size)` 會直接返回從當前位置往後讀取 `chunk_size` 大小的檔案內容，不必等待任何換行符出現。

所以，如果使用 `file.read()` 方法，我們的函式可以改寫成這樣:

```python
def count_nine_v2(fname):
    """計算檔案裡包含多少個數字 '9'，每次讀取 8kb
    """
    count = 0
    block_size = 1024 * 8
    with open(fname) as fp:
        while True:
            chunk = fp.read(block_size)
            # 當檔案沒有更多內容時，read 呼叫將會返回空字串 ''
            if not chunk:
                break
            count += chunk.count('9')
    return count
```

在新函式中，我們使用了一個 `while` 迴圈來讀取檔案內容，每次最多讀取 8kb 大小，這樣可以避免之前需要拼接一個巨大字串的過程，把記憶體佔用降低非常多。

### 利用生成器解耦程式碼

假如我們在討論的不是 Python，而是其他程式語言。那麼可以說上面的程式碼已經很好了。但是如果你認真分析一下 `count_nine_v2` 函式，你會發現在迴圈體內部，存在著兩個獨立的邏輯：**資料生成（read 呼叫與 chunk 判斷）** 與 **資料消費**。而這兩個獨立邏輯被耦合在了一起。

正如我在[《編寫地道迴圈》](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)裡所提到的，為了提升複用能力，我們可以定義一個新的 `chunked_file_reader` 生成器函式，由它來負責所有與“資料生成”相關的邏輯。這樣 `count_nine_v3` 裡面的主迴圈就只需要負責計數即可。

```python
def chunked_file_reader(fp, block_size=1024 * 8):
    """生成器函式：分塊讀取檔案內容
    """
    while True:
        chunk = fp.read(block_size)
        # 當檔案沒有更多內容時，read 呼叫將會返回空字串 ''
        if not chunk:
            break
        yield chunk


def count_nine_v3(fname):
    count = 0
    with open(fname) as fp:
        for chunk in chunked_file_reader(fp):
            count += chunk.count('9')
    return count
```

進行到這一步，程式碼似乎已經沒有最佳化的空間了，但其實不然。[iter(iterable)](https://docs.python.org/3/library/functions.html#iter) 是一個用來構造迭代器的內建函式，但它還有一個更少人知道的用法。當我們使用 `iter(callable, sentinel)` 的方式呼叫它時，會返回一個特殊的物件，迭代它將不斷產生可呼叫物件 callable 的呼叫結果，直到結果為 setinel 時，迭代終止。

```python
def chunked_file_reader(file, block_size=1024 * 8):
    """生成器函式：分塊讀取檔案內容，使用 iter 函式
    """
    # 首先使用 partial(fp.read, block_size) 構造一個新的無需引數的函式
    # 迴圈將不斷返回 fp.read(block_size) 呼叫結果，直到其為 '' 時終止
    for chunk in iter(partial(file.read, block_size), ''):
        yield chunk
```

最終，只需要兩行程式碼，我們就完成了一個可複用的分塊檔案讀取函式。那麼，這個函式在效能方面的表現如何呢？

和一開始的 **2GB 記憶體/耗時 65 秒** 相比，使用生成器的版本只需要 **7MB 記憶體 / 12 秒** 就能完成計算。效率提升了接近 4 倍，記憶體佔用更是不到原來的 1%。

## 建議三：設計接受檔案物件的函式

統計完檔案裡的 “9” 之後，讓我們換一個需求。現在，我想要統計每個檔案裡出現了多少個英文母音字母*（aeiou）*。只要對之前的程式碼稍作調整，很快就可以寫出新函式 `count_vowels`。

```python
def count_vowels(filename):
    """統計某個檔案中，包含母音字母(aeiou)的數量
    """
    VOWELS_LETTERS = {'a', 'e', 'i', 'o', 'u'}
    count = 0
    with open(filename, 'r') as fp:
        for line in fp:
            for char in line:
                if char.lower() in VOWELS_LETTERS:
                    count += 1
    return count


# OUTPUT: 16
print(count_vowels('small_file.txt'))
```

和之前“統計 9”的函式相比，新函式變得稍微複雜了一些。為了保證程式的正確性，我需要為它寫一些單元測試。但當我準備寫測試時，卻發現這件事情非常麻煩，主要問題點如下：

1. 函式接收檔案路徑作為引數，所以我們需要傳遞一個實際存在的檔案
2. 為了準備測試用例，我要麼提供幾個樣板檔案，要麼寫一些臨時檔案
3. 而檔案是否能被正常開啟、讀取，也成了我們需要測試的邊界情況

**如果，你發現你的函式難以編寫單元測試，那通常意味著你應該改進它的設計。**上面的函式應該如何改進呢？答案是：*讓函式依賴“檔案物件”而不是檔案路徑*。

修改後的函式程式碼如下：

```python
def count_vowels_v2(fp):
    """統計某個檔案中，包含母音字母(aeiou)的數量
    """
    VOWELS_LETTERS = {'a', 'e', 'i', 'o', 'u'}
    count = 0
    for line in fp:
        for char in line:
            if char.lower() in VOWELS_LETTERS:
                count += 1
    return count


# 修改函式後，開啟檔案的職責被移交給了上層函式呼叫者
with open('small_file.txt') as fp:
    print(count_vowels_v2(fp))
```

**這個改動帶來的主要變化，在於它提升了函式的適用面。**因為 Python 是“鴨子型別”的，雖然函式需要接受檔案物件，但其實我們可以把任何實現了檔案協議的 “類檔案物件（file-like object）” 傳入 `count_vowels_v2` 函式中。

而 Python 中有著非常多“類檔案物件”。比如 io 模組內的 [StringIO](https://docs.python.org/3/library/io.html#io.StringIO) 物件就是其中之一。它是一種基於記憶體的特殊物件，擁有和檔案物件幾乎一致的介面設計。

利用 StringIO，我們可以非常方便的為函式編寫單元測試。

```python
# 注意：以下測試函式需要使用 pytest 執行
import pytest
from io import StringIO


@pytest.mark.parametrize(
    "content,vowels_count", [
        # 使用 pytest 提供的引數化測試工具，定義測試引數列表
        # (檔案內容, 期待結果)
        ('', 0),
        ('Hello World!', 3),
        ('HELLO WORLD!', 3),
        ('你好，世界', 0),
    ]
)
def test_count_vowels_v2(content, vowels_count):
    # 利用 StringIO 構造類檔案物件 "file"
    file = StringIO(content)
    assert count_vowels_v2(file) == vowels_count
```

使用 pytest 執行測試可以發現，函式可以透過所有的用例：

```raw
❯ pytest vowels_counter.py
====== test session starts ======
collected 4 items

vowels_counter.py ... [100%]

====== 4 passed in 0.06 seconds ======
```

而讓編寫單元測試變得更簡單，並非修改函式依賴後的唯一好處。除了 StringIO 外，subprocess 模組呼叫系統命令時用來儲存標準輸出的 [PIPE](https://docs.python.org/3/library/subprocess.html#subprocess.PIPE) 物件，也是一種“類檔案物件”。這意味著我們可以直接把某個命令的輸出傳遞給 `count_vowels_v2` 函式來計算母音字母數：

```python
import subprocess

# 統計 /tmp 下面所有一級子檔名（目錄名）有多少母音字母
p = subprocess.Popen(['ls', '/tmp'], stdout=subprocess.PIPE, encoding='utf-8')

# p.stdout 是一個流式類檔案物件，可以直接傳入函式
# OUTPUT: 42
print(count_vowels_v2(p.stdout))
```

正如之前所說，將函式引數修改為“檔案物件”，最大的好處是提高了函式的 **適用面** 和 **可組合性**。透過依賴更為抽象的“類檔案物件”而非檔案路徑，給函式的使用方式開啟了更多可能，StringIO、PIPE 以及任何其他滿足協議的物件都可以成為函式的客戶。

不過，這樣的改造並非毫無缺點，它也會給呼叫方帶來一些不便。假如呼叫方就是想要使用檔案路徑，那麼就必須得自行處理檔案的開啟操作。

### 如何編寫相容二者的函式

有沒有辦法即擁有“接受檔案物件”的靈活性，又能讓傳遞檔案路徑的呼叫方更方便？答案是：*有，而且標準庫中就有這樣的例子。*

開啟標準庫裡的 `xml.etree.ElementTree` 模組，翻開裡面的 `ElementTree.parse` 方法。你會發現這個方法即可以使用檔案物件呼叫，也接受字串的檔案路徑。而它實現這一點的手法也非常簡單易懂：

```
def parse(self, source, parser=None):
    """*source* is a file name or file object, *parser* is an optional parser
    """
    close_source = False
    # 透過判斷 source 是否有 "read" 屬性來判定它是不是“類檔案物件”
    # 如果不是，那麼呼叫 open 函式開啟它並負擔起在函式末尾關閉它的責任
    if not hasattr(source, "read"):
        source = open(source, "rb")
        close_source = True
```

使用這種基於“鴨子型別”的靈活檢測方式，`count_vowels_v2` 函式也同樣可以被改造得更方便，我在這裡就不再重複啦。

## 總結

檔案操作我們在日常工作中經常需要接觸的領域，使用更方便的模組、利用生成器節約記憶體以及編寫適用面更廣的函式，可以讓我們編寫出更高效的程式碼。

讓我們最後再總結一下吧：

- 使用 pathlib 模組可以簡化檔案和目錄相關的操作，並讓程式碼更直觀
- [PEP-519](https://www.python.org/dev/peps/pep-0519/) 定義了表示“檔案路徑”的標準協議，Path 物件實現了這個協議
- 透過定義生成器函式來分塊讀取大檔案可以節約記憶體
- 使用 `iter(callable, sentinel)` 可以在一些特定場景簡化程式碼
- 難以編寫測試的程式碼，通常也是需要改進的程式碼
- 讓函式依賴“類檔案物件”可以提升函式的適用面和可組合性

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【12.寫好面向物件程式碼的原則（上）】](12-write-solid-python-codes-part-1.md)

[<<<上一篇【10.做一個精通規則的玩家】](10-a-good-player-know-the-rules.md)

## 附錄

- 題圖來源: Photo by Devon Divine on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：異常處理的三個好習慣](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：編寫地道迴圈的兩個建議](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


## 註解

1. <a id="annot1"></a>視機器空閒記憶體的多少，這個過程可能會消耗比 2GB 更多的記憶體。


