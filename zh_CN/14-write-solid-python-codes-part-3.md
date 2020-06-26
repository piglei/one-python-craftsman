# Python 工匠：写好面向对象代码的原则（下）

## 前言

> 这是 “Python 工匠”系列的第 14 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)


<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/carolina-garcia-tavizon-w1280.jpg" width="100%" />
</div>
 
在这篇文章中，我将继续介绍 SOLID 原则剩下的两位成员：**I（接口隔离原则）** 和 **D（依赖倒置原则）**。为了方便，这篇文章将会使用先 D 后 I 的顺序。

## D：依赖倒置原则

软件是由一个个模块组合而成的。当你跟别人说：*“我在写一个很复杂的软件”*，其实你并不是直接在写那个软件，你只是在编写它的一个个模块，最后把它们放在一起组合成你的软件。

有了模块，模块间自然就有了依赖关系。比如，你的个人博客可能依赖着 Flask 框架，而 Flask 又依赖了 Werkzeug，Werkzeug 又由更多个低层模块组成。

依赖倒置原则（Dependency Inversion Principle）就是一条和依赖关系相关的原则。它认为：**“高层模块不应该依赖于低层模块，二者都应该依赖于抽象。”**

> High-level modules should not depend on low-level modules. Both should depend on abstractions.

这个原则看上去有点反直觉。毕竟，在我们的第一堂编程课上，老师就是这么教我们写代码的：*“高层模块要依赖低层模块，hello world 程序依赖 printf()。”*那为什么这条原则又说不要这样做呢？而依赖倒置原则里的“倒置”又是指什么？

让我们先把这些问题放在一边，看看下面这个小需求。上面这些问题的答案都藏在这个需求中。

### 需求：按域名分组统计 HN 新闻数量

