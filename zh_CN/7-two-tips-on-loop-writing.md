# Python 工匠：编写地道循环的两个建议

## 前言

> 这是 “Python 工匠”系列的第 7 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/04/lai-man-nung-1205465-unsplash_w1280.jpg" width="100%" />
</div>

循环是一种常用的程序控制结构。我们常说，机器相比人类的最大优点之一，就是机器可以不眠不休的重复做某件事情，但人却不行。而**“循环”**，则是实现让机器不断重复工作的关键概念。

在循环语法方面，Python 表现的即传统又不传统。它虽然抛弃了常见的 `for (init; condition; incrment)` 三段式结构，但还是选择了 `for` 和 `while` 这两个经典的关键字来表达循环。绝大多数情况下，我们的循环需求都可以用  `for <item> in <iterable>` 来满足，`while <condition>` 相比之下用的则更少些。

虽然循环的语法很简单，但是要写好它确并不容易。在这篇文章里，我们将探讨什么是“地道”的循环代码，以及如何编写它们。

## 什么是“地道”的循环？

“地道”这个词，通常被用来形容某人做某件事情时，非常符合当地传统，做的非常好。打个比方，你去参加一个朋友聚会，同桌的有一位广东人，对方一开口，句句都是标准京腔、完美儿化音。那你可以对她说：“您的北京话说的真**地道**”。

既然“地道”这个词形容的经常是口音、做菜的口味这类实实在在的东西，那“地道”的循环代码又是什么意思呢？让我拿一个经典的例子来解释一下。

如果你去问一位刚学习 Python 一个月的人：“*如何在遍历一个列表的同时获取当前下标？*”。他可能会交出这样的代码：

```python
index = 0
for name in names:
    print(index, name)
    index += 1
```

上面的循环虽然没错，但它确一点都不“地道”。一个拥有三年 Python 开发经验的人会说，代码应该这么写：

```python
for i, name in enumerate(names):
    print(i, name)
```

