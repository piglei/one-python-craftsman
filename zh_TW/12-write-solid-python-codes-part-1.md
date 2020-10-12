# Python 工匠：寫好面向物件程式碼的原則（上）

## 前言


> 這是 “Python 工匠”系列的第 12 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/kelly-sikkema-Z9AU36chmQI-unsplash_w1280.jpg" width="100%" />
</div>

Python 是一門支援多種程式設計風格的語言，面對相同的需求，擁有不同背景的程式設計師可能會寫出風格迥異的 Python 程式碼。比如一位習慣編寫 C 語言的程式設計師，通常會定義一大堆函式來搞定所有事情，這是[“程序式程式設計”](https://en.wikipedia.org/wiki/Procedural_programming)的思想。而一位有 Java 背景的程式設計師則更傾向於設計許多個相互關聯的類*（class）*，這是 [“面向物件程式設計（後簡稱 OOP）”](https://en.wikipedia.org/wiki/Object-oriented_programming)。

雖然不同的程式設計風格各有特點，無法直接比較。但是 OOP 思想在現代軟體開發中起到的重要作用應該是毋庸置疑的。

很多人在學習如何寫好 OOP 程式碼時，會選擇從那 [23 種經典的“設計模式”](https://zh.wikipedia.org/wiki/%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F_(%E8%AE%A1%E7%AE%97%E6%9C%BA))開始。不過對於 Python 程式設計師來說，我認為這並非是一個最佳選擇。

### Python 對 OOP 的支援

Python 語言雖然擁有類、繼承、多型等核心 OOP 特性，但和那些完全基於 OOP 思想設計的程式語言*（比如 Java）*相比，它在 OOP 支援方面做了很多簡化工作。比如它 **沒有嚴格的類私有成員，沒有介面（Interface）物件** 等。

而與此同時，Python 靈活的函式物件、鴨子型別等許多動態特性又讓一些在其他語言中很難做到的事情變得非常簡單。這些語言間的差異共同導致了一個結果：*很多經典的設計模式到了 Python 裡，就丟失了那個“味道”，實用性也大打折扣。*

拿大家最熟悉的單例模式來說。你可以花上一大把時間，來學習如何在 Python 中利用 `__new__` 方法或元類*（metaclass）*來實現單例設計模式，但最後你會發現，自己 95% 的需求都可以透過直接定義一個模組級全域性變數來搞定。

所以，與具體化的 **設計模式** 相比，我覺得一些更為抽象的 **設計原則** 適用性更廣、更適合運用到 Python 開發工作中。而談到關於 OOP 的設計原則，“SOLID” 是眾多原則中最有名的一個。

### SOLID 設計原則

著名的設計模式書籍[《設計模式：可複用面向物件軟體的基礎》](https://book.douban.com/subject/1052241/)出版於 1994 年，距今已有超過 25 年的歷史。而這篇文章的主角： “SOLID 設計原則”同樣也並不年輕。

早在 2000 年，[Robert C. Martin](https://en.wikipedia.org/wiki/Robert_C._Martin) 就在他的文章 "Design Principles and Design Patterns" 中整理並提出了 “SOLID” 設計原則的雛型，之後又在他的經典著作[《敏捷軟體開發 : 原則、模式與實踐》](https://book.douban.com/subject/1140457/)中將其發揚光大。“SOLID” 由 5 個單詞組合的首字母縮寫組成，分別代表 5 條不同的面向物件領域的設計原則。

在編寫 OOP 程式碼時，如果遵循這 5 條設計原則，就更可能寫出可擴充套件、易於修改的程式碼。相反，如果不斷違反其中的一條或多條原則，那麼很快你的程式碼就會變得不可擴充套件、難以維護。

接下來，讓我用一個真實的 Python 程式碼樣例來分別向你詮釋這 5 條設計原則。

> 寫在最前面的注意事項：
> 
> 0. “原則”不是“法律”，它只起到指導作用，並非不可以違反
> 1. “原則”的後兩條與介面（Interface）有關，而 Python 沒有介面，所以對這部分的詮釋是我的個人理解，與原版可能略有出入
> 2. 文章後面的內容含有大量程式碼，請做好心理準備 ☕️
> 3. 為了增強程式碼的說明性，本文中的程式碼使用了 Python3 中的 [型別註解特性](https://docs.python.org/3/library/typing.html)

## SOLID 原則與 Python

[Hacker News](https://news.ycombinator.com/)*(後簡稱 HN)* 是一個在程式設計師圈子裡很受歡迎的站點。在它的首頁，有很多由使用者提交後基於推薦演算法排序的科技相關內容。

我經常會去上面看一些熱門文章，但我覺得每次開啟瀏覽器訪問有點麻煩。所以，我準備編寫一個指令碼，自動抓取 HN 首頁 Top5 的新聞標題與連結，並用純文字的方式寫入到檔案。方便自己用其他工具閱讀。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/hackernews_frontpage.png" width="100%" />
圖：Hacker News 首頁截圖
</div>

編寫爬蟲幾乎是 Python 天生的拿手好戲。利用 requests、lxml 等模組提供的好用功能，我可以輕鬆實現上面的需求。下面是我第一次編寫好的程式碼：

```python
import io
import sys
from typing import Generator

import requests
from lxml import etree


class Post:
    """HN(https://news.ycombinator.com/) 上的條目

    :param title: 標題
    :param link: 連結
    :param points: 當前得分
    :param comments_cnt: 評論數
    """
    def __init__(self, title: str, link: str, points: str, comments_cnt: str):
        self.title = title
        self.link = link
        self.points = int(points)
        self.comments_cnt = int(comments_cnt)


class HNTopPostsSpider:
    """抓取 HackerNews Top 內容條目

    :param fp: 儲存抓取結果的目標檔案物件
    :param limit: 限制條目數，預設為 5
    """
    ITEMS_URL = 'https://news.ycombinator.com/'
    FILE_TITLE = 'Top news on HN'

    def __init__(self, fp: io.TextIOBase, limit: int = 5):
        self.fp = fp
        self.limit = limit

    def fetch(self) -> Generator[Post, None, None]:
        """從 HN 抓取 Top 內容
        """
        resp = requests.get(self.ITEMS_URL)

        # 使用 XPath 可以方便的從頁面解析出你需要的內容，以下均為頁面解析程式碼
        # 如果你對 xpath 不熟悉，可以忽略這些程式碼，直接跳到 yield Post() 部分
        html = etree.HTML(resp.text)
        items = html.xpath('//table[@class="itemlist"]/tr[@class="athing"]')
        for item in items[:self.limit]:
            node_title = item.xpath('./td[@class="title"]/a')[0]
            node_detail = item.getnext()
            points_text = node_detail.xpath('.//span[@class="score"]/text()')
            comments_text = node_detail.xpath('.//td/a[last()]/text()')[0]

            yield Post(
                title=node_title.text,
                link=node_title.get('href'),
                # 條目可能會沒有評分
                points=points_text[0].split()[0] if points_text else '0',
                comments_cnt=comments_text.split()[0]
            )

    def write_to_file(self):
        """以純文字格式將 Top 內容寫入檔案
        """
        self.fp.write(f'# {self.FILE_TITLE}\n\n')
        # enumerate 接收第二個引數，表示從這個數開始計數（預設為 0）
        for i, post in enumerate(self.fetch(), 1):
            self.fp.write(f'> TOP {i}: {post.title}\n')
            self.fp.write(f'> 分數：{post.points} 評論數：{post.comments_cnt}\n')
            self.fp.write(f'> 地址：{post.link}\n')
            self.fp.write('------\n')


def main():

    # with open('/tmp/hn_top5.txt') as fp:
    #     crawler = HNTopPostsSpider(fp)
    #     crawler.write_to_file()

    # 因為 HNTopPostsSpider 接收任何 file-like 的物件，所以我們可以把 sys.stdout 傳進去
    # 實現往控制檯標準輸出列印的功能
    crawler = HNTopPostsSpider(sys.stdout)
    crawler.write_to_file()


if __name__ == '__main__':
    main()
```

你可以把上面的程式碼稱之為符合 OOP 風格的，因為在上面的程式碼裡，我定義了兩個類：

1. `Post`：表示單個 HN 內容條目，其中定義了標題、連結等欄位，是用來銜接“抓取”和“寫入檔案”兩件事情的資料類
2. `HNTopPostsSpider`：抓取 HN 內容的爬蟲類，其中定義了抓取頁面、解析、寫入結果的方法，是完成主要工作的類

如果你本地的 Python 環境配置正常，那麼可以嘗試執行一下上面這段程式碼，它會輸出下面這樣的內容：

```text
❯ python news_digester.py
> TOP 1: Show HN: NoAgeismInTech – Job board for companies fighting ageism in tech
> 分數：104 評論數：26
> 地址：https://noageismintech.com/
------
> TOP 2: Magic Leap sues former employee who founded the China-based Nreal for IP theft
> 分數：17 評論數：2
> 地址：https://www.bloomberg.com/news/articles/2019-06-18/secretive-magic-leap-says-ex-engineer-copied-headset-for-china
------
... ...
```

這個指令碼基於面向物件的方式編寫*（換句話說，就是定義了一些 class 😒）*，可以滿足我的需求。但是從設計的角度來看，它卻違反了 SOLID 原則的第一條：“Single responsibility principle（單一職責原則）”，讓我們來看看是為什麼。

## S：單一職責原則

SOLID 設計原則裡的第一個字母 S 來自於 “Single responsibility principle（單一職責原則）” 的首字母。這個原則認為：**“一個類應該僅僅只有一個被修改的理由。”**換句話說，每個類都應該只有一種職責。

而在上面的程式碼中，`HNTopPostsSpider` 這個類違反了這個原則。因為我們可以很容易的找到兩個不同的修改它的理由：

- **理由 1**: HN 網站的程式設計師突然更新了頁面樣式，舊的 xpath 解析演算法從新頁面上解析不到內容，需要修改 `fetch` 方法內的解析邏輯。
- **理由 2**: 使用者*（也就是我）*突然覺得純文字格式的輸出不好看，想要改成 Markdown 樣式。需要修改 `write_to_file` 方法內的輸出邏輯。

所以，`HNTopPostsSpider` 類違反了“單一職責原則”，因為它有著多個被修改的理由。而這背後的根本原因是因為它承擔著 “抓取帖子列表” 和 "將帖子列表寫入檔案" 這兩種完全不同的職責。

### 違反“單一職責原則”的壞處

如果某個類違反了“單一職責原則”，那意味著我們經常會因為不同的原因去修改它。這可能會導致不同功能之間相互影響。比如，可能我在某天調整了頁面解析邏輯，卻發現輸出的檔案格式也全部亂掉了。

另外，單個類承擔的職責越多，意味著這個類的複雜度也就越高，它的維護成本也同樣會水漲船高。違反“單一職責原則”的類同樣也難以被複用，假如我有其他程式碼想複用 `HNTopPostsSpider` 類的抓取和解析邏輯，會發現我必須要提供一個莫名其妙的檔案物件給它才行。

那麼，要如何修改程式碼才能讓它遵循“單一職責原則”呢？辦法有很多，最傳統的是：**把大類拆分為小類**。

### 拆分大類為多個小類

為了讓 `HNTopPostsSpider` 類的職責更純粹，我們可以把其中與“寫入檔案”相關的內容拆分出去作為一個新的類：

```python
class PostsWriter:
    """負責將帖子列表寫入到檔案
    """
    def __init__(self, fp: io.TextIOBase, title: str):
        self.fp = fp
        self.title = title

    def write(self, posts: List[Post]):
        self.fp.write(f'# {self.title}\n\n')
        # enumerate 接收第二個引數，表示從這個數開始計數（預設為 0）
        for i, post in enumerate(posts, 1):
            self.fp.write(f'> TOP {i}: {post.title}\n')
            self.fp.write(f'> 分數：{post.points} 評論數：{post.comments_cnt}\n')
            self.fp.write(f'> 地址：{post.link}\n')
            self.fp.write('------\n')
```

而在 `HNTopPostsSpider` 類裡，可以透過呼叫 `PostsWriter` 的方式來完成之前的工作：

```python
class HNTopPostsSpider:
    FILE_TITLE = 'Top news on HN'
    
    <... 已省略 ...>

    def write_to_file(self, fp: io.TextIOBase):
        """以純文字格式將 Top 內容寫入檔案

        例項化引數檔案物件 fp 被挪到了 write_to_file 方法中
        """
        # 將檔案寫入邏輯託管給 PostsWriter 類處理
        writer = PostsWriter(fp, title=self.FILE_TITLE)
        writer.write(list(self.fetch()))
```

透過這種方式，我們讓 `HNTopPostsSpider` 和 `PostsWriter` 類都各自滿足了“單一職責原則”。我只會因為解析邏輯變動才去修改 `HNTopPostsSpider` 類，同樣，修改 `PostsWriter` 類的原因也只有調整輸出格式一種。這兩個類各自的修改可以單獨進行而不會相互影響。

### 另一種方案：使用函式

“單一職責原則”雖然是針對類說的，但其實它的適用範圍可以超出類本身。比如在 Python 中，透過定義函式，同樣也可以讓上面的程式碼符合單一職責原則。

我們可以把“寫入檔案”的邏輯拆分為一個新的函式，由它來專門承擔起將帖子列表寫入檔案的職責：

```python
def write_posts_to_file(posts: List[Post], fp: io.TextIOBase, title: str):
    """負責將帖子列表寫入檔案
    """
    fp.write(f'# {title}\n\n')
    for i, post in enumerate(posts, 1):
        fp.write(f'> TOP {i}: {post.title}\n')
        fp.write(f'> 分數：{post.points} 評論數：{post.comments_cnt}\n')
        fp.write(f'> 地址：{post.link}\n')
        fp.write('------\n')
```

而對於 `HNTopPostsSpider` 類來說，改動可以更進一步。這次我們可以直接刪除其中和檔案寫入相關的所有程式碼。讓它只負責一件事情：“獲取帖子列表”。

```python
class HNTopPostsSpider:
    """抓取 HackerNews Top 內容條目

    :param limit: 限制條目數，預設為 5
    """
    ITEMS_URL = 'https://news.ycombinator.com/'

    def __init__(self, limit: int = 5):
        self.limit = limit

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
```

相應的，類和函式的呼叫方 `main` 函式就需要稍作調整，它需要負責把 `write_posts_to_file` 函式和 `HNTopPostsSpider` 類之間協調起來，共同完成工作：

```python
def main():
    crawler = HNTopPostsSpider()

    posts = list(crawler.fetch())
    file_title = 'Top news on HN'
    write_posts_to_file(posts, sys.stdout, file_title)
```

將“檔案寫入”職責拆分為新函式是一個 Python 特色的解決方案，它雖然沒有那麼 OO*（面向物件）*，但是同樣滿足“單一職責原則”，而且在很多場景下更靈活與高效。

## O：開放-關閉原則

O 來自於 “Open–closed principle（開放-關閉原則）” 的首字母，它認為：**“類應該對擴充套件開放，對修改封閉。”**這是一個從字面上很難理解的原則，它同樣有著另外一種說法：**“你應該可以在不修改某個類的前提下，擴充套件它的行為。”**

這原則聽上去有點讓人犯迷糊，如何能做到不修改程式碼又改變行為呢？讓我來舉一個例子：你知道 Python 裡的內建排序函式 `sorted` 嗎？

如果我們想對某個列表排序，可以直接呼叫 `sorted` 函式：

```python
>>> l = [5, 3, 2, 4, 1]
>>> sorted(l)
[1, 2, 3, 4, 5]
```

現在，假如我們想改變 `sorted` 函式的排序邏輯。比如，讓它使用所有元素對 3 取餘後的結果來排序。我們是不是需要去修改 `sorted` 函式的原始碼？當然不用，只需要在呼叫 `sort` 函式時，傳入自定義的排序函式 `key` 引數就行了：

```python
>>> l = [8, 1, 9]
# 按照元素對 3 的餘數排序，能被 3 整除的 9 排在了最前面，隨後是 1 和 8
>>> sorted(l, key=lambda i: i % 3)
[9, 1, 8]
```

透過上面的例子，我們可以認為：`sorted` 函式是一個符合“開放-關閉原則”的絕佳例子，因為它：

- **對擴充套件開放**：你可以透過傳入自定義 `key` 函式來擴充套件它的行為
- **對修改關閉**：你無需修改 sort 函式本身

### 如何違反“開放-關閉原則”

現在，讓我們回到爬蟲小程式。在使用了一段時間之後，使用者*（還是我）*覺得每次抓取到的內容有點不合口味。我其實只關注那些來自特定網站，比如 github 上的內容。所以我需要修改 `HNTopPostsSpider` 類的程式碼來對結果進行過濾：

```python
class HNTopPostsSpider:
    # <... 已省略 ...>

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
        counter = 0
        for item in items:
            if counter >= self.limit:
                break

            # <... 已省略 ...>
            link = node_title.get('href')

            # 只關注來自 github.com 的內容
            if 'github' in link.lower():
                counter += 1
                yield Post(... ...)
```

完成修改後，讓我們來簡單測試一下效果：

```text
❯ python news_digester_O_before.py
# Top news on HN

> TOP 1: Mimalloc – A compact general-purpose allocator
> 分數：291 評論數：40
> 地址：https://github.com/microsoft/mimalloc
------
> TOP 2: Olivia: An open source chatbot build with a neural network in Go
> 分數：53 評論數：19
> 地址：https://github.com/olivia-ai/olivia
------
<... 已省略 ...>
```

看上去新加的過濾程式碼起到了作用，現在只有連結中含有 `github` 的內容才會被寫入到結果中。

但是，正如某位哲學家的名言所說：*“這世間唯一不變的，只有變化本身。”*某天，使用者*（永遠是我）*突然覺得，來自 `bloomberg` 的內容也都很有意思，所以我想要把 `bloomberg` 也加入篩選關鍵字邏輯裡。

這時我們就會發現：現在的程式碼違反了"開放-關閉原則"。因為我必須要修改現有的 `HNTopPostsSpider` 類程式碼，調整那個 `if 'github' in link.lower()` 判斷語句才能完成我的需求。

“開放-關閉原則”告訴我們，類應該透過擴充套件而不是修改的方式改變自己的行為。那麼我應該如何調整程式碼，讓它可以遵循原則呢？

### 使用類繼承來改造程式碼

繼承是面向物件理論中最重要的概念之一。它允許我們在父類中定義好資料和方法，然後透過繼承的方式讓子類獲得這些內容，並可以選擇性的對其中一些進行重寫，修改它的行為。

使用繼承的方式來讓類遵守“開放-關閉原則”的關鍵點在於：**找到父類中會變動的部分，將其抽象成新的方法（或屬性），最終允許新的子類來重寫它以改變類的行為。**

對於 `HNTopPostsSpider` 類來說。首先，我們需要找到其中會變動的那部分邏輯，也就是*“判斷是否對條目感興趣”*，然後將其抽象出來，定義為新的方法：

```python
class HNTopPostsSpider:
    # <... 已省略 ...>

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
        for item in items:
            # <... 已省略 ...>
            
            post = Post( ... ... )
            # 使用測試方法來判斷是否返回該帖子
            if self.interested_in_post(post):
                counter += 1
                yield post

    def interested_in_post(self, post: Post) -> bool:
        """判斷是否應該將帖子加入結果中
        """
        return True
```

如果我們只關心來自 `github` 的帖子，那麼只需要定義一個繼承於 `HNTopPostsSpider` 子類，然後重寫父類的 `interested_in_post` 方法即可。

```python
class GithubOnlyHNTopPostsSpider(HNTopPostsSpider):
    """只關心來自 Github 的內容
    """
    def interested_in_post(self, post: Post) -> bool:
        return 'github' in post.link.lower()

def main():
    # crawler = HNTopPostsSpider()
    # 使用新的子類
    crawler = GithubOnlyHNTopPostsSpider()
    <... ...>
```

假如我們的興趣發生了變化？沒關係，增加新的子類就行：

```python
class GithubNBloomBergHNTopPostsSpider(HNTopPostsSpider):
    """只關係來自 Github/BloomBerg 的內容
    """
    def interested_in_post(self, post: Post) -> bool:
        if 'github' in post.link.lower() \
                or 'bloomberg' in post.link.lower():
            return True
        return False
```

所有的這一切，都不需要修改原本的 `HNTopPostsSpider` 類的程式碼，只需要不斷在它的基礎上建立新的子類就能完成新需求。最終實現了對擴充套件開放、對改變關閉。

### 使用組合與依賴注入來改造程式碼

雖然類的繼承特性很強大，但它並非唯一辦法，[依賴注入（Dependency injection）](https://en.wikipedia.org/wiki/Dependency_injection) 是解決這個問題的另一種思路。與繼承不同，依賴注入允許我們在類例項化時，透過引數將業務邏輯的變化點：**帖子過濾演算法** 注入到類例項中。最終同樣實現“開放-關閉原則”。

首先，我們定義一個名為 `PostFilter` 的抽象類：

```python
from abc import ABC, abstractmethod

class PostFilter(metaclass=ABCMeta):
    """抽象類：定義如何過濾帖子結果
    """
    @abstractmethod
    def validate(self, post: Post) -> bool:
        """判斷帖子是否應該被保留"""
```

> Hint：定義抽象類在 Python 的 OOP 中並不是必須的，你也可以不定義它，直接從下面的 DefaultPostFilter 開始。

然後定義一個繼承於該抽象類的預設 `DefaultPostFilter` 類，過濾邏輯為保留所有結果。之後再調整一下 `HNTopPostsSpider` 類的構造方法，讓它接收一個名為 `post_filter` 的結果過濾器：

```python
class DefaultPostFilter(PostFilter):
    """保留所有帖子
    """
    def validate(self, post: Post) -> bool:
        return True


class HNTopPostsSpider:
    """抓取 HackerNews Top 內容條目

    :param limit: 限制條目數，預設為 5
    :param post_filter: 過濾結果條目的演算法，預設為保留所有
    """
    ITEMS_URL = 'https://news.ycombinator.com/'

    def __init__(self, limit: int = 5, post_filter: Optional[PostFilter] = None):
        self.limit = limit
        self.post_filter = post_filter or DefaultPostFilter()

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
        for item in items:
            # <... 已省略 ...>
            
            post = Post( ... ... )
            
            # 使用測試方法來判斷是否返回該帖子
            if self.post_filter.validate(post):
                counter += 1
                yield post
```

預設情況下，`HNTopPostsSpider.fetch` 會保留所有的結果。假如我們想要定義自己的過濾演算法，只要新建自己的 `PostFilter` 類即可，下面是兩個分別過濾 GitHub 與 BloomBerg 的 `PostFilter` 類：

```
class GithubPostFilter(PostFilter):
    def validate(self, post: Post) -> bool:
        return 'github' in post.link.lower()


class GithubNBloomPostFilter(PostFilter):
    def validate(self, post: Post) -> bool:
        if 'github' in post.link.lower() or 'bloomberg' in post.link.lower():
            return True
        return False
```

在 `main()` 函式中，我可以用不同的 `post_filter` 引數來例項化 `HNTopPostsSpider` 類，最終滿足不同的過濾需求：

```python
def main():
    # crawler = HNTopPostsSpider()
    # crawler = HNTopPostsSpider(post_filter=GithubPostFilter())
    crawler = HNTopPostsSpider(post_filter=GithubNBloomPostFilter())

    posts = list(crawler.fetch())
    file_title = 'Top news on HN'
    write_posts_to_file(posts, sys.stdout, file_title)
```

與基於繼承的方式一樣，利用將“過濾演算法”抽象為 `PostFilter` 類並以例項化引數的方式注入到 `HNTopPostsSpider` 中，我們同樣實現了“開放-關閉原則”。

### 使用資料驅動思想來改造程式碼

在實現“開放-關閉”原則的眾多手法中，除了繼承與依賴注入外，還有一種經常被用到的方式：**“資料驅動”**。這個方式的核心思想在於：**將經常變動的東西，完全以資料的方式抽離出來。當需求變動時，只改動資料，程式碼邏輯保持不動。**

它的原理與“依賴注入”有一些相似，同樣是把變化的東西抽離到類外部。不同的是，後者抽離的通常是類，而前者抽離的是資料。

為了讓 `HNTopPostsSpider` 類的行為可以被資料驅動，我們需要使其接收 `filter_by_link_keywords` 引數：

```python
class HNTopPostsSpider:
    """抓取 HackerNews Top 內容條目

    :param limit: 限制條目數，預設為 5
    :param filter_by_link_keywords: 過濾結果的關鍵詞列表，預設為 None 不過濾
    """
    ITEMS_URL = 'https://news.ycombinator.com/'

    def __init__(self,
                 limit: int = 5,
                 filter_by_link_keywords: Optional[List[str]] = None):
        self.limit = limit
        self.filter_by_link_keywords = filter_by_link_keywords

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
        for item in items:
            # <... 已省略 ...>
            
            post = Post( ... ... )
            
            if self.filter_by_link_keywords is None:
                counter += 1
                yield post
            # 當 link 中出現任意一個關鍵詞時，返回結果
            elif any(keyword in post.link for keyword in self.filter_by_link_keywords):
                counter += 1
                yield post
```

調整了初始化引數後，還需要在 `main` 函式中定義 `link_keywords` 變數並將其傳入到 `HNTopPostsSpider` 類的構造方法中，之後所有針對過濾關鍵詞的調整都只需要修改這個列表即可，無需改動 `HNTopPostsSpider` 類的程式碼，同樣滿足了“開放-關閉原則”。

```python
def main():
    # link_keywords = None
    link_keywords = [
        'github.com',
        'bloomberg.com'
    ]
    crawler = HNTopPostsSpider(filter_by_link_keywords=link_keywords)

    posts = list(crawler.fetch())
    file_title = 'Top news on HN'
    write_posts_to_file(posts, sys.stdout, file_title)
```

與前面的繼承和依賴注入方式相比，“資料驅動”的程式碼更簡潔，不需要定義額外的類。但它同樣也存在缺點：**它的可定製性不如前面的兩種方式**。假如，我想要以“連結是否以某個字串結尾”作為新的過濾條件，那麼現在的資料驅動程式碼就有心無力了。

如何選擇合適的方式來讓程式碼符合“開放-關閉原則”，需要根據具體的需求和場景來判斷。這也是一個無法一蹴而就、需要大量練習和經驗積累的過程。

## 總結

在這篇文章中，我透過一個具體的 Python 程式碼案例，向你描述了 “SOLID” 設計原則中的前兩位成員：**“單一職責原則”** 與 **“開放-關閉原則”**。

這兩個原則雖然看上去很簡單，但是它們背後蘊藏了許多從好程式碼中提煉而來的智慧。它們的適用範圍也不僅僅侷限在 OOP 中。一旦你深入理解它們後，你可能會驚奇的在許多設計模式和框架中發現它們的影子*（比如這篇文章就出現了至少 3 種設計模式，你知道是哪些嗎？）*。

讓我們最後再總結一下吧：

- **“S: 單一職責原則”** 認為一個類只應該有一種被修改的原因
- 編寫更小的類通常更不容易違反 S 原則
- S 原則同樣適用於函式，你可以讓函式和類協同工作
- **“O: 開放-關閉原則”** 認為類應該對改動關閉，對擴充套件開放
- 找到需求中頻繁變化的那個點，是讓類遵循 O 原則的重點所在
- 使用子類繼承的方式可以讓類遵守 O 原則
- 透過定義演算法類，並進行依賴注入，也可以讓類遵循 O 原則
- 將資料與邏輯分離，使用資料驅動的方式也是改造程式碼的好辦法

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【13.寫好面向物件程式碼的原則（中）】](13-write-solid-python-codes-part-2.md)

[<<<上一篇【11.高效操作檔案的三個建議】](11-three-tips-on-writing-file-related-codes.md)


## 附錄

- 題圖來源: Photo by Kelly Sikkema on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：讓函式返回結果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)
- [Python 工匠：編寫地道迴圈的兩個建議](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)
- [Python 工匠：高效操作檔案的三個建議](https://www.zlovezl.cn/articles/three-tips-on-writing-file-related-codes/)



