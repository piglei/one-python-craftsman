# Python 工匠：做一个精通规则的玩家

## 前言

> 这是 “Python 工匠”系列的第 10 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/05/jeshoots-com-632498-unsplash_w1280.jpg" width="100%" />
</div>

编程，其实和玩电子游戏有一些相似之处。你在玩不同游戏前，需要先学习每个游戏的不同规则，只有熟悉和灵活运用游戏规则，才更有可能在游戏中获胜。

而编程也是一样，不同编程语言同样有着不一样的“规则”。大到是否支持面向对象，小到是否可以定义常量，编程语言的规则比绝大多数电子游戏要复杂的多。

当我们编程时，如果直接拿一种语言的经验套用到另外一种语言上，很多时候并不能取得最佳结果。这就好像一个 CS（反恐精英） 高手在不了解规则的情况下去玩 PUBG（绝地求生），虽然他的枪法可能万中无一，但是极有可能在发现第一个敌人前，他就会倒在某个窝在草丛里的敌人的伏击下。

### Python 里的规则

Python 是一门初见简单、深入后愈觉复杂的语言。拿 Python 里最重要的“对象”概念来说，Python 为其定义了多到让你记不全的规则，比如：

- 定义了 `__str__` 方法的对象，就可以使用 `str()` 函数来返回可读名称
- 定义了 `__next__` 和 `__iter__` 方法的对象，就可以被循环迭代
- 定义了 `__bool__` 方法的对象，在进行布尔判断时就会使用自定义的逻辑
- ... ...

**熟悉规则，并让自己的代码适应这些规则，可以帮助我们写出更地道的代码，事半功倍的完成工作。**下面，让我们来看一个有关适应规则的故事。

## 案例：从两份旅游数据中获取人员名单

某日，在一个主打新西兰出境游的旅游公司里，商务同事突然兴冲冲的跑过来找到我，说他从某合作伙伴那里，要到了两份重要的数据：

1. 所有去过“泰国普吉岛”的人员及联系方式
2. 所有去过“新西兰”的人员及联系方式

数据采用了 JSON 格式，如下所示：

```python
# 去过普吉岛的人员数据
users_visited_phuket = [
    {"first_name": "Sirena", "last_name": "Gross", "phone_number": "650-568-0388", "date_visited": "2018-03-14"},
    {"first_name": "James", "last_name": "Ashcraft", "phone_number": "412-334-4380", "date_visited": "2014-09-16"},
    ... ...
]

# 去过新西兰的人员数据
users_visited_nz = [
    {"first_name": "Justin", "last_name": "Malcom", "phone_number": "267-282-1964", "date_visited": "2011-03-13"},
    {"first_name": "Albert", "last_name": "Potter", "phone_number": "702-249-3714", "date_visited": "2013-09-11"},
    ... ...
]
```

每份数据里面都有着`姓`、`名`、`手机号码`、`旅游时间` 四个字段。基于这份数据，商务同学提出了一个*（听上去毫无道理）*的假设：“去过普吉岛的人，应该对去新西兰旅游也很有兴趣。我们需要从这份数据里，找出那些**去过普吉岛但没有去过新西兰的人**，针对性的卖产品给他们。

### 第一次蛮力尝试

有了原始数据和明确的需求，接下来的问题就是如何写代码了。依靠蛮力，我很快就写出了第一个方案：

```python
def find_potential_customers_v1():
    """找到去过普吉岛但是没去过新西兰的人
    """
    for phuket_record in users_visited_phuket:
        is_potential = True
        for nz_record in users_visited_nz:
            if phuket_record['first_name'] == nz_record['first_name'] and \
                    phuket_record['last_name'] == nz_record['last_name'] and \
                    phuket_record['phone_number'] == nz_record['phone_number']:
                is_potential = False
                break

        if is_potential:
            yield phuket_record
```

因为原始数据里没有*“用户 ID”*之类的唯一标示，所以我们只能把“姓名和电话号码完全相同”作为判断是不是同一个人的标准。

`find_potential_customers_v1` 函数通过循环的方式，先遍历所有去过普吉岛的人，然后再遍历新西兰的人，如果在新西兰的记录中找不到完全匹配的记录，就把它当做“潜在客户”返回。

