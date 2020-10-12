# Python 工匠：善用變數來改善程式碼質量

## 『Python 工匠』是什麼？

我一直覺得程式設計某種意義上是一門『手藝』，因為優雅而高效的程式碼，就如同完美的手工藝品一樣讓人賞心悅目。

在雕琢程式碼的過程中，有大工程：比如應該用什麼架構、哪種設計模式。也有更多的小細節，比如何時使用異常（Exceptions）、或怎麼給變數起名。那些真正優秀的程式碼，正是由無數優秀的細節造就的。

『Python 工匠』這個系列文章，是我的一次小小嚐試。它專注於分享 Python 程式設計中的一些偏**『小』**的東西。希望能夠幫到每一位程式設計路上的匠人。

> 這是 “Python 工匠”系列的第 1 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

## 變數和程式碼質量

作為『Python 工匠』系列文章的第一篇，我想先談談 『變數（Variables）』。因為如何定義和使用變數，一直都是學習任何一門程式語言最先要掌握的技能之一。

變數用的好或不好，和程式碼質量有著非常重要的聯絡。在關於變數的諸多問題中，為變數起一個好名字尤其重要。

### 內容目錄

* [如何為變數起名](#如何為變數起名)
    * [1. 變數名要有描述性，不能太寬泛](#1-變數名要有描述性不能太寬泛)
    * [2. 變數名最好讓人能猜出型別](#2-變數名最好讓人能猜出型別)
        * [『什麼樣的名字會被當成 bool 型別？』](#什麼樣的名字會被當成-bool-型別)
        * [『什麼樣的名字會被當成 int/float 型別？』](#什麼樣的名字會被當成-intfloat-型別)
        * [其他型別](#其他型別)
    * [3. 適當使用『匈牙利命名法』](#3-適當使用匈牙利命名法)
    * [4. 變數名儘量短，但是絕對不要太短](#4-變數名儘量短但是絕對不要太短)
        * [使用短名字的例外情況](#使用短名字的例外情況)
    * [5. 其他注意事項](#5-其他注意事項)
* [更好的使用變數](#更好的使用變數)
    * [1. 保持一致性](#1-保持一致性)
    * [2. 儘量不要用 globals()/locals()](#2-儘量不要用-globalslocals)
    * [3. 變數定義儘量靠近使用](#3-變數定義儘量靠近使用)
    * [4. 合理使用 namedtuple/dict 來讓函式返回多個值](#4-合理使用-namedtupledict-來讓函式返回多個值)
    * [5. 控制單個函式內的變數數量](#5-控制單個函式內的變數數量)
    * [6. 及時刪掉那些沒用的變數](#6-及時刪掉那些沒用的變數)
    * [7. 能不定義變數就不定義](#7-能不定義變數就不定義)
* [結語](#結語)

## 如何為變數起名

在電腦科學領域，有一句著名的格言（俏皮話）：

> There are only two hard things in Computer Science: cache invalidation and naming things.
> 在電腦科學領域只有兩件難事：快取失效 和 給東西起名字
> 
> -- Phil Karlton

第一個『快取過期問題』的難度不用多說，任何用過快取的人都會懂。至於第二個『給東西起名字』這事的難度，我也是深有體會。在我的職業生涯裡，度過的最為黑暗的下午之一，就是坐在顯示器前抓耳撓腮為一個新專案起一個合適的名字。

程式設計時起的最多的名字，還數各種變數。給變數起一個好名字很重要，**因為好的變數命名可以極大提高程式碼的整體可讀性。**

下面幾點，是我總結的為變數起名時，最好遵守的基本原則。

### 1. 變數名要有描述性，不能太寬泛

在**可接受的長度範圍內**，變數名能把它所指向的內容描述的越精確越好。所以，儘量不要用那些過於寬泛的詞來作為你的變數名：

- **BAD**: `day`, `host`, `cards`, `temp`
- **GOOD**:  `day_of_week`, `hosts_to_reboot`, `expired_cards`

### 2. 變數名最好讓人能猜出型別

所有學習 Python 的人都知道，Python 是一門動態型別語言，它（至少在 [PEP 484](https://www.python.org/dev/peps/pep-0484/) 出現前）沒有變數型別宣告。所以當你看到一個變數時，除了透過上下文猜測，沒法輕易知道它是什麼型別。

不過，人們對於變數名和變數型別的關係，通常會有一些直覺上的約定，我把它們總結在了下面。

#### 『什麼樣的名字會被當成 bool 型別？』

布林型別變數的最大特點是：它只存在兩個可能的值**『是』** 或 **『不是』**。所以，用 `is`、`has` 等非黑即白的詞修飾的變數名，會是個不錯的選擇。原則就是：**讓讀到變數名的人覺得這個變數只會有『是』或『不是』兩種值**。

下面是幾個不錯的示例：

- `is_superuser`：『是否超級使用者』，只會有兩種值：是/不是
- `has_error`：『有沒有錯誤』，只會有兩種值：有/沒有
- `allow_vip`：『是否允許 VIP』，只會有兩種值：允許/不允許
- `use_msgpack`：『是否使用 msgpack』，只會有兩種值：使用/不使用
- `debug`：『是否開啟除錯模式』，被當做 bool 主要是因為約定俗成

#### 『什麼樣的名字會被當成 int/float 型別？』

人們看到和數字相關的名字，都會預設他們是 int/float 型別，下面這些是比較常見的：

- 釋義為數字的所有單詞，比如：`port（埠號）`、`age（年齡）`、`radius（半徑）` 等等
- 使用 _id 結尾的單詞，比如：`user_id`、`host_id`
- 使用 length/count 開頭或者結尾的單詞，比如： `length_of_username`、`max_length`、`users_count`

**注意：**不要使用普通的複數來表示一個 int 型別變數，比如 `apples`、`trips`，最好用 `number_of_apples`、`trips_count` 來替代。

#### 其他型別

對於 str、list、tuple、dict 這些複雜型別，很難有一個統一的規則讓我們可以透過名字去猜測變數型別。比如 `headers`，既可能是一個頭資訊列表，也可能是包含頭資訊的 dict。

對於這些型別的變數名，最推薦的方式，就是編寫規範的文件，在函式和方法的 document string 中，使用 sphinx 格式（[Python 官方文件使用的文件工具](http://www.sphinx-doc.org/en/stable/)）來標註所有變數的型別。 

### 3. 適當使用『匈牙利命名法』

第一次知道『[匈牙利命名法](https://en.wikipedia.org/wiki/Hungarian_notation)』，是在 [Joel on Software 的一篇博文](http://www.joelonsoftware.com/articles/Wrong.html)中。簡而言之，匈牙利命名法就是把變數的『型別』縮寫，放到變數名的最前面。

關鍵在於，這裡說的變數『型別』，並非指傳統意義上的 int/str/list 這種型別，而是指那些和你的程式碼業務邏輯相關的型別。

比如，在你的程式碼中有兩個變數：`students` 和 `teachers`，他們指向的內容都是一個包含 Person 物件的 list 。使用『匈牙利命名法』後，可以把這兩個名字改寫成這樣：

students -> `pl_students`
teachers -> `pl_teachers`

其中 pl 是 **person list** 的首字母縮寫。當變數名被加上字首後，如果你看到以 `pl_` 打頭的變數，就能知道它所指向的值型別了。

很多情況下，使用『匈牙利命名法』是個不錯的主意，因為它可以改善你的程式碼可讀性，尤其在那些變數眾多、同一型別多次出現時。注意不要濫用就好。

### 4. 變數名儘量短，但是絕對不要太短

在前面，我們提到要讓變數名有描述性。如果不給這條原則加上任何限制，那麼你很有可能寫出這種描述性極強的變數名：`how_much_points_need_for_level2`。如果程式碼中充斥著這種過長的變數名，對於程式碼可讀性來說是個災難。

一個好的變數名，長度應該控制在 **兩到三個單詞左右**。比如上面的名字，可以縮寫為 `points_level2`。

**絕大多數情況下，都應該避免使用那些只有一兩個字母的短名字**，比如陣列索引三劍客 `i`、`j`、`k`，用有明確含義的名字，比如 person_index 來代替它們總是會更好一些。

#### 使用短名字的例外情況

有時，上面的原則也存在一些例外。當一些意義明確但是較長的變數名重複出現時，為了讓程式碼更簡潔，使用短名字縮寫是完全可以的。但是為了降低理解成本，同一段程式碼內最好不要使用太多這種短名字。

比如在 Python 中匯入模組時，就會經常用到短名字作為別名，像 Django i18n 翻譯時常用的 `gettext` 方法通常會被縮寫成 `_` 來使用*（from django.utils.translation import ugettext as _）*

### 5. 其他注意事項

其他一些給變數命名的注意事項：

- 同一段程式碼內不要使用過於相似的變數名，比如同時出現 `users`、`users1`、 `user3` 這種序列
- 不要使用帶否定含義的變數名，用 `is_special` 代替 `is_not_normal`

## 更好的使用變數

前面講了如何為變數取一個好名字，下面我們談談在日常使用變數時，應該注意的一些小細節。

### 1. 保持一致性

如果你在一個方法內裡面把圖片變數叫做 `photo`，在其他的地方就不要把它改成 `image`，這樣只會讓程式碼的閱讀者困惑：『`image` 和 `photo` 到底是不是同一個東西？』

另外，雖然 Python 是動態型別語言，但那也不意味著你可以用同一個變數名一會表示 str 型別，過會又換成 list。**同一個變數名指代的變數型別，也需要保持一致性。**

### 2. 儘量不要用 globals()/locals()

也許你第一次發現 globals()/locals() 這對內建函式時很興奮，迫不及待的寫下下面這種極端『簡潔』的程式碼：

```python
def render_trip_page(request, user_id, trip_id):
    user = User.objects.get(id=user_id)
    trip = get_object_or_404(Trip, pk=trip_id)
    is_suggested = is_suggested(user, trip)
    # 利用 locals() 節約了三行程式碼，我是個天才！
    return render(request, 'trip.html', locals())
```

千萬不要這麼做，這樣只會讓讀到這段程式碼的人（包括三個月後的你自己）痛恨你，因為他需要記住這個函式內定義的所有變數（想想這個函式增長到兩百行會怎麼樣？），更別提 locals() 還會把一些不必要的變數傳遞出去。

更何況， [The Zen of Python（Python 之禪）](https://www.python.org/dev/peps/pep-0020/) 說的清清楚楚：**Explicit is better than implicit.（顯式優於隱式）**。所以，還是老老實實把程式碼寫成這樣吧：

```python
    return render(request, 'trip.html', {
        'user': user,
        'trip': trip,
        'is_suggested': is_suggested
    })
```

### 3. 變數定義儘量靠近使用

這個原則屬於老生常談了。很多人（包括我）在剛開始學習程式設計時，會有一個習慣。就是把所有的變數定義寫在一起，放在函式或方法的最前面。

```python
def generate_trip_png(trip):
    path = []
    markers = []
    photo_markers = []
    text_markers = []
    marker_count = 0
    point_count = 0
    ... ...
```

這樣做只會讓你的程式碼『看上去很整潔』，但是對提高程式碼可讀性沒有任何幫助。

更好的做法是，**讓變數定義儘量靠近使用**。那樣當你閱讀程式碼時，可以更好的理解程式碼的邏輯，而不是費勁的去想這個變數到底是什麼、哪裡定義的？

### 4. 合理使用 namedtuple/dict 來讓函式返回多個值

Python 的函式可以返回多個值：

```python
def latlon_to_address(lat, lon):
    return country, province, city

# 利用多返回值一次解包定義多個變數
country, province, city = latlon_to_address(lat, lon)
```

但是，這樣的用法會產生一個小問題：如果某一天， `latlon_to_address` 函式需要返回『城區（District）』時怎麼辦？

如果是上面這種寫法，你需要找到所有呼叫 `latlon_to_address` 的地方，補上多出來的這個變數，否則 *ValueError: too many values to unpack* 就會找上你：

```python
country, province, city, district = latlon_to_address(lat, lon)
# 或者使用 _ 忽略多出來的返回值
country, province, city, _ = latlon_to_address(lat, lon)
```

對於這種可能變動的多返回值函式，使用 namedtuple/dict 會更方便一些。當你新增返回值時，不會對之前的函式呼叫產生任何破壞性的影響：

```python
# 1. 使用 dict
def latlon_to_address(lat, lon):
    return {
        'country': country,
        'province': province,
        'city': city
    }

addr_dict = latlon_to_address(lat, lon)

# 2. 使用 namedtuple
from collections import namedtuple

Address = namedtuple("Address", ['country', 'province', 'city'])

def latlon_to_address(lat, lon):
    return Address(
        country=country,
        province=province,
        city=city
    )

addr = latlon_to_address(lat, lon)
```

不過這樣做也有壞處，因為程式碼對變更的相容性雖然變好了，但是你不能繼續用之前 `x, y = f()` 的方式一次解包定義多個變量了。取捨在於你自己。

### 5. 控制單個函式內的變數數量

人腦的能力是有限的，研究表明，人類的短期記憶只能同時記住不超過十個名字。所以，當你的某個函式過長（一般來說，超過一屏的的函式就會被認為有點過長了），包含了太多變數時。請及時把它拆分為多個小函式吧。

### 6. 及時刪掉那些沒用的變數

這條原則非常簡單，也很容易做到。但是如果沒有遵守，那它對你的程式碼質量的打擊是毀滅級的。會讓閱讀你程式碼的人有一種被愚弄的感覺。

```python
def fancy_func():
    # 讀者心理：嗯，這裡定義了一個 fancy_vars
    fancy_vars = get_fancy()
    ... ...（一大堆程式碼過後）

    # 讀者心理：這裡就結束了？之前的 fancy_vars 去哪了？被貓吃了嗎？
    return result
```

所以，請開啟 IDE 的智慧提示，及時清理掉那些定義了但是沒有使用的變數吧。

### 7. 定義臨時變數提升可讀性

有時，我們的程式碼裡會出現一些複雜的表示式，像下面這樣：

```python
# 為所有性別為女性，或者級別大於 3 的活躍使用者發放 10000 個金幣
if user.is_active and (user.sex == 'female' or user.level > 3):
    user.add_coins(10000)
    return
```

看見 `if` 後面那一長串了嗎？有點難讀對不對？但是如果我們把它賦值成一個臨時變數，
就能給讀者一個心理緩衝，提高可讀性：

```
# 為所有性別為女性，或者級別大於 3 的活躍使用者發放 10000 個金幣
user_is_eligible = user.is_active and (user.sex == 'female' or user.level > 3):

if user_is_eligible:
    user.add_coins(10000)
    return
```

定義臨時變數可以提高可讀性。但有時，把不必要的東西賦值成臨時變數反而會讓程式碼顯得囉嗦：

```python
def get_best_trip_by_user_id(user_id):

    # 心理活動：『嗯，這個值未來說不定會修改/二次使用』，讓我們先把它定義成變數吧！
    user = get_user(user_id)
    trip = get_best_trip(user_id)
    result = {
        'user': user,
        'trip': trip
    }
    return result
```

其實，你所想的『未來』永遠不會來，這段程式碼裡的三個臨時變數完全可以去掉，變成這樣：

```python
def get_best_trip_by_user_id(user_id):
    return {
        'user': get_user(user_id),
        'trip': get_best_trip(user_id)
    }
```

沒必要為了那些可能出現的變動，犧牲程式碼當前的可讀性。如果以後有定義變數的需求，那就以後再加吧。

## 結語

碎碎唸了一大堆，不知道有多少人能夠堅持到最後。變數作為程式語言的重要組成部分，值得我們在定義和使用它時，多花一丁點時間思考一下，那樣會讓你的程式碼變得更優秀。

這是『Python 工匠』系列文章的第一篇，不知道看完文章的你，有沒有什麼想吐槽的？請留言告訴我吧。

[>>>下一篇【2.編寫條件分支程式碼的技巧】](2-if-else-block-secrets.md)

> 文章更新記錄：
> 
> - 2018.04.09：根據 @onlyice 的建議，添加了 namedtuple 部分

