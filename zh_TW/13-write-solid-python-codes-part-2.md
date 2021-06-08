# Python 工匠：寫好面向物件程式碼的原則（中）

## 前言

> 這是 “Python 工匠”系列的第 13 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/11/neonbrand-CXDw96Oy-Yw-unsplash_w1280.jpg" width="100%" />
</div>

在 [上一篇文章](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/) 裡，我用一個虛擬小專案作為例子，講解了“SOLID”設計原則中的前兩位成員：S*（單一職責原則）*與 O*（開放-關閉原則）*。

在這篇文章中，我將繼續介紹 SOLID 原則的第三位成員：**L（里氏替換原則）**。

## 里氏替換原則與繼承

在開始前，我覺得有必要先提一下 [繼承（Inheritance）](https://en.wikipedia.org/wiki/Inheritance)。因為和前面兩條非常抽象的原則不同，“里氏替換原則”是一條非常具體的，和類繼承有關的原則。

在 OOP 世界裡，繼承算是一個非常特殊的存在，它有點像一把無堅不摧的雙刃劍，強大且危險。合理使用繼承，可以大大減少類與類之間的重複程式碼，讓程式事半功倍，而不當的繼承關係，則會讓類與類之間建立起錯誤的強耦合，帶來大片難以理解和維護的程式碼。

正是因為這樣，對繼承的態度也可以大致分為兩類。大多數人認為，繼承和多型、封裝等特性一樣，屬於面向物件程式設計的幾大核心特徵之一。而同時有另一部分人覺得，繼承帶來的 [壞處遠比好處多](https://www.javaworld.com/article/2073649/why-extends-is-evil.html)。甚至在 Go 這門相對年輕的程式語言裡，設計者直接去掉了繼承，提倡完全使用組合來替代。

從我個人的程式設計經驗來看，繼承確實極易被誤用。要設計出合理的繼承關係，是一件需要深思熟慮的困難事兒。不過幸運的是，在這方面，"里氏替換原則"*(後簡稱 L 原則)* 為我們提供了非常好的指導意義。

讓我們來看看它的內容。

## L：里氏替換原則

同前面的 S 與 O 兩個原則的命名方式不同，里氏替換原則*（Liskov Substitution Principle）*是直接用它的發明者 [Barbara Liskov](https://en.wikipedia.org/wiki/Barbara_Liskov) 命名的，原文看起來像一個複雜的數學公式：

> Let q(x) be a property provable about objects of x of type T. Then q(y) should be provable for objects y of type S where S is a subtype of T.
> - 出處: [Liskov substitution principle - Wikipedia](https://en.wikipedia.org/wiki/Liskov_substitution_principle)

如果把它比較通俗的翻譯過來，大概是這樣：**當你使用繼承時，子類（派生類）物件應該可以在程式中替代父類（基類）物件使用，而不破壞程式原本的功能。**

光說有點難理解，讓我們用程式碼來看看一個在 Python 中違反 Liskov 原則的例子。

## 一個違反 L 原則的樣例

假設我們在為一個 Web 站點設計使用者模型。這個站點的使用者分為兩類：普通使用者和站點管理員。所以在程式碼裡，我們定義了兩個使用者類：普通使用者類 `User` 和管理員類 `Admin`。

```python
class User(Model):
    """普通使用者模型類
    """
    def __init__(self, username: str):
        self.username = username

    def deactivate(self):
        """停用當前使用者
        """
        self.is_active = False
        self.save()

class Admin(User):
    """管理員使用者類
    """
    def deactivate(self):
        # 管理員使用者不允許被停用
        raise RuntimeError('admin can not be deactivated!')
```

因為普通使用者的絕大多數操作在管理員上都適用，所以我們把 `Admin` 類設計成了繼承自 `User` 類的子類。不過在“停用”操作方面，管理員和普通使用者之間又有所區別： **普通使用者可以被停用，但管理員不行。**

於是在 `Admin` 類裡，我們重寫了 `deactivate` 方法，使其丟擲一個 `RuntimeError` 異常，讓管理員物件無法被停用。

子類繼承父類，然後重寫父類的少量行為，這看上去正是類繼承的典型用法。但不幸的是，這段程式碼違反了“里氏替換原則”。具體是怎麼回事呢？讓我們來看看。

### 不當繼承關係如何違反 L 原則

現在，假設我們需要寫一個新函式，它可以同時接受多個使用者物件作為引數，批次將它們停用。程式碼如下：

```python
def deactivate_users(users: Iterable[User]):
    """批次停用多個使用者
    """
    for user in users:
        user.deactivate()
```

很明顯，上面的程式碼是有問題的。因為 `deactivate_users` 函式在引數註解裡寫到，它接受一切 **可被迭代的 User 物件**，那麼管理員 `Admin` 是不是 `User` 物件？當然是，因為它是繼承自 `User` 類的子類。

但是，如果你真的把 `[User("foo"), Admin("bar_admin")]` 這樣的使用者列表傳到 `deactivate_users` 函式裡，程式立馬就會丟擲 `RuntimeError` 異常，因為管理員物件 `Admin("bar_admin")` 壓根不支援停用操作。

在 `deactivate_users` 函式看來，子類 `Admin` 無法隨意替換父類 `User` 使用，所以現在的程式碼是不符合 L 原則的。

### 一個簡單但錯誤的解決辦法

要修復上面的函式，最直接的辦法就是在函式內部增加一個額外的型別判斷：

```python
def deactivate_users(users: Iterable[User]):
    """批次停用多個使用者
    """
    for user in users:
        # 管理員使用者不支援 deactivate 方法，跳過
        if isinstance(user, Admin):
            logger.info(f'skip deactivating admin user {user.username}')
            continue

        user.deactivate()
```

在修改版的 `deactivate_users` 函式裡，如果它在迴圈時恰好發現某個使用者是 `Admin` 類，就跳過這次操作。這樣它就能正確處理那些混合了管理員的使用者列表了。

但是，這樣修改的缺點是顯而易見的。因為雖然到目前為止，只有 `Admin` 型別的使用者不允許被停用。但是，**誰能保證未來不會出現其他不能被停用的使用者型別呢？**比如：

- 公司員工不允許被停用
- VIP 使用者不允許被停用
- 等等(... ...)

而當這些新需求在未來不斷出現時，我們就需要重複的修改 `deactivate_users` 函式，來不斷適配這些無法被停用的新使用者型別。

```python
def deactivate_users(users: Iterable[User]):
    for user in users:
        # 在型別判斷語句不斷追加新使用者型別
        if isinstance(user, (Admin, VIPUser, Staff)):
            ... ...
```

現在，讓我們再回憶一下前面的 SOLID 第二原則：**“開放-關閉原則”**。這條原則認為：好的程式碼應該對擴充套件開發，**對修改關閉**。而上面的函式很明顯不符合這條原則。

到這裡你會發現，**SOLID 裡的每條原則並非完全獨立的個體，它們之間其實互有聯絡。**比如，在這個例子裡，我們先是違反了“里氏替換原則”，然後我們使用了錯誤的修復方式：*增加型別判斷*。之後發現，這樣的程式碼同樣也無法符合“開放-關閉原則”。

### 正確的修改辦法

既然為函式增加型別判斷無法讓程式碼變得更好，那我們就應該從別的方面入手。

“里氏替換原則”提到，**子類*（Admin）*應該可以隨意替換它的父類*（User）*，而不破壞程式*（deactivate_users）*本身的功能。**我們試過直接修改類的使用者來遵守這條原則，但是失敗了。所以這次，讓我們試著從源頭上解決問題：重新設計類之間的繼承關係。

具體點來說，子類不能只是簡單透過丟擲異常的方式對某個類方法進行“退化”。如果 *“物件不能支援某種操作”* 本身就是這個型別的 **核心特徵** 之一，那我們在進行父類設計時，就應該把這個 **核心特徵** 設計進去。

拿使用者型別舉例，*“使用者可能無法被停用”* 就是 `User` 類的核心特徵之一，所以在設計父類時，我們就應該把它作為類方法*（或屬性）*寫進去。

讓我們看看調整後的程式碼：

```python
class User(Model):
    """普通使用者模型類
    """
    def __init__(self, username: str):
        self.username = username

    def allow_deactivate(self) -> bool:
        """是否允許被停用
        """
        return True

    def deactivate(self):
        """將當前使用者停用
        """
        self.is_active = True
        self.save()

class Admin(User):
    """管理員使用者類
    """
    def allow_deactivate(self) -> bool:
        # 管理員使用者不允許被停用
        return False

def deactivate_users(users: Iterable[User]):
    """批次停用多個使用者
    """
    for user in users:
        if not user.allow_deactivate():
            logger.info(f'user {user.username} does not allow deactivating, skip.')
            continue

        user.deactivate()
```

在新程式碼裡，我們在父類中增加了 `allow_deactivate` 方法，由它來決定當前的使用者型別是否允許被停用。而在 `deactivate_users` 函式中，也不再需要透過脆弱的型別判斷，來判定某類使用者是否可以被停用。我們只需要呼叫 `user.allow_deactivate()` 方法，程式便能自動跳過那些不支援停用操作的使用者物件。

在這樣的設計中，`User` 類的子類 `Admin` 做到了可以完全替代父類使用，而不會破壞程式 `deactivate_users` 的功能。

所以我們可以說，修改後的類繼承結構是符合里氏替換原則的。

## 另一種違反方式：子類修改方法返回值

除了上面的例子外，還有一種常見的違反里氏替換原則的情況。讓我們看看下面這段程式碼：

```python
class User(Model):
    """普通使用者模型類
    """
    def __init__(self, username: str):
        self.username = username

    def list_related_posts(self) -> List[int]:
        """查詢所有與之相關的帖子 ID
        """
        return [post.id for post in session.query(Post).filter(username=self.username)]

class Admin(User):
    """管理員使用者類
    """
    def list_related_posts(self) -> Iterable[int]:
        # 管理員與所有的帖子都有關，為了節約記憶體，使用生成器返回帖子 ID
        for post in session.query(Post).all():
            yield post.id
```

在這段程式碼裡，我給使用者類增加了一個新方法：`list_related_posts`，呼叫它可以拿到所有和當前使用者有關的帖子 ID。對於普通使用者，方法返回的是自己釋出過的所有帖子，而管理員則是站點裡的所有帖子。

現在，假設我需要寫一個函式，來獲取和使用者有關的所有帖子標題：

```python
def list_user_post_titles(user: User) -> Iterable[str]:
    """獲取與使用者有關的所有帖子標題
    """
    for post_id in user.list_related_posts():
        yield session.query(Post).get(post_id).title
```

對於上面的 `list_user_post_titles` 函式來說，無論傳入的 `user` 引數是 `User` 還是 `Admin` 型別，它都能正常工作。因為，雖然普通使用者和管理員型別的 `list_related_posts` 方法返回結果略有區別，但它們都是**“可迭代的帖子 ID”**，所以函式裡的迴圈在碰到不同的使用者型別時都能正常進行。

既然如此，那上面的程式碼符合“里氏替換原則”嗎？答案是否定的。因為雖然在當前 `list_user_post_titles` 函式的視角看來，子類 `Admin` 可以任意替代父類 `User` 使用，但這只是特殊用例下的一個巧合，並沒有通用性。請看看下面這個場景。

有一位新成員最近加入了專案開發，她需要實現一個新函式來獲取與使用者有關的所有帖子數量。當她讀到 `User` 類程式碼時，發現 `list_related_posts` 方法返回一個包含所有帖子 ID 的列表，於是她就此寫下了統計帖子數量的程式碼：

```python
def get_user_posts_count(user: User) -> int:
    """獲取與使用者相關的帖子個數
    """
    return len(user.list_related_posts())
```

在大多數情況下，當 `user` 引數只是普通使用者類時，上面的函式是可以正常執行的。

不過有一天，有其他人偶然使用了一個管理員使用者呼叫了上面的函式，馬上就碰到了異常：`TypeError: object of type 'generator' has no len()`。這時因為 `Admin` 雖然是 `User` 型別的子類，但它的 `list_related_posts` 方法返回卻是一個可迭代的生成器，並不是列表物件。而生成器是不支援 `len()` 操作的。

所以，對於新的 `get_user_posts_count` 函式來說，現在的使用者類繼承結構仍然違反了 L 原則。

### 分析類方法返回結果

在我們的程式碼裡，`User` 類和 `Admin` 類的 `list_related_posts` 返回的是兩類不同的結果：

- `User 類`：返回一個包含帖子 ID 的列表物件
- `Admin 類`：返回一個產生帖子 ID 的生成器

很明顯，二者之間存在共通點：它們都是可被迭代的 int 物件（`Iterable[int]`）。這也是為什麼對於第一個獲取使用者帖子標題的函式來說，兩個使用者類可以互相交換使用的原因。

不過，針對某個特定函式，子類可以替代父類使用，並不等同於程式碼就符合“里氏替換原則”。要符合 L 原則，**我們一定得讓子類方法和父類返回同一型別的結果，支援同樣的操作。或者更進一步，返回支援更多種操作的子型別結果也是可以接受的。**

而現在的設計沒做到這點，現在的子類返回值所支援的操作，只是父類的一個子集。`Admin` 子類的 `list_related_posts` 方法所返回的生成器，只支援父類 `User` 返回列表裡的“迭代操作”，而不支援其他行為（比如 `len()`）。所以我們沒辦法隨意的用子類替換父類，自然也就無法符合里氏替換原則。

> **注意：**此處說“生成器”支援的操作是“列表”的子集其實不是特別嚴謹，因為生成器還支援 `.send()` 等其他操作。不過在這裡，我們可以只關注它的可迭代特性。

### 如何修改程式碼

為了讓程式碼符合“里氏替換原則”。我們需要讓子類和父類的同名方法，返回同一類結果。

```python
class User(Model):
    """普通使用者模型類
    """
    def __init__(self, username: str):
        self.username = username

    def list_related_posts(self) -> Iterable[int]:
        """查詢所有與之相關的帖子 ID
        """
        for post in session.query(Post).filter(username=self.username):
            yield post.id

    def get_related_posts_count(self) -> int:
        """獲取與使用者有關的帖子總數
        """
        value = 0
        for _ in self.list_related_posts():
            value += 1
        return value


class Admin(User):
    """管理員使用者類
    """
    def list_related_posts(self) -> Iterable[int]:
        # 管理員與所有的帖子都有關，為了節約記憶體，使用生成器返回
        for post in session.query(Post).all():
            yield post.id
```

而對於“獲取與使用者有關的帖子總數”這個需求，我們可以直接在父類 `User` 中定義一個 `get_related_posts_count` 方法，遍歷帖子 ID，統計數量後返回。

### 方法引數與 L 原則

除了子類方法返回不一致的型別以外，子類對父類方法引數的變更也容易導致違反 L 原則。拿下面這段程式碼為例：

```python
class User(Model):
    def list_related_posts(self, include_hidden: bool = False) -> List[int]:
        # ... ...


class Admin(User):
    def list_related_posts(self) -> List[int]:
        # ... ...
```

如果父類 `User` 的 `list_related_posts` 方法接收一個可選的 `include_hidden` 引數，那它的子類就不應該去掉這個引數。否則當某個函式呼叫依賴了 `include_hidden` 引數，但使用者物件卻是子類 `Admin` 型別時，程式就會報錯。

為了讓程式碼符合 L 原則，我們必須做到 **讓子類的方法引數簽名和父類完全一致，或者更寬鬆**。這樣才能做到在任何使用引數呼叫父類方法的地方，隨意用子類替換。

比如下面這樣就是符合 L 原則的：

```python
class User(Model):
    def list_related_posts(self, include_hidden: bool = False) -> List[int]:
        # ... ...


class Admin(User):
    def list_related_posts(self, include_hidden: bool = False, active_only = True) -> List[int]:
        # 子類可以為方法增加額外的可選引數：active_only
        # ... ...
```

## 總結

在這篇文章裡，我透過兩個具體場景，向你描述了 “SOLID” 設計原則中的第三位成員：**里氏替換原則**。

“里氏替換原則”是一個非常具體的原則，它專門為 OOP 裡的繼承場景服務。當你設計類繼承關係，尤其是編寫子類程式碼時，請經常性的問自己這個問題：*“如果我把專案裡所有使用父類的地方換成這個子類，程式是否還能正常執行？”*

如果答案是否定的，那麼你就應該考慮調整一下現在的類設計了。調整方式有很多種，有時候你得把大類拆分為更小的類，有時候你得調換類之間的繼承關係，有時候你得為父類新增新的方法和屬性，就像文章裡的第一個場景一樣。只要開動腦筋，總會找到合適的辦法。

讓我們最後再總結一下吧：

- **“L：里氏替換原則”**認為子類應該可以任意替換父類被使用
- 在類的使用方增加具體的型別判斷（*isinstance*），通常不是最佳解決方案
- 違反里氏替換原則，通常也會導致違反“開放-關閉”原則
- 考慮什麼是類的核心特徵，然後為父類增加新的方法和屬性可以幫到你
- 子類方法應該和父類同名方法返回同一型別，或者返回支援更多操作的子型別也行
- 子類的方法引數應該和父類同名方法完全一致，或者更為寬鬆

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【14.寫好面向物件程式碼的原則（下）】](14-write-solid-python-codes-part-3.md)

[<<<上一篇【12.寫好面向物件程式碼的原則（上）】](12-write-solid-python-codes-part-1.md)

## 附錄

- 題圖來源: Photo by NeONBRAND on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：寫好面向物件程式碼的原則（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：編寫地道迴圈的兩個建議](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)
- [Python 工匠：高效操作檔案的三個建議](https://www.zlovezl.cn/articles/three-tips-on-writing-file-related-codes/)