[`enumerate()`](https://docs.python.org/3/library/functions.html#enumerate) 是 Python 的一个内置函数，它接收一个“可迭代”对象作为参数，然后返回一个不断生成 `(当前下标, 当前元素)` 的新可迭代对象。这个场景使用它最适合不过。

所以，在上面的例子里，我们会认为第二段循环代码比第一段更“地道”。因为它用更直观的代码，更聪明的完成了工作。

### enumerate() 所代表的编程思路

不过，判断某段循环代码是否地道，并不仅仅是以知道或不知道某个内置方法作为标准。我们可以从上面的例子挖掘出更深层的东西。

如你所见，Python 的 `for` 循环只有 `for <item> in <iterable>` 这一种结构，而结构里的前半部分 - *赋值给 item* - 没有太多花样可玩。所以后半部分的 **可迭代对象** 是我们唯一能够大做文章的东西。而以 `enumerate()` 函数为代表的*“修饰函数”*，刚好提供了一种思路：**通过修饰可迭代对象来优化循环本身。**

这就引出了我的第一个建议。

## 建议1：使用函数修饰被迭代对象来优化循环

使用修饰函数处理可迭代对象，可以在各种方面影响循环代码。而要找到合适的例子来演示这个方法，并不用去太远，内置模块 [itertools](https://docs.python.org/3.6/library/itertools.html) 就是一个绝佳的例子。

简单来说，itertools 是一个包含很多面向可迭代对象的工具函数集。我在之前的系列文章[《容器的门道》](https://www.zlovezl.cn/articles/mastering-container-types/)里提到过它。

如果要学习 itertools，那么 [Python 官方文档](https://docs.python.org/3.6/library/itertools.html) 是你的首选，里面有非常详细的模块相关资料。但在这篇文章里，侧重点将和官方文档稍有不同。我会通过一些常见的代码场景，来详细解释它是如何改善循环代码的。

### 1. 使用 product 扁平化多层嵌套循环

虽然我们都知道*“扁平的代码比嵌套的好”*。但有时针对某类需求，似乎一定得写多层嵌套循环才行。比如下面这段：

```python
def find_twelve(num_list1, num_list2, num_list3):
    """从 3 个数字列表中，寻找是否存在和为 12 的 3 个数
    """
    for num1 in num_list1:
        for num2 in num_list2:
            for num3 in num_list3:
                if num1 + num2 + num3 == 12:
                    return num1, num2, num3
```

对于这种需要嵌套遍历多个对象的多层循环代码，我们可以使用 [product()](https://docs.python.org/3.6/library/itertools.html#itertools.product) 函数来优化它。`product()` 可以接收多个可迭代对象，然后根据它们的笛卡尔积不断生成结果。


```python
from itertools import product


def find_twelve_v2(num_list1, num_list2, num_list3):
    for num1, num2, num3 in product(num_list1, num_list2, num_list3):
        if num1 + num2 + num3 == 12:
            return num1, num2, num3
```

相比之前的代码，使用 `product()` 的函数只用了一层 for 循环就完成了任务，代码变得更精炼了。

### 2. 使用 islice 实现循环内隔行处理

有一份包含 Reddit 帖子标题的外部数据文件，里面的内容格式是这样的：

```
python-guide: Python best practices guidebook, written for humans.
---
Python 2 Death Clock
---
Run any Python Script with an Alexa Voice Command
---
<... ...>
```

可能是为了美观，在这份文件里的每两个标题之间，都有一个 `"---"` 分隔符。现在，我们需要获取文件里所有的标题列表，所以在遍历文件内容的过程中，必须跳过这些无意义的分隔符。

参考之前对 `enumerate()` 函数的了解，我们可以通过在循环内加一段基于当前循环序号的 `if` 判断来做到这一点：

```python
def parse_titles(filename):
    """从隔行数据文件中读取 reddit 主题名称
    """
    with open(filename, 'r') as fp:
        for i, line in enumerate(fp):
            # 跳过无意义的 '---' 分隔符
            if i % 2 == 0:
                yield line.strip()
```

但对于这类在循环内进行隔行处理的需求来说，如果使用 itertools 里的 [islice()](https://docs.python.org/3.6/library/itertools.html#itertools.islice) 函数修饰被循环对象，可以让循环体代码变得更简单直接。

`islice(seq, start, end, step)` 函数和数组切片操作*（ list[start:stop:step] ）*有着几乎一模一样的参数。如果需要在循环内部进行隔行处理的话，只要设置第三个递进步长参数 step 值为 2 即可*（默认为 1）*。

```python
from itertools import islice

def parse_titles_v2(filename):
    with open(filename, 'r') as fp:
        # 设置 step=2，跳过无意义的 '---' 分隔符
        for line in islice(fp, 0, None, 2):
            yield line.strip()
```

### 3. 使用 takewhile 替代 break 语句

有时，我们需要在每次循环开始时，判断循环是否需要提前结束。比如下面这样：

```python
for user in users:
    # 当第一个不合格的用户出现后，不再进行后面的处理
    if not is_qualified(user):
        break

    # 进行处理 ... ...
```

对于这类需要提前中断的循环，我们可以使用 [takewhile()](https://docs.python.org/3.6/library/itertools.html#itertools.takewhile) 函数来简化它。`takewhile(predicate, iterable)` 会在迭代 `iterable` 的过程中不断使用当前对象作为参数调用 `predicate` 函数并测试返回结果，如果函数返回值为真，则生成当前对象，循环继续。否则立即中断当前循环。

使用 `takewhile` 的代码样例：

```
from itertools import takewhile

for user in takewhile(is_qualified, users):
    # 进行处理 ... ...
```

itertools 里面还有一些其他有意思的工具函数，他们都可以用来和循环搭配使用，比如使用 chain 函数扁平化双层嵌套循环、使用 zip_longest 函数一次同时循环多个对象等等。

篇幅有限，我在这里不再一一介绍。如果有兴趣，可以自行去官方文档详细了解。

### 4. 使用生成器编写自己的修饰函数

除了 itertools 提供的那些函数外，我们还可以非常方便的使用生成器来定义自己的循环修饰函数。

让我们拿一个简单的函数举例：

```python
def sum_even_only(numbers):
    """对 numbers 里面所有的偶数求和"""
    result = 0
    for num in numbers:
        if num % 2 == 0:
            result += num
    return result
```

在上面的函数里，循环体内为了过滤掉所有奇数，引入了一条额外的 `if` 判断语句。如果要简化循环体内容，我们可以定义一个生成器函数来专门进行偶数过滤：

```python
def even_only(numbers):
    for num in numbers:
        if num % 2 == 0:
            yield num


def sum_even_only_v2(numbers):
    """对 numbers 里面所有的偶数求和"""
    result = 0
    for num in even_only(numbers):
        result += num
    return result
```

将 `numbers` 变量使用 `even_only` 函数装饰后，`sum_even_only_v2` 函数内部便不用继续关注“偶数过滤”逻辑了，只需要简单完成求和即可。

> Hint：当然，上面的这个函数其实并不实用。在现实世界里，这种简单需求最适合直接用生成器/列表表达式搞定：`sum(num for num in numbers if num % 2 == 0)`

## 建议2：按职责拆解循环体内复杂代码块

我一直觉得循环是一个比较神奇的东西，每当你写下一个新的循环代码块，就好像开辟了一片黑魔法阵，阵内的所有内容都会开始无休止的重复执行。

但我同时发现，这片黑魔法阵除了能带来好处，**它还会引诱你不断往阵内塞入越来越多的代码，包括过滤掉无效元素、预处理数据、打印日志等等。甚至一些原本不属于同一抽象的内容，也会被塞入到同一片黑魔法阵内。**

你可能会觉得这一切理所当然，我们就是迫切需要阵内的魔法效果。如果不把这一大堆逻辑塞满到循环体内，还能把它们放哪去呢？

让我们来看看下面这个业务场景。在网站中，有一个每 30 天执行一次的周期脚本，它的任务是是查询过去 30 天内，在每周末特定时间段登录过的用户，然后为其发送奖励积分。

代码如下：

```python
import time
import datetime


def award_active_users_in_last_30days():
    """获取所有在过去 30 天周末晚上 8 点到 10 点登录过的用户，为其发送奖励积分
    """
    days = 30
    for days_delta in range(days):
        dt = datetime.date.today() - datetime.timedelta(days=days_delta)
        # 5: Saturday, 6: Sunday
        if dt.weekday() not in (5, 6):
            continue

        time_start = datetime.datetime(dt.year, dt.month, dt.day, 20, 0)
        time_end = datetime.datetime(dt.year, dt.month, dt.day, 23, 0)

        # 转换为 unix 时间戳，之后的 ORM 查询需要
        ts_start = time.mktime(time_start.timetuple())
        ts_end = time.mktime(time_end.timetuple())

        # 查询用户并挨个发送 1000 奖励积分
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            # 这里可以添加复杂逻辑
            send_awarding_points(record.user_id, 1000)
```

上面这个函数主要由两层循环构成。外层循环的职责，主要是获取过去 30 天内符合要求的时间，并将其转换为 UNIX 时间戳。之后由内层循环使用这两个时间戳进行积分发送。

如之前所说，外层循环所开辟的黑魔法阵内被塞的满满当当。但通过观察后，我们可以发现 **整个循环体其实是由两个完全无关的任务构成的：“挑选日期与准备时间戳” 以及 “发送奖励积分”**。

### 复杂循环体如何应对新需求

这样的代码有什么坏处呢？让我来告诉你。

某日，产品找过来说，有一些用户周末半夜不睡觉，还在刷我们的网站，我们得给他们发通知让他们以后早点睡觉。于是新需求出现了：**“给过去 30 天内在周末凌晨 3 点到 5 点登录过的用户发送一条通知”**。

新问题也随之而来。敏锐如你，肯定一眼可以发现，这个新需求在用户筛选部分的要求，和之前的需求非常非常相似。但是，如果你再打开之前那团循环体看看，你会发现代码根本没法复用，因为在循环内部，不同的逻辑完全被 **耦合** 在一起了。☹️

在计算机的世界里，我们经常用**“耦合”**这个词来表示事物之间的关联关系。上面的例子中，*“挑选时间”*和*“发送积分”*这两件事情身处同一个循环体内，建立了非常强的耦合关系。

为了更好的进行代码复用，我们需要把函数里的*“挑选时间”*部分从循环体中解耦出来。而我们的老朋友，**“生成器函数”**是进行这项工作的不二之选。

### 使用生成器函数解耦循环体

要把 *“挑选时间”* 部分从循环内解耦出来，我们需要定义新的生成器函数 `gen_weekend_ts_ranges()`，专门用来生成需要的 UNIX 时间戳：

```python
def gen_weekend_ts_ranges(days_ago, hour_start, hour_end):
    """生成过去一段时间内周六日特定时间段范围，并以 UNIX 时间戳返回
    """
    for days_delta in range(days_ago):
        dt = datetime.date.today() - datetime.timedelta(days=days_delta)
        # 5: Saturday, 6: Sunday
        if dt.weekday() not in (5, 6):
            continue

        time_start = datetime.datetime(dt.year, dt.month, dt.day, hour_start, 0)
        time_end = datetime.datetime(dt.year, dt.month, dt.day, hour_end, 0)

        # 转换为 unix 时间戳，之后的 ORM 查询需要
        ts_start = time.mktime(time_start.timetuple())
        ts_end = time.mktime(time_end.timetuple())
        yield ts_start, ts_end
```

有了这个生成器函数后，旧需求“发送奖励积分”和新需求“发送通知”，就都可以在循环体内复用它来完成任务了：

```python
def award_active_users_in_last_30days_v2():
    """发送奖励积分"""
    for ts_start, ts_end in gen_weekend_ts_ranges(30, hour_start=20, hour_end=23):
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            send_awarding_points(record.user_id, 1000)


def notify_nonsleep_users_in_last_30days():
    """发送通知"""
    for ts_start, ts_end in gen_weekend_ts_range(30, hour_start=3, hour_end=6):
        for record in LoginRecord.filter_by_range(ts_start, ts_end):
            notify_user(record.user_id, 'You should sleep more')
```

## 总结

在这篇文章里，我们首先简单解释了“地道”循环代码的定义。然后提出了第一个建议：使用修饰函数来改善循环。之后我虚拟了一个业务场景，描述了按职责拆解循环内代码的重要性。

一些要点总结：

- 使用函数修饰被循环对象本身，可以改善循环体内的代码
- itertools 里面有很多工具函数都可以用来改善循环
- 使用生成器函数可以轻松定义自己的修饰函数
- 循环内部，是一个极易发生“代码膨胀”的场地
- 请使用生成器函数将循环内不同职责的代码块解耦出来，获得更好的灵活性

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【8.使用装饰器的技巧】](8-tips-on-decorators.md)

[<<<上一篇【6.异常处理的三个好习惯】](6-three-rituals-of-exceptions-handling.md)

## 附录

- 题图来源: Photo by Lai man nung on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：容器的门道](https://www.zlovezl.cn/articles/mastering-container-types/)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：异常处理的三个好习惯](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)



