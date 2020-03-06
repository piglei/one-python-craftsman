# Python 工匠：使用数字与字符串的技巧


## 序言

> 这是 “Python 工匠”系列的第 3 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

数字是几乎所有编程语言里最基本的数据类型，它是我们通过代码连接现实世界的基础。在 Python 里有三种数值类型：整型（int）、浮点型（float）和复数（complex）。绝大多数情况下，我们只需要和前两种打交道。

整型在 Python 中比较让人省心，因为它不区分有无符号并且永不溢出。但浮点型仍和绝大多数其他编程语言一样，依然有着精度问题，经常让很多刚进入编程世界大门的新人们感到困惑：["Why Are Floating Point Numbers Inaccurate?"](https://stackoverflow.com/questions/21895756/why-are-floating-point-numbers-inaccurate)。

相比数字，Python 里的字符串要复杂的多。要掌握它，你得先弄清楚 bytes 和 str 的区别。如果更不巧，你还是位 Python2 用户的话，光 unicode 和字符编码问题就够你喝上好几壶了*（赶快迁移到 Python3 吧，就在今天！）*。

不过，上面提到的这些都不是这篇文章的主题，如果感兴趣，你可以在网上找到成堆的相关资料。在这篇文章里，我们将讨论一些 **更细微、更不常见** 的编程实践。来帮助你写出更好的 Python 代码。

### 内容目录

* [最佳实践](#最佳实践)
    * [1. 少写数字字面量](#1-少写数字字面量)
        * [使用 enum 枚举类型改善代码](#使用-enum-枚举类型改善代码)
    * [2. 别在裸字符串处理上走太远](#2-别在裸字符串处理上走太远)
    * [3. 不必预计算字面量表达式](#3-不必预计算字面量表达式)
* [实用技巧](#实用技巧)
    * [1. 布尔值其实也是“数字”](#1-布尔值其实也是数字)
    * [2. 改善超长字符串的可读性](#2-改善超长字符串的可读性)
        * [当多级缩进里出现多行字符串时](#当多级缩进里出现多行字符串时)
    * [3. 别忘了那些 “r” 开头的内建字符串函数](#3-别忘了那些-r-开头的内建字符串函数)
    * [4. 使用“无穷大” float("inf")](#4-使用无穷大-floatinf)
* [常见误区](#常见误区)
    * [1. “value  = 1” 并非线程安全](#1-value--1-并非线程安全)
    * [2. 字符串拼接并不慢](#2-字符串拼接并不慢)
* [结语](#结语)

## 最佳实践

### 1. 少写数字字面量

“数字字面量（integer literal）” 是指那些直接出现在代码里的数字。它们分布在代码里的各个角落，比如代码 `del users[0]` 里的 `0` 就是一个数字字面量。它们简单、实用，每个人每天都在写。**但是，当你的代码里不断重复出现一些特定字面量时，你的“代码质量告警灯”就应该亮起黄灯 🚥 了。**

举个例子，假如你刚加入一家心仪已久的新公司，同事转交给你的项目里有这么一个函数：

```python
def mark_trip_as_featured(trip):
    """将某个旅程添加到推荐栏目
    """
    if trip.source == 11:
        do_some_thing(trip)
    elif trip.source == 12:
        do_some_other_thing(trip)
    ... ...
    return
```

这个函数做了什么事？你努力想搞懂它的意思，不过 `trip.source == 11` 是什么情况？那 `== 12` 呢？这两行代码很简单，没有用到任何魔法特性。但初次接触代码的你可能需要花费**一整个下午**，才能弄懂它们的含义。

**问题就出在那几个数字字面量上。** 最初写下这个函数的人，可能是在公司成立之初加入的那位元老程序员。而他对那几个数字的含义非常清楚。但如果你是一位刚接触这段代码的新人，就完全是另外一码事了。

#### 使用 enum 枚举类型改善代码

那么，怎么改善这段代码？最直接的方式，就是为这两个条件分支添加注释。不过在这里，“添加注释”显然不是提升代码可读性的最佳办法*（其实在绝大多数其他情况下都不是）*。我们需要用有意义的名称来代替这些字面量，而`枚举类型（enum）`用在这里最合适不过了。

`enum` 是 Python 自 3.4 版本引入的内置模块，如果你使用的是更早的版本，可以通过 `pip install enum34` 来安装它。下面是使用 enum 的样例代码：

```python
# -*- coding: utf-8 -*-
from enum import IntEnum

class TripSource(IntEnum):
    FROM_WEBSITE = 11
    FROM_IOS_CLIENT = 12


def mark_trip_as_featured(trip):
    if trip.source == TripSource.FROM_WEBSITE:
        do_some_thing(trip)
    elif trip.source == TripSource.FROM_IOS_CLIENT:
        do_some_other_thing(trip)
    ... ...
    return
```

将重复出现的数字字面量定义成枚举类型，不光可以改善代码的可读性，代码出现 Bug 的几率也会降低。

试想一下，如果你在某个分支判断时将 `11` 错打成了 `111` 会怎么样？我们时常会犯这种错，而这类错误在早期特别难被发现。将这些数字字面量全部放入枚举类型中可以比较好的规避这类问题。类似的，将字符串字面量改写成枚举也可以获得同样的好处。

使用枚举类型代替字面量的好处：

- **提升代码可读性**：所有人都不需要记忆某个神奇的数字代表什么
- **提升代码正确性**：减少打错数字或字母产生 bug 的可能性

当然，你完全没有必要把代码里的所有字面量都改成枚举类型。 **代码里出现的字面量，只要在它所处的上下文里面容易理解，就可以使用它。** 比如那些经常作为数字下标出现的 `0` 和 `-1` 就完全没有问题，因为所有人都知道它们的意思。

### 2. 别在裸字符串处理上走太远

什么是“裸字符串处理”？在这篇文章里，它指**只使用基本的加减乘除和循环、配合内置函数/方法来操作字符串，获得我们需要的结果。**

所有人都写过这样的代码。有时候我们需要拼接一大段发给用户的告警信息，有时我们需要构造一大段发送给数据库的 SQL 查询语句，就像下面这样：

```python
def fetch_users(conn, min_level=None, gender=None, has_membership=False, sort_field="created"):
    """获取用户列表
   
    :param int min_level: 要求的最低用户级别，默认为所有级别
    :param int gender: 筛选用户性别，默认为所有性别
    :param int has_membership: 筛选所有会员/非会员用户，默认非会员
    :param str sort_field: 排序字段，默认为按 created "用户创建日期"
    :returns: 列表：[(User ID, User Name), ...]
    """
    # 一种古老的 SQL 拼接技巧，使用 "WHERE 1=1" 来简化字符串拼接操作
    # 区分查询 params 来避免 SQL 注入问题
    statement = "SELECT id, name FROM users WHERE 1=1"
    params = []
    if min_level is not None:
        statement += " AND level >= ?"
        params.append(min_level)
    if gender is not None:
        statement += " AND gender >= ?"
        params.append(gender)
    if has_membership:
        statement += " AND has_membership == true"
    else:
        statement += " AND has_membership == false"
    
    statement += " ORDER BY ?"
    params.append(sort_field)
    return list(conn.execute(statement, params))
```

我们之所以用这种方式拼接出需要的字符串 - *在这里是 SQL 语句* - 是因为这样做简单、直接，符合直觉。但是这样做最大的问题在于：**随着函数逻辑变得更复杂，这段拼接代码会变得容易出错、难以扩展。**事实上，上面这段 Demo 代码也只是仅仅做到**看上去**没有明显的 bug 而已 *（谁知道有没有其他隐藏问题）*。

其实，对于 SQL 语句这种结构化、有规则的字符串，用对象化的方式构建和编辑它才是更好的做法。下面这段代码用 [SQLAlchemy](https://www.sqlalchemy.org/) 模块完成了同样的功能：

```python
def fetch_users_v2(conn, min_level=None, gender=None, has_membership=False, sort_field="created"):
    """获取用户列表
    """
    query = select([users.c.id, users.c.name])
    if min_level is not None:
        query = query.where(users.c.level >= min_level)
    if gender is not None:
        query = query.where(users.c.gender == gender)
    query = query.where(users.c.has_membership == has_membership).order_by(users.c[sort_field])
    return list(conn.execute(query))
```

上面的 `fetch_users_v2` 函数更短也更好维护，而且根本不需要担心 SQL 注入问题。所以，当你的代码中出现复杂的裸字符串处理逻辑时，请试着用下面的方式替代它：

`Q: 目标/源字符串是结构化的，遵循某种格式吗？`

- 是：找找是否已经有开源的对象化模块操作它们，或是自己写一个
    - SQL：SQLAlchemy
    - XML：lxml
    - JSON、YAML ...
- 否：尝试使用模板引擎而不是复杂字符串处理逻辑来达到目的
    - Jinja2
    - Mako
    - Mustache

### 3. 不必预计算字面量表达式

我们的代码里偶尔会出现一些比较复杂的数字，就像下面这样：

```python
def f1(delta_seconds):
    # 如果时间已经过去了超过 11 天，不做任何事
    if delta_seconds > 950400:
        return 
    ...
```

话说在前头，上面的代码没有任何毛病。

首先，我们在小本子（当然，和我一样的聪明人会用 IPython）上算了算：`11天一共包含多少秒？`。然后再把结果 `950400` 这个神奇的数字填进我们的代码里，最后心满意足的在上面补上一行注释：告诉所有人这个神奇的数字是怎么来的。

我想问的是：*“为什么我们不直接把代码写成 `if delta_seconds < 11 * 24 * 3600:` 呢？”*

**“性能”，答案一定会是“性能”**。我们都知道 Python 是一门~~（速度欠佳的）~~解释型语言，所以预先计算出 `950400` 正是因为我们不想让每次对函数 `f1` 的调用都带上这部分的计算开销。不过事实是：**即使我们把代码改成 `if delta_seconds < 11 * 24 * 3600:`，函数也不会多出任何额外的开销。**

Python 代码在执行时会被解释器编译成字节码，而真相就藏在字节码里。让我们用 dis 模块看看：

```python
def f1(delta_seconds):
    if delta_seconds < 11 * 24 * 3600:
        return

import dis
dis.dis(f1)

# dis 执行结果
  5           0 LOAD_FAST                0 (delta_seconds)
              2 LOAD_CONST               1 (950400)
              4 COMPARE_OP               0 (<)
              6 POP_JUMP_IF_FALSE       12

  6           8 LOAD_CONST               0 (None)
             10 RETURN_VALUE
        >>   12 LOAD_CONST               0 (None)
             14 RETURN_VALUE
```

看见上面的 `2 LOAD_CONST               1 (950400)` 了吗？这表示 Python 解释器在将源码编译成成字节码时，会计算 `11 * 24 * 3600` 这段整表达式，并用 `950400` 替换它。

所以，**当我们的代码中需要出现复杂计算的字面量时，请保留整个算式吧。它对性能没有任何影响，而且会增加代码的可读性。**

> Hint：Python 解释器除了会预计算数值字面量表达式以外，还会对字符串、列表做类似的操作。一切都是为了性能。谁让你们老吐槽 Python 慢呢？

## 实用技巧

### 1. 布尔值其实也是“数字”

Python 里的两个布尔值 `True` 和 `False` 在绝大多数情况下都可以直接等价于 `1`  和 `0` 两个整数来使用，就像这样：

```python
>>> True + 1
2
>>> 1 / False
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ZeroDivisionError: division by zero
```

那么记住这点有什么用呢？首先，它们可以配合 `sum` 函数在需要计算总数时简化操作：

```python
>>> l = [1, 2, 4, 5, 7]
>>> sum(i % 2 == 0 for i in l)
2
```

此外，如果将某个布尔值表达式作为列表的下标使用，可以实现类似三元表达式的目的：

```python
# 类似的三元表达式："Javascript" if 2 > 1 else "Python"
>>> ["Python", "Javascript"][2 > 1]
'Javascript'
```

### 2. 改善超长字符串的可读性

单行代码的长度不宜太长。比如 PEP8 里就建议每行字符数不得超过 **79**。现实世界里，大部分人遵循的单行最大字符数在 79 到 119 之间。如果只是代码，这样的要求是比较容易达到的，但假设代码里需要出现一段超长的字符串呢？

这时，除了使用斜杠 `\` 和加号 `+` 将长字符串拆分为好几段以外，还有一种更简单的办法：**使用括号将长字符串包起来，然后就可以随意折行了**：

```python
def main():
    logger.info(("There is something really bad happened during the process. "
                 "Please contact your administrator."))
```

#### 当多级缩进里出现多行字符串时

日常编码时，还有一种比较麻烦的情况。就是需要在已经有缩进层级的代码里，插入多行字符串字面量。因为多行字符串不能包含当前的缩进空格，所以，我们需要把代码写成这样：

```python
def main():
    if user.is_active:
        message = """Welcome, today's movie list:
- Jaw (1975)
- The Shining (1980)
- Saw (2004)"""
```

但是这样写会破坏整段代码的缩进视觉效果，显得非常突兀。要改善它有很多种办法，比如我们可以把这段多行字符串作为变量提取到模块的最外层。不过，如果在你的代码逻辑里更适合用字面量的话，你也可以用标准库 `textwrap` 来解决这个问题：

```
from textwrap import dedent

def main():
    if user.is_active:
        # dedent 将会缩进掉整段文字最左边的空字符串
        message = dedent("""\
            Welcome, today's movie list:
            - Jaw (1975)
            - The Shining (1980)
            - Saw (2004)""")
```

#### 大数字也可以变得更加可读

> 该小节内容由 [@laixintao](https://github.com/laixintao) 提供。

对那些特别大的数字，可以通过在中间添加下划线来提高可读性
([PEP515](https://www.python.org/dev/peps/pep-0515/)，需要 Python3.6+)。

比如：

```
>>> 10_000_000.0  # 以“千”为单位划分数字
10000000.0
>>> 0xCAFE_F00D  # 16进制数字同样有效，4个一组更易读
3405705229
>>> 0b_0011_1111_0100_1110  # 二进制也有效
16206
>>> int('0b_1111_0000', 2)  # 处理字符串的时候也会正确处理下划线
240
```

### 3. 别忘了那些 “r” 开头的内建字符串函数

Python 的字符串有着非常多实用的内建方法，最常用的有 `.strip()`、`.split()` 等。这些内建方法里的大多数，处理起来的顺序都是从左往右。但是其中也包含了部分以 `r` 打头的**从右至左处理**的镜像方法。在处理特定逻辑时，使用它们可以让你事半功倍。

假设我们需要解析一些访问日志，日志格式为："{user_agent}" {content_length}：

    >>> log_line = '"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36" 47632'


如果使用 `.split()` 将日志拆分为 `(user_agent, content_length) `，我们需要这么写：

```python
>>> l = log_line.split()
>>> " ".join(l[:-1]), l[-1]
('"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"', '47632')
```

但是如果使用 `.rsplit()` 的话，处理逻辑就更直接了：

```python
>>> log_line.rsplit(None, 1)
['"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"', '47632']
```


### 4. 使用“无穷大” float("inf")

如果有人问你：*“Python 里什么数字最大/最小？”*。你应该怎么回答？有这样的东西存在吗？

答案是：“有的，它们就是：`float("inf")` 和 `float("-inf")`”。它们俩分别对应着数学世界里的正负无穷大。当它们和任意数值进行比较时，满足这样的规律：`float("-inf") < 任意数值 < float("inf")`。

因为它们有着这样的特点，我们可以在某些场景用上它们：

```python
# A. 根据年龄升序排序，没有提供年龄放在最后边
>>> users = {"tom": 19, "jenny": 13, "jack": None, "andrew": 43}
>>> sorted(users.keys(), key=lambda user: users.get(user) or float('inf'))
['jenny', 'tom', 'andrew', 'jack']

# B. 作为循环初始值，简化第一次判断逻辑
>>> max_num = float('-inf')
>>> # 找到列表中最大的数字
>>> for i in [23, 71, 3, 21, 8]:
...:    if i > max_num:
...:         max_num = i
...:
>>> max_num
71
```

## 常见误区

### 1. “value += 1” 并非线程安全

当我们编写多线程程序时，经常需要处理复杂的共享变量和竞态等问题。

“线程安全”，通常被用来形容 **某个行为或者某类数据结构，可以在多线程环境下被共享使用并产生预期内的结果。**一个典型的满足“线程安全”的模块就是 [queue 队列模块](https://docs.python.org/3/library/queue.html)。

而我们常做的 `value += 1` 操作，很容易被想当然的认为是“线程安全”的。因为它看上去就是一个原子操作 *（指一个最小的操作单位，执行途中不会插入任何其他操作）*。然而真相并非如此，虽然从 Python 代码上来看，`value += 1` 这个操作像是原子的。但它最终被 Python 解释器执行的时候，早就不再 *“原子”* 了。

我们可以用前面提到的 `dis` 模块来验证一下：

```
def incr(value):
    value += 1


# 使用 dis 模块查看字节码
import dis

dis.dis(incr)
      0 LOAD_FAST                0 (value)
      2 LOAD_CONST               1 (1)
      4 INPLACE_ADD
      6 STORE_FAST               0 (value)
      8 LOAD_CONST               0 (None)
     10 RETURN_VALUE
```

在上面输出结果中，可以看到这个简单的累加语句，会被编译成包括取值和保存在内的好几个不同步骤，而在多线程环境下，任意一个其他线程都有可能在其中某个步骤切入进来，阻碍你获得正确的结果。

**因此，请不要凭借自己的直觉来判断某个行为是否“线程安全”，不然等程序在高并发环境下出现奇怪的 bug 时，你将为自己的直觉付出惨痛的代价。**

### 2. 字符串拼接并不慢

我刚接触 Python 不久时，在某个网站看到这样一个说法： *“Python 里的字符串是不可变的，所以每一次对字符串进行拼接都会生成一个新对象，导致新的内存分配，效率非常低”。* 我对此深信不疑。

所以，一直以来，我尽量都在避免使用 `+=` 的方式去拼接字符串，而是用 `"".join(str_list)` 之类的方式来替代。

但是，在某个偶然的机会下，我对 Python 的字符串拼接做了一次简单的性能测试后发现： **Python 的字符串拼接根本就不慢！** 在查阅了一些资料后，最终发现了真相。

Python 的字符串拼接在 2.2 以及之前的版本确实很慢，和我最早看到的说法行为一致。但是因为这个操作太常用了，所以之后的版本里专门针对它做了性能优化。大大提升了执行效率。

如今使用 `+=` 的方式来拼接字符串，效率已经非常接近 `"".join(str_list)` 了。所以，该拼接时就拼接吧，不必担心任何性能问题。

> Hint: 如果你想了解更详细的相关内容，可以读一下这篇文章：[Python - Efficient String Concatenation in Python (2016 edition) - smcl](http://blog.mclemon.io/python-efficient-string-concatenation-in-python-2016-edition)

## 结语

以上就是『Python 工匠』系列文章的第三篇，内容比较零碎。由于篇幅原因，一些常用的操作比如字符串格式化等，文章里并没有涵盖到。以后有机会再写吧。

让我们最后再总结一下要点：

- 编写代码时，请考虑阅读者的感受，不要出现太多神奇的字面量
- 当操作结构化字符串时，使用对象化模块比直接处理更有优势
- dis 模块非常有用，请多多使用它验证你的猜测
- 多线程环境下的编码非常复杂，要足够谨慎，不要相信自己的直觉
- Python 语言的更新非常快，不要被别人的经验所左右

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【4.容器的门道】](4-mastering-container-types.md)

[<<<上一篇【2.编写条件分支代码的技巧】](2-if-else-block-secrets.md)


