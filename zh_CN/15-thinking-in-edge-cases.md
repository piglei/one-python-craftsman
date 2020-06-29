# Python 工匠：在边界处思考

## 前言

> 这是 “Python 工匠”系列的第 15 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2020/06/jessica-ruscello-DoSDQvzjeH0-unsplash_w1440.jpg" width="100%" />
</div>

2016 年，Linux 操作系统的创造者 Linus Torvalds 参加了一场[ TED 访谈节目](https://www.ted.com/talks/linus_torvalds_the_mind_behind_linux/transcript?language=en)。整个节目的前半部分，主要是他在讲如何在家光着膀子写出 Linux 的故事，没有涉及太多编程相关的事情。

不过在访谈快结束时，突然出现了一个有趣的环节。主持人向 Linus 提问道：“你曾说过更愿意和那些有着好的 **代码品味** 的人共事，那在你眼里，什么才是好的代码品味？”

为了解释这个问题，Linus 在大屏幕上展示了一份代码。我把其摘抄如下。

```c
remove_list_entry(entry) {
    prev = NULL;
    walk = head;
    
    // 遍历链表
    while (walk != entry) {
        prev = walk;
        walk = walk->next;
    }
    
    // 关键：当要删除时，判断当前位置是否在链表头部进行不同的动作
    if (!prev)
        head = entry->next;
    else
        prev->next = entry->next;
}
```

函数 `remove_list_entry` 的主要功能是通过遍历链表，删除里面的某个成员。但在这份代码中，存在一个 **[边界情况（Edge Case）](https://en.wikipedia.org/wiki/Edge_case)**。

在编程时，“边界情况”是指那些只在极端情景下出现的情况。比如在上面的代码里，当我们要找的元素刚好处于链表头部时，就是一个边界情况。为了处理它，函数在删除前进行了一次 `if / else` 判断。

Linus 认为这条 if 语句是整段代码的“坏味道”来源，写出它的人代码品味不够好 ☹️。那么，一个品味更好的人应该怎么写呢？很快，屏幕上出现了第二份代码。

```c
remove_list_entry(entry) {
    indirect = &head
    
    // 遍历链表过程代码已省略
    
    // 当要删除时，直接进行指针操作删除
    *indirect = entry->next
}
```

在新代码中，`remove_list_entry` 函数利用了 C 语言里的指针特性，把之前的 `if / else` 完全消除了。无论待删除的目标是在链表头部还是中间，函数都能一视同仁的完成删除操作。之前的边界情况消失了。

看到这你是不是在犯嘀咕：*Python 又没有指针，你跟我说这么多指针不指针的干啥？*虽然 Python 没有指针，但我觉得这个例子为我们提供了一个很有趣的主题。那就是 **如何充分利用语言特性，更好的处理编码时的边界情况。**

我认为，好代码在处理边界情况时应该是简洁的、“润物细无声”的。就像上面的例子一样，可以做到让边界情况消融在代码主流程中。在写 Python 时，有不少编码技巧和惯例可以帮我们做到这一点，一块来看看吧。

## 第一课：使用分支还是异常？

今天周末，你计划参加朋友组织的聚餐，临出门时突然想起来最近是雨季。于是你掏出手机打开天气 App，看看今天是不是会下雨。如果下雨，就带上一把伞再出门。

假如把“今天下雨”类比成编程时的 *边界情况*，那“看天气预报 + 带伞”就是我们的边界处理代码。这种 `if 下雨 then 带伞` 的分支式判断，基本是一种来自直觉的思考本能。所以，当我们在编程时发现边界情况时，第一反应往往就是：**“弄个 if 分支把它包起来吧！”**。

比如下面这段代码：

```python
def counter_ap(l):
    """计算列表里面每个元素出现的数量"""
    result = {}
    for key in l:
        # 主流程：累加计数器
        if key in result:
            result[key] += 1
        # **边界情况：当元素第一次出现时，先初始化值为 1**
        else:
            result[key] = 1
    return result

# 执行结果：
print(counter_ap(['apple', 'banana', 'apple']))
{'apple': 2, 'banana': 1}
```

在上面的循环里，代码的主流程是*“对每个 key 的计数器加 1”*。但是，当 result 字典里还没有 `key` 元素时，是不能直接进行累加操作的（会抛出 `KeyError`）。

```python
>>> result = {}
>>> result['foo'] += 1
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
KeyError: 'foo'
```

于是一个边界情况出现了：当元素第一次出现时，我们需要对值进行初始化。

所以，我专门写了一条 `if` 语句去处理这个边界情况。代码简单，无需过多解释。但你可能不知道的是，其实有一个术语来专门描述这种编程风格：**“（LBYL）Look Before You Leap”**。

“LBYL” 这缩写不太好翻译。用大白话讲，就是在进行操作前，先对可能的边界情况进行条件判断。根据结果不同，确定是处理边界情况，还是执行主流程。

如之前所说，使用 “LBYL” 来处理边界情况，几乎是一种直觉式的行为。*“有边界情况，就加上 if 分支”*和*“如果天气预报说下雨，我就带伞出门”*一样，是一种基本不需要过脑子的操作。

而在 LBYL 之外，有着与其形成鲜明对比的另外一种风格：**“EAFP（Easier to Ask for Forgiveness than Permission）”**。

### 获取原谅比许可简单(EAFP)

“EAFP” 通常被翻译成“获取原谅比许可简单”。如果还用下雨举例，那 EAFP 的做法就类似于 *“出门前不看任何天气预报，如果淋雨了，就回家后洗澡吃感冒药 💊”*。

使用 EAFP 风格的代码是这样的：

```python
def counter_af(l):
    result = {}
    for key in l:
        try:
            # 总是直接执行主流程：累加计数器
            result[key] += 1
        except KeyError:
            # 边界情况：当元素第一次出现时会报错 KeyError，此时进行初始化
            result[key] = 1
    return result
```

和 LBYL 相比，EAFP 编程风格更为简单粗暴。它总是直奔主流程而去，把边界情况都放在异常处理 `try except` 块内消化掉。

如果你问我：“这两种编程风格哪个更好？”，我只能说整个 Python 社区对基于异常捕获的“请求原谅（EAFP）”型编程风格有着明显的偏爱。其中的原因有很多。

首先，和许多其他编程语言不同，在 Python 里抛出异常是一个很轻量的操作，即使程序会大量抛出、捕获异常，使用 EAFP 也不会给程序带来额外的负担。

其次，“请求原谅”在性能上通常也更有优势，因为程序总是直奔主流程而去，只有极少数情况下才需要处理边界情况。拿上面的例子来说，第二段代码通常会比第一段更快，因为它不用在每次循环时都做一次额外的成员检查。

> Hint：如果你想了解更多这方面的知识，建议阅读： [Write Cleaner Python: Use Exceptions](https://jeffknupp.com/blog/2013/02/06/write-cleaner-python-use-exceptions/)

所以，每当你想凭直觉写下 `if else` 来处理边界情况时，先考虑下使用 `try` 来捕获异常是不是更合适。毕竟，Pythonista 们总是喜欢“吃感冒药 💊”胜过“看天气预报”。😅

## 当容器内容不存在时

Python 里有很多内建的容器类型，比如字典、列表、集合等等。在进行容器操作时，经常会出现一些边界情况。其中“要访问的内容不存在”，是最为常见的一类：

- 操作字典时，访问的键 `key` 不存在，会抛出 `KeyError` 异常
- 操作列表、元组时，访问的下标 `index` 不存在，会抛出 `IndexError` 异常

对于这类边界情况，除了针对性的捕获对应异常外，还有许多其他处理方式。

### 使用 defaultdict 改写示例

在前面的例子里，我们使用了 `try except` 语句处理了*“key 第一次出现”*这个边界情况。虽然我说过，使用 `try` 的代码比 `if` 更好，但这不代表它就是一份地道的 Python 代码。

为什么？因为如果你想统计列表元素的话，直接用 `collections.defaultdict` 就可以了：

```python
from collections import defaultdict


def counter_by_collections(l):
    result = defaultdict(int)
    for key in l:
        result[key] += 1
    return result
```

这样的代码既不用“获取许可”，也无需“请求原谅”。 整个函数只有一个主流程，代码更清晰、更自然。 

为什么 `defaultdict` 可以让边界情况消失？因为究其根本，之前的代码就是少了针对 *“键不存在”* 时的默认处理逻辑。所以，当我们用 `defaultdict` 声明了如何处理这个边界情况时，原本需要手动判断的部分就消失了。

> Hint：就上面的例子来说，使用 [collections.Counter](https://docs.python.org/3/library/collections.html#collections.Counter) 也能达到同样的目的。

### 使用 setdefault 取值并修改

有时候，我们需要操作字典里的某个值，但它又可能并不存在。比如下面这个例子：

```python
# 往字典的 values 键追加新值，假如不存在，先以列表初始化
try:
    d['values'].append(value)
except KeyError:
    d['values'] = [value]
```

针对这种情况，我们可以使用 **`d.setdefault(key, default=None)`** 方法来简化边界处理逻辑，直接替换上面的异常捕获语句：

```python
# 如果 setdefault 指定的 key（此处为 "values"）不存在，以 [] 初始化，否则返回已存在
# 的值。
d.setdefault('values', []).append(value)
```

> Hint：使用 `defaultdict(list)` 同样可以利索的解决这个问题。

### 使用 dict.pop 删除不存在的键

如果我们要删除字典的某个 `key`，一般会使用 `del` 关键字。但当 `key` 不存在时，删除操作就会抛出 `KeyError` 异常。

所以，想要安全删除某个 `key`，还得加上一段异常捕获逻辑。

```python
try:
    del d[key]
except KeyError:
    # 忽略 key 不存在的情况
    pass
```

但假设只是单纯的想删除某个 `key`，并不关心它是否存在、有没有删成功。使用 `dict.pop(key, default)` 方法就够了。

只要在调用 `dict.pop` 方法时传入默认值，`key` 不存在时就不会抛出异常了。

```python
# 使用 pop 方法，指定 default 值为 None，当 key 不存在时，不会报错
d.pop(key, None)
```

> Hint：严格来说，`pop` 方法的主要用途并不是去删除某个 key，而是 **取出** 某个 key 对应的值。不过我觉得偶尔用它来做删除也无伤大雅。

### 当列表切片越界时

所有人都知道，当你的列表*（或元组）*只有 3 个元素，而你想要访问第 4 个时，解释器会报出 `IndexError` 错误。我们通常称这类错误为*“数组越界”*。

```python
>>> l = [1, 2, 3]
>>> l[2]
3
>>> l[3]
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
IndexError: list index out of range
```

但你可能不知道的是，假如你请求的不是某一个元素，而是一段范围的切片。那么无论你指定的范围是否有效，程序都只会返回一个空列表 `[]`，而不会抛出任何错误：

```python
>>> l = []
>>> l[1000:1001]
[]
```

了解了这点后，你会发现像下面这种边界处理代码根本没有必要：

```python
def sum_list(l, limit):
    """对列表的前 limit 个元素求和
    """
    # 如果 limit 过大，设置为数组长度避免越界
    if limit > len(l):
        limit = len(l)
    return sum(l[:limit])
```

因为做切片不会抛出任何错误，所以不需要判断 limit 是否超出范围，直接做 `sum` 操作即可：

```python
def sum_list(l, limit):
    return sum(l[:limit])
```

利用这个特点，我们还可以简化一些特定的边界处理逻辑。比如安全删除列表的某个元素：

```
# 使用异常捕获安全删除列表的第 5 个元素
try:
    l.pop(5)
except IndexError:
    pass

# 删除从 5 开始的长度为 1 的切片，不需要捕获任何异常
del l[5:6]
```

## 好用又危险的 “or” 操作符

`or` 是一个几乎在所有编程语言里都有的操作符，它在 Python 里通常被用来和 `and` 一起做布尔值逻辑运算。比如:

```python
>>> False or True
True
```

但 `or` 还有一个有趣的特点是短路求值，比如在下面的例子里，`1 / 0` 永远不会被执行*（也就意味着不会抛出 ZeroDivisionError）*：

```python
>>> True or (1 / 0)
True
```

在很多场景下，我们可以利用 `or` 的特点来简化一些边界处理逻辑。看看下面这个例子：

```python
context = {}
# 仅当 extra_context 不为 None 时，将其追加进 context 中
if extra_context:
    context.update(extra_context)
```

在这段代码里，`extra_context` 的值一般情况下会是一个字典，但有时也可能是 `None`。所以我加了一个条件判断语句，当它的值不为 `None` 时才做 `.update` 操作。

如果使用 `or` 操作符，我们可以让上面的语句更简练：

```
context.update(extra_context or {})
```

因为 `a or b or c or ...` 这样的表达式，会返回这些变量里第一个布尔值为真的值，直到最后一个为止。所以 `extra_context or {}` 在 `extra_context` 为 `None` 时其实就等于 `{}`。因此之前的条件判断就可以被简化成一个 `or` 表达式了。

使用 `a or b` 来表示*“ a 为空时用 b 代替”*，这种写法一点也不新鲜。你在各种编程语、各类框架源码源码里都能发现它的影子。但在这个写法下，其实也藏有一个陷阱。

因为 `or` 操作计算的是变量的布尔真假值。所以，不光是 `None`，所有的 0、[]、{}、set() 以及其他所有会被判断为布尔假的东西，都会在 `or` 运算中被忽略。

```python
# 所有的 0、空列表、空字符串等，都是布尔假值
>>> bool(None), bool(0), bool([]), bool({}), bool(''), bool(set())
(False, False, False, False, False, False)
```

如果忘记了 `or` 的这个特点，可能会碰到一些很奇怪的问题。比如这段代码：

```python
timeout = config.timeout or 60
```

虽然上面代码的目的，是想要判断当 `config.timeout` 为 `None` 时使用 60 做默认值。但假如 `config.timeout` 的值被主动配置成了 `0` 秒，`timeout` 也会因为上面的 `0 or 60 = 60` 运算被重新赋值为 60。正确的配置因此被忽略掉了。

所以，有时使用 `if` 来进行精确的边界处理会更稳妥一些：

```python
if config.timeout is None:
    timeout = 60
```

## 不要手动去做数据校验

无数前辈的经验告诉我们：*“不要信任任何用户输入”*。这意味着所有存在用户输入的地方，都必须对其进行校验。那些无效、危险的用户输入值，就是需要我们处理的边界情况。

假如我在写一个命令行小程序，需要让用户输入一个 0-100 范围的数字。要是用户的输入无效，就要求其重新输入。

程序大概长这样：

```python
def input_a_number():
    """要求用户输入一个 0-100 的数字，如果无效则重新输入
    """
    while True:
        number = input('Please input a number (0-100): ')

        #  此处往下的三条 if 语句都是输入值的边界校验代码
        if not number:
            print('Input can not be empty!')
            continue
        if not number.isdigit():
            print('Your input is not a valid number!')
            continue
        if not (0 <= int(number) <= 100):
            print('Please input a number between 0 and 100!')
            continue

        number = int(number)
        break

    print(f'Your number is {number}')
```

执行效果如下：

```python
Please input a number (0-100):
Input can not be empty!
Please input a number (0-100): foo
Your input is not a valid number!
Please input a number (0-100): 65
Your number is 65
```

这个函数一共有 14 行有效代码。其中有 3 段 if 共 9 行代码，都是用于校验的边界值检查代码。也许你觉得这样的检查很正常，但请想象一下，假如需要校验的输入不止一个、校验逻辑也比这个复杂怎么办？那样的话，**这些边界值检查代码就会变得又臭又长。**

如何改进这些代码呢？把它们抽离出去，作为一个校验函数和核心逻辑隔离开是个不错的办法。但更重要的在于，要把*“输入数据校验”*作为一个独立的职责与领域，用更恰当的模块来完成这项工作。

在数据校验这块，[pydantic](https://pydantic-docs.helpmanual.io/) 模块是一个不错的选择。如果用它来做校验，代码可以被简化成这样:

```python
from pydantic import BaseModel, conint, ValidationError


class NumberInput(BaseModel):
    # 使用类型注解 conint 定义 number 属性的取值范围
    number: conint(ge=0, le=100)


def input_a_number_with_pydantic():
    while True:
        number = input('Please input a number (0-100): ')

        # 实例化为 pydantic 模型，捕获校验错误异常
        try:
            number_input = NumberInput(number=number)
        except ValidationError as e:
            print(e)
            continue

        number = number_input.number
        break

    print(f'Your number is {number}')
```

在日常编码时，我们应该尽量避免去手动校验数据。而是应该使用*（或者自己实现）*合适的第三方校验模块，把这部分边界处理工作抽象出去，简化主流程代码。

> Hint: 假如你在开发 Web 应用，那么数据校验部分通常来说都挺容易。比如 Django 框架有自己的 forms 模块，Flask 也可以使用 WTForms 来进行数据校验。

## 不要忘记做数学计算

很多年前刚接触 Web 开发时，我想学着用 JavaScript 来实现一个简单的文字跑马灯动画。如果你不知道啥是“跑马灯”，我可以稍微解释一下。“跑马灯”就是让一段文字从页面左边往右边不断循环滚动，十几年前的网站特别流行这个。😬

我记得里面有一段逻辑是这样的：*控制文字不断往右边移动，当横坐标超过页面宽度时，重置坐标后继续。*我当时写出来的代码，翻译成 Python 大概是这样：

```python
while True:
    if element.position_x > page_width:
        # 边界情况：当对象位置超过页面宽度时，重置位置到最左边
        element.position_x -= page_width
        
    # 元素向右边滚动一个单位宽度
    element.position_x += width_unit
```

看上去还不错对不对？我刚写完它时也是这么认为的。但后来有一天，我重新看到它时，才发现其中的古怪之处。

在上面的代码里，我需要在主循环里保证 “element.position_x 不会超过页面宽度 page_width”。所以我写了一个 if 来处理当 `position_x` 超过页面宽度的情况。

但如果是要保证某个累加的数字*（position_x）*不超过另一个数字*（page_width）*，直接用 `%` 做取模运算不就好了吗？

```python
while True:
    # 使用 % page_width 控制不要超过页面宽度
    element.position_x = (element.position_x + width_unit) % page_width
```

这样写的话，代码里的边界情况就连着那行 `if` 语句一起消失了。

和取模运算类似的操作还有很多，比如 `abs()`、`math.floor()` 等等。我们应该记住，不要写出 `if value < 0: value = -value` 这种“边界判断代码”，直接使用 `abs(value)` 就好，不要重新发明绝对值运算。

## 总结

“边界情况（Edge cases）”是我们在日常编码时的老朋友。但它不怎么招人喜欢，毕竟，我们都希望自己的代码只有一条主流程贯穿始终，不需要太多的条件判断、异常捕获。

但边界情况同时又是无法避免的，只要有代码，边界情况就会存在。所以，如果能更好的处理它们，我们的代码就可以变得更清晰易读。

除了上面介绍的这些思路外，还有很多东西都可以帮助我们处理边界情况，比如利用面向对象的多态特性、使用 [空对象模式](https://github.com/piglei/one-python-craftsman/blob/master/zh_CN/5-function-returning-tips.md#5-%E5%90%88%E7%90%86%E4%BD%BF%E7%94%A8%E7%A9%BA%E5%AF%B9%E8%B1%A1%E6%A8%A1%E5%BC%8F) 等等。

最后再总结一下：

- 使用条件判断和异常捕获都可以用来处理边界情况
- 在 Python 里，我们更倾向于使用基于异常捕获的 EAFP 风格
- 使用 defaultdict / setdefault / pop 可以巧妙的处理当键不存在时的边界情况
- 对列表进行不存在的范围切片不会抛出异常
- 使用 `or` 可以简化默认值边界处理逻辑，但也要注意不要掉入陷阱
- 不要手动去做数据校验，使用 `pydantic` 或其他的数据校验模块
- 利用取模、绝对值计算等方式，可以简化一些特定的边界处理逻辑

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[<<<上一篇【14.写好面向对象代码的原则（下）】](14-write-solid-python-codes-part-3.md)

> 为了避免内容重复，在系列第 4 篇“容器的门道”里出现的 EAPF 相关内容会被删除，并入到本文中。

## 附录

- 题图来源: Photo by Jessica Ruscello on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：写好面向对象代码的原则（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：让函数返回结果的技巧](https://www.zlovezl.cn/articles/function-returning-tips/)


