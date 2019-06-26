# Python 工匠：让函数返回结果的技巧

## 序言

> 这是 “Python 工匠”系列的第 5 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/03/dominik-scythe-283337-unsplash-w1280.jpg" width="100%" />
</div>

毫无疑问，函数是 Python 语言里最重要的概念之一。在编程时，我们将真实世界里的大问题分解为小问题，然后通过一个个函数交出答案。函数即是重复代码的克星，也是对抗代码复杂度的最佳武器。

如同大部分故事都会有结局，绝大多数函数也都是以**返回结果**作为结束。函数返回结果的手法，决定了调用它时的体验。所以，了解如何优雅的让函数返回结果，是编写好函数的必备知识。

### Python 的函数返回方式

Python 函数通过调用 `return` 语句来返回结果。使用 `return value` 可以返回单个值，用 `return value1, value2` 则能让函数同时返回多个值。

如果一个函数体内没有任何 `return` 语句，那么这个函数的返回值默认为 `None`。除了通过 `return` 语句返回内容，在函数内还可以使用抛出异常*（raise Exception）*的方式来“返回结果”。

接下来，我将列举一些与函数返回相关的常用编程建议。

### 内容目录

* [编程建议](#编程建议)
   * [1. 单个函数不要返回多种类型](#1-单个函数不要返回多种类型)
   * [2. 使用 partial 构造新函数](#2-使用-partial-构造新函数)
   * [3. 抛出异常，而不是返回结果与错误](#3-抛出异常而不是返回结果与错误)
   * [4. 谨慎使用 None 返回值](#4-谨慎使用-none-返回值)
      * [1. 作为操作类函数的默认返回值](#1-作为操作类函数的默认返回值)
      * [2. 作为某些“意料之中”的可能没有的值](#2-作为某些意料之中的可能没有的值)
      * [3. 作为调用失败时代表“错误结果”的值](#3-作为调用失败时代表错误结果的值)
   * [5. 合理使用“空对象模式”](#5-合理使用空对象模式)
   * [6. 使用生成器函数代替返回列表](#6-使用生成器函数代替返回列表)
   * [7. 限制递归的使用](#7-限制递归的使用)
* [总结](#总结)
* [附录](#附录)

## 编程建议

### 1. 单个函数不要返回多种类型

Python 语言非常灵活，我们能用它轻松完成一些在其他语言里很难做到的事情。比如：*让一个函数同时返回不同类型的结果。*从而实现一种看起来非常实用的“多功能函数”。

就像下面这样：

```python
def get_users(user_id=None):
    if user_id is not None:
        return User.get(user_id)
    else:
        return User.filter(is_active=True)


# 返回单个用户
get_users(user_id=1)
# 返回多个用户
get_users()
```

当我们需要获取单个用户时，就传递 `user_id` 参数，否则就不传参数拿到所有活跃用户列表。一切都由一个函数 `get_users` 来搞定。这样的设计似乎很合理。

然而在函数的世界里，以编写具备“多功能”的瑞士军刀型函数为荣不是一件好事。这是因为好的函数一定是 [“单一职责（Single responsibility）”](https://en.wikipedia.org/wiki/Single_responsibility_principle) 的。**单一职责意味着一个函数只做好一件事，目的明确。**这样的函数也更不容易在未来因为需求变更而被修改。

而返回多种类型的函数一定是违反“单一职责”原则的，**好的函数应该总是提供稳定的返回值，把调用方的处理成本降到最低。**像上面的例子，我们应该编写两个独立的函数 `get_user_by_id(user_id)`、`get_active_users()` 来替代。

### 2. 使用 partial 构造新函数

假设这么一个场景，在你的代码里有一个参数很多的函数 `A`，适用性很强。而另一个函数 `B` 则是完全通过调用 `A` 来完成工作，是一种类似快捷方式的存在。

比方在这个例子里， `double` 函数就是完全通过 `multiply` 来完成计算的：

```python
def multiply(x, y):
    return x * y


def double(value):
    # 返回另一个函数调用结果
    return multiply(2, value)
```

对于上面这种场景，我们可以使用 `functools` 模块里的 [`partial()`](https://docs.python.org/3.6/library/functools.html#functools.partial) 函数来简化它。

`partial(func, *args, **kwargs)` 基于传入的函数与可变（位置/关键字）参数来构造一个新函数。**所有对新函数的调用，都会在合并了当前调用参数与构造参数后，代理给原始函数处理。**

利用 `partial` 函数，上面的 `double` 函数定义可以被修改为单行表达式，更简洁也更直接。

```python
import functools

double = functools.partial(multiply, 2)
```

> 建议阅读：[partial 函数官方文档](https://docs.python.org/3.6/library/functools.html#functools.partial)

### 3. 抛出异常，而不是返回结果与错误

我在前面提过，Python 里的函数可以返回多个值。基于这个能力，我们可以编写一类特殊的函数：**同时返回结果与错误信息的函数。**

```python
def create_item(name):
    if len(name) > MAX_LENGTH_OF_NAME:
        return None, 'name of item is too long'
    if len(CURRENT_ITEMS) > MAX_ITEMS_QUOTA:
        return None, 'items is full'
    return Item(name=name), ''


def create_from_input():
    name = input()
    item, err_msg = create_item(name)
    if err_msg:
        print(f'create item failed: {err_msg}')
    else:
        print(f'item<{name}> created')
```

在示例中，`create_item` 函数的作用是创建新的 Item 对象。同时，为了在出错时给调用方提供错误详情，它利用了多返回值特性，把错误信息作为第二个结果返回。

乍看上去，这样的做法很自然。尤其是对那些有 `Go` 语言编程经验的人来说更是如此。但是在 Python 世界里，这并非解决此类问题的最佳办法。因为这种做法会增加调用方进行错误处理的成本，尤其是当很多函数都遵循这个规范而且存在多层调用时。

Python 具备完善的*异常（Exception）*机制，并且在某种程度上鼓励我们使用异常（[官方文档关于 EAFP 的说明](https://docs.python.org/3/glossary.html#term-eafp)）。所以，**使用异常来进行错误流程处理才是更地道的做法。**

引入自定义异常后，上面的代码可以被改写成这样：

```python
class CreateItemError(Exception):
    """创建 Item 失败时抛出的异常"""

def create_item(name):
    """创建一个新的 Item
    
    :raises: 当无法创建时抛出 CreateItemError
    """
    if len(name) > MAX_LENGTH_OF_NAME:
        raise CreateItemError('name of item is too long')
    if len(CURRENT_ITEMS) > MAX_ITEMS_QUOTA:
        raise CreateItemError('items is full')
    return Item(name=name)


def create_for_input():
    name = input()
    try:
        item = create_item(name)
    except CreateItemError as e:
        print(f'create item failed: {err_msg}')
    else:
        print(f'item<{name}> created')

```

使用“抛出异常”替代“返回 (结果, 错误信息)”后，整个错误流程处理乍看上去变化不大，但实际上有着非常多不同，一些细节：

- 新版本函数拥有更稳定的返回值类型，它永远只会返回 `Item` 类型或是抛出异常
- 虽然我在这里鼓励使用异常，但“异常”总是会无法避免的让人 **感到惊讶**，所以，最好在函数文档里说明可能抛出的异常类型
- 异常不同于返回值，它在被捕获前会不断往调用栈上层汇报。所以 `create_item` 的一级调用方完全可以省略异常处理，交由上层处理。这个特点给了我们更多的灵活性，但同时也带来了更大的风险。


> Hint：如何在编程语言里处理错误，是一个至今仍然存在争议的主题。比如像上面不推荐的多返回值方式，正是缺乏异常的 Go 语言中最核心的错误处理机制。另外，即使是异常机制本身，不同编程语言之间也存在着差别。
> 
> 异常，或是不异常，都是由语言设计者进行多方取舍后的结果，更多时候不存在绝对性的优劣之分。**但是，单就 Python 语言而言，使用异常来表达错误无疑是更符合 Python 哲学，更应该受到推崇的。**


### 4. 谨慎使用 None 返回值

`None` 值通常被用来表示**“某个应该存在但是缺失的东西”**，它在 Python 里是独一无二的存在。很多编程语言里都有与 None 类似的设计，比如 JavaScript 里的 `null`、Go 里的 `nil` 等。因为 None 所拥有的独特 *虚无* 气质，它经常被作为函数返回值使用。

当我们使用 None 作为函数返回值时，通常是下面 3 种情况。

#### 1. 作为操作类函数的默认返回值

当某个操作类函数不需要任何返回值时，通常就会返回 None。同时，None 也是不带任何 `return` 语句函数的默认返回值。

对于这种函数，使用 None 是没有任何问题的，标准库里的 `list.append()`、`os.chdir()` 均属此类。

#### 2. 作为某些“意料之中”的可能没有的值

有一些函数，它们的目的通常是去尝试性的做某件事情。视情况不同，最终可能有结果，也可能没有结果。**而对调用方来说，“没有结果”完全是意料之中的事情**。对这类函数来说，使用 None 作为“没结果”时的返回值也是合理的。

在 Python 标准库里，正则表达式模块 `re` 下的 `re.search`、`re.match` 函数均属于此类，这两个函数在可以找到匹配结果时返回 `re.Match` 对象，找不到时则返回 `None`。

#### 3. 作为调用失败时代表“错误结果”的值

有时，`None` 也会经常被我们用来作为函数调用失败时的默认返回值，比如下面这个函数：

```python
def create_user_from_name(username):
    """通过用户名创建一个 User 实例"""
    if validate_username(username):
        return User.from_username(username)
    else:
        return None


user = create_user_from_name(username)
if user:
    user.do_something()
```

当 username 不合法时，函数 `create_user_from_name` 将会返回 None。但在这个场景下，这样做其实并不好。

不过你也许会觉得这个函数完全合情合理，甚至你会觉得它和我们提到的上一个“没有结果”时的用法非常相似。那么如何区分这两种不同情形呢？关键在于：**函数签名（名称与参数）与 None 返回值之间是否存在一种“意料之中”的暗示。**

让我解释一下，每当你让函数返回 None 值时，请**仔细阅读函数名**，然后问自己一个问题：*假如我是该函数的使用者，从这个名字来看，“拿不到任何结果”是否是该函数名称含义里的一部分？*

分别用这两个函数来举例：

- `re.search()`：从函数名来看，`search`，代表着从目标字符串里去**搜索**匹配结果，而搜索行为，一向是可能有也可能没有结果的，所以该函数适合返回 None
- `create_user_from_name()`：从函数名来看，代表基于一个名字来构建用户，并不能读出一种`可能返回、可能不返回`的含义。所以不适合返回 None

对于那些不能从函数名里读出 None 值暗示的函数来说，有两种修改方式。第一种，如果你坚持使用 None 返回值，那么请修改函数的名称。比如可以将函数 `create_user_from_name()` 改名为 `create_user_or_none()`。

第二种方式则更常见的多：用抛出异常*（raise Exception）*来代替 None 返回值。因为，如果返回不了正常结果并非函数意义里的一部分，这就代表着函数出现了*“意料以外的状况”*，而这正是 **Exceptions 异常** 所掌管的领域。

使用异常改写后的例子：

```python
class UnableToCreateUser(Exception):
    """当无法创建用户时抛出"""


def create_user_from_name(username):
    ""通过用户名创建一个 User 实例"
    
    :raises: 当无法创建用户时抛出 UnableToCreateUser
    """
    if validate_username(username):
        return User.from_username(username)
    else:
        raise UnableToCreateUser(f'unable to create user from {username}')


try:
    user = create_user_from_name(username)
except UnableToCreateUser:
    # Error handling
else:
    user.do_something()
```

与 None 返回值相比，抛出异常除了拥有我们在上个场景提到的那些特点外，还有一个额外的优势：**可以在异常信息里提供出现意料之外结果的原因**，这是只返回一个 None 值做不到的。

### 5. 合理使用“空对象模式”

我在前面提到函数可以用 `None` 值或异常来返回错误结果，但这两种方式都有一个共同的缺点。那就是所有需要使用函数返回值的地方，都必须加上一个 `if` 或 `try/except` 防御语句，来判断结果是否正常。

让我们看一个可运行的完整示例：

```python
import decimal


class CreateAccountError(Exception):
    """Unable to create a account error"""


class Account:
    """一个虚拟的银行账号"""

    def __init__(self, username, balance):
        self.username = username
        self.balance = balance

    @classmethod
    def from_string(cls, s):
        """从字符串初始化一个账号"""
        try:
            username, balance = s.split()
            balance = decimal.Decimal(float(balance))
        except ValueError:
            raise CreateAccountError('input must follow pattern "{ACCOUNT_NAME} {BALANCE}"')

        if balance < 0:
            raise CreateAccountError('balance can not be negative')
        return cls(username=username, balance=balance)


def caculate_total_balance(accounts_data):
    """计算所有账号的总余额
    """
    result = 0
    for account_string in accounts_data:
        try:
            user = Account.from_string(account_string)
        except CreateAccountError:
            pass
        else:
            result += user.balance
    return result


accounts_data = [
    'piglei 96.5',
    'cotton 21',
    'invalid_data',
    'roland $invalid_balance',
    'alfred -3',
]

print(caculate_total_balance(accounts_data))
```

在这个例子里，每当我们调用 `Account.from_string` 时，都必须使用 `try/except` 来捕获可能发生的异常。如果项目里需要调用很多次该函数，这部分工作就变得非常繁琐了。针对这种情况，可以使用[“空对象模式（Null object pattern）”](https://en.wikipedia.org/wiki/Null_object_pattern)来改善这个控制流。

Martin Fowler 在他的经典著作[《重构》](https://martinfowler.com/books/refactoring.html) 中用一个章节详细说明过这个模式。简单来说，**就是使用一个符合正常结果接口的“空类型”来替代空值返回/抛出异常，以此来降低调用方处理结果的成本。**

引入“空对象模式”后，上面的示例可以被修改成这样：

```python
class Account:
    # def __init__ 已省略... ...
    
    @classmethod
    def from_string(cls, s):
        """从字符串初始化一个账号

        :returns: 如果输入合法，返回 Account object，否则返回 NullAccount
        """
        try:
            username, balance = s.split()
            balance = decimal.Decimal(float(balance))
        except ValueError:
            return NullAccount()

        if balance < 0:
            return NullAccount()
        return cls(username=username, balance=balance)


class NullAccount:
    username = ''
    balance = 0

    @classmethod
    def from_string(cls, s):
        raise NotImplementedError
```

在新版代码里，我定义了 `NullAccount` 这个新类型，用来作为 `from_string` 失败时的错误结果返回。这样修改后的最大变化体现在 `caculate_total_balance` 部分：

```python
def caculate_total_balance(accounts_data):
    """计算所有账号的总余额
    """
    return sum(Account.from_string(s).balance for s in accounts_data)
```

调整之后，调用方不必再显式使用 try 语句来处理错误，而是可以假设 `Account.from_string` 函数总是会返回一个合法的 Account 对象，从而大大简化整个计算逻辑。

> Hint：在 Python 世界里，“空对象模式”并不少见，比如大名鼎鼎的 Django 框架里的 [AnonymousUser](https://docs.djangoproject.com/en/2.1/ref/contrib/auth/#anonymoususer-object) 就是一个典型的 null object。

### 6. 使用生成器函数代替返回列表

在函数里返回列表特别常见，通常，我们会先初始化一个列表 `results = []`，然后在循环体内使用 `results.append(item)` 函数填充它，最后在函数的末尾返回。

对于这类模式，我们可以用生成器函数来简化它。粗暴点说，就是用 `yield item` 替代 `append` 语句。使用生成器的函数通常更简洁、也更具通用性。

```python
def foo_func(items):
    for item in items:
        # ... 处理 item 后直接使用 yield 返回
        yield item
```

我在 [系列第 4 篇文章“容器的门道”](https://www.zlovezl.cn/articles/mastering-container-types/) 里详细分析过这个模式，更多细节可以访问文章，搜索 “写扩展性更好的代码” 查看。

### 7. 限制递归的使用

当函数返回自身调用时，也就是 `递归` 发生时。递归是一种在特定场景下非常有用的编程技巧，但坏消息是：Python 语言对递归支持的非常有限。

这份“有限的支持”体现在很多方面。首先，Python 语言不支持[“尾递归优化”](https://en.wikipedia.org/wiki/Tail_call)。另外 Python 对最大递归层级数也有着严格的限制。

所以我建议：**尽量少写递归**。如果你想用递归解决问题，先想想它是不是能方便的用循环来替代。如果答案是肯定的，那么就用循环来改写吧。如果迫不得已，一定需要使用递归时，请考虑下面几个点：

- 函数输入数据规模是否稳定，是否一定不会超过 `sys.getrecursionlimit()` 规定的最大层数限制
- 是否可以通过使用类似 [functools.lru_cache](https://docs.python.org/3/library/functools.html#functools.lru_cache) 的缓存工具函数来降低递归层数

## 总结

在这篇文章中，我虚拟了一些与 Python 函数返回有关的场景，并针对每个场景提供了我的优化建议。最后再总结一下要点：

- 让函数拥有稳定的返回值，一个函数只做好一件事
- 使用 `functools.partial` 定义快捷函数
- 抛出异常也是返回结果的一种方式，使用它来替代返回错误信息
- 函数是否适合返回 None，由函数签名的“含义”所决定
- 使用“空对象模式”可以简化调用方的错误处理逻辑
- 多使用生成器函数，尽量用循环替代递归

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【6.异常处理的三个好习惯】](6-three-rituals-of-exceptions-handling.md)

[<<<上一篇【4.容器的门道】](4-mastering-container-types.md)

## 附录

- 题图来源: Dominik Scythe on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：善用变量改善代码质量](https://www.zlovezl.cn/articles/python-using-variables-well/)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：使用数字与字符串的技巧](https://www.zlovezl.cn/articles/tips-on-numbers-and-strings/)



