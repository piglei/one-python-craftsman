# Python 工匠：寫好面向物件程式碼的原則（下）

## 前言

> 這是 “Python 工匠”系列的第 14 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)


<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/carolina-garcia-tavizon-w1280.jpg" width="100%" />
</div>
 
在這篇文章中，我將繼續介紹 SOLID 原則剩下的兩位成員：**I（介面隔離原則）** 和 **D（依賴倒置原則）**。為了方便，這篇文章將會使用先 D 後 I 的順序。

## D：依賴倒置原則

軟體是由一個個模組組合而成的。當你跟別人說：*“我在寫一個很複雜的軟體”*，其實你並不是直接在寫那個軟體，你只是在編寫它的一個個模組，最後把它們放在一起組合成你的軟體。

有了模組，模組間自然就有了依賴關係。比如，你的個人部落格可能依賴著 Flask 框架，而 Flask 又依賴了 Werkzeug，Werkzeug 又由更多個低層模組組成。

依賴倒置原則（Dependency Inversion Principle）就是一條和依賴關係相關的原則。它認為：**“高層模組不應該依賴於低層模組，二者都應該依賴於抽象。”**

> High-level modules should not depend on low-level modules. Both should depend on abstractions.

這個原則看上去有點反直覺。畢竟，在我們的第一堂程式設計課上，老師就是這麼教我們寫程式碼的：*“高層模組要依賴低層模組，hello world 程式依賴 printf()。”*那為什麼這條原則又說不要這樣做呢？而依賴倒置原則裡的“倒置”又是指什麼？

讓我們先把這些問題放在一邊，看看下面這個小需求。上面這些問題的答案都藏在這個需求中。

### 需求：按域名分組統計 HN 新聞數量