这次出场的还是我们的老朋友：新闻站点 [Hacker News](https://news.ycombinator.com/)。在 HN 上，每个用户提交的条目标题后面，都跟着这条内容的来源域名。

我想要按照来源域名来分组统计条目数量，这样就能知道哪个站在 HN 上最受欢迎。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_3_hn.jpg" width="100%" />
图：Hacker News 条目来源截图
</div>

这个需求非常简单，使用 `requests`、`lxml` 模块可以很快完成任务：

```python
# file: hn_site_grouper.py
import requests
from lxml import etree
from typing import Dict
from collections import Counter


class SiteSourceGrouper:
    """对 HN 页面的新闻来源站点进行分组统计
    """
    def __init__(self, url: str):
        self.url = url

    def get_groups(self) -> Dict[str, int]:
        """获取 (域名, 个数) 分组
        """
        resp = requests.get(self.url)
        html = etree.HTML(resp.text)
        # 通过 xpath 语法筛选新闻域名标签
        elems = html.xpath('//table[@class="itemlist"]//span[@class="sitestr"]')

        groups = Counter()
        for elem in elems:
            groups.update([elem.text])
        return groups


def main():
    groups = SiteSourceGrouper("https://news.ycombinator.com/").get_groups()
    # 打印最常见的 3 个域名
    for key, value in groups.most_common(3):
        print(f'Site: {key} | Count: {value}')


if __name__ == '__main__':
    main()
```

代码执行结果：

```bash
❯ python hn_sitestr_grouper.py
Site: github.com | Count: 2
Site: howonlee.github.io | Count: 1
Site: latimes.com | Count: 1
```

这段代码很短，核心代码总共不到 20 行。现在，让我们来理一理它里面的依赖关系。

`SiteSourceGrouper` 是我们的核心类。为了完成任务，它需要使用 `requests` 模块获取首页内容、`lxml` 模块解析标题。所以，现在的依赖关系是“正向”的，高层模块 `SiteSourceGrouper` 依赖低层模块 `requests`、`lxml`。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_D_before.png" width="100%" />
图：SiteSourceGrouper 依赖 requests、lxml
</div>

也许现在这张图在你眼里看起来特别合理。正常的依赖关系不就应该是这样的吗？别着急，我们还没给代码写单元测试呢。

### 为 SiteSourceGrouper 编写单元测试

现在让我来为这段代码加上单元测试。首先让最普通的情况开始：

```python
from hn_site_grouper import SiteSourceGrouper
from collections import Counter


def test_grouper_returning_valid_types():
    """测试 get_groups 是否返回了正确类型
    """
    grouper = SiteSourceGrouper('https://news.ycombinator.com/')
    result = grouper.get_groups()
    assert isinstance(result, Counter), "groups should be Counter instance"
```

这是一个再简单不过的单元测试，我调用了 `SiteSourceGrouper.get_groups()` 方法，然后简单校验了一下返回结果类型是否正常。

这个测试在本地电脑上执行时没有一点问题，可以正常通过。但当我在服务器上执行这段单元测试代码时，却发现它根本没办法成功。因为 **我的服务器不能访问外网。**

```python
# 运行单元测试时提示网络错误
requests.exceptions.ConnectionError: HTTPSConnectionPool(host='news.ycombinator.com', port=443):  ... ... [Errno 8] nodename nor servname provided, or not known'))
```

到这里，单元测试暴露了 `SiteSourceGrouper` 类的一个问题：*它的核心逻辑依赖 requests 模块和网络连接，严格限制了单元测试的执行条件。*

既然如此，那要如何解决这个问题呢？如果你去问一个有经验的 Python 的开发者，十有八九他会甩给你一句话：**“用 mock 啊！”**

#### 使用 mock 模块

[mock](https://docs.python.org/3/library/unittest.mock.html) 是 unittest 里的一个模块，同时也是一类测试手法的统称。假如你需要测试的模块里有一部分依赖很难被满足*（比如代码需要访问一整套 Kubernetes 集群）*，或者你想在测试时故意替换掉某些依赖，那么 mock 就能派上用场。

在这个例子里，使用 unittest.mock 模块需要做下面这些事情：

- 把一份正确的 HN 页面内容保存为本地文件 `static_hn.html`
- 在测试文件中导入 `unittest.mock` 模块
- 在测试函数中，通过 [`mock.path('requests.get')`](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.patch) 替换网络请求部分
- 将其修改为直接返回文件 `static_hn.html` 的内容

使用 mock 后的代码看起来是这样的：

```python
from unittest import mock

def test_grouper_returning_valid_types():
    """测试 get_groups 是否返回了正确类型
    """
    resp = mock.Mock()
    # Mock 掉 requests.get 函数
    with mock.patch('hn_site_grouper.requests.get') as mocked_get:
        mocked_get.return_value = resp
        with open('static_hn.html', 'r') as fp:
            # Mock 掉响应的 text 字段
            resp.text = fp.read()

        grouper = SiteSourceGrouper('https://news.ycombinator.com/')
        result = grouper.get_groups()
        assert isinstance(result, Counter), "groups should be Counter instance"
```

上面的代码并不算复杂。对于 Python 这类动态语言来说，使用 mock 有着一种得天独厚的优势。因为在 Python 里，运行时的一切对象几乎都可以被替换掉。

不过虽然 mock 用起来很方便，但它不是解决我们问题的最佳做法。因为 mock 在带来方便的同时，也让测试代码变得更复杂和难以理解。而且，给测试加上 mock 也仅仅只是让我的单元测试能够跑起来，糟糕设计仍然是糟糕设计。它无法体现出单元测试最重要的价值之一：**“通过编写测试反向推动设计改进”**。

所以，我们需要做的是改进依赖关系，而不只是简单的在测试时把依赖模块替换掉。如何改进依赖关系？让我们看看“依赖倒置”是如何做的。

### 实现依赖倒置原则

首先，让我们重温一下“依赖倒置原则”*（后简称 D 原则）*的内容：**“高层模块不应该依赖于低层模块，二者都应该依赖于抽象。”**

在上面的代码里，高层模块 `SiteSourceGrouper` 就直接依赖了低层模块 `requests`。为了让代码符合 D 原则，我们首先需要创造一个处于二者中间的抽象，然后让两个模块可以都依赖这个新的抽象层。

创建抽象的第一步*（可能也是最重要的一步）*，就是确定这个抽象层的职责。在例子中，高层模块主要依赖 `requests` 做了这些事：

- 通过 `requests.get()` 获取 response
- 通过 `response.text` 获取响应文本

所以，这个抽象层的主要职责就是产生 HN 站点的页面文本。我们可以给它起个名字：`HNWebPage`。

确定了抽象层的职责和名字后，接下来应该怎么实现它呢？在 Java 或 Go 语言里，标准答案是定义 **Interface**（接口）。因为对于这些编程语言来说，“接口”这两个字基本就可以等同于“抽象”。

拿 Go 来说，“Hacker News 站点页面”这层抽象就可以被定义成这样的 Interface：

```go
type HNWebPage interface {
    // GetText 获取页面文本
	 GetText() (string, error)
}
```

不过，Python 根本没有接口这种东西。那该怎么办呢？虽然 Python 没有接口，但是有一个非常类似的东西：**“抽象类（Abstrace Class）”**。使用 [`abc`](https://docs.python.org/3/library/abc.html) 模块就可以轻松定义出一个抽象类：

```
from abc import ABCMeta, abstractmethod


class HNWebPage(metaclass=ABCMeta):
    """抽象类：Hacker New 站点页面
    """

    @abstractmethod
    def get_text(self) -> str:
        raise NotImplementedError
```

抽象类和普通类的区别之一就是你不能将它实例化。如果你尝试实例化一个抽象类，解释器会报出下面的错误：

```
TypeError: Can't instantiate abstract class HNWebPage with abstract methods get_text
```

所以，光有抽象类还不能算完事，我们还得定义几个依赖这个抽象类的实体。首先定义的是 `RemoteHNWebPage` 类。它的作用就是通过 requests 模块请求 HN 页面，返回页面内容。

```
class RemoteHNWebPage(HNWebPage):
    """远程页面，通过请求 HN 站点返回内容"""

    def __init__(self, url: str):
        self.url = url

    def get_text(self) -> str:
        resp = requests.get(self.url)
        return resp.text
```

定义了 `RemoteHNWebPage` 类后，`SiteSourceGrouper` 类的初始化方法和 `get_groups` 也需要做对应的调整：

```
class SiteSourceGrouper:
    """对 HN 页面的新闻来源站点进行分组统计
    """

    def __init__(self, page: HNWebPage):
        self.page = page

    def get_groups(self) -> Dict[str, int]:
        """获取 (域名, 个数) 分组
        """
        html = etree.HTML(self.page.get_text())
        # 通过 xpath 语法筛选新闻域名标签
        elems = html.xpath('//table[@class="itemlist"]//span[@class="sitestr"]')

        groups = Counter()
        for elem in elems:
            groups.update([elem.text])
        return groups


def main():
    # 实例化 page，传入 SiteSourceGrouper
    page = RemoteHNWebPage(url="https://news.ycombinator.com/")
    grouper = SiteSourceGrouper(page).get_groups()
```

做完这些修改后，让我们再看看现在的模块依赖关系：

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_D_after.png" width="100%" />
图：SiteSourceGrouper 和 RemoteHNWebPage 都依赖抽象层 HNWebPage
</div>

在图中，高层模块不再依赖低层模块，二者同时依赖于抽象概念 `HNWebPage`，低层模块的依赖箭头和之前相比倒过来了。所以我们称其为 **依赖倒置**。

### 依赖倒置后的单元测试

再回到之前的单元测试上来。通过引入了新的抽象层 `HNWebPage`，我们可以实现一个不依赖外部网络的新类型 `LocalHNWebPage`。

```
class LocalHNWebPage(HNWebPage):
    """本地页面，根据本地文件返回页面内容"""

    def __init__(self, path: str):
        self.path = path

    def get_text(self) -> str:
        with open(self.path, 'r') as fp:
            return fp.read()
```

所以，单元测试也可以改为使用 `LocalHNWebPage`：

```
def test_grouper_from_local():
    page = LocalHNWebPage(path="./static_hn.html")
    grouper = SiteSourceGrouper(page)
    result = grouper.get_groups()
    assert isinstance(result, Counter), "groups should be Counter instance"
```

这样就可以在没有外网的服务器上测试 `SiteSourceGrouper` 类的核心逻辑了。

> Hint：其实上面的测试函数 `test_grouper_from_local` 远远算不上一个合格的测试用例。
> 
> 如果真要测试 `SiteSourceGrouper` 的核心逻辑。我们应该准备一个虚构的 Hacker News 页面 *（比如刚好包含 5 个 来源自 github.com 的条目）*，然后判断结果是否包含 `assert result['github.com] == 5`

### 问题：一定要使用抽象类 abc 吗？

为了实现依赖倒置，我们在上面定义了抽象类：`HNWebPage`。那是不是只有定义了抽象类才能实现依赖倒置？只有用了抽象类才算是依赖倒置呢？

**答案是否定的。** 如果你愿意，你可以把代码里的抽象类 `HNWebPage` 以及所有的相关引用都删掉，你会发现没有它们代码仍然可以正常运行。

这是因为 Python 是一门“鸭子类型”语言。这意味着只要 `RemoteHNWebPage` 和 `LocalHNWebPage` 类型保持着统一的接口协议*（提供 .get_text() 公开方法）*，并且它们的 **协议符合我们定义的抽象**。那么那个中间层就存在，依赖倒置就是成立的。至于这份 **协议** 是通过抽象类还是普通父类（甚至可以是普通函数）定义的，就没那么重要了。

所以，虽然在某些编程语言中，实现依赖倒置必须得定义新的接口类型，但在 Python 里，依赖倒置并不是抽象类 abc 的特权。

### 问题：抽象一定是好东西吗？

前面的所有内容，都是在说新增一个抽象层，然后让依赖关系倒过来的种种好处。所以，多抽象的代码一定就是好的吗？缺少抽象的代码就一定不够灵活？

和所有这类问题的标准回答一样，答案是：**视情况而定。**

当你习惯了依赖倒置原则以后，你会发现 *抽象（Abstract）* 其实是一种思维方式，而不仅仅是一种编程手法。如果你愿意，你可以在代码里的所有地方都 **硬挤** 一层额外抽象出来：

- 比如代码依赖了 lxml 模块的 xpath 具体实现，我是不是得定义一层  *“HNTitleDigester”* 把它抽象进去？
- 比如代码里的字符串字面量也是具体实现，我是不是得定义一个 *"StringLike"* 类型把它抽象进去？
- ... ...

事实上，抽象的好处显而易见：**它解耦了高层模块和低层模块间的依赖关系，让代码变得更灵活。** 但抽象同时也带来了额外的编码与理解成本。所以，了解何时 **不** 抽象与何时抽象同样重要。**只有对代码中那些现在或未来会发生变化的东西进行抽象，才能获得最大的收益。**

## I：接口隔离原则

接口隔离原则*（后简称 I 原则）*全称为 *“Interface Segregation Principles”*。顾名思义，它是一条和“接口（Interface）”有关的原则。

我在前面解释过何为“接口（Interface）”。**接口是模块间相互交流的抽象协议**，它在不同的编程语言里有着不同的表现形态。比如在 Go 里它是 `type ... interface`，而在 Python 中它可以是抽象类、普通类或者函数，甚至某个只在你大脑里存在的一套协议。

I 原则认为：**“客户（client）应该不依赖于它不使用的方法”**

> The interface-segregation principle (ISP) states that no client should be forced to depend on methods it does not use.

这里说的“客户（Client）”指的是接口的使用方 *（客户程序）*，也就是调用接口方法的高层模块。拿上一个统计 HN 页面条目的例子来说：

- `使用方（客户程序）`：SiteSourceGrouper
- `接口（其实是抽象类）`：HNWebPage
- `依赖关系`：调用接口方法：`get_text()` 获取页面文本

在 I 原则看来，**一个接口所提供的方法，应该就是使用方所需要的方法，不多不少刚刚好。** 所以，在上个例子里，我们设计的接口 `HNWebPage` 是符合接口隔离原则的。因为它没有向使用方提供任何后者不需要的方法 。

> 你需要 get_text()！我提供 get_text()！刚刚好！

所以，这条原则看上去似乎很容易遵守。既然如此，让我们试试来违反它吧！

### 例子：开发页面归档功能

让我们接着上一个例子开始。在实现了上个需求后，我现在有一个代表 Hacker News 站点页面的抽象类 `HNWebPage`，它只提供了一种行为，就是获取当前页面的文本内容。

```python
class HNWebPage(metaclass=ABCMeta):

    @abstractmethod
    def get_text(self) -> str:
        """获取页面文本内容"""
```

现在，假设我要开发一个和 HN 页面有关的新功能： **我想在不同时间点对 HN 首页内容进行归档，观察热点新闻在不同时间点发生的变化。** 所以除了页面文本内容外，我还需要拿到页面的大小、生成时间这些额外信息，然后将它们都保存到数据库中。

为了做到这一点，现在的 `HNWebPage` 类需要被扩展一下：

```python
class HNWebPage(metaclass=ABCMeta):

    @abstractmethod
    def get_text(self) -> str:
        """获取页面文本内容"""
        
    # 新增 get_size 与 get_generated_at
        
    @abstractmethod
    def get_size(self) -> int:
        """获取页面大小"""

    @abstractmethod
    def get_generated_at(self) -> datetime.datetime:
        """获取页面生成时间"""
```

我在原来的类上增加了两个新的抽象方法：`get_size` 和 `get_generated_at`。这样归档程序就能通过它们拿到页面大小和生成时间了。

改完抽象类后，紧接着的任务就是修改依赖它的实体类。

### 问题：实体类不符合 HNWebPage 接口规范

在修改抽象类前，我们有两个实现了它协议的实体类：`RemoteHNWebPage` 和 `LocalHNWebPage`。如今，`HNWebPage` 增加了两个新方法 `get_size` 和 `get_generated_at`。我们自然需要把这两个实体类也加上这两个方法。

`RemoteHNWebPage` 类的修改很好做，我们只要让 `get_size` 放回页面长度，让 `get_generated_at` 返回当前时间就行了。

```python
# class RemoteHNWebPage:
#
def get_generated_at(self) -> datetime.datetime:
    # 页面生成时间等同于通过 requests 请求的时间
    return datetime.datetime.now()
```

但是，在给 `LocalHNWebPage` 添加 `get_generated_at` 方法时，我碰到了一个问题。`LocalHNWebPage` 是一个完全基于本地页面文件作为数据来源的类，仅仅通过 “static_hn.html” 这么一个本地文件，我根本就没法知道它的内容是什么时候生成的。

这时我只能选择让它的 `get_generated_at` 方法返回一个错误的结果*（比如文件的修改时间）*，或者直接抛出异常。无论是哪种做法，我都可能违反 [里式替换原则](https://www.zlovezl.cn/articles/write-solid-python-codes-part-2/)。

> Hint：里式替换原则认为子类（派生类）对象应该可以在程序中替代父类（基类）对象使用，而不破坏程序原本的功能。让方法抛出异常显然破坏了这一点。

```python
# class LocalHNWebPage:
#
def get_generated_at(self) -> datetime.datetime:
    raise NotImplementedError("local web page can not provide generate_at info")
```

所以，对现有接口的盲目扩展暴露出来一个问题：**更多的接口方法意味着更高的实现成本，给实现方带来麻烦的概率也变高了。**

不过现在让我们暂且把这个问题放到一边，继续写一个 `SiteAchiever` 类完成归档任务：

```python
class SiteAchiever:
    """将不同时间点的 HN 页面归档"""

    def save_page(self, page: HNWebPage):
        """将页面保存到后端数据库
        """
        data = {
            "content": page.get_text(),
            "generated_at": page.get_generated_at(),
            "size": page.get_size(),
        }
        # 将 data 保存到数据库中
```

### 成功违反 I 协议

代码写到这，让我们回头看看上个例子里的 *条目来源分组类 `SiteSourceGrouper`* 。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_I_before.png" width="100%" />
图：成功违反了 I 协议
</div>

当我修改完抽象类后，虽然 `SiteSourceGrouper` 仍然依赖着 `HNWebPage`，但它其实只使用了 `get_text` 这一个方法而已，其他  `get_size`、`get_generated` 这些它 **不使用的方法也成为了它的依赖。**

很明显，现在的设计违反了接口隔离原则。为了修复这一点，我们需要将 `HNWebPage` 拆成更小的接口。

### 如何分拆接口

设计接口有一个技巧：**让客户（调用方）来驱动协议设计**。让我们来看看，`HNWebPage` 到底有哪些客户：

- `SiteSourceGrouper`：域名来源统计，依赖 `get_text()`
- `SiteAchiever`：HN 页面归档程序，依赖 `get_text()`、`get_size()`、`get_generated_at()`

按照上面的方式，我们可以把 `HNWebPage` 分离成两个独立的抽象类：

```python
class ContentOnlyHNWebPage(metaclass=ABCMeta):
    """抽象类：Hacker New 站点页面（仅提供内容）
    """

    @abstractmethod
    def get_text(self) -> str:
        raise NotImplementedError


class HNWebPage(ContentOnlyHNWebPage):
    """抽象类：Hacker New 站点页面（含元数据）
    """

    @abstractmethod
    def get_size(self) -> int:
        """获取页面大小"""

    @abstractmethod
    def get_generated_at(self) -> datetime.datetime:
        """获取页面生成时间"""
```

将旧类拆分成两个不同的抽象类后，`SiteSourceGrouper` 和 `SiteAchiever` 就可以分别依赖不同的抽象类了。

同时，对于 `LocalHNWebPage` 类来说，它也只需要实现那个只返回的文本的 `ContentOnlyHNWebPage` 就行。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/02/SOLID_I_after.png" width="100%" />
图：实施接口隔离后的结果
</div>

### 一些不容易发现的违反情况

虽然我花了很长的篇幅，用了好几个抽象类才把接口隔离原则讲明白，但其实在我们的日常编码中，对这条原则的违反经常会出现在一些更容易被忽视的地方。

举个例子，当我们在 web 站点里判断用户请求的 Cookies 或头信息是否包含某个标记值时，我们经常直接写一个依赖整个 `request` 对象的函数：

```python
def is_new_visitor(request: HttpRequest) -> bool:
    """从 Cookies 判断是否新访客
    """
    return request.COOKIES.get('is_new_visitor') == 'y'
```

但事实上，除了 `.COOKIES` 以外，`is_new_visitor` 根本就不需要 `request` 对象里面的任何其他内容。“用户请求对象（request）”是一个比“Cookie 字典（request.COOKIES）”复杂得多的抽象。我们完全可以把函数改成只接收 cookies 字典。

```python
def is_new_visitor(cookies: Dict) -> bool:
    """从 Cookies 判断是否新访客
    """
    return cookies.get('is_new_visitor') == 'y'
```

类似的情况还有很多，比如一个发短信的函数本身只需要两个参数 `电话号码` 和 `用户姓名`，但是函数却依赖了整个用户对象 `User`，里面包含着几十个用不上的其他字段和方法。

对于这类函数，我们都可以重新考虑一下它们的抽象是否合理，是否需要应用接口隔离原则。

### 现实世界中的接口隔离

当你知道了接口隔离原则的种种好处后，你很自然就会养成写小类、小接口的习惯。在现实世界里，其实已经有很多小而精的接口设计可以供你参考。比如：

- Python 的 [collections.abc](https://docs.python.org/3/library/collections.abc.html) 模块里面有非常多的小接口
- Go 里面的 [Reader 和 Writer](https://golang.org/pkg/io/#Reader) 也是非常好的例子

## 总结

在这篇文章里，我向你介绍了 SOLID 原则的最后两位成员：**“依赖倒置原则”** 与 **“接口隔离原则”**。

这两条原则之间有一个共同点，那就是它们都和 **“抽象”** 有着紧密的联系。前者告诉我们要面向抽象而非实现编程，后者则教导我们在设计抽象时应该做到精准。

最后再总结一下：

- **“D：依赖倒置原则”** 认为高层模块和低层模块都应该依赖于抽象
- 依赖抽象，意味着我们可以完全修改低层实现，而不影响高层代码
- 在 Python 中你可以使用 abc 模块来定义抽象类
- 除 abc 外，你也可以使用其他技术来完成依赖倒置
- **“I：接口隔离原则”** 认为客户不应该依赖任何它不使用的方法
- 设计接口就是设计抽象
- 违反接口隔离原则也可能会导致违反单一职责与里式替换原则
- 写更小的类、写更小的接口在大多数情况下是个好主意

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【15.在边界处思考】](15-thinking-in-edge-cases.md)

[<<<上一篇【13.写好面向对象代码的原则（中）】](13-write-solid-python-codes-part-2.md)


## 附录

- 题图来源: Photo by Carolina Garcia Tavizon on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：写好面向对象代码的原则（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：写好面向对象代码的原则（中）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-2/)
- [Python 工匠：写好面向对象代码的原则（下）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-3/)


