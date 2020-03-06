# Python 工匠：善用变量来改善代码质量

## 『Python 工匠』是什么？

我一直觉得编程某种意义上是一门『手艺』，因为优雅而高效的代码，就如同完美的手工艺品一样让人赏心悦目。

在雕琢代码的过程中，有大工程：比如应该用什么架构、哪种设计模式。也有更多的小细节，比如何时使用异常（Exceptions）、或怎么给变量起名。那些真正优秀的代码，正是由无数优秀的细节造就的。

『Python 工匠』这个系列文章，是我的一次小小尝试。它专注于分享 Python 编程中的一些偏**『小』**的东西。希望能够帮到每一位编程路上的匠人。

> 这是 “Python 工匠”系列的第 1 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

## 变量和代码质量

作为『Python 工匠』系列文章的第一篇，我想先谈谈 『变量（Variables）』。因为如何定义和使用变量，一直都是学习任何一门编程语言最先要掌握的技能之一。

变量用的好或不好，和代码质量有着非常重要的联系。在关于变量的诸多问题中，为变量起一个好名字尤其重要。

### 内容目录

* [如何为变量起名](#如何为变量起名)
    * [1. 变量名要有描述性，不能太宽泛](#1-变量名要有描述性不能太宽泛)
    * [2. 变量名最好让人能猜出类型](#2-变量名最好让人能猜出类型)
        * [『什么样的名字会被当成 bool 类型？』](#什么样的名字会被当成-bool-类型)
        * [『什么样的名字会被当成 int/float 类型？』](#什么样的名字会被当成-intfloat-类型)
        * [其他类型](#其他类型)
    * [3. 适当使用『匈牙利命名法』](#3-适当使用匈牙利命名法)
    * [4. 变量名尽量短，但是绝对不要太短](#4-变量名尽量短但是绝对不要太短)
        * [使用短名字的例外情况](#使用短名字的例外情况)
    * [5. 其他注意事项](#5-其他注意事项)
* [更好的使用变量](#更好的使用变量)
    * [1. 保持一致性](#1-保持一致性)
    * [2. 尽量不要用 globals()/locals()](#2-尽量不要用-globalslocals)
    * [3. 变量定义尽量靠近使用](#3-变量定义尽量靠近使用)
    * [4. 合理使用 namedtuple/dict 来让函数返回多个值](#4-合理使用-namedtupledict-来让函数返回多个值)
    * [5. 控制单个函数内的变量数量](#5-控制单个函数内的变量数量)
    * [6. 及时删掉那些没用的变量](#6-及时删掉那些没用的变量)
    * [7. 能不定义变量就不定义](#7-能不定义变量就不定义)
* [结语](#结语)

## 如何为变量起名

在计算机科学领域，有一句著名的格言（俏皮话）：

> There are only two hard things in Computer Science: cache invalidation and naming things.
> 在计算机科学领域只有两件难事：缓存过期 和 给东西起名字
> 
> -- Phil Karlton

第一个『缓存过期问题』的难度不用多说，任何用过缓存的人都会懂。至于第二个『给东西起名字』这事的难度，我也是深有体会。在我的职业生涯里，度过的最为黑暗的下午之一，就是坐在显示器前抓耳挠腮为一个新项目起一个合适的名字。

编程时起的最多的名字，还数各种变量。给变量起一个好名字很重要，**因为好的变量命名可以极大提高代码的整体可读性。**

下面几点，是我总结的为变量起名时，最好遵守的基本原则。

### 1. 变量名要有描述性，不能太宽泛

在**可接受的长度范围内**，变量名能把它所指向的内容描述的越精确越好。所以，尽量不要用那些过于宽泛的词来作为你的变量名：

- **BAD**: `day`, `host`, `cards`, `temp`
- **GOOD**:  `day_of_week`, `hosts_to_reboot`, `expired_cards`

### 2. 变量名最好让人能猜出类型

所有学习 Python 的人都知道，Python 是一门动态类型语言，它（至少在 [PEP 484](https://www.python.org/dev/peps/pep-0484/) 出现前）没有变量类型声明。所以当你看到一个变量时，除了通过上下文猜测，没法轻易知道它是什么类型。

不过，人们对于变量名和变量类型的关系，通常会有一些直觉上的约定，我把它们总结在了下面。

#### 『什么样的名字会被当成 bool 类型？』

布尔类型变量的最大特点是：它只存在两个可能的值**『是』** 或 **『不是』**。所以，用 `is`、`has` 等非黑即白的词修饰的变量名，会是个不错的选择。原则就是：**让读到变量名的人觉得这个变量只会有『是』或『不是』两种值**。

下面是几个不错的示例：

- `is_superuser`：『是否超级用户』，只会有两种值：是/不是
- `has_error`：『有没有错误』，只会有两种值：有/没有
- `allow_vip`：『是否允许 VIP』，只会有两种值：允许/不允许
- `use_msgpack`：『是否使用 msgpack』，只会有两种值：使用/不使用
- `debug`：『是否开启调试模式』，被当做 bool 主要是因为约定俗成

#### 『什么样的名字会被当成 int/float 类型？』

人们看到和数字相关的名字，都会默认他们是 int/float 类型，下面这些是比较常见的：

- 释义为数字的所有单词，比如：`port（端口号）`、`age（年龄）`、`radius（半径）` 等等
- 使用 _id 结尾的单词，比如：`user_id`、`host_id`
- 使用 length/count 开头或者结尾的单词，比如： `length_of_username`、`max_length`、`users_count`

**注意：**不要使用普通的复数来表示一个 int 类型变量，比如 `apples`、`trips`，最好用 `number_of_apples`、`trips_count` 来替代。

#### 其他类型

对于 str、list、tuple、dict 这些复杂类型，很难有一个统一的规则让我们可以通过名字去猜测变量类型。比如 `headers`，既可能是一个头信息列表，也可能是包含头信息的 dict。

对于这些类型的变量名，最推荐的方式，就是编写规范的文档，在函数和方法的 document string 中，使用 sphinx 格式（[Python 官方文档使用的文档工具](http://www.sphinx-doc.org/en/stable/)）来标注所有变量的类型。 

### 3. 适当使用『匈牙利命名法』

第一次知道『[匈牙利命名法](https://en.wikipedia.org/wiki/Hungarian_notation)』，是在 [Joel on Software 的一篇博文](http://www.joelonsoftware.com/articles/Wrong.html)中。简而言之，匈牙利命名法就是把变量的『类型』缩写，放到变量名的最前面。

关键在于，这里说的变量『类型』，并非指传统意义上的 int/str/list 这种类型，而是指那些和你的代码业务逻辑相关的类型。

比如，在你的代码中有两个变量：`students` 和 `teachers`，他们指向的内容都是一个包含 Person 对象的 list 。使用『匈牙利命名法』后，可以把这两个名字改写成这样：

students -> `pl_students`
teachers -> `pl_teachers`

其中 pl 是 **person list** 的首字母缩写。当变量名被加上前缀后，如果你看到以 `pl_` 打头的变量，就能知道它所指向的值类型了。

很多情况下，使用『匈牙利命名法』是个不错的主意，因为它可以改善你的代码可读性，尤其在那些变量众多、同一类型多次出现时。注意不要滥用就好。

### 4. 变量名尽量短，但是绝对不要太短

在前面，我们提到要让变量名有描述性。如果不给这条原则加上任何限制，那么你很有可能写出这种描述性极强的变量名：`how_much_points_need_for_level2`。如果代码中充斥着这种过长的变量名，对于代码可读性来说是个灾难。

一个好的变量名，长度应该控制在 **两到三个单词左右**。比如上面的名字，可以缩写为 `points_level2`。

**绝大多数情况下，都应该避免使用那些只有一两个字母的短名字**，比如数组索引三剑客 `i`、`j`、`k`，用有明确含义的名字，比如 person_index 来代替它们总是会更好一些。

#### 使用短名字的例外情况

有时，上面的原则也存在一些例外。当一些意义明确但是较长的变量名重复出现时，为了让代码更简洁，使用短名字缩写是完全可以的。但是为了降低理解成本，同一段代码内最好不要使用太多这种短名字。

比如在 Python 中导入模块时，就会经常用到短名字作为别名，像 Django i18n 翻译时常用的 `gettext` 方法通常会被缩写成 `_` 来使用*（from django.utils.translation import ugettext as _）*

### 5. 其他注意事项

其他一些给变量命名的注意事项：

- 同一段代码内不要使用过于相似的变量名，比如同时出现 `users`、`users1`、 `user3` 这种序列
- 不要使用带否定含义的变量名，用 `is_special` 代替 `is_not_normal`

## 更好的使用变量

前面讲了如何为变量取一个好名字，下面我们谈谈在日常使用变量时，应该注意的一些小细节。

### 1. 保持一致性

如果你在一个方法内里面把图片变量叫做 `photo`，在其他的地方就不要把它改成 `image`，这样只会让代码的阅读者困惑：『`image` 和 `photo` 到底是不是同一个东西？』

另外，虽然 Python 是动态类型语言，但那也不意味着你可以用同一个变量名一会表示 str 类型，过会又换成 list。**同一个变量名指代的变量类型，也需要保持一致性。**

### 2. 尽量不要用 globals()/locals()

也许你第一次发现 globals()/locals() 这对内建函数时很兴奋，迫不及待的写下下面这种极端『简洁』的代码：

```python
def render_trip_page(request, user_id, trip_id):
    user = User.objects.get(id=user_id)
    trip = get_object_or_404(Trip, pk=trip_id)
    is_suggested = is_suggested(user, trip)
    # 利用 locals() 节约了三行代码，我是个天才！
    return render(request, 'trip.html', locals())
```

千万不要这么做，这样只会让读到这段代码的人（包括三个月后的你自己）痛恨你，因为他需要记住这个函数内定义的所有变量（想想这个函数增长到两百行会怎么样？），更别提 locals() 还会把一些不必要的变量传递出去。

更何况， [The Zen of Python（Python 之禅）](https://www.python.org/dev/peps/pep-0020/) 说的清清楚楚：**Explicit is better than implicit.（显式优于隐式）**。所以，还是老老实实把代码写成这样吧：

```python
    return render(request, 'trip.html', {
        'user': user,
        'trip': trip,
        'is_suggested': is_suggested
    })
```

### 3. 变量定义尽量靠近使用

这个原则属于老生常谈了。很多人（包括我）在刚开始学习编程时，会有一个习惯。就是把所有的变量定义写在一起，放在函数或方法的最前面。

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

这样做只会让你的代码『看上去很整洁』，但是对提高代码可读性没有任何帮助。

更好的做法是，**让变量定义尽量靠近使用**。那样当你阅读代码时，可以更好的理解代码的逻辑，而不是费劲的去想这个变量到底是什么、哪里定义的？

### 4. 合理使用 namedtuple/dict 来让函数返回多个值

Python 的函数可以返回多个值：

```python
def latlon_to_address(lat, lon):
    return country, province, city

# 利用多返回值一次解包定义多个变量
country, province, city = latlon_to_address(lat, lon)
```

但是，这样的用法会产生一个小问题：如果某一天， `latlon_to_address` 函数需要返回『城区（District）』时怎么办？

如果是上面这种写法，你需要找到所有调用 `latlon_to_address` 的地方，补上多出来的这个变量，否则 *ValueError: too many values to unpack* 就会找上你：

```python
country, province, city, district = latlon_to_address(lat, lon)
# 或者使用 _ 忽略多出来的返回值
country, province, city, _ = latlon_to_address(lat, lon)
```

对于这种可能变动的多返回值函数，使用 namedtuple/dict 会更方便一些。当你新增返回值时，不会对之前的函数调用产生任何破坏性的影响：

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

不过这样做也有坏处，因为代码对变更的兼容性虽然变好了，但是你不能继续用之前 `x, y = f()` 的方式一次解包定义多个变量了。取舍在于你自己。

### 5. 控制单个函数内的变量数量

人脑的能力是有限的，研究表明，人类的短期记忆只能同时记住不超过十个名字。所以，当你的某个函数过长（一般来说，超过一屏的的函数就会被认为有点过长了），包含了太多变量时。请及时把它拆分为多个小函数吧。

### 6. 及时删掉那些没用的变量

这条原则非常简单，也很容易做到。但是如果没有遵守，那它对你的代码质量的打击是毁灭级的。会让阅读你代码的人有一种被愚弄的感觉。

```python
def fancy_func():
    # 读者心理：嗯，这里定义了一个 fancy_vars
    fancy_vars = get_fancy()
    ... ...（一大堆代码过后）

    # 读者心理：这里就结束了？之前的 fancy_vars 去哪了？被猫吃了吗？
    return result
```

所以，请打开 IDE 的智能提示，及时清理掉那些定义了但是没有使用的变量吧。

### 7. 定义临时变量提升可读性

有时，我们的代码里会出现一些复杂的表达式，像下面这样：

```python
# 为所有性别为女性，或者级别大于 3 的活跃用户发放 10000 个金币
if user.is_active and (user.sex == 'female' or user.level > 3):
    user.add_coins(10000)
    return
```

看见 `if` 后面那一长串了吗？有点难读对不对？但是如果我们把它赋值成一个临时变量，
就能给读者一个心理缓冲，提高可读性：

```
# 为所有性别为女性，或者级别大于 3 的活跃用户发放 10000 个金币
user_is_eligible = user.is_active and (user.sex == 'female' or user.level > 3):

if user_is_eligible:
    user.add_coins(10000)
    return
```

定义临时变量可以提高可读性。但有时，把不必要的东西赋值成临时变量反而会让代码显得啰嗦：

```python
def get_best_trip_by_user_id(user_id):

    # 心理活动：『嗯，这个值未来说不定会修改/二次使用』，让我们先把它定义成变量吧！
    user = get_user(user_id)
    trip = get_best_trip(user_id)
    result = {
        'user': user,
        'trip': trip
    }
    return result
```

其实，你所想的『未来』永远不会来，这段代码里的三个临时变量完全可以去掉，变成这样：

```python
def get_best_trip_by_user_id(user_id):
    return {
        'user': get_user(user_id),
        'trip': get_best_trip(user_id)
    }
```

没必要为了那些可能出现的变动，牺牲代码当前的可读性。如果以后有定义变量的需求，那就以后再加吧。

## 结语

碎碎念了一大堆，不知道有多少人能够坚持到最后。变量作为程序语言的重要组成部分，值得我们在定义和使用它时，多花一丁点时间思考一下，那样会让你的代码变得更优秀。

这是『Python 工匠』系列文章的第一篇，不知道看完文章的你，有没有什么想吐槽的？请留言告诉我吧。

[>>>下一篇【2.编写条件分支代码的技巧】](2-if-else-block-secrets.md)

> 文章更新记录：
> 
> - 2018.04.09：根据 @onlyice 的建议，添加了 namedtuple 部分

