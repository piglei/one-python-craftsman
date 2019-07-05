# Python 工匠：容器的门道

## 序言

> 这是 “Python 工匠”系列的第 4 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static//uploaded/2019/01/6002476959_cca2bf5424_b_thumb.jpg" width="100%" /><div>
图片来源: <a href="https://www.flickr.com/photos/chiotsrun/6002476959/in/photolist-a9qgh4-W4eQ1j-7MrCfo-4ARLWp-dwCzHh-Tascu9-RNRbRf-foLHW5-22dkkHM-9ceFA8-aGGd3a-26X3sqQ-iuTwX9-q52ktA-osn2eb-29oujY-6mXd1c-8E92nc-mPbq55-9GuPU8-26Q1NZG-8UL8PL-pdyFsW-7V8ifD-VZavJ8-2cUdHbU-9WrgjZ-6g7M5K-VMLVrb-cXDd4-bygFJG-C76kP-nMQW54-7MoQqn-qA3fud-c92dBU-tAzTBm-7KqFXc-24VvcW1-djQX9e-5LzjkA-63U4kb-bt1EEY-jLRpKo-dQSWBH-aDbqXc-8KhfnE-2m5ZsF-6ciuiR-qwdbt">"The Humble Mason Jar" by Chiot's Run</a> - 非商业性使用 2.0 通用</div>
</div>

容器”这两个字很少被 Python 技术文章提起。一看到“容器”，大家想到的多是那头蓝色小鲸鱼：*Docker*，但这篇文章和它没有任何关系。本文里的容器，是 Python 中的一个抽象概念，是对**专门用来装其他对象的数据类型**的统称。

在 Python 中，有四类最常见的内建容器类型：`列表（list）`、`元组（tuple）`、`字典（dict）`、`集合（set）`。通过单独或是组合使用它们，可以高效的完成很多事情。

Python 语言自身的内部实现细节也与这些容器类型息息相关。比如 Python 的类实例属性、全局变量 `globals()` 等就都是通过字典类型来存储的。

在这篇文章里，我首先会从容器类型的定义出发，尝试总结出一些日常编码的最佳实践。之后再围绕各个容器类型提供的特殊机能，分享一些编程的小技巧。

### 内容目录

