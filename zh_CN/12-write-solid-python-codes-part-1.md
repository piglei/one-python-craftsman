# Python 工匠：写好面向对象代码的原则（上）

## 前言


> 这是 “Python 工匠”系列的第 12 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/kelly-sikkema-Z9AU36chmQI-unsplash_w1280.jpg" width="100%" />
</div>

Python 是一门支持多种编程风格的语言，面对相同的需求，拥有不同背景的程序员可能会写出风格迥异的 Python 代码。比如一位习惯编写 C 语言的程序员，通常会定义一大堆函数来搞定所有事情，这是[“过程式编程”](https://en.wikipedia.org/wiki/Procedural_programming)的思想。而一位有 Java 背景的程序员则更倾向于设计许多个相互关联的类*（class）*，这是 [“面向对象编程（后简称 OOP）”](https://en.wikipedia.org/wiki/Object-oriented_programming)。

虽然不同的编程风格各有特点，无法直接比较。但是 OOP 思想在现代软件开发中起到的重要作用应该是毋庸置疑的。

很多人在学习如何写好 OOP 代码时，会选择从那 [23 种经典的“设计模式”](https://zh.wikipedia.org/wiki/%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F_(%E8%AE%A1%E7%AE%97%E6%9C%BA))开始。不过对于 Python 程序员来说，我认为这并非是一个最佳选择。

### Python 对 OOP 的支持

Python 语言虽然拥有类、继承、多态等核心 OOP 特性，但和那些完全基于 OOP 思想设计的编程语言*（比如 Java）*相比，它在 OOP 支持方面做了很多简化工作。比如它 **没有严格的类私有成员，没有接口（Interface）对象** 等。

而与此同时，Python 灵活的函数对象、鸭子类型等许多动态特性又让一些在其他语言中很难做到的事情变得非常简单。这些语言间的差异共同导致了一个结果：*很多经典的设计模式到了 Python 里，就丢失了那个“味道”，实用性也大打折扣。*

拿大家最熟悉的单例模式来说。你可以花上一大把时间，来学习如何在 Python 中利用 `__new__` 方法或元类*（metaclass）*来实现单例设计模式，但最后你会发现，自己 95% 的需求都可以通过直接定义一个模块级全局变量来搞定。

所以，与具体化的 **设计模式** 相比，我觉得一些更为抽象的 **设计原则** 适用性更广、更适合运用到 Python 开发工作中。而谈到关于 OOP 的设计原则，“SOLID” 是众多原则中最有名的一个。

### SOLID 设计原则

著名的设计模式书籍[《设计模式：可复用面向对象软件的基础》](https://book.douban.com/subject/1052241/)出版于 1994 年，距今已有超过 25 年的历史。而这篇文章的主角： “SOLID 设计原则”同样也并不年轻。

早在 2000 年，[Robert C. Martin](https://en.wikipedia.org/wiki/Robert_C._Martin) 就在他的文章 "Design Principles and Design Patterns" 中整理并提出了 “SOLID” 设计原则的雏型，之后又在他的经典著作[《敏捷软件开发 : 原则、模式与实践》](https://book.douban.com/subject/1140457/)中将其发扬光大。“SOLID” 由 5 个单词组合的首字母缩写组成，分别代表 5 条不同的面向对象领域的设计原则。

在编写 OOP 代码时，如果遵循这 5 条设计原则，就更可能写出可扩展、易于修改的代码。相反，如果不断违反其中的一条或多条原则，那么很快你的代码就会变得不可扩展、难以维护。

接下来，让我用一个真实的 Python 代码样例来分别向你诠释这 5 条设计原则。

> 写在最前面的注意事项：
> 
> 0. “原则”不是“法律”，它只起到指导作用，并非不可以违反
> 1. “原则”的后两条与接口（Interface）有关，而 Python 没有接口，所以对这部分的诠释是我的个人理解，与原版可能略有出入
> 2. 文章后面的内容含有大量代码，请做好心理准备 ☕️
> 3. 为了增强代码的说明性，本文中的代码使用了 Python3 中的 [类型注解特性](https://docs.python.org/3/library/typing.html)

## SOLID 原则与 Python

[Hacker News](https://news.ycombinator.com/)*(后简称 HN)* 是一个在程序员圈子里很受欢迎的站点。在它的首页，有很多由用户提交后基于推荐算法排序的科技相关内容。

我经常会去上面看一些热门文章，但我觉得每次打开浏览器访问有点麻烦。所以，我准备编写一个脚本，自动抓取 HN 首页 Top5 的新闻标题与链接，并用纯文本的方式写入到文件。方便自己用其他工具阅读。

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/hackernews_frontpage.png" width="100%" />
图：Hacker News 首页截图
</div>

编写爬虫几乎是 Python 天生的拿手好戏。利用 requests、lxml 等模块提供的好用功能，我可以轻松实现上面的需求。下面是我第一次编写好的代码：

```python
import io
import sys
from typing import Generator

import requests
from lxml import etree


class Post:
    """HN(https://news.ycombinator.com/) 上的条目

    :param title: 标题
    :param link: 链接
    :param points: 当前得分
    :param comments_cnt: 评论数
    """
    def __init__(self, title: str, link: str, points: str, comments_cnt: str):
        self.title = title
        self.link = link
        self.points = int(points)
        self.comments_cnt = int(comments_cnt)


class HNTopPostsSpider:
    """抓取 HackerNews Top 内容条目

    :param fp: 存储抓取结果的目标文件对象
    :param limit: 限制条目数，默认为 5
    """
    ITEMS_URL = 'https://news.ycombinator.com/'
    FILE_TITLE = 'Top news on HN'

    def __init__(self, fp: io.TextIOBase, limit: int = 5):
        self.fp = fp
        self.limit = limit

    def fetch(self) -> Generator[Post, None, None]:
        """从 HN 抓取 Top 内容
        """
        resp = requests.get(self.ITEMS_URL)

        # 使用 XPath 可以方便的从页面解析出你需要的内容，以下均为页面解析代码
        # 如果你对 xpath 不熟悉，可以忽略这些代码，直接跳到 yield Post() 部分
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
                # 条目可能会没有评分
                points=points_text[0].split()[0] if points_text else '0',
                comments_cnt=comments_text.split()[0]
            )

    def write_to_file(self):
        """以纯文本格式将 Top 内容写入文件
        """
        self.fp.write(f'# {self.FILE_TITLE}\n\n')
        # enumerate 接收第二个参数，表示从这个数开始计数（默认为 0）
        for i, post in enumerate(self.fetch(), 1):
            self.fp.write(f'> TOP {i}: {post.title}\n')
            self.fp.write(f'> 分数：{post.points} 评论数：{post.comments_cnt}\n')
            self.fp.write(f'> 地址：{post.link}\n')
            self.fp.write('------\n')


def main():

    # with open('/tmp/hn_top5.txt') as fp:
    #     crawler = HNTopPostsSpider(fp)
    #     crawler.write_to_file()

    # 因为 HNTopPostsSpider 接收任何 file-like 的对象，所以我们可以把 sys.stdout 传进去
    # 实现往控制台标准输出打印的功能
    crawler = HNTopPostsSpider(sys.stdout)
    crawler.write_to_file()


if __name__ == '__main__':
    main()
```

你可以把上面的代码称之为符合 OOP 风格的，因为在上面的代码里，我定义了两个类：

1. `Post`：表示单个 HN 内容条目，其中定义了标题、链接等字段，是用来衔接“抓取”和“写入文件”两件事情的数据类
2. `HNTopPostsSpider`：抓取 HN 内容的爬虫类，其中定义了抓取页面、解析、写入结果的方法，是完成主要工作的类

如果你本地的 Python 环境配置正常，那么可以尝试执行一下上面这段代码，它会输出下面这样的内容：

```text
❯ python news_digester.py
> TOP 1: Show HN: NoAgeismInTech – Job board for companies fighting ageism in tech
> 分数：104 评论数：26
> 地址：https://noageismintech.com/
------
> TOP 2: Magic Leap sues former employee who founded the China-based Nreal for IP theft
> 分数：17 评论数：2
> 地址：https://www.bloomberg.com/news/articles/2019-06-18/secretive-magic-leap-says-ex-engineer-copied-headset-for-china
------
... ...
```

这个脚本基于面向对象的方式编写*（换句话说，就是定义了一些 class 😒）*，可以满足我的需求。但是从设计的角度来看，它却违反了 SOLID 原则的第一条：“Single responsibility principle（单一职责原则）”，让我们来看看是为什么。

## S：单一职责原则

SOLID 设计原则里的第一个字母 S 来自于 “Single responsibility principle（单一职责原则）” 的首字母。这个原则认为：**“一个类应该仅仅只有一个被修改的理由。”**换句话说，每个类都应该只有一种职责。

而在上面的代码中，`HNTopPostsSpider` 这个类违反了这个原则。因为我们可以很容易的找到两个不同的修改它的理由：

- **理由 1**: HN 网站的程序员突然更新了页面样式，旧的 xpath 解析算法从新页面上解析不到内容，需要修改 `fetch` 方法内的解析逻辑。
- **理由 2**: 用户*（也就是我）*突然觉得纯文本格式的输出不好看，想要改成 Markdown 样式。需要修改 `write_to_file` 方法内的输出逻辑。

所以，`HNTopPostsSpider` 类违反了“单一职责原则”，因为它有着多个被修改的理由。而这背后的根本原因是因为它承担着 “抓取帖子列表” 和 "将帖子列表写入文件" 这两种完全不同的职责。

### 违反“单一职责原则”的坏处

如果某个类违反了“单一职责原则”，那意味着我们经常会因为不同的原因去修改它。这可能会导致不同功能之间相互影响。比如，可能我在某天调整了页面解析逻辑，却发现输出的文件格式也全部乱掉了。

另外，单个类承担的职责越多，意味着这个类的复杂度也就越高，它的维护成本也同样会水涨船高。违反“单一职责原则”的类同样也难以被复用，假如我有其他代码想复用 `HNTopPostsSpider` 类的抓取和解析逻辑，会发现我必须要提供一个莫名其妙的文件对象给它才行。

那么，要如何修改代码才能让它遵循“单一职责原则”呢？办法有很多，最传统的是：**把大类拆分为小类**。

### 拆分大类为多个小类

为了让 `HNTopPostsSpider` 类的职责更纯粹，我们可以把其中与“写入文件”相关的内容拆分出去作为一个新的类：

```python
class PostsWriter:
    """负责将帖子列表写入到文件
    """
    def __init__(self, fp: io.TextIOBase, title: str):
        self.fp = fp
        self.title = title

    def write(self, posts: List[Post]):
        self.fp.write(f'# {self.title}\n\n')
        # enumerate 接收第二个参数，表示从这个数开始计数（默认为 0）
        for i, post in enumerate(posts, 1):
            self.fp.write(f'> TOP {i}: {post.title}\n')
            self.fp.write(f'> 分数：{post.points} 评论数：{post.comments_cnt}\n')
            self.fp.write(f'> 地址：{post.link}\n')
            self.fp.write('------\n')
```

而在 `HNTopPostsSpider` 类里，可以通过调用 `PostsWriter` 的方式来完成之前的工作：

```python
class HNTopPostsSpider:
    FILE_TITLE = 'Top news on HN'
    
    <... 已省略 ...>

    def write_to_file(self, fp: io.TextIOBase):
        """以纯文本格式将 Top 内容写入文件

        实例化参数文件对象 fp 被挪到了 write_to_file 方法中
        """
        # 将文件写入逻辑托管给 PostsWriter 类处理
        writer = PostsWriter(fp, title=self.FILE_TITLE)
        writer.write(list(self.fetch()))
```

通过这种方式，我们让 `HNTopPostsSpider` 和 `PostsWriter` 类都各自满足了“单一职责原则”。我只会因为解析逻辑变动才去修改 `HNTopPostsSpider` 类，同样，修改 `PostsWriter` 类的原因也只有调整输出格式一种。这两个类各自的修改可以单独进行而不会相互影响。

### 另一种方案：使用函数

“单一职责原则”虽然是针对类说的，但其实它的适用范围可以超出类本身。比如在 Python 中，通过定义函数，同样也可以让上面的代码符合单一职责原则。

我们可以把“写入文件”的逻辑拆分为一个新的函数，由它来专门承担起将帖子列表写入文件的职责：

```python
def write_posts_to_file(posts: List[Post], fp: io.TextIOBase, title: str):
    """负责将帖子列表写入文件
    """
    fp.write(f'# {title}\n\n')
    for i, post in enumerate(posts, 1):
        fp.write(f'> TOP {i}: {post.title}\n')
        fp.write(f'> 分数：{post.points} 评论数：{post.comments_cnt}\n')
        fp.write(f'> 地址：{post.link}\n')
        fp.write('------\n')
```

而对于 `HNTopPostsSpider` 类来说，改动可以更进一步。这次我们可以直接删除其中和文件写入相关的所有代码。让它只负责一件事情：“获取帖子列表”。

```python
class HNTopPostsSpider:
    """抓取 HackerNews Top 内容条目

    :param limit: 限制条目数，默认为 5
    """
    ITEMS_URL = 'https://news.ycombinator.com/'

    def __init__(self, limit: int = 5):
        self.limit = limit

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
```

相应的，类和函数的调用方 `main` 函数就需要稍作调整，它需要负责把 `write_posts_to_file` 函数和 `HNTopPostsSpider` 类之间协调起来，共同完成工作：

```python
def main():
    crawler = HNTopPostsSpider()

    posts = list(crawler.fetch())
    file_title = 'Top news on HN'
    write_posts_to_file(posts, sys.stdout, file_title)
```

将“文件写入”职责拆分为新函数是一个 Python 特色的解决方案，它虽然没有那么 OO*（面向对象）*，但是同样满足“单一职责原则”，而且在很多场景下更灵活与高效。

## O：开放-关闭原则

O 来自于 “Open–closed principle（开放-关闭原则）” 的首字母，它认为：**“类应该对扩展开放，对修改封闭。”**这是一个从字面上很难理解的原则，它同样有着另外一种说法：**“你应该可以在不修改某个类的前提下，扩展它的行为。”**

这原则听上去有点让人犯迷糊，如何能做到不修改代码又改变行为呢？让我来举一个例子：你知道 Python 里的内置排序函数 `sorted` 吗？

如果我们想对某个列表排序，可以直接调用 `sorted` 函数：

```python
>>> l = [5, 3, 2, 4, 1]
>>> sorted(l)
[1, 2, 3, 4, 5]
```

现在，假如我们想改变 `sorted` 函数的排序逻辑。比如，让它使用所有元素对 3 取余后的结果来排序。我们是不是需要去修改 `sorted` 函数的源码？当然不用，只需要在调用 `sort` 函数时，传入自定义的排序函数 `key` 参数就行了：

```python
>>> l = [8, 1, 9]
# 按照元素对 3 的余数排序，能被 3 整除的 9 排在了最前面，随后是 1 和 8
>>> sorted(l, key=lambda i: i % 3)
[9, 1, 8]
```

通过上面的例子，我们可以认为：`sorted` 函数是一个符合“开放-关闭原则”的绝佳例子，因为它：

- **对扩展开放**：你可以通过传入自定义 `key` 函数来扩展它的行为
- **对修改关闭**：你无需修改 sort 函数本身

### 如何违反“开放-关闭原则”

现在，让我们回到爬虫小程序。在使用了一段时间之后，用户*（还是我）*觉得每次抓取到的内容有点不合口味。我其实只关注那些来自特定网站，比如 github 上的内容。所以我需要修改 `HNTopPostsSpider` 类的代码来对结果进行过滤：

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

            # 只关注来自 github.com 的内容
            if 'github' in link.lower():
                counter += 1
                yield Post(... ...)
```

完成修改后，让我们来简单测试一下效果：

```text
❯ python news_digester_O_before.py
# Top news on HN

> TOP 1: Mimalloc – A compact general-purpose allocator
> 分数：291 评论数：40
> 地址：https://github.com/microsoft/mimalloc
------
> TOP 2: Olivia: An open source chatbot build with a neural network in Go
> 分数：53 评论数：19
> 地址：https://github.com/olivia-ai/olivia
------
<... 已省略 ...>
```

看上去新加的过滤代码起到了作用，现在只有链接中含有 `github` 的内容才会被写入到结果中。

但是，正如某位哲学家的名言所说：*“这世间唯一不变的，只有变化本身。”*某天，用户*（永远是我）*突然觉得，来自 `bloomberg` 的内容也都很有意思，所以我想要把 `bloomberg` 也加入筛选关键字逻辑里。

这时我们就会发现：现在的代码违反了"开放-关闭原则"。因为我必须要修改现有的 `HNTopPostsSpider` 类代码，调整那个 `if 'github' in link.lower()` 判断语句才能完成我的需求。

“开放-关闭原则”告诉我们，类应该通过扩展而不是修改的方式改变自己的行为。那么我应该如何调整代码，让它可以遵循原则呢？

### 使用类继承来改造代码

继承是面向对象理论中最重要的概念之一。它允许我们在父类中定义好数据和方法，然后通过继承的方式让子类获得这些内容，并可以选择性的对其中一些进行重写，修改它的行为。

使用继承的方式来让类遵守“开放-关闭原则”的关键点在于：**找到父类中会变动的部分，将其抽象成新的方法（或属性），最终允许新的子类来重写它以改变类的行为。**

对于 `HNTopPostsSpider` 类来说。首先，我们需要找到其中会变动的那部分逻辑，也就是*“判断是否对条目感兴趣”*，然后将其抽象出来，定义为新的方法：

```python
class HNTopPostsSpider:
    # <... 已省略 ...>

    def fetch(self) -> Generator[Post, None, None]:
        # <... 已省略 ...>
        for item in items:
            # <... 已省略 ...>
            
            post = Post( ... ... )
            # 使用测试方法来判断是否返回该帖子
            if self.interested_in_post(post):
                counter += 1
                yield post

    def interested_in_post(self, post: Post) -> bool:
        """判断是否应该将帖子加入结果中
        """
        return True
```

如果我们只关心来自 `github` 的帖子，那么只需要定义一个继承于 `HNTopPostsSpider` 子类，然后重写父类的 `interested_in_post` 方法即可。

```python
class GithubOnlyHNTopPostsSpider(HNTopPostsSpider):
    """只关心来自 Github 的内容
    """
    def interested_in_post(self, post: Post) -> bool:
        return 'github' in post.link.lower()

def main():
    # crawler = HNTopPostsSpider()
    # 使用新的子类
    crawler = GithubOnlyHNTopPostsSpider()
    <... ...>
```

假如我们的兴趣发生了变化？没关系，增加新的子类就行：

```python
class GithubNBloomBergHNTopPostsSpider(HNTopPostsSpider):
    """只关系来自 Github/BloomBerg 的内容
    """
    def interested_in_post(self, post: Post) -> bool:
        if 'github' in post.link.lower() \
                or 'bloomberg' in post.link.lower():
            return True
        return False
```

所有的这一切，都不需要修改原本的 `HNTopPostsSpider` 类的代码，只需要不断在它的基础上创建新的子类就能完成新需求。最终实现了对扩展开放、对改变关闭。

### 使用组合与依赖注入来改造代码

虽然类的继承特性很强大，但它并非唯一办法，[依赖注入（Dependency injection）](https://en.wikipedia.org/wiki/Dependency_injection) 是解决这个问题的另一种思路。与继承不同，依赖注入允许我们在类实例化时，通过参数将业务逻辑的变化点：**帖子过滤算法** 注入到类实例中。最终同样实现“开放-关闭原则”。

首先，我们定义一个名为 `PostFilter` 的抽象类：

```python
from abc import ABC, abstractmethod

class PostFilter(metaclass=ABCMeta):
    """抽象类：定义如何过滤帖子结果
    """
    @abstractmethod
    def validate(self, post: Post) -> bool:
        """判断帖子是否应该被保留"""
```

> Hint：定义抽象类在 Python 的 OOP 中并不是必须的，你也可以不定义它，直接从下面的 DefaultPostFilter 开始。

然后定义一个继承于该抽象类的默认 `DefaultPostFilter` 类，过滤逻辑为保留所有结果。之后再调整一下 `HNTopPostsSpider` 类的构造方法，让它接收一个名为 `post_filter` 的结果过滤器：

```python
class DefaultPostFilter(PostFilter):
    """保留所有帖子
    """
    def validate(self, post: Post) -> bool:
        return True


class HNTopPostsSpider:
    """抓取 HackerNews Top 内容条目

    :param limit: 限制条目数，默认为 5
    :param post_filter: 过滤结果条目的算法，默认为保留所有
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
            
            # 使用测试方法来判断是否返回该帖子
            if self.post_filter.validate(post):
                counter += 1
                yield post
```

默认情况下，`HNTopPostsSpider.fetch` 会保留所有的结果。假如我们想要定义自己的过滤算法，只要新建自己的 `PostFilter` 类即可，下面是两个分别过滤 GitHub 与 BloomBerg 的 `PostFilter` 类：

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

在 `main()` 函数中，我可以用不同的 `post_filter` 参数来实例化 `HNTopPostsSpider` 类，最终满足不同的过滤需求：

```python
def main():
    # crawler = HNTopPostsSpider()
    # crawler = HNTopPostsSpider(post_filter=GithubPostFilter())
    crawler = HNTopPostsSpider(post_filter=GithubNBloomPostFilter())

    posts = list(crawler.fetch())
    file_title = 'Top news on HN'
    write_posts_to_file(posts, sys.stdout, file_title)
```

与基于继承的方式一样，利用将“过滤算法”抽象为 `PostFilter` 类并以实例化参数的方式注入到 `HNTopPostsSpider` 中，我们同样实现了“开放-关闭原则”。

### 使用数据驱动思想来改造代码

在实现“开放-关闭”原则的众多手法中，除了继承与依赖注入外，还有一种经常被用到的方式：**“数据驱动”**。这个方式的核心思想在于：**将经常变动的东西，完全以数据的方式抽离出来。当需求变动时，只改动数据，代码逻辑保持不动。**

它的原理与“依赖注入”有一些相似，同样是把变化的东西抽离到类外部。不同的是，后者抽离的通常是类，而前者抽离的是数据。

为了让 `HNTopPostsSpider` 类的行为可以被数据驱动，我们需要使其接收 `filter_by_link_keywords` 参数：

```python
class HNTopPostsSpider:
    """抓取 HackerNews Top 内容条目

    :param limit: 限制条目数，默认为 5
    :param filter_by_link_keywords: 过滤结果的关键词列表，默认为 None 不过滤
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
            # 当 link 中出现任意一个关键词时，返回结果
            elif any(keyword in post.link for keyword in self.filter_by_link_keywords):
                counter += 1
                yield post
```

调整了初始化参数后，还需要在 `main` 函数中定义 `link_keywords` 变量并将其传入到 `HNTopPostsSpider` 类的构造方法中，之后所有针对过滤关键词的调整都只需要修改这个列表即可，无需改动 `HNTopPostsSpider` 类的代码，同样满足了“开放-关闭原则”。

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

与前面的继承和依赖注入方式相比，“数据驱动”的代码更简洁，不需要定义额外的类。但它同样也存在缺点：**它的可定制性不如前面的两种方式**。假如，我想要以“链接是否以某个字符串结尾”作为新的过滤条件，那么现在的数据驱动代码就有心无力了。

如何选择合适的方式来让代码符合“开放-关闭原则”，需要根据具体的需求和场景来判断。这也是一个无法一蹴而就、需要大量练习和经验积累的过程。

## 总结

在这篇文章中，我通过一个具体的 Python 代码案例，向你描述了 “SOLID” 设计原则中的前两位成员：**“单一职责原则”** 与 **“开放-关闭原则”**。

这两个原则虽然看上去很简单，但是它们背后蕴藏了许多从好代码中提炼而来的智慧。它们的适用范围也不仅仅局限在 OOP 中。一旦你深入理解它们后，你可能会惊奇的在许多设计模式和框架中发现它们的影子*（比如这篇文章就出现了至少 3 种设计模式，你知道是哪些吗？）*。

让我们最后再总结一下吧：

- **“S: 单一职责原则”**认为一个类只应该有一种被修改的原因
- 编写更小的类通常更不容易违反 S 原则
- S 原则同样适用于函数，你可以让函数和类协同工作
- **“O: 开放-关闭原则”**认为类应该对改动关闭，对扩展开放
- 找到需求中频繁变化的那个点，是让类遵循 O 原则的重点所在
- 使用子类继承的方式可以让类遵守 O 原则
- 通过定义算法类，并进行依赖注入，也可以让类遵循 O 原则
- 将数据与逻辑分离，使用数据驱动的方式也是改造代码的好办法

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[<<<上一篇【11.高效操作文件的三个建议】](11-three-tips-on-writing-file-related-codes.md)


## 附录

- 题图来源: Photo by Kelly Sikkema on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：让函数返回结果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)
- [Python 工匠：高效操作文件的三个建议](https://www.zlovezl.cn/articles/three-tips-on-writing-file-related-codes/)



