# Python 工匠： 異常處理的三個好習慣

## 前言

> 這是 “Python 工匠”系列的第 6 篇文章。[[檢視系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/03/bernard-hermant-665508-unsplash_w1280.jpg" width="100%" />
</div>

如果你用 Python 程式設計，那麼你就無法避開異常，因為異常在這門語言裡無處不在。打個比方，當你在指令碼執行時按 `ctrl+c` 退出，直譯器就會產生一個 `KeyboardInterrupt` 異常。而 `KeyError`、`ValueError`、`TypeError` 等更是日常程式設計裡隨處可見的老朋友。

異常處理工作由“捕獲”和“丟擲”兩部分組成。“捕獲”指的是使用 `try ... except` 包裹特定語句，妥當的完成錯誤流程處理。而恰當的使用 `raise` 主動“丟擲”異常，更是優雅程式碼裡必不可少的組成部分。

在這篇文章裡，我會分享與異常處理相關的 3 個好習慣。繼續閱讀前，我希望你已經瞭解了下面這些知識點：

- 異常的基本語法與用法*（建議閱讀官方文件 [“Errors and Exceptions”](https://docs.python.org/3.6/tutorial/errors.html)）*
- 為什麼要使用異常代替錯誤返回*（建議閱讀[《讓函式返回結果的技巧》](https://www.zlovezl.cn/articles/function-returning-tips/)）*
- 為什麼在寫 Python 時鼓勵使用異常 *（建議閱讀 [“Write Cleaner Python: Use Exceptions”](https://jeffknupp.com/blog/2013/02/06/write-cleaner-python-use-exceptions/)）*

## 三個好習慣

### 1. 只做最精確的異常捕獲

假如你不夠了解異常機制，就難免會對它有一種天然恐懼感。你可能會覺得：*異常是一種不好的東西，好的程式就應該捕獲所有的異常，讓一切都平平穩穩的執行。*而抱著這種想法寫出的程式碼，裡面通常會出現大段含糊的異常捕獲邏輯。

讓我們用一段可執行指令碼作為樣例：

```python
# -*- coding: utf-8 -*-
import requests
import re


def save_website_title(url, filename):
    """獲取某個地址的網頁標題，然後將其寫入到檔案中
    
    :returns: 如果成功儲存，返回 True，否則列印錯誤，返回 False
    """
    try:
        resp = requests.get(url)
        obj = re.search(r'<title>(.*)</title>', resp.text)
        if not obj:
            print('save failed: title tag not found in page content')
            return False

        title = obj.grop(1)
        with open(filename, 'w') as fp:
            fp.write(title)
            return True
    except Exception:
        print(f'save failed: unable to save title of {url} to {filename}')
        return False


def main():
    save_website_title('https://www.qq.com', 'qq_title.txt')


if __name__ == '__main__':
    main()
```

腳本里的 `save_website_title` 函式做了好幾件事情。它首先透過網路獲取網頁內容，然後利用正則匹配出標題，最後將標題寫在本地檔案裡。而這裡有兩個步驟很容易出錯：**網路請求** 與 **本地檔案操作**。所以在程式碼裡，我們用一個大大的 `try ... except` 語句塊，將這幾個步驟都包裹了起來。**安全第一** ⛑。

那麼，這段看上去簡潔易懂的程式碼，裡面藏著什麼問題呢？

如果你旁邊剛好有一臺安裝了 Python 的電腦，那麼你可以試著跑一遍上面的指令碼。你會發現，上面的程式碼是不能成功執行的。而且你還會發現，無論你如何修改網址和目標檔案的值，程式仍然會報錯 *“save failed: unable to...”*。為什麼呢？

問題就藏在這個碩大無比的 `try ... except` 語句塊裡。假如你把眼睛貼近螢幕，非常仔細的檢查這段程式碼。你會發現在編寫函式時，我犯了一個**小錯誤**，我把獲取正則匹配串的方法錯打成了 `obj.grop(1)`，少了一個 'u'（`obj.group(1)`）。

但正是因為那個過於龐大、含糊的異常捕獲，這個由打錯方法名導致的原本該被丟擲的 `AttibuteError` 卻被吞噬了。從而給我們的 debug 過程增加了不必要的麻煩。

異常捕獲的目的，不是去捕獲儘可能多的異常。假如我們從一開始就堅持：**只做最精準的異常捕獲**。那麼這樣的問題就根本不會發生，精準捕獲包括：

- 永遠只捕獲那些可能會丟擲異常的語句塊
- 儘量只捕獲精確的異常型別，而不是模糊的 `Exception`

依照這個原則，我們的樣例應該被改成這樣：

```python
from requests.exceptions import RequestException


def save_website_title(url, filename):
    try:
        resp = requests.get(url)
    except RequestException as e:
        print(f'save failed: unable to get page content: {e}')
        return False

    # 這段正則操作本身就是不應該丟擲異常的，所以我們沒必要使用 try 語句塊
    # 假如 group 被誤打成了 grop 也沒關係，程式馬上就會透過 AttributeError 來
    # 告訴我們。
    obj = re.search(r'<title>(.*)</title>', resp.text)
    if not obj:
        print('save failed: title tag not found in page content')
        return False
    title = obj.group(1)

    try:
        with open(filename, 'w') as fp:
            fp.write(title)
    except IOError as e:
        print(f'save failed: unable to write to file {filename}: {e}')
        return False
    else:
        return True
```

### 2. 別讓異常破壞抽象一致性

大約四五年前，當時的我正在開發某移動應用的後端 API 專案。如果你也有過開發後端 API 的經驗，那麼你一定知道，這樣的系統都需要制定一套**“API 錯誤碼規範”**，來為客戶端處理呼叫錯誤時提供方便。

一個錯誤碼返回大概長這個樣子：

```javascript
// HTTP Status Code: 400
// Content-Type: application/json
{
    "code": "UNABLE_TO_UPVOTE_YOUR_OWN_REPLY",
    "detail": "你不能推薦自己的回覆"
}
```

在制定好錯誤碼規範後，接下來的任務就是如何實現它。當時的專案使用了 Django 框架，而 Django 的錯誤頁面正是使用了異常機制實現的。打個比方，如果你想讓一個請求返回 404 狀態碼，那麼只要在該請求處理過程中執行 `raise Http404` 即可。

所以，我們很自然的從 Django 獲得了靈感。首先，我們在專案內定義了錯誤碼異常類：`APIErrorCode`。然後依據“錯誤碼規範”，寫了很多繼承該類的錯誤碼。當需要返回錯誤資訊給使用者時，只需要做一次 `raise` 就能搞定。

```python
raise error_codes.UNABLE_TO_UPVOTE
raise error_codes.USER_HAS_BEEN_BANNED
... ...
```

毫無意外，所有人都很喜歡用這種方式來返回錯誤碼。因為它用起來非常方便，無論呼叫棧多深，只要你想給使用者返回錯誤碼，呼叫 `raise error_codes.ANY_THING` 就好。

隨著時間推移，專案也變得越來越龐大，丟擲 `APIErrorCode` 的地方也越來越多。有一天，我正準備複用一個底層圖片處理函式時，突然碰到了一個問題。

我看到了一段讓我非常糾結的程式碼：

```python
# 在某個處理影象的模組內部
# <PROJECT_ROOT>/util/image/processor.py
def process_image(...):
    try:
        image = Image.open(fp)
    except Exception:
        # 說明（非專案原註釋）：該異常將會被 Django 的中介軟體捕獲，往前端返回
        # "上傳的圖片格式有誤" 資訊
        raise error_codes.INVALID_IMAGE_UPLOADED
    ... ...
```

`process_image` 函式會嘗試解析一個檔案物件，如果該物件不能被作為圖片正常開啟，就丟擲 `error_codes.INVALID_IMAGE_UPLOADED （APIErrorCode 子類）` 異常，從而給呼叫方返回錯誤程式碼 JSON。

讓我給你從頭理理這段程式碼。最初編寫 `process_image` 時，我雖然把它放在了 `util.image` 模組裡，但當時調這個函式的地方就只有 *“處理使用者上傳圖片的 POST 請求”* 而已。為了偷懶，我讓函式直接丟擲 `APIErrorCode` 異常來完成了錯誤處理工作。

再來說當時的問題。那時我需要寫一個在後臺執行的批處理圖片指令碼，而它剛好可以複用 `process_image` 函式所實現的功能。但這時不對勁的事情出現了，如果我想複用該函式，那麼：

- 我必須去捕獲一個名為 `INVALID_IMAGE_UPLOADED` 的異常
    - **哪怕我的圖片根本就不是來自於使用者上傳**
- 我必須引入 `APIErrorCode` 異常類作為依賴來捕獲異常
    - **哪怕我的指令碼和 Django API 根本沒有任何關係**

**這就是異常類抽象層級不一致導致的結果。**APIErrorCode 異常類的意義，在於表達一種能夠直接被終端使用者（人）識別並消費的“錯誤程式碼”。**它在整個專案裡，屬於最高層的抽象之一。**但是出於方便，我們卻在底層模組裡引入並丟擲了它。這打破了 `image.processor` 模組的抽象一致性，影響了它的可複用性和可維護性。

這類情況屬於“模組丟擲了**高於**所屬抽象層級的異常”。避免這類錯誤需要注意以下幾點：

- 讓模組只丟擲與當前抽象層級一致的異常
    - 比如 `image.processer` 模組應該丟擲自己封裝的 `ImageOpenError` 異常
- 在必要的地方進行異常包裝與轉換
    - 比如，應該在貼近高層抽象（檢視 View 函式）的地方，將影象處理模組的 `ImageOpenError` 低階異常包裝轉換為 `APIErrorCode` 高階異常

修改後的程式碼：

```python
# <PROJECT_ROOT>/util/image/processor.py
class ImageOpenError(Exception):
    pass


def process_image(...):
    try:
        image = Image.open(fp)
    except Exception as e:
        raise ImageOpenError(exc=e)
    ... ...
    
# <PROJECT_ROOT>/app/views.py
def foo_view_function(request):
    try:
        process_image(fp)
    except ImageOpenError:
        raise error_codes.INVALID_IMAGE_UPLOADED
```

除了應該避免丟擲**高於**當前抽象級別的異常外，我們同樣應該避免洩露**低於**當前抽象級別的異常。

如果你用過 `requests` 模組，你可能已經發現它請求頁面出錯時所丟擲的異常，並不是它在底層所使用的 `urllib3` 模組的原始異常，而是透過 `requests.exceptions` 包裝過一次的異常。

```python
>>> try:
...     requests.get('https://www.invalid-host-foo.com')
... except Exception as e:
...     print(type(e))
...
<class 'requests.exceptions.ConnectionError'>
```

這樣做同樣是為了保證異常類的抽象一致性。因為 urllib3 模組是 requests 模組依賴的底層實現細節，而這個細節有可能在未來版本發生變動。所以必須對它丟擲的異常進行恰當的包裝，避免未來的底層變更對 `requests` 使用者端錯誤處理邏輯產生影響。

### 3. 異常處理不應該喧賓奪主

在前面我們提到異常捕獲要精準、抽象級別要一致。但在現實世界中，如果你嚴格遵循這些流程，那麼很有可能會碰上另外一個問題：**異常處理邏輯太多，以至於擾亂了程式碼核心邏輯**。具體表現就是，程式碼裡充斥著大量的 `try`、`except`、`raise` 語句，讓核心邏輯變得難以辨識。

讓我們看一段例子：

```python
def upload_avatar(request):
    """使用者上傳新頭像"""
    try:
        avatar_file = request.FILES['avatar']
    except KeyError:
        raise error_codes.AVATAR_FILE_NOT_PROVIDED

    try:
       resized_avatar_file = resize_avatar(avatar_file)
    except FileTooLargeError as e:
        raise error_codes.AVATAR_FILE_TOO_LARGE
    except ResizeAvatarError as e:
        raise error_codes.AVATAR_FILE_INVALID

    try:
        request.user.avatar = resized_avatar_file
        request.user.save()
    except Exception:
        raise error_codes.INTERNAL_SERVER_ERROR
    return HttpResponse({})
```

這是一個處理使用者上傳頭像的檢視函式。這個函式內做了三件事情，並且針對每件事都做了異常捕獲。如果做某件事時發生了異常，就返回對使用者友好的錯誤到前端。

這樣的處理流程縱然合理，但是顯然程式碼裡的異常處理邏輯有點“喧賓奪主”了。一眼看過去全是程式碼縮排，很難提煉出程式碼的核心邏輯。

早在 2.5 版本時，Python 語言就已經提供了對付這類場景的工具：“上下文管理器（context manager）”。上下文管理器是一種配合 `with` 語句使用的特殊 Python 物件，透過它，可以讓異常處理工作變得更方便。

那麼，如何利用上下文管理器來改善我們的異常處理流程呢？讓我們直接看程式碼吧。

```python
class raise_api_error:
    """captures specified exception and raise ApiErrorCode instead

    :raises: AttributeError if code_name is not valid
    """
    def __init__(self, captures, code_name):
        self.captures = captures
        self.code = getattr(error_codes, code_name)

    def __enter__(self):
        # 該方法將在進入上下文時呼叫
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        # 該方法將在退出上下文時呼叫
        # exc_type, exc_val, exc_tb 分別表示該上下文內丟擲的
        # 異常型別、異常值、錯誤棧
        if exc_type is None:
            return False

        if exc_type == self.captures:
            raise self.code from exc_val
        return False
```

在上面的程式碼裡，我們定義了一個名為 `raise_api_error` 的上下文管理器，它在進入上下文時什麼也不做。但是在退出上下文時，會判斷當前上下文中是否丟擲了型別為 `self.captures` 的異常，如果有，就用 `APIErrorCode` 異常類替代它。

使用該上下文管理器後，整個函式可以變得更清晰簡潔：

```python
def upload_avatar(request):
    """使用者上傳新頭像"""
    with raise_api_error(KeyError, 'AVATAR_FILE_NOT_PROVIDED'):
        avatar_file = request.FILES['avatar']

    with raise_api_error(ResizeAvatarError, 'AVATAR_FILE_INVALID'),\
            raise_api_error(FileTooLargeError, 'AVATAR_FILE_TOO_LARGE'):
        resized_avatar_file = resize_avatar(avatar_file)

    with raise_api_error(Exception, 'INTERNAL_SERVER_ERROR'):
        request.user.avatar = resized_avatar_file
        request.user.save()
    return HttpResponse({})
```

> Hint：建議閱讀 [PEP 343 -- The "with" Statement | Python.org](https://www.python.org/dev/peps/pep-0343/)，瞭解與上下文管理器有關的更多知識。
> 
> 模組 [contextlib](https://docs.python.org/3/library/contextlib.html) 也提供了非常多與編寫上下文管理器相關的工具函式與樣例。

## 總結

在這篇文章中，我分享了與異常處理相關的三個建議。最後再總結一下要點：

- 只捕獲可能會丟擲異常的語句，避免含糊的捕獲邏輯
- 保持模組異常類的抽象一致性，必要時對底層異常類進行包裝
- 使用“上下文管理器”可以簡化重複的異常處理邏輯

看完文章的你，有沒有什麼想吐槽的？請留言或者在 [專案 Github Issues](https://github.com/piglei/one-python-craftsman) 告訴我吧。

[>>>下一篇【7.編寫地道迴圈的兩個建議】](7-two-tips-on-loop-writing.md)

[<<<上一篇【5.讓函式返回結果的技巧】](5-function-returning-tips.md)

## 附錄

- 題圖來源: Photo by Bernard Hermant on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：善用變數改善程式碼質量](https://www.zlovezl.cn/articles/python-using-variables-well/)
- [Python 工匠：編寫條件分支程式碼的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：讓程式返回結果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)


