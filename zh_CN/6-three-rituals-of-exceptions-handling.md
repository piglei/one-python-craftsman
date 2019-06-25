# Python 工匠： 异常处理的三个好习惯

## 前言

> 这是 “Python 工匠”系列的第 6 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/03/bernard-hermant-665508-unsplash_w1280.jpg" width="100%" />
</div>

如果你用 Python 编程，那么你就无法避开异常，因为异常在这门语言里无处不在。打个比方，当你在脚本执行时按 `ctrl+c` 退出，解释器就会产生一个 `KeyboardInterrupt` 异常。而 `KeyError`、`ValueError`、`TypeError` 等更是日常编程里随处可见的老朋友。

异常处理工作由“捕获”和“抛出”两部分组成。“捕获”指的是使用 `try ... except` 包裹特定语句，妥当的完成错误流程处理。而恰当的使用 `raise` 主动“抛出”异常，更是优雅代码里必不可少的组成部分。

在这篇文章里，我会分享与异常处理相关的 3 个好习惯。继续阅读前，我希望你已经了解了下面这些知识点：

- 异常的基本语法与用法*（建议阅读官方文档 [“Errors and Exceptions”](https://docs.python.org/3.6/tutorial/errors.html)）*
- 为什么要使用异常代替错误返回*（建议阅读[《让函数返回结果的技巧》](https://www.zlovezl.cn/articles/function-returning-tips/)）*
- 为什么在写 Python 时鼓励使用异常 *（建议阅读 [“Write Cleaner Python: Use Exceptions”](https://jeffknupp.com/blog/2013/02/06/write-cleaner-python-use-exceptions/)）*

## 三个好习惯

### 1. 只做最精确的异常捕获

假如你不够了解异常机制，就难免会对它有一种天然恐惧感。你可能会觉得：*异常是一种不好的东西，好的程序就应该捕获所有的异常，让一切都平平稳稳的运行。*而抱着这种想法写出的代码，里面通常会出现大段含糊的异常捕获逻辑。

让我们用一段可执行脚本作为样例：

```python
# -*- coding: utf-8 -*-
import requests
import re


def save_website_title(url, filename):
    """获取某个地址的网页标题，然后将其写入到文件中
    
    :returns: 如果成功保存，返回 True，否则打印错误，返回 False
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

脚本里的 `save_website_title` 函数做了好几件事情。它首先通过网络获取网页内容，然后利用正则匹配出标题，最后将标题写在本地文件里。而这里有两个步骤很容易出错：**网络请求** 与 **本地文件操作**。所以在代码里，我们用一个大大的 `try ... except` 语句块，将这几个步骤都包裹了起来。**安全第一** ⛑。

那么，这段看上去简洁易懂的代码，里面藏着什么问题呢？

如果你旁边刚好有一台安装了 Python 的电脑，那么你可以试着跑一遍上面的脚本。你会发现，上面的代码是不能成功执行的。而且你还会发现，无论你如何修改网址和目标文件的值，程序仍然会报错 *“save failed: unable to...”*。为什么呢？

问题就藏在这个硕大无比的 `try ... except` 语句块里。假如你把眼睛贴近屏幕，非常仔细的检查这段代码。你会发现在编写函数时，我犯了一个**小错误**，我把获取正则匹配串的方法错打成了 `obj.grop(1)`，少了一个 'u'（`obj.group(1)`）。

但正是因为那个过于庞大、含糊的异常捕获，这个由打错方法名导致的原本该被抛出的 `AttibuteError` 却被吞噬了。从而给我们的 debug 过程增加了不必要的麻烦。

异常捕获的目的，不是去捕获尽可能多的异常。假如我们从一开始就坚持：**只做最精准的异常捕获**。那么这样的问题就根本不会发生，精准捕获包括：

- 永远只捕获那些可能会抛出异常的语句块
- 尽量只捕获精确的异常类型，而不是模糊的 `Exception`

依照这个原则，我们的样例应该被改成这样：

```python
from requests.exceptions import RequestException


def save_website_title(url, filename):
    try:
        resp = requests.get(url)
    except RequestException as e:
        print(f'save failed: unable to get page content: {e}')
        return False

    # 这段正则操作本身就是不应该抛出异常的，所以我们没必要使用 try 语句块
    # 假如 group 被误打成了 grop 也没关系，程序马上就会通过 AttributeError 来
    # 告诉我们。
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

### 2. 别让异常破坏抽象一致性

大约四五年前，当时的我正在开发某移动应用的后端 API 项目。如果你也有过开发后端 API 的经验，那么你一定知道，这样的系统都需要制定一套**“API 错误码规范”**，来为客户端处理调用错误时提供方便。

一个错误码返回大概长这个样子：

```javascript
// HTTP Status Code: 400
// Content-Type: application/json
{
    "code": "UNABLE_TO_UPVOTE_YOUR_OWN_REPLY",
    "detail": "你不能推荐自己的回复"
}
```

在制定好错误码规范后，接下来的任务就是如何实现它。当时的项目使用了 Django 框架，而 Django 的错误页面正是使用了异常机制实现的。打个比方，如果你想让一个请求返回 404 状态码，那么只要在该请求处理过程中执行 `raise Http404` 即可。

所以，我们很自然的从 Django 获得了灵感。首先，我们在项目内定义了错误码异常类：`APIErrorCode`。然后依据“错误码规范”，写了很多继承该类的错误码。当需要返回错误信息给用户时，只需要做一次 `raise` 就能搞定。

```python
raise error_codes.UNABLE_TO_UPVOTE
raise error_codes.USER_HAS_BEEN_BANNED
... ...
```

毫无意外，所有人都很喜欢用这种方式来返回错误码。因为它用起来非常方便，无论调用栈多深，只要你想给用户返回错误码，调用 `raise error_codes.ANY_THING` 就好。

随着时间推移，项目也变得越来越庞大，抛出 `APIErrorCode` 的地方也越来越多。有一天，我正准备复用一个底层图片处理函数时，突然碰到了一个问题。

我看到了一段让我非常纠结的代码：

```python
# 在某个处理图像的模块内部
# <PROJECT_ROOT>/util/image/processor.py
def process_image(...):
    try:
        image = Image.open(fp)
    except Exception:
        # 说明（非项目原注释）：该异常将会被 Django 的中间件捕获，往前端返回
        # "上传的图片格式有误" 信息
        raise error_codes.INVALID_IMAGE_UPLOADED
    ... ...
```

`process_image` 函数会尝试解析一个文件对象，如果该对象不能被作为图片正常打开，就抛出 `error_codes.INVALID_IMAGE_UPLOADED （APIErrorCode 子类）` 异常，从而给调用方返回错误代码 JSON。

让我给你从头理理这段代码。最初编写 `process_image` 时，我虽然把它放在了 `util.image` 模块里，但当时调这个函数的地方就只有 *“处理用户上传图片的 POST 请求”* 而已。为了偷懒，我让函数直接抛出 `APIErrorCode` 异常来完成了错误处理工作。

再来说当时的问题。那时我需要写一个在后台运行的批处理图片脚本，而它刚好可以复用 `process_image` 函数所实现的功能。但这时不对劲的事情出现了，如果我想复用该函数，那么：

- 我必须去捕获一个名为 `INVALID_IMAGE_UPLOADED` 的异常
    - **哪怕我的图片根本就不是来自于用户上传**
- 我必须引入 `APIErrorCode` 异常类作为依赖来捕获异常
    - **哪怕我的脚本和 Django API 根本没有任何关系**

**这就是异常类抽象层级不一致导致的结果。**APIErrorCode 异常类的意义，在于表达一种能够直接被终端用户（人）识别并消费的“错误代码”。**它在整个项目里，属于最高层的抽象之一。**但是出于方便，我们却在底层模块里引入并抛出了它。这打破了 `image.processor` 模块的抽象一致性，影响了它的可复用性和可维护性。

这类情况属于“模块抛出了**高于**所属抽象层级的异常”。避免这类错误需要注意以下几点：

- 让模块只抛出与当前抽象层级一致的异常
    - 比如 `image.processer` 模块应该抛出自己封装的 `ImageOpenError` 异常
- 在必要的地方进行异常包装与转换
    - 比如，应该在贴近高层抽象（视图 View 函数）的地方，将图像处理模块的 `ImageOpenError` 低级异常包装转换为 `APIErrorCode` 高级异常

修改后的代码：

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

除了应该避免抛出**高于**当前抽象级别的异常外，我们同样应该避免泄露**低于**当前抽象级别的异常。

如果你用过 `requests` 模块，你可能已经发现它请求页面出错时所抛出的异常，并不是它在底层所使用的 `urllib3` 模块的原始异常，而是通过 `requests.exceptions` 包装过一次的异常。

```python
>>> try:
...     requests.get('https://www.invalid-host-foo.com')
... except Exception as e:
...     print(type(e))
...
<class 'requests.exceptions.ConnectionError'>
```

这样做同样是为了保证异常类的抽象一致性。因为 urllib3 模块是 requests 模块依赖的底层实现细节，而这个细节有可能在未来版本发生变动。所以必须对它抛出的异常进行恰当的包装，避免未来的底层变更对 `requests` 用户端错误处理逻辑产生影响。

### 3. 异常处理不应该喧宾夺主

在前面我们提到异常捕获要精准、抽象级别要一致。但在现实世界中，如果你严格遵循这些流程，那么很有可能会碰上另外一个问题：**异常处理逻辑太多，以至于扰乱了代码核心逻辑**。具体表现就是，代码里充斥着大量的 `try`、`except`、`raise` 语句，让核心逻辑变得难以辨识。

让我们看一段例子：

```python
def upload_avatar(request):
    """用户上传新头像"""
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

这是一个处理用户上传头像的视图函数。这个函数内做了三件事情，并且针对每件事都做了异常捕获。如果做某件事时发生了异常，就返回对用户友好的错误到前端。

这样的处理流程纵然合理，但是显然代码里的异常处理逻辑有点“喧宾夺主”了。一眼看过去全是代码缩进，很难提炼出代码的核心逻辑。

早在 2.5 版本时，Python 语言就已经提供了对付这类场景的工具：“上下文管理器（context manager）”。上下文管理器是一种配合 `with` 语句使用的特殊 Python 对象，通过它，可以让异常处理工作变得更方便。

那么，如何利用上下文管理器来改善我们的异常处理流程呢？让我们直接看代码吧。

```python
class raise_api_error:
    """captures specified exception and raise ApiErrorCode instead

    :raises: AttributeError if code_name is not valid
    """
    def __init__(self, captures, code_name):
        self.captures = captures
        self.code = getattr(error_codes, code_name)

    def __enter__(self):
        # 该方法将在进入上下文时调用
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        # 该方法将在退出上下文时调用
        # exc_type, exc_val, exc_tb 分别表示该上下文内抛出的
        # 异常类型、异常值、错误栈
        if exc_type is None:
            return False

        if exc_type == self.captures:
            raise self.code from exc_val
        return False
```

在上面的代码里，我们定义了一个名为 `raise_api_error` 的上下文管理器，它在进入上下文时什么也不做。但是在退出上下文时，会判断当前上下文中是否抛出了类型为 `self.captures` 的异常，如果有，就用 `APIErrorCode` 异常类替代它。

使用该上下文管理器后，整个函数可以变得更清晰简洁：

```python
def upload_avatar(request):
    """用户上传新头像"""
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

> Hint：建议阅读 [PEP 343 -- The "with" Statement | Python.org](https://www.python.org/dev/peps/pep-0343/)，了解与上下文管理器有关的更多知识。
> 
> 模块 [contextlib](https://docs.python.org/3/library/contextlib.html) 也提供了非常多与编写上下文管理器相关的工具函数与样例。

## 总结

在这篇文章中，我分享了与异常处理相关的三个建议。最后再总结一下要点：

- 只捕获可能会抛出异常的语句，避免含糊的捕获逻辑
- 保持模块异常类的抽象一致性，必要时对底层异常类进行包装
- 使用“上下文管理器”可以简化重复的异常处理逻辑

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【7.编写地道循环的两个建议】](7-two-tips-on-loop-writing.md)

[<<<上一篇【5.让函数返回结果的技巧】](5-function-returning-tips.md)

## 附录

- 题图来源: Photo by Bernard Hermant on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：善用变量改善代码质量](https://www.zlovezl.cn/articles/python-using-variables-well/)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：让程序返回结果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)