* [底层看容器](#底层看容器)
    * [写更快的代码](#写更快的代码)
        * [1. 避免频繁扩充列表/创建新列表](#1-避免频繁扩充列表创建新列表)
        * [2. 在列表头部操作多的场景使用 deque 模块](#2-在列表头部操作多的场景使用-deque-模块)
        * [3. 使用集合/字典来判断成员是否存在](#3-使用集合字典来判断成员是否存在)
* [高层看容器](#高层看容器)
    * [写扩展性更好的代码](#写扩展性更好的代码)
        * [面向容器接口编程](#面向容器接口编程)
* [常用技巧](#常用技巧)
    * [1. 使用元组改善分支代码](#1-使用元组改善分支代码)
    * [2. 在更多地方使用动态解包](#2-在更多地方使用动态解包)
    * [3. 最好不用“获取许可”，也无需“要求原谅”](#3-最好不用获取许可也无需要求原谅)
    * [4. 使用 next() 函数](#4-使用-next-函数)
    * [5. 使用有序字典来去重](#5-使用有序字典来去重)
* [常见误区](#常见误区)
    * [1. 当心那些已经枯竭的迭代器](#1-当心那些已经枯竭的迭代器)
    * [2. 别在循环体内修改被迭代对象](#2-别在循环体内修改被迭代对象)
* [总结](#总结)
* [系列其他文章](#系列其他文章)
* [注解](#注解)


### 当我们谈论容器时，我们在谈些什么？

我在前面给了“容器”一个简单的定义：*专门用来装其他对象的就是容器*。但这个定义太宽泛了，无法对我们的日常编程产生什么指导价值。要真正掌握 Python 里的容器，需要分别从两个层面入手：

- **底层实现**：内置容器类型使用了什么数据结构？某项操作如何工作？
- **高层抽象**：什么决定了某个对象是不是容器？哪些行为定义了容器？

下面，让我们一起站在这两个不同的层面上，重新认识容器。


## 底层看容器

Python 是一门高级编程语言，**它所提供的内置容器类型，都是经过高度封装和抽象后的结果**。和“链表”、“红黑树”、“哈希表”这些名字相比，所有 Python 内建类型的名字，都只描述了这个类型的功能特点，其他人完全没法只通过这些名字了解它们的哪怕一丁点内部细节。

这是 Python 编程语言的优势之一。相比 C 语言这类更接近计算机底层的编程语言，Python 重新设计并实现了对编程者更友好的内置容器类型，屏蔽掉了内存管理等额外工作。为我们提供了更好的开发体验。

但如果这是 Python 语言的优势的话，为什么我们还要费劲去了解容器类型的实现细节呢？答案是：**关注细节可以帮助我们编写出更快的代码。**

### 写更快的代码

#### 1. 避免频繁扩充列表/创建新列表

所有的内建容器类型都不限制容量。如果你愿意，你可以把递增的数字不断塞进一个空列表，最终撑爆整台机器的内存。

在 Python 语言的实现细节里，列表的内存是按需分配的[[注1]](#annot1)，当某个列表当前拥有的内存不够时，便会触发内存扩容逻辑。而分配内存是一项昂贵的操作。虽然大部分情况下，它不会对你的程序性能产生什么严重的影响。但是当你处理的数据量特别大时，很容易因为内存分配拖累整个程序的性能。

还好，Python 早就意识到了这个问题，并提供了官方的问题解决指引，那就是：**“变懒”**。

如何解释“变懒”？`range()` 函数的进化是一个非常好的例子。

在 Python 2 中，如果你调用 `range(100000000)`，需要等待好几秒才能拿到结果，因为它需要返回一个巨大的列表，花费了非常多的时间在内存分配与计算上。但在 Python 3 中，同样的调用马上就能拿到结果。因为函数返回的不再是列表，而是一个类型为 `range` 的懒惰对象，只有在你迭代它、或是对它进行切片时，它才会返回真正的数字给你。

**所以说，为了提高性能，内建函数 `range` “变懒”了。** 而为了避免过于频繁的内存分配，在日常编码中，我们的函数同样也需要变懒，这包括：

- 更多的使用 `yield` 关键字，返回生成器对象
- 尽量使用生成器表达式替代列表推导表达式
    - 生成器表达式：`(i for i in range(100))` 👍
    - 列表推导表达式：`[i for i in range(100)]`
- 尽量使用模块提供的懒惰对象：
    - 使用 `re.finditer` 替代 `re.findall`
    - 直接使用可迭代的文件对象： `for line in fp`，而不是 `for line in fp.readlines()`

#### 2. 在列表头部操作多的场景使用 deque 模块

列表是基于数组结构（Array）实现的，当你在列表的头部插入新成员（`list.insert(0, item)`）时，它后面的所有其他成员都需要被移动，操作的时间复杂度是 `O(n)`。这导致在列表的头部插入成员远比在尾部追加（`list.append(item)` 时间复杂度为 `O(1)`）要慢。

如果你的代码需要执行很多次这类操作，请考虑使用 [collections.deque](https://docs.python.org/3.7/library/collections.html#collections.deque) 类型来替代列表。因为 deque 是基于双端队列实现的，无论是在头部还是尾部追加元素，时间复杂度都是 `O(1)`。

#### 3. 使用集合/字典来判断成员是否存在

当你需要判断成员是否存在于某个容器时，用集合比列表更合适。因为 `item in [...]` 操作的时间复杂度是 `O(n)`，而 `item in {...}` 的时间复杂度是 `O(1)`。这是因为字典与集合都是基于哈希表（Hash Table）数据结构实现的。

```python
# 这个例子不是特别恰当，因为当目标集合特别小时，使用集合还是列表对效率的影响微乎其微
# 但这不是重点 :)
VALID_NAMES = ["piglei", "raymond", "bojack", "caroline"]

# 转换为集合类型专门用于成员判断
VALID_NAMES_SET = set(VALID_NAMES)


def validate_name(name):
    if name not in VALID_NAMES_SET:
        # 此处使用了 Python 3.6 添加的 f-strings 特性
        raise ValueError(f"{name} is not a valid name!")
```

> Hint: 强烈建议阅读 [TimeComplexity - Python Wiki](https://wiki.python.org/moin/TimeComplexity)，了解更多关于常见容器类型的时间复杂度相关内容。
> 
> 如果你对字典的实现细节感兴趣，也强烈建议观看 Raymond Hettinger 的演讲 [Modern Dictionaries(YouTube)](https://www.youtube.com/watch?v=p33CVV29OG8&t=1403s)

## 高层看容器

Python 是一门“[鸭子类型](https://en.wikipedia.org/wiki/Duck_typing)”语言：*“当看到一只鸟走起来像鸭子、游泳起来像鸭子、叫起来也像鸭子，那么这只鸟就可以被称为鸭子。”* 所以，当我们说某个对象是什么类型时，在根本上其实指的是： **这个对象满足了该类型的特定接口规范，可以被当成这个类型来使用。** 而对于所有内置容器类型来说，同样如此。

打开位于 [collections](https://docs.python.org/3.7/library/collections.html) 模块下的 [abc](https://docs.python.org/3/library/collections.abc.html)*（“抽象类 Abstract Base Classes”的首字母缩写）* 子模块，可以找到所有与容器相关的接口（抽象类）[[注2]](#annot2)定义。让我们分别看看那些内建容器类型都满足了什么接口：

- **列表（list）**：满足 `Iterable`、`Sequence`、`MutableSequence` 等接口
- **元组（tuple）**：满足 `Iterable`、`Sequence`
- **字典（dict）**：满足 `Iterable`、`Mapping`、`MutableMapping` [[注3]](#annot3)
- **集合（set）**：满足 `Iterable`、`Set`、`MutableSet` [[注4]](#annot4)

每个内置容器类型，其实就是满足了多个接口定义的组合实体。比如所有的容器类型都满足 `“可被迭代的”（Iterable`） 这个接口，这意味着它们都是“可被迭代”的。但是反过来，不是所有“可被迭代”的对象都是容器。就像字符串虽然可以被迭代，但我们通常不会把它当做“容器”来看待。

了解这个事实后，我们将**在 Python 里重新认识**面向对象编程中最重要的原则之一：**面向接口而非具体实现来编程。**

让我们通过一个例子，看看如何理解 Python 里的“面向接口编程”。

### 写扩展性更好的代码

某日，我们接到一个需求：*有一个列表，里面装着很多用户评论，为了在页面正常展示，需要将所有超过一定长度的评论用省略号替代*。

这个需求很好做，很快我们就写出了第一个版本的代码：

```python
# 注：为了加强示例代码的说明性，本文中的部分代码片段使用了Python 3.5
# 版本添加的 Type Hinting 特性

def add_ellipsis(comments: typing.List[str], max_length: int = 12):
    """如果评论列表里的内容超过 max_length，剩下的字符用省略号代替
    """
    index = 0
    for comment in comments:
        comment = comment.strip()
        if len(comment) > max_length:
            comments[index] = comment[:max_length] + '...'
        index += 1
    return comments


comments = [
    "Implementation note",
    "Changed",
    "ABC for generator",
]
print("\n".join(add_ellipsis(comments)))
# OUTPUT:
# Implementati...
# Changed
# ABC for gene...
```

上面的代码里，`add_ellipsis` 函数接收一个列表作为参数，然后遍历它，替换掉需要修改的成员。这一切看上去很合理，因为我们接到的最原始需求就是：“有一个 **列表**，里面...”。**但如果有一天，我们拿到的评论不再是被继续装在列表里，而是在不可变的元组里呢？**

那样的话，现有的函数设计就会逼迫我们写出 `add_ellipsis(list(comments))` 这种即慢又难看的代码了。😨

#### 面向容器接口编程

我们需要改进函数来避免这个问题。因为 `add_ellipsis` 函数强依赖了列表类型，所以当参数类型变为元组时，现在的函数就不再适用了*（原因：给 `comments[index]` 赋值的地方会抛出 `TypeError` 异常）。* 如何改善这部分的设计？秘诀就是：**让函数依赖“可迭代对象”这个抽象概念，而非实体列表类型。**

使用生成器特性，函数可以被改成这样：

```python
def add_ellipsis_gen(comments: typing.Iterable[str], max_length: int = 12):
    """如果可迭代评论里的内容超过 max_length，剩下的字符用省略号代替
    """
    for comment in comments:
        comment = comment.strip()
        if len(comment) > max_length:
            yield comment[:max_length] + '...'
        else:
            yield comment


print("\n".join(add_ellipsis_gen(comments)))
```

在新函数里，我们将依赖的参数类型从列表改成了可迭代的抽象类。这样做有很多好处，一个最明显的就是：无论评论是来自列表、元组或是某个文件，新函数都可以轻松满足：

```python
# 处理放在元组里的评论
comments = ("Implementation note", "Changed", "ABC for generator")
print("\n".join(add_ellipsis_gen(comments)))

# 处理放在文件里的评论
with open("comments") as fp:
    for comment in add_ellipsis_gen(fp):
        print(comment)
```

将依赖由某个具体的容器类型改为抽象接口后，函数的适用面变得更广了。除此之外，新函数在执行效率等方面也都更有优势。现在让我们再回到之前的问题。**从高层来看，什么定义了容器？**

答案是： **各个容器类型实现的接口协议定义了容器。** 不同的容器类型在我们的眼里，应该是 `是否可以迭代`、`是否可以修改`、`有没有长度` 等各种特性的组合。我们需要在编写相关代码时，**更多的关注容器的抽象属性，而非容器类型本身**，这样可以帮助我们写出更优雅、扩展性更好的代码。

> Hint：在 [itertools](https://docs.python.org/3/library/itertools.html) 内置模块里可以找到更多关于处理可迭代对象的宝藏。

## 常用技巧

### 1. 使用元组改善分支代码

有时，我们的代码里会出现超过三个分支的 `if/else` 。就像下面这样：

```python
import time


def from_now(ts):
    """接收一个过去的时间戳，返回距离当前时间的相对时间文字描述
    """
    now = time.time()
    seconds_delta = int(now - ts)
    if seconds_delta < 1:
        return "less than 1 second ago"
    elif seconds_delta < 60:
        return "{} seconds ago".format(seconds_delta)
    elif seconds_delta < 3600:
        return "{} minutes ago".format(seconds_delta // 60)
    elif seconds_delta < 3600 * 24:
        return "{} hours ago".format(seconds_delta // 3600)
    else:
        return "{} days ago".format(seconds_delta // (3600 * 24))


now = time.time()
print(from_now(now))
print(from_now(now - 24))
print(from_now(now - 600))
print(from_now(now - 7500))
print(from_now(now - 87500))
# OUTPUT:
# less than 1 second ago
# 24 seconds ago
# 10 minutes ago
# 2 hours ago
# 1 days ago
```

上面这个函数挑不出太多毛病，很多很多人都会写出类似的代码。但是，如果你仔细观察它，可以在分支代码部分找到一些明显的“**边界**”。 比如，当函数判断某个时间是否应该用“秒数”展示时，用到了 `60`。而判断是否应该用分钟时，用到了 `3600`。

**从边界提炼规律是优化这段代码的关键。** 如果我们将所有的这些边界放在一个有序元组中，然后配合二分查找模块 [bisect](https://docs.python.org/3.7/library/bisect.html)。整个函数的控制流就能被大大简化：

```python
import bisect


# BREAKPOINTS 必须是已经排好序的，不然无法进行二分查找
BREAKPOINTS = (1, 60, 3600, 3600 * 24)
TMPLS = (
    # unit, template
    (1, "less than 1 second ago"),
    (1, "{units} seconds ago"),
    (60, "{units} minutes ago"),
    (3600, "{units} hours ago"),
    (3600 * 24, "{units} days ago"),
)


def from_now(ts):
    """接收一个过去的时间戳，返回距离当前时间的相对时间文字描述
    """
    seconds_delta = int(time.time() - ts)
    unit, tmpl = TMPLS[bisect.bisect(BREAKPOINTS, seconds_delta)]
    return tmpl.format(units=seconds_delta // unit)
```

除了用元组可以优化过多的 `if/else` 分支外，有些情况下字典也能被用来做同样的事情。关键在于从现有代码找到重复的逻辑与规律，并多多尝试。

### 2. 在更多地方使用动态解包

动态解包操作是指使用 `*` 或 `**` 运算符将可迭代对象“解开”的行为，在 Python 2 时代，这个操作只能被用在函数参数部分，并且对出现顺序和数量都有非常严格的要求，使用场景非常单一。

```python
def calc(a, b, multiplier=1):
    return (a + b) * multiplier


# Python2 中只支持在函数参数部分进行动态解包
print calc(*[1, 2], **{"multiplier": 10})
# OUTPUT: 30
```

不过，Python 3 尤其是 3.5 版本后，`*` 和 `**` 的使用场景被大大扩充了。举个例子，在 Python 2 中，如果我们需要合并两个字典，需要这么做：

```python
def merge_dict(d1, d2):
    # 因为字典是可被修改的对象，为了避免修改原对象，此处需要复制一个 d1 的浅拷贝
    result = d1.copy()
    result.update(d2)
    return result
    
user = merge_dict({"name": "piglei"}, {"movies": ["Fight Club"]})
```

但是在 Python 3.5 以后的版本，你可以直接用 `**` 运算符来快速完成字典的合并操作：

```
user = {**{"name": "piglei"}, **{"movies": ["Fight Club"]}}
```

除此之外，你还可以在普通赋值语句中使用 `*` 运算符来动态的解包可迭代对象。如果你想详细了解相关内容，可以阅读下面推荐的 PEP。

> Hint：推进动态解包场景扩充的两个 PEP：
> - [PEP 3132 -- Extended Iterable Unpacking | Python.org](https://www.python.org/dev/peps/pep-3132/)
> - [PEP 448 -- Additional Unpacking Generalizations | Python.org](https://www.python.org/dev/peps/pep-0448/)

### 3. 最好不用“获取许可”，也无需“要求原谅”

这个小标题可能会稍微让人有点懵，让我来简短的解释一下：“获取许可”与“要求原谅”是两种不同的编程风格。如果用一个经典的需求：*“计算列表内各个元素出现的次数”* 来作为例子，两种不同风格的代码会是这样：

```python
# AF: Ask for Forgiveness
# 要做就做，如果抛出异常了，再处理异常
def counter_af(l):
    result = {}
    for key in l:
        try:
            result[key] += 1
        except KeyError:
            result[key] = 1
    return result


# AP: Ask for Permission
# 做之前，先问问能不能做，可以做再做
def counter_ap(l):
    result = {}
    for key in l:
        if key in result:
            result[key] += 1
        else:
            result[key] = 1
    return result
```

整个 Python 社区对第一种 *Ask for Forgiveness* 的异常捕获式编程风格有着明显的偏爱。这其中有很多原因，首先，在 Python 中抛出异常是一个很轻量的操作。其次，第一种做法在性能上也要优于第二种，因为它不用在每次循环的时候都做一次额外的成员检查。

不过，示例里的两段代码在现实世界中都非常少见。为什么？因为如果你想统计次数的话，直接用 `collections.defaultdict` 就可以了：

```python
from collections import defaultdict


def counter_by_collections(l):
    result = defaultdict(int)
    for key in l:
        result[key] += 1
    return result
```

这样的代码既不用“获取许可”，也无需“请求原谅”。 **整个代码的控制流变得更清晰自然了。** 所以，如果可能的话，请尽量想办法省略掉那些 **非核心** 的异常捕获逻辑。一些小提示：

- 操作字典成员时：使用 `collections.defaultdict` 类型
    - 或者使用 `dict[key] = dict.setdefault(key, 0) + 1` 内建函数
- 如果移除字典成员，不关心是否存在：
    - 调用 pop 函数时设置默认值，比如 `dict.pop(key, None)`
- 在字典获取成员时指定默认值：`dict.get(key, default_value)`
- 对列表进行不存在的切片访问不会抛出 `IndexError` 异常：`["foo"][100:200]`

### 4. 使用 next() 函数

`next()` 是一个非常实用的内建函数，它接收一个迭代器作为参数，然后返回该迭代器的下一个元素。使用它配合生成器表达式，可以高效的实现*“从列表中查找第一个满足条件的成员”* 之类的需求。

```python
numbers = [3, 7, 8, 2, 21]
# 获取并 **立即返回** 列表里的第一个偶数
print(next(i for i in numbers if i % 2 == 0))
# OUTPUT: 8
```

### 5. 使用有序字典来去重

字典和集合的结构特点保证了它们的成员不会重复，所以它们经常被用来去重。但是，使用它们俩去重后的结果会丢失原有列表的顺序。这是由底层数据结构“哈希表（Hash Table）”的特点决定的。

```python
>>> l = [10, 2, 3, 21, 10, 3]
# 去重但是丢失了顺序
>>> set(l)
{3, 10, 2, 21}
```

如果既需要去重又必须保留顺序怎么办？我们可以使用 `collections.OrderedDict` 模块:

```python
>>> from collections import OrderedDict
>>> list(OrderedDict.fromkeys(l).keys())
[10, 2, 3, 21]
```

> Hint: 在 Python 3.6 中，默认的字典类型修改了实现方式，已经变成有序的了。并且在 Python 3.7 中，该功能已经从 **语言的实现细节** 变成了为 **可依赖的正式语言特性**。
> 
> 但是我觉得让整个 Python 社区习惯这一点还需要一些时间，毕竟目前“字典是无序的”还是被印在无数本 Python 书上。所以，我仍然建议在一切需要有序字典的地方使用 OrderedDict。

## 常见误区

### 1. 当心那些已经枯竭的迭代器

在文章前面，我们提到了使用“懒惰”生成器的种种好处。但是，所有事物都有它的两面性。生成器的最大的缺点之一就是：**它会枯竭**。当你完整遍历过它们后，之后的重复遍历就不能拿到任何新内容了。

```python
numbers = [1, 2, 3]
numbers = (i * 2 for i in numbers)

# 第一次循环会输出 2, 4, 6
for number in numbers:
    print(number)

# 这次循环什么都不会输出，因为迭代器已经枯竭了
for number in numbers:
    print(number)
```

而且不光是生成器表达式，Python 3 里的 map、filter 内建函数也都有一样的特点。忽视这个特点很容易导致代码中出现一些难以察觉的 Bug。

Instagram 就在项目从 Python 2 到 Python 3 的迁移过程中碰到了这个问题。它们在 PyCon 2017 上分享了对付这个问题的故事。访问文章 [Instagram 在 PyCon 2017 的演讲摘要](https://www.zlovezl.cn/articles/instagram-pycon-2017/)，搜索“迭代器”可以查看详细内容。

### 2. 别在循环体内修改被迭代对象

这是一个很多 Python 初学者会犯的错误。比如，我们需要一个函数来删掉列表里的所有偶数：

```python
def remove_even(numbers):
    """去掉列表里所有的偶数
    """
    for i, number in enumerate(numbers):
        if number % 2 == 0:
            # 有问题的代码
            del numbers[i]


numbers = [1, 2, 7, 4, 8, 11]
remove_even(numbers)
print(numbers)
# OUTPUT: [1, 7, 8, 11]
```

注意到结果里那个多出来的 “8” 了吗？当你在遍历一个列表的同时修改它，就会出现这样的事情。因为被迭代的对象 `numbers` 在循环过程中被修改了。**遍历的下标在不断增长，而列表本身的长度同时又在不断缩减。这样就会导致列表里的一些成员其实根本就没有被遍历到。**

所以对于这类操作，请使用一个新的空列表保存结果，或者利用 `yield` 返回一个生成器。而不是修改被迭代的列表或是字典对象本身。

## 总结

在这篇文章中，我们首先从“容器类型”的定义出发，在底层和高层两个层面探讨了容器类型。之后遵循系列文章传统，提供了一些编写容器相关代码时的技巧。

让我们最后再总结一下要点：

- 了解容器类型的底层实现，可以帮助你写出性能更好的代码
- 提炼需求里的抽象概念，面向接口而非实现编程
- 多使用“懒惰”的对象，少生成“迫切”的列表
- 使用元组和字典可以简化分支代码结构
- 使用 `next()` 函数配合迭代器可以高效完成很多事情，但是也需要注意“枯竭”问题
- collections、itertools 模块里有非常多有用的工具，快去看看吧！

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【5.让函数返回结果的技巧】](5-function-returning-tips.md)

[<<<上一篇【3.编写条件分支代码的技巧】](3-tips-on-numbers-and-strings.md)

## 系列其他文章

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：善用变量改善代码质量](https://www.zlovezl.cn/articles/python-using-variables-well/)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：使用数字与字符串的技巧](https://www.zlovezl.cn/articles/tips-on-numbers-and-strings/)

## 注解

1. <a id="annot1"></a>Python 这门语言除了 CPython 外，还有许许多多的其他版本实现。如无特别说明，本文以及 “Python 工匠” 系列里出现的所有 Python 都特指 Python 的 C 语言实现 CPython
2. <a id="annot2"></a>Python 里没有类似其他编程语言里的“Interface 接口”类型，只有类似的“抽象类”概念。为了表达方便，后面的内容均统一使用“接口”来替代“抽象类”。
3. <a id="annot3"></a>有没有只实现了 Mapping 但又不是 MutableMapping 的类型？试试 [MappingProxyType({})](https://docs.python.org/3/library/types.html#types.MappingProxyType)
4. <a id="annot4"></a>有没有只实现了 Set 但又不是 MutableSet 的类型？试试 [frozenset()](https://docs.python.org/3/library/stdtypes.html#frozenset)