这个函数虽然可以完成任务，但是相信不用我说你也能发现。**它有着非常严重的性能问题。**对于每一条去过普吉岛的记录，我们都需要遍历所有新西兰访问记录，尝试找到匹配。整个算法的时间复杂度是可怕的 `O(n*m)`，如果新西兰的访问条目数很多的话，那么执行它将耗费非常长的时间。

为了优化内层循环性能，我们需要减少线性查找匹配部分的开销。

### 尝试使用集合优化函数

如果你对 Python 有所了解的话，那么你肯定知道，Python 里的字典和集合对象都是基于 [哈希表（Hash Table）](https://en.wikipedia.org/wiki/Hash_table) 实现的。判断一个东西是不是在集合里的平均时间复杂度是 `O(1)`，非常快。

所以，对于上面的函数，我们可以先尝试针对新西兰访问记录初始化一个集合，之后的查找匹配部分就可以变得很快，函数整体时间复杂度就能变为 `O(n+m)`。

让我们看看新的函数：

```python
def find_potential_customers_v2():
    """找到去过普吉岛但是没去过新西兰的人，性能改进版
    """
    # 首先，遍历所有新西兰访问记录，创建查找索引
    nz_records_idx = {
        (rec['first_name'], rec['last_name'], rec['phone_number'])
        for rec in users_visited_nz
    }

    for rec in users_visited_phuket:
        key = (rec['first_name'], rec['last_name'], rec['phone_number'])
        if key not in nz_records_idx:
            yield rec
```

使用了集合对象后，新函数在速度上相比旧版本有了飞跃性的突破。但是，对这个问题的优化并不是到此为止，不然文章标题就应该改成：“如何使用集合提高程序性能” 了。

### 对问题的重新思考

让我们来尝试重新抽象思考一下问题的本质。首先，我们有一份装了很多东西的容器 A*（普吉岛访问记录）*，然后给我们另一个装了很多东西的容器 B*（新西兰访问记录）*，之后定义相等规则：“姓名与电话一致”。最后基于这个相等规则，求 A 和 B 之间的**“差集”**。

如果你对 Python 里的集合不是特别熟悉，我就稍微多介绍一点。假如我们拥有两个集合 A 和 B，那么我们可以直接使用 `A - B` 这样的数学运算表达式来计算二者之间的 **差集**。

```python
>>> a = {1, 3, 5, 7}
>>> b = {3, 5, 8}
# 产生新集合：所有在 a 但是不在 b 里的元素
>>> a - b
{1, 7}
```
 
所以，计算“所有去过普吉岛但没去过新西兰的人”，其实就是一次集合的求差值操作。那么要怎么做，才能把我们的问题套入到集合的游戏规则里去呢?
 
### 利用集合的游戏规则
 
在 Python 中，如果要把某个东西装到集合或字典里，一定要满足一个基本条件：**“这个东西必须是可以被哈希（Hashable）的”** 。什么是 “Hashable”？

举个例子，Python 里面的所有可变对象，比如字典，就 **不是** Hashable 的。当你尝试把字典放入集合中时，会发生这样的错误：

```python
>>> s = set()
>>> s.add({'foo': 'bar'})
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'dict'
```

所以，如果要利用集合解决我们的问题，就首先得定义我们自己的 “Hashable” 对象：`VisitRecord`。而要让一个自定义对象变得 Hashable，唯一要做的事情就是定义对象的 `__hash__` 方法。

```python
class VisitRecord:
    """旅游记录
    """
    def __init__(self, first_name, last_name, phone_number, date_visited):
        self.first_name = first_name
        self.last_name = last_name
        self.phone_number = phone_number
        self.date_visited = date_visited
```

一个好的哈希算法，应该让不同对象之间的值尽可能的唯一，这样可以最大程度减少[“哈希碰撞”](https://en.wikipedia.org/wiki/Collision_(computer_science))发生的概率，默认情况下，所有 Python 对象的哈希值来自它的内存地址。

在这个问题里，我们需要自定义对象的 `__hash__` 方法，让它利用 `（姓，名，电话）`元组作为 `VisitRecord` 类的哈希值来源。

```python
def __hash__(self):
    return hash(
        (self.first_name, self.last_name, self.phone_number)
    )
```

自定义完 `__hash__` 方法后，`VisitRecord` 实例就可以正常的被放入集合中了。但这还不够，为了让前面提到的求差值算法正常工作，我们还需要实现 `__eq__` 特殊方法。

`__eq__` 是 Python 在判断两个对象是否相等时调用的特殊方法。默认情况下，它只有在自己和另一个对象的内存地址完全一致时，才会返回 `True`。但是在这里，我们复用了 `VisitRecord` 对象的哈希值，当二者相等时，就认为它们一样。

```python
def __eq__(self, other):
    # 当两条访问记录的名字与电话号相等时，判定二者相等。
    if isinstance(other, VisitRecord) and hash(other) == hash(self):
        return True
    return False
```

完成了恰当的数据建模后，之后的求差值运算便算是水到渠成了。新版本的函数只需要一行代码就能完成操作：

```python
def find_potential_customers_v3():
    return set(VisitRecord(**r) for r in users_visited_phuket) - \
        set(VisitRecord(**r) for r in users_visited_nz)
```

> Hint：如果你使用的是 Python 2，那么除了 `__eq__` 方法外，你还需要自定义类的 `__ne__`（判断不相等时使用） 方法。

### 使用 dataclass 简化代码

故事到这里并没有结束。在上面的代码里，我们手动定义了自己的 **数据类** `VisitRecord`，实现了 `__init__`、`__eq__` 等初始化方法。但其实还有更简单的做法。

因为定义数据类这种需求在 Python 中实在太常见了，所以在 3.7 版本中，标准库中新增了 [dataclasses](https://docs.python.org/3/library/dataclasses.html) 模块，专门帮你简化这类工作。

如果使用 dataclasses 提供的特性，我们的代码可以最终简化成下面这样：

```python
@dataclass(unsafe_hash=True)
class VisitRecordDC:
    first_name: str
    last_name: str
    phone_number: str
    # 跳过“访问时间”字段，不作为任何对比条件
    date_visited: str = field(hash=False, compare=False)


def find_potential_customers_v4():
    return set(VisitRecordDC(**r) for r in users_visited_phuket) - \
        set(VisitRecordDC(**r) for r in users_visited_nz)
```

不用干任何脏活累活，只要不到十行代码就完成了工作。

### 案例总结

问题解决以后，让我们再做一点小小的总结。在处理这个问题时，我们一共使用了三种方案：

1. 使用普通的两层循环筛选符合规则的结果集
2. 利用哈希表结构（set 对象）创建索引，提升处理效率
3. 将数据转换为自定义对象，利用规则，直接使用集合运算

为什么第三种方式会比前面两种好呢？

首先，第一个方案的性能问题过于明显，所以很快就会被放弃。那么第二个方案呢？仔细想想看，方案二其实并没有什么明显的缺点。甚至和第三个方案相比，因为少了自定义对象的过程，它在性能与内存占用上，甚至有可能会微微强于后者。

但请再思考一下，如果你把方案二的代码换成另外一种语言，比如 Java，它是不是基本可以做到 1:1 的完全翻译？换句话说，**它虽然效率高、代码直接，但是它没有完全利用好 Python 世界提供的规则，最大化的从中受益。**

如果要具体化这个问题里的“规则”，那就是 **“Python 拥有内置结构集合，集合之间可以进行差值等四则运算”** 这个事实本身。匹配规则后编写的方案三代码拥有下面这些优势：

- 为数据建模后，可以更方便的定义其他方法
- 如果需求变更，做反向差值运算、求交集运算都很简单
- 理解集合与 dataclasses 逻辑后，代码远比其他版本更简洁清晰
- 如果要修改相等规则，比如“只拥有相同姓的记录就算作一样”，只需要继承`VisitRecord` 覆盖 `__eq__` 方法即可

## 其他规则如何影响我们

在前面，我们花了很大的篇幅讲了如何利用“集合的规则”来编写事半功倍的代码。除此之外，Python 世界中还有着很多其他规则。如果能熟练掌握这些规则，就可以设计出符合 Python 惯例的 API，让代码更简洁精炼。

下面是两个具体的例子。

### 使用 `__format__` 做对象字符串格式化

如果你的自定义对象需要定义多种字符串表示方式，就像下面这样：

```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def get_simple_display(self):
        return f'{self.name}({self.age})'

    def get_long_display(self):
        return f'{self.name} is {self.age} years old.'


piglei = Student('piglei', '18')
# OUTPUT: piglei(18)
print(piglei.get_simple_display())
# OUTPUT: piglei is 18 years old.
print(piglei.get_long_display())
```

那么除了增加这种 `get_xxx_display()` 额外方法外，你还可以尝试自定义 `Student` 类的 `__format__` 方法，因为那才是将对象变为字符串的标准规则。

```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __format__(self, format_spec):
        if format_spec == 'long':
            return f'{self.name} is {self.age} years old.'
        elif format_spec == 'simple':
            return f'{self.name}({self.age})'
        raise ValueError('invalid format spec')


piglei = Student('piglei', '18')
print('{0:simple}'.format(piglei))
print('{0:long}'.format(piglei))
```

### 使用 `__getitem__` 定义对象切片操作

如果你要设计某个可以装东西的容器类型，那么你很可能会为它定义“是否为空”、“获取第 N 个对象”等方法：

```python
class Events:
    def __init__(self, events):
        self.events = events

    def is_empty(self):
        return not bool(self.events)

    def list_events_by_range(self, start, end):
        return self.events[start:end]

events = Events([
    'computer started',
    'os launched',
    'docker started',
    'os stopped',
])

# 判断是否有内容，打印第二个和第三个对象
if not events.is_empty():
    print(events.list_events_by_range(1, 3))
```

但是，这样并非最好的做法。因为 Python 已经为我们提供了一套对象规则，所以我们不需要像写其他语言的 OO*（面向对象）* 代码那样去自己定义额外方法。我们有更好的选择：

```python

class Events:
    def __init__(self, events):
        self.events = events

    def __len__(self):
        """自定义长度，将会被用来做布尔判断"""
        return len(self.events)

    def __getitem__(self, index):
        """自定义切片方法"""
        # 直接将 slice 切片对象透传给 events 处理
        return self.events[index]

# 判断是否有内容，打印第二个和第三个对象
if events:
    print(events[1:3])
```

新的写法相比旧代码，更能适配进 Python 世界的规则，API 也更为简洁。

关于如何适配规则、写出更好的 Python 代码。Raymond Hettinger 在 PyCon  2015 上有过一次非常精彩的演讲 [“Beyond PEP8 - Best practices for beautiful intelligible code”](https://www.youtube.com/watch?v=wf-BqAjZb8M)。这次演讲长期排在我个人的 *“PyCon 视频 TOP5”*  名单上，如果你还没有看过，我强烈建议你现在就去看一遍 :)

> Hint：更全面的 Python 对象模型规则可以在 [官方文档](https://docs.python.org/3/reference/datamodel.html) 找到，有点难读，但值得一读。

## 总结

Python 世界有着一套非常复杂的规则，这些规则的涵盖范围包括“对象与对象是否相等“、”对象与对象谁大谁小”等等。它们大部分都需要通过重新定义“双下划线方法 `__xxx__`” 去实现。

如果熟悉这些规则，并在日常编码中活用它们，有助于我们更高效的解决问题、设计出更符合 Python 哲学的 API。下面是本文的一些要点总结：

- **永远记得对原始需求做抽象分析，比如问题是否能用集合求差集解决**
- 如果要把对象放入集合，需要自定义对象的 `__hash__` 与 `__eq__` 方法
- `__hash__` 方法决定性能（碰撞出现概率），`__eq__` 决定对象间相等逻辑
- 使用 dataclasses 模块可以让你少写很多代码
- 使用 `__format__` 方法替代自己定义的字符串格式化方法
- 在容器类对象上使用 `__len__`、`__getitem__` 方法，而不是自己实现

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【11.高效操作文件的三个建议】](11-three-tips-on-writing-file-related-codes.md)

[<<<上一篇【9.一个关于模块的小故事】](9-a-story-on-cyclic-imports.md)

## 附录

- 题图来源: Photo by JESHOOTS.COM on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：异常处理的三个好习惯](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