這次出場的還是我們的老朋友：新聞站點 [Hacker News](https://news.ycombinator.com/)。在 HN 上，每個使用者提交的條目標題後面，都跟著這條內容的來源域名。

我想要按照來源域名來分組統計條目數量，這樣就能知道哪個站在 HN 上最受歡迎。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_3_hn.jpg" width="100%" />
圖：Hacker News 條目來源截圖
</div>

這個需求非常簡單，使用 `requests`、`lxml` 模組可以很快完成任務：

```python
# file: hn_site_grouper.py
import requests
from lxml import etree
from typing import Dict
from collections import Counter


class SiteSourceGrouper:
    """對 HN 頁面的新聞來源站點進行分組統計
    """
    def __init__(self, url: str):
        self.url = url

    def get_groups(self) -> Dict[str, int]:
        """獲取 (域名, 個數) 分組
        """
        resp = requests.get(self.url)
        html = etree.HTML(resp.text)
        # 透過 xpath 語法篩選新聞域名標籤
        elems = html.xpath('//table[@class="itemlist"]//span[@class="sitestr"]')

        groups = Counter()
        for elem in elems:
            groups.update([elem.text])
        return groups


def main():
    groups = SiteSourceGrouper("https://news.ycombinator.com/").get_groups()
    # 列印最常見的 3 個域名
    for key, value in groups.most_common(3):
        print(f'Site: {key} | Count: {value}')


if __name__ == '__main__':
    main()
```

程式碼執行結果：

```bash
❯ python hn_sitestr_grouper.py
Site: github.com | Count: 2
Site: howonlee.github.io | Count: 1
Site: latimes.com | Count: 1
```

這段程式碼很短，核心程式碼總共不到 20 行。現在，讓我們來理一理它裡面的依賴關係。

`SiteSourceGrouper` 是我們的核心類。為了完成任務，它需要使用 `requests` 模組獲取首頁內容、`lxml` 模組解析標題。所以，現在的依賴關係是“正向”的，高層模組 `SiteSourceGrouper` 依賴低層模組 `requests`、`lxml`。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_D_before.png" width="100%" />
圖：SiteSourceGrouper 依賴 requests、lxml
</div>

也許現在這張圖在你眼裡看起來特別合理。正常的依賴關係不就應該是這樣的嗎？彆著急，我們還沒給程式碼寫單元測試呢。

### 為 SiteSourceGrouper 編寫單元測試

現在讓我來為這段程式碼加上單元測試。首先讓最普通的情況開始：

```python
from hn_site_grouper import SiteSourceGrouper
from collections import Counter


def test_grouper_returning_valid_types():
    """測試 get_groups 是否返回了正確型別
    """
    grouper = SiteSourceGrouper('https://news.ycombinator.com/')
    result = grouper.get_groups()
    assert isinstance(result, Counter), "groups should be Counter instance"
```

這是一個再簡單不過的單元測試，我呼叫了 `SiteSourceGrouper.get_groups()` 方法，然後簡單校驗了一下返回結果型別是否正常。

這個測試在本地電腦上執行時沒有一點問題，可以正常透過。但當我在伺服器上執行這段單元測試程式碼時，卻發現它根本沒辦法成功。因為 **我的伺服器不能訪問外網。**

```python
# 執行單元測試時提示網路錯誤
requests.exceptions.ConnectionError: HTTPSConnectionPool(host='news.ycombinator.com', port=443):  ... ... [Errno 8] nodename nor servname provided, or not known'))
```

到這裡，單元測試暴露了 `SiteSourceGrouper` 類的一個問題：*它的核心邏輯依賴 requests 模組和網路連線，嚴格限制了單元測試的執行條件。*

既然如此，那要如何解決這個問題呢？如果你去問一個有經驗的 Python 的開發者，十有八九他會甩給你一句話：**“用 mock 啊！”**

#### 使用 mock 模組

[mock](https://docs.python.org/3/library/unittest.mock.html) 是 unittest 裡的一個模組，同時也是一類測試手法的統稱。假如你需要測試的模組裡有一部分依賴很難被滿足*（比如程式碼需要訪問一整套 Kubernetes 叢集）*，或者你想在測試時故意替換掉某些依賴，那麼 mock 就能派上用場。

在這個例子裡，使用 unittest.mock 模組需要做下面這些事情：

- 把一份正確的 HN 頁面內容儲存為本地檔案 `static_hn.html`
- 在測試檔案中匯入 `unittest.mock` 模組
- 在測試函式中，透過 [`mock.path('requests.get')`](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.patch) 替換網路請求部分
- 將其修改為直接返回檔案 `static_hn.html` 的內容

使用 mock 後的程式碼看起來是這樣的：

```python
from unittest import mock

def test_grouper_returning_valid_types():
    """測試 get_groups 是否返回了正確型別
    """
    resp = mock.Mock()
    # Mock 掉 requests.get 函式
    with mock.patch('hn_site_grouper.requests.get') as mocked_get:
        mocked_get.return_value = resp
        with open('static_hn.html', 'r') as fp:
            # Mock 掉響應的 text 欄位
            resp.text = fp.read()

        grouper = SiteSourceGrouper('https://news.ycombinator.com/')
        result = grouper.get_groups()
        assert isinstance(result, Counter), "groups should be Counter instance"
```

上面的程式碼並不算複雜。對於 Python 這類動態語言來說，使用 mock 有著一種得天獨厚的優勢。因為在 Python 裡，執行時的一切物件幾乎都可以被替換掉。

不過雖然 mock 用起來很方便，但它不是解決我們問題的最佳做法。因為 mock 在帶來方便的同時，也讓測試程式碼變得更復雜和難以理解。而且，給測試加上 mock 也僅僅只是讓我的單元測試能夠跑起來，糟糕設計仍然是糟糕設計。它無法體現出單元測試最重要的價值之一：**“透過編寫測試反向推動設計改進”**。

所以，我們需要做的是改進依賴關係，而不只是簡單的在測試時把依賴模組替換掉。如何改進依賴關係？讓我們看看“依賴倒置”是如何做的。

### 實現依賴倒置原則

首先，讓我們重溫一下“依賴倒置原則”*（後簡稱 D 原則）*的內容：**“高層模組不應該依賴於低層模組，二者都應該依賴於抽象。”**

在上面的程式碼裡，高層模組 `SiteSourceGrouper` 就直接依賴了低層模組 `requests`。為了讓程式碼符合 D 原則，我們首先需要創造一個處於二者中間的抽象，然後讓兩個模組可以都依賴這個新的抽象層。

建立抽象的第一步*（可能也是最重要的一步）*，就是確定這個抽象層的職責。在例子中，高層模組主要依賴 `requests` 做了這些事：

- 透過 `requests.get()` 獲取 response
- 透過 `response.text` 獲取響應文字

所以，這個抽象層的主要職責就是產生 HN 站點的頁面文字。我們可以給它起個名字：`HNWebPage`。

確定了抽象層的職責和名字後，接下來應該怎麼實現它呢？在 Java 或 Go 語言裡，標準答案是定義 **Interface**（介面）。因為對於這些程式語言來說，“介面”這兩個字基本就可以等同於“抽象”。

拿 Go 來說，“Hacker News 站點頁面”這層抽象就可以被定義成這樣的 Interface：

```go
type HNWebPage interface {
    // GetText 獲取頁面文字
	 GetText() (string, error)
}
```

不過，Python 根本沒有介面這種東西。那該怎麼辦呢？雖然 Python 沒有介面，但是有一個非常類似的東西：**“抽象類（Abstrace Class）”**。使用 [`abc`](https://docs.python.org/3/library/abc.html) 模組就可以輕鬆定義出一個抽象類：

```
from abc import ABCMeta, abstractmethod


class HNWebPage(metaclass=ABCMeta):
    """抽象類：Hacker New 站點頁面
    """

    @abstractmethod
    def get_text(self) -> str:
        raise NotImplementedError
```

抽象類和普通類的區別之一就是你不能將它例項化。如果你嘗試例項化一個抽象類，直譯器會報出下面的錯誤：

```
TypeError: Can't instantiate abstract class HNWebPage with abstract methods get_text
```

所以，光有抽象類還不能算完事，我們還得定義幾個依賴這個抽象類的實體。首先定義的是 `RemoteHNWebPage` 類。它的作用就是透過 requests 模組請求 HN 頁面，返回頁面內容。

```
class RemoteHNWebPage(HNWebPage):
    """遠端頁面，透過請求 HN 站點返回內容"""

    def __init__(self, url: str):
        self.url = url

    def get_text(self) -> str:
        resp = requests.get(self.url)
        return resp.text
```

定義了 `RemoteHNWebPage` 類後，`SiteSourceGrouper` 類的初始化方法和 `get_groups` 也需要做對應的調整：

```
class SiteSourceGrouper:
    """對 HN 頁面的新聞來源站點進行分組統計
    """

    def __init__(self, page: HNWebPage):
        self.page = page

    def get_groups(self) -> Dict[str, int]:
        """獲取 (域名, 個數) 分組
        """
        html = etree.HTML(self.page.get_text())
        # 透過 xpath 語法篩選新聞域名標籤
        elems = html.xpath('//table[@class="itemlist"]//span[@class="sitestr"]')

        groups = Counter()
        for elem in elems:
            groups.update([elem.text])
        return groups


def main():
    # 例項化 page，傳入 SiteSourceGrouper
    page = RemoteHNWebPage(url="https://news.ycombinator.com/")
    grouper = SiteSourceGrouper(page).get_groups()
```

做完這些修改後，讓我們再看看現在的模組依賴關係：

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_D_after.png" width="100%" />
圖：SiteSourceGrouper 和 RemoteHNWebPage 都依賴抽象層 HNWebPage
</div>

在圖中，高層模組不再依賴低層模組，二者同時依賴於抽象概念 `HNWebPage`，低層模組的依賴箭頭和之前相比倒過來了。所以我們稱其為 **依賴倒置**。

### 依賴倒置後的單元測試

再回到之前的單元測試上來。透過引入了新的抽象層 `HNWebPage`，我們可以實現一個不依賴外部網路的新型別 `LocalHNWebPage`。

```
class LocalHNWebPage(HNWebPage):
    """本地頁面，根據本地檔案返回頁面內容"""

    def __init__(self, path: str):
        self.path = path

    def get_text(self) -> str:
        with open(self.path, 'r') as fp:
            return fp.read()
```

所以，單元測試也可以改為使用 `LocalHNWebPage`：

```
def test_grouper_from_local():
    page = LocalHNWebPage(path="./static_hn.html")
    grouper = SiteSourceGrouper(page)
    result = grouper.get_groups()
    assert isinstance(result, Counter), "groups should be Counter instance"
```

這樣就可以在沒有外網的伺服器上測試 `SiteSourceGrouper` 類的核心邏輯了。

> Hint：其實上面的測試函式 `test_grouper_from_local` 遠遠算不上一個合格的測試用例。
> 
> 如果真要測試 `SiteSourceGrouper` 的核心邏輯。我們應該準備一個虛構的 Hacker News 頁面 *（比如剛好包含 5 個 來源自 github.com 的條目）*，然後判斷結果是否包含 `assert result['github.com] == 5`

### 問題：一定要使用抽象類 abc 嗎？

為了實現依賴倒置，我們在上面定義了抽象類：`HNWebPage`。那是不是隻有定義了抽象類才能實現依賴倒置？只有用了抽象類才算是依賴倒置呢？

**答案是否定的。** 如果你願意，你可以把程式碼裡的抽象類 `HNWebPage` 以及所有的相關引用都刪掉，你會發現沒有它們程式碼仍然可以正常執行。

這是因為 Python 是一門“鴨子型別”語言。這意味著只要 `RemoteHNWebPage` 和 `LocalHNWebPage` 型別保持著統一的介面協議*（提供 .get_text() 公開方法）*，並且它們的 **協議符合我們定義的抽象**。那麼那個中間層就存在，依賴倒置就是成立的。至於這份 **協議** 是透過抽象類還是普通父類（甚至可以是普通函式）定義的，就沒那麼重要了。

所以，雖然在某些程式語言中，實現依賴倒置必須得定義新的介面型別，但在 Python 裡，依賴倒置並不是抽象類 abc 的特權。

### 問題：抽象一定是好東西嗎？

前面的所有內容，都是在說新增一個抽象層，然後讓依賴關係倒過來的種種好處。所以，多抽象的程式碼一定就是好的嗎？缺少抽象的程式碼就一定不夠靈活？

和所有這類問題的標準回答一樣，答案是：**視情況而定。**

當你習慣了依賴倒置原則以後，你會發現 *抽象（Abstract）* 其實是一種思維方式，而不僅僅是一種程式設計手法。如果你願意，你可以在程式碼裡的所有地方都 **硬擠** 一層額外抽象出來：

- 比如程式碼依賴了 lxml 模組的 xpath 具體實現，我是不是得定義一層  *“HNTitleDigester”* 把它抽象進去？
- 比如程式碼裡的字串字面量也是具體實現，我是不是得定義一個 *"StringLike"* 型別把它抽象進去？
- ... ...

事實上，抽象的好處顯而易見：**它解耦了高層模組和低層模組間的依賴關係，讓程式碼變得更靈活。** 但抽象同時也帶來了額外的編碼與理解成本。所以，瞭解何時 **不** 抽象與何時抽象同樣重要。**只有對程式碼中那些現在或未來會發生變化的東西進行抽象，才能獲得最大的收益。**

## I：介面隔離原則

介面隔離原則*（後簡稱 I 原則）*全稱為 *“Interface Segregation Principles”*。顧名思義，它是一條和“介面（Interface）”有關的原則。

我在前面解釋過何為“介面（Interface）”。**介面是模組間相互交流的抽象協議**，它在不同的程式語言裡有著不同的表現形態。比如在 Go 裡它是 `type ... interface`，而在 Python 中它可以是抽象類、普通類或者函式，甚至某個只在你大腦裡存在的一套協議。

I 原則認為：**“客戶（client）應該不依賴於它不使用的方法”**

> The interface-segregation principle (ISP) states that no client should be forced to depend on methods it does not use.

這裡說的“客戶（Client）”指的是介面的使用方 *（客戶程式）*，也就是呼叫介面方法的高層模組。拿上一個統計 HN 頁面條目的例子來說：

- `使用方（客戶程式）`：SiteSourceGrouper
- `介面（其實是抽象類）`：HNWebPage
- `依賴關係`：呼叫介面方法：`get_text()` 獲取頁面文字

在 I 原則看來，**一個介面所提供的方法，應該就是使用方所需要的方法，不多不少剛剛好。** 所以，在上個例子裡，我們設計的介面 `HNWebPage` 是符合介面隔離原則的。因為它沒有向使用方提供任何後者不需要的方法 。

> 你需要 get_text()！我提供 get_text()！剛剛好！

所以，這條原則看上去似乎很容易遵守。既然如此，讓我們試試來違反它吧！

### 例子：開發頁面歸檔功能

讓我們接著上一個例子開始。在實現了上個需求後，我現在有一個代表 Hacker News 站點頁面的抽象類 `HNWebPage`，它只提供了一種行為，就是獲取當前頁面的文字內容。

```python
class HNWebPage(metaclass=ABCMeta):

    @abstractmethod
    def get_text(self) -> str:
        """獲取頁面文字內容"""
```

現在，假設我要開發一個和 HN 頁面有關的新功能： **我想在不同時間點對 HN 首頁內容進行歸檔，觀察熱點新聞在不同時間點發生的變化。** 所以除了頁面文字內容外，我還需要拿到頁面的大小、生成時間這些額外資訊，然後將它們都儲存到資料庫中。

為了做到這一點，現在的 `HNWebPage` 類需要被擴充套件一下：

```python
class HNWebPage(metaclass=ABCMeta):

    @abstractmethod
    def get_text(self) -> str:
        """獲取頁面文字內容"""
        
    # 新增 get_size 與 get_generated_at
        
    @abstractmethod
    def get_size(self) -> int:
        """獲取頁面大小"""

    @abstractmethod
    def get_generated_at(self) -> datetime.datetime:
        """獲取頁面生成時間"""
```

我在原來的類上增加了兩個新的抽象方法：`get_size` 和 `get_generated_at`。這樣歸檔程式就能透過它們拿到頁面大小和生成時間了。

改完抽象類後，緊接著的任務就是修改依賴它的實體類。

### 問題：實體類不符合 HNWebPage 介面規範

在修改抽象類前，我們有兩個實現了它協議的實體類：`RemoteHNWebPage` 和 `LocalHNWebPage`。如今，`HNWebPage` 增加了兩個新方法 `get_size` 和 `get_generated_at`。我們自然需要把這兩個實體類也加上這兩個方法。

`RemoteHNWebPage` 類的修改很好做，我們只要讓 `get_size` 放回頁面長度，讓 `get_generated_at` 返回當前時間就行了。

```python
# class RemoteHNWebPage:
#
def get_generated_at(self) -> datetime.datetime:
    # 頁面生成時間等同於透過 requests 請求的時間
    return datetime.datetime.now()
```

但是，在給 `LocalHNWebPage` 新增 `get_generated_at` 方法時，我碰到了一個問題。`LocalHNWebPage` 是一個完全基於本地頁面檔案作為資料來源的類，僅僅透過 “static_hn.html” 這麼一個本地檔案，我根本就沒法知道它的內容是什麼時候生成的。

這時我只能選擇讓它的 `get_generated_at` 方法返回一個錯誤的結果*（比如檔案的修改時間）*，或者直接丟擲異常。無論是哪種做法，我都可能違反 [裡式替換原則](https://www.zlovezl.cn/articles/write-solid-python-codes-part-2/)。

> Hint：裡式替換原則認為子類（派生類）物件應該可以在程式中替代父類（基類）物件使用，而不破壞程式原本的功能。讓方法丟擲異常顯然破壞了這一點。

```python
# class LocalHNWebPage:
#
def get_generated_at(self) -> datetime.datetime:
    raise NotImplementedError("local web page can not provide generate_at info")
```

所以，對現有介面的盲目擴充套件暴露出來一個問題：**更多的介面方法意味著更高的實現成本，給實現方帶來麻煩的概率也變高了。**

不過現在讓我們暫且把這個問題放到一邊，繼續寫一個 `SiteAchiever` 類完成歸檔任務：

```python
class SiteAchiever:
    """將不同時間點的 HN 頁面歸檔"""

    def save_page(self, page: HNWebPage):
        """將頁面儲存到後端資料庫
        """
        data = {
            "content": page.get_text(),
            "generated_at": page.get_generated_at(),
            "size": page.get_size(),
        }
        # 將 data 儲存到資料庫中
```

### 成功違反 I 協議

程式碼寫到這，讓我們回頭看看上個例子裡的 *條目來源分組類 `SiteSourceGrouper`* 。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_I_before.png" width="100%" />
圖：成功違反了 I 協議
</div>

當我修改完抽象類後，雖然 `SiteSourceGrouper` 仍然依賴著 `HNWebPage`，但它其實只使用了 `get_text` 這一個方法而已，其他  `get_size`、`get_generated` 這些它 **不使用的方法也成為了它的依賴。**

很明顯，現在的設計違反了介面隔離原則。為了修復這一點，我們需要將 `HNWebPage` 拆成更小的介面。

### 如何分拆介面

設計介面有一個技巧：**讓客戶（呼叫方）來驅動協議設計**。讓我們來看看，`HNWebPage` 到底有哪些客戶：

- `SiteSourceGrouper`：域名來源統計，依賴 `get_text()`
- `SiteAchiever`：HN 頁面歸檔程式，依賴 `get_text()`、`get_size()`、`get_generated_at()`

按照上面的方式，我們可以把 `HNWebPage` 分離成兩個獨立的抽象類：

```python
class ContentOnlyHNWebPage(metaclass=ABCMeta):
    """抽象類：Hacker New 站點頁面（僅提供內容）
    """

    @abstractmethod
    def get_text(self) -> str:
        raise NotImplementedError


class HNWebPage(ContentOnlyHNWebPage):
    """抽象類：Hacker New 站點頁面（含元資料）
    """

    @abstractmethod
    def get_size(self) -> int:
        """獲取頁面大小"""

    @abstractmethod
    def get_generated_at(self) -> datetime.datetime:
        """獲取頁面生成時間"""
```

將舊類拆分成兩個不同的抽象類後，`SiteSourceGrouper` 和 `SiteAchiever` 就可以分別依賴不同的抽象類了。

同時，對於 `LocalHNWebPage` 類來說，它也只需要實現那個只返回的文字的 `ContentOnlyHNWebPage` 就行。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_I_after.png" width="100%" />
圖：實施介面隔離後的結果
</div>

### 一些不容易發現的違反情況

雖然我花了很長的篇幅，用了好幾個抽象類才把介面隔離原則講明白，但其實在我們的日常編碼中，對這條原則的違反經常會出現在一些更容易被忽視的地方。

舉個例子，當我們在 web 站點裡判斷使用者請求的 Cookies 或頭資訊是否包含某個標記值時，我們經常直接寫一個依賴整個 `request` 物件的函式：

```python
def is_new_visitor(request: HttpRequest) -> bool:
    """從 Cookies 判斷是否新訪客
    """
    return request.COOKIES.get('is_new_visitor') == 'y'
```

但事實上，除了 `.COOKIES` 以外，`is_new_visitor` 根本就不需要 `request` 物件裡面的任何其他內容。“使用者請求物件（request）”是一個比“Cookie 字典（request.COOKIES）”複雜得多的抽象。我們完全可以把函式改成只接收 cookies 字典。

```python
def is_new_visitor(cookies: Dict) -> bool:
    """從 Cookies 判斷是否新訪客
    """
    return cookies.get('is_new_visitor') == 'y'
```

類似的情況還有很多，比如一個發簡訊的函式本身只需要兩個引數 `電話號碼` 和 `使用者姓名`，但是函式卻依賴了整個使用者物件 `User`，裡面包含著幾十個用不上的其他欄位和方法。

對於這類函式，我們都可以重新考慮一下它們的抽象是否合理，是否需要應用介面隔離原則。

### 現實世界中的介面隔離

當你知道了介面隔離原則的種種好處後，你很自然就會養成寫小類、小介面的習慣。在現實世界裡，其實已經有很多小而精的介面設計可以供你參考。比如：

- Python 的 [collections.abc](https://docs.python.org/3/library/collections.abc.html) 模組裡面有非常多的小介面
- Go 裡面的 [Reader 和 Writer](https://golang.org/pkg/io/#Reader) 也是非常好的例子

## 總結

在這篇文章裡，我向你介紹了 SOLID 原則的最後兩位成員：**“依賴倒置原則”** 與 **“介面隔離原則”**。

這兩條原則之間有一個共同點，那就是它們都和 **“抽象”** 有著緊密的聯絡。前者告訴我們要面向抽象而非實現程式設計，後者則教導我們在設計抽象時應該做到精準。

最後再總結一下：

- **“D：依賴倒置原則”** 認為高層模組和低層模組都應該依賴於抽象
- 依賴抽象，意味著我們可以完全修改低層實現，而不影響高層程式碼
- 在 Python 中你可以使用 abc 模組來定義抽象類
- 除 abc 外，你也可以使用其他技術來完成依賴倒置
- **“I：介面隔離原則”** 認為客戶不應該依賴任何它不使用的方法
- 設計介面就是設計抽象
- 違反介面隔離原則也可能會導致違反單一職責與裡式替換原則
- 寫更小的類、寫更小的介面在大多數情況下是個好主意

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【15.在邊界處思考】](15-thinking-in-edge-cases.md)

[<<<上一篇【13.寫好面向物件程式碼的原則（中）】](13-write-solid-python-codes-part-2.md)


## 附錄

- 題圖來源: Photo by Carolina Garcia Tavizon on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：寫好面向物件程式碼的原則（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：寫好面向物件程式碼的原則（中）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-2/)
- [Python 工匠：寫好面向物件程式碼的原則（下）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-3/)


