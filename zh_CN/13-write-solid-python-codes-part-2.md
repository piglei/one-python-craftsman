# Python 工匠：写好面向对象代码的原则（中）

## 前言

> 这是 “Python 工匠”系列的第 13 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/11/neonbrand-CXDw96Oy-Yw-unsplash_w1280.jpg" width="100%" />
</div>

在 [上一篇文章](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/) 里，我用一个虚拟小项目作为例子，讲解了“SOLID”设计原则中的前两位成员：S*（单一职责原则）*与 O*（开放-关闭原则）*。

在这篇文章中，我将继续介绍 SOLID 原则的第三位成员：**L（里氏替换原则）**。

## 里氏替换原则与继承

在开始前，我觉得有必要先提一下 [继承（Inheritance）](https://en.wikipedia.org/wiki/Inheritance)。因为和前面两条非常抽象的原则不同，“里氏替换原则”是一条非常具体的，和类继承有关的原则。

在 OOP 世界里，继承算是一个非常特殊的存在，它有点像一把无坚不摧的双刃剑，强大且危险。合理使用继承，可以大大减少类与类之间的重复代码，让程序事半功倍，而不当的继承关系，则会让类与类之间建立起错误的强耦合，带来大片难以理解和维护的代码。

正是因为这样，对继承的态度也可以大致分为两类。大多数人认为，继承和多态、封装等特性一样，属于面向对象编程的几大核心特征之一。而同时有另一部分人觉得，继承带来的 [坏处远比好处多](https://www.javaworld.com/article/2073649/why-extends-is-evil.html)。甚至在 Go 这门相对年轻的编程语言里，设计者直接去掉了继承，提倡完全使用组合来替代。

从我个人的编程经验来看，继承确实极易被误用。要设计出合理的继承关系，是一件需要深思熟虑的困难事儿。不过幸运的是，在这方面，"里氏替换原则"*(后简称 L 原则)* 为我们提供了非常好的指导意义。

让我们来看看它的内容。

## L：里氏替换原则

同前面的 S 与 O 两个原则的命名方式不同，里氏替换原则*（Liskov Substitution Principle）*是直接用它的发明者 [Barbara Liskov](https://en.wikipedia.org/wiki/Barbara_Liskov) 命名的，原文看起来像一个复杂的数学公式：

> Let q(x) be a property provable about objects of x of type T. Then q(y) should be provable for objects y of type S where S is a subtype of T.
> - 出处: [Liskov substitution principle - Wikipedia](https://en.wikipedia.org/wiki/Liskov_substitution_principle)

如果把它比较通俗的翻译过来，大概是这样：**当你使用继承时，子类（派生类）对象应该可以在程序中替代父类（基类）对象使用，而不破坏程序原本的功能。**

光说有点难理解，让我们用代码来看看一个在 Python 中违反 Liskov 原则的例子。

## 一个违反 L 原则的样例

假设我们在为一个 Web 站点设计用户模型。这个站点的用户分为两类：普通用户和站点管理员。所以在代码里，我们定义了两个用户类：普通用户类 `User` 和管理员类 `Admin`。

```python
class User(Model):
    """普通用户模型类
    """
    def __init__(self, username: str):
        self.username = username

    def deactivate(self):
        """停用当前用户
        """
        self.is_active = True
        self.save()

class Admin(User):
    """管理员用户类
    """
    def deactivate(self):
        # 管理员用户不允许被停用
        raise RuntimeError('admin can not be deactivated!')
```

因为普通用户的绝大多数操作在管理员上都适用，所以我们把 `Admin` 类设计成了继承自 `User` 类的子类。不过在“停用”操作方面，管理员和普通用户之间又有所区别： **普通用户可以被停用，但管理员不行。**

于是在 `Admin` 类里，我们重写了 `deactivate` 方法，使其抛出一个 `RuntimeError` 异常，让管理员对象无法被停用。

子类继承父类，然后重写父类的少量行为，这看上去正是类继承的典型用法。但不幸的是，这段代码违反了“里氏替换原则”。具体是怎么回事呢？让我们来看看。

### 不当继承关系如何违反 L 原则

现在，假设我们需要写一个新函数，它可以同时接受多个用户对象作为参数，批量将它们停用。代码如下：

```python
def deactivate_users(users: Iterable[User]):
    """批量停用多个用户
    """
    for user in users:
        user.deactivate()
```

很明显，上面的代码是有问题的。因为 `deactivate_users` 函数在参数注解里写到，它接受一切 **可被迭代的 User 对象**，那么管理员 `Admin` 是不是 `User` 对象？当然是，因为它是继承自 `User` 类的子类。

但是，如果你真的把 `[User("foo"), Admin("bar_admin")]` 这样的用户列表传到 `deactivate_users` 函数里，程序立马就会抛出 `RuntimeError` 异常，因为管理员对象 `Admin("bar_admin")` 压根不支持停用操作。

在 `deactivate_users` 函数看来，子类 `Admin` 无法随意替换父类 `User` 使用，所以现在的代码是不符合 L 原则的。

### 一个简单但错误的解决办法

要修复上面的函数，最直接的办法就是在函数内部增加一个额外的类型判断：

```python
def deactivate_users(users: Iterable[User]):
    """批量停用多个用户
    """
    for user in users:
        # 管理员用户不支持 deactivate 方法，跳过
        if isinstance(user, Admin):
            logger.info(f'skip deactivating admin user {user.username}')
            continue

        user.deactivate()
```

在修改版的 `deactivate_users` 函数里，如果它在循环时恰好发现某个用户是 `Admin` 类，就跳过这次操作。这样它就能正确处理那些混合了管理员的用户列表了。

但是，这样修改的缺点是显而易见的。因为虽然到目前为止，只有 `Admin` 类型的用户不允许被停用。但是，**谁能保证未来不会出现其他不能被停用的用户类型呢？**比如：

- 公司员工不允许被停用
- VIP 用户不允许被停用
- 等等(... ...)

而当这些新需求在未来不断出现时，我们就需要重复的修改 `deactivate_users` 函数，来不断适配这些无法被停用的新用户类型。

```python
def deactivate_users(users: Iterable[User]):
    for user in users:
        # 在类型判断语句不断追加新用户类型
        if isinstance(user, (Admin, VIPUser, Staff)):
            ... ...
```

现在，让我们再回忆一下前面的 SOLID 第二原则：**“开放-关闭原则”**。这条原则认为：好的代码应该对扩展开发，**对修改关闭**。而上面的函数很明显不符合这条原则。

到这里你会发现，**SOLID 里的每条原则并非完全独立的个体，它们之间其实互有联系。**比如，在这个例子里，我们先是违反了“里氏替换原则”，然后我们使用了错误的修复方式：*增加类型判断*。之后发现，这样的代码同样也无法符合“开放-关闭原则”。

### 正确的修改办法

既然为函数增加类型判断无法让代码变得更好，那我们就应该从别的方面入手。

“里氏替换原则”提到，**子类*（Admin）*应该可以随意替换它的父类*（User）*，而不破坏程序*（deactivate_users）*本身的功能。**我们试过直接修改类的使用者来遵守这条原则，但是失败了。所以这次，让我们试着从源头上解决问题：重新设计类之间的继承关系。

具体点来说，子类不能只是简单通过抛出异常的方式对某个类方法进行“退化”。如果 *“对象不能支持某种操作”* 本身就是这个类型的 **核心特征** 之一，那我们在进行父类设计时，就应该把这个 **核心特征** 设计进去。

拿用户类型举例，*“用户可能无法被停用”* 就是 `User` 类的核心特征之一，所以在设计父类时，我们就应该把它作为类方法*（或属性）*写进去。

让我们看看调整后的代码：

```python
class User(Model):
    """普通用户模型类
    """
    def __init__(self, username: str):
        self.username = username

    def allow_deactivate(self) -> bool:
        """是否允许被停用
        """
        return True

    def deactivate(self):
        """将当前用户停用
        """
        self.is_active = True
        self.save()

class Admin(User):
    """管理员用户类
    """
    def allow_deactivate(self) -> bool:
        # 管理员用户不允许被停用
        return False

def deactivate_users(users: Iterable[User]):
    """批量停用多个用户
    """
    for user in users:
        if not user.allow_deactivate():
            logger.info(f'user {user.username} does not allow deactivating, skip.')
            continue

        user.deactivate()
```

在新代码里，我们在父类中增加了 `allow_deactivate` 方法，由它来决定当前的用户类型是否允许被停用。而在 `deactivate_users` 函数中，也不再需要通过脆弱的类型判断，来判定某类用户是否可以被停用。我们只需要调用 `user.allow_deactivate()` 方法，程序便能自动跳过那些不支持停用操作的用户对象。

在这样的设计中，`User` 类的子类 `Admin` 做到了可以完全替代父类使用，而不会破坏程序 `deactivate_users` 的功能。

所以我们可以说，修改后的类继承结构是符合里氏替换原则的。

## 另一种违反方式：子类修改方法返回值

除了上面的例子外，还有一种常见的违反里氏替换原则的情况。让我们看看下面这段代码：

```python
class User(Model):
    """普通用户模型类
    """
    def __init__(self, username: str):
        self.username = username

    def list_related_posts(self) -> List[int]:
        """查询所有与之相关的帖子 ID
        """
        return [post.id for post in session.query(Post).filter(username=self.username)]

class Admin(User):
    """管理员用户类
    """
    def list_related_posts(self) -> Iterable[int]:
        # 管理员与所有的帖子都有关，为了节约内存，使用生成器返回帖子 ID
        for post in session.query(Post).all():
            yield post.id
```

在这段代码里，我给用户类增加了一个新方法：`list_related_posts`，调用它可以拿到所有和当前用户有关的帖子 ID。对于普通用户，方法返回的是自己发布过的所有帖子，而管理员则是站点里的所有帖子。

现在，假设我需要写一个函数，来获取和用户有关的所有帖子标题：

```python
def list_user_post_titles(user: User) -> Iterable[str]:
    """获取与用户有关的所有帖子标题
    """
    for post_id in user.list_related_posts():
        yield session.query(Post).get(post_id).title
```

对于上面的 `list_user_post_titles` 函数来说，无论传入的 `user` 参数是 `User` 还是 `Admin` 类型，它都能正常工作。因为，虽然普通用户和管理员类型的 `list_related_posts` 方法返回结果略有区别，但它们都是**“可迭代的帖子 ID”**，所以函数里的循环在碰到不同的用户类型时都能正常进行。

既然如此，那上面的代码符合“里氏替换原则”吗？答案是否定的。因为虽然在当前 `list_user_post_titles` 函数的视角看来，子类 `Admin` 可以任意替代父类 `User` 使用，但这只是特殊用例下的一个巧合，并没有通用性。请看看下面这个场景。

有一位新成员最近加入了项目开发，她需要实现一个新函数来获取与用户有关的所有帖子数量。当她读到 `User` 类代码时，发现 `list_related_posts` 方法返回一个包含所有帖子 ID 的列表，于是她就此写下了统计帖子数量的代码：

```python
def get_user_posts_count(user: User) -> int:
    """获取与用户相关的帖子个数
    """
    return len(user.list_related_posts())
```

在大多数情况下，当 `user` 参数只是普通用户类时，上面的函数是可以正常执行的。

不过有一天，有其他人偶然使用了一个管理员用户调用了上面的函数，马上就碰到了异常：`TypeError: object of type 'generator' has no len()`。这时因为 `Admin` 虽然是 `User` 类型的子类，但它的 `list_related_posts` 方法返回却是一个可迭代的生成器，并不是列表对象。而生成器是不支持 `len()` 操作的。

所以，对于新的 `get_user_posts_count` 函数来说，现在的用户类继承结构仍然违反了 L 原则。

### 分析类方法返回结果

在我们的代码里，`User` 类和 `Admin` 类的 `list_related_posts` 返回的是两类不同的结果：

- `User 类`：返回一个包含帖子 ID 的列表对象
- `Admin 类`：返回一个产生帖子 ID 的生成器

很明显，二者之间存在共通点：它们都是可被迭代的 int 对象（`Iterable[int]`）。这也是为什么对于第一个获取用户帖子标题的函数来说，两个用户类可以互相交换使用的原因。

不过，针对某个特定函数，子类可以替代父类使用，并不等同于代码就符合“里氏替换原则”。要符合 L 原则，**我们一定得让子类方法和父类返回同一类型的结果，支持同样的操作。或者更进一步，返回支持更多种操作的子类型结果也是可以接受的。**

而现在的设计没做到这点，现在的子类返回值所支持的操作，只是父类的一个子集。`Admin` 子类的 `list_related_posts` 方法所返回的生成器，只支持父类 `User` 返回列表里的“迭代操作”，而不支持其他行为（比如 `len()`）。所以我们没办法随意的用子类替换父类，自然也就无法符合里氏替换原则。

> **注意：**此处说“生成器”支持的操作是“列表”的子集其实不是特别严谨，因为生成器还支持 `.send()` 等其他操作。不过在这里，我们可以只关注它的可迭代特性。

### 如何修改代码

为了让代码符合“里氏替换原则”。我们需要让子类和父类的同名方法，返回同一类结果。

```python
class User(Model):
    """普通用户模型类
    """
    def __init__(self, username: str):
        self.username = username

    def list_related_posts(self) -> Iterable[int]:
        """查询所有与之相关的帖子 ID
        """
        for post in session.query(Post).filter(username=self.username):
            yield post.id

    def get_related_posts_count(self) -> int:
        """获取与用户有关的帖子总数
        """
        value = 0
        for _ in self.list_related_posts():
            value += 1
        return value


class Admin(User):
    """管理员用户类
    """
    def list_related_posts(self) -> Iterable[int]:
        # 管理员与所有的帖子都有关，为了节约内存，使用生成器返回
        for post in session.query(Post).all():
            yield post.id
```

而对于“获取与用户有关的帖子总数”这个需求，我们可以直接在父类 `User` 中定义一个 `get_related_posts_count` 方法，遍历帖子 ID，统计数量后返回。

### 方法参数与 L 原则

除了子类方法返回不一致的类型以外，子类对父类方法参数的变更也容易导致违反 L 原则。拿下面这段代码为例：

```python
class User(Model):
    def list_related_posts(self, include_hidden: bool = False) -> List[int]:
        # ... ...


class Admin(User):
    def list_related_posts(self) -> List[int]:
        # ... ...
```

如果父类 `User` 的 `list_related_posts` 方法接收一个可选的 `include_hidden` 参数，那它的子类就不应该去掉这个参数。否则当某个函数调用依赖了 `include_hidden` 参数，但用户对象却是子类 `Admin` 类型时，程序就会报错。

为了让代码符合 L 原则，我们必须做到 **让子类的方法参数签名和父类完全一致，或者更宽松**。这样才能做到在任何使用参数调用父类方法的地方，随意用子类替换。

比如下面这样就是符合 L 原则的：

```python
class User(Model):
    def list_related_posts(self, include_hidden: bool = False) -> List[int]:
        # ... ...


class Admin(User):
    def list_related_posts(self, include_hidden: bool = False, active_only = True) -> List[int]:
        # 子类可以为方法增加额外的可选参数：active_only
        # ... ...
```

## 总结

在这篇文章里，我通过两个具体场景，向你描述了 “SOLID” 设计原则中的第三位成员：**里氏替换原则**。

“里氏替换原则”是一个非常具体的原则，它专门为 OOP 里的继承场景服务。当你设计类继承关系，尤其是编写子类代码时，请经常性的问自己这个问题：*“如果我把项目里所有使用父类的地方换成这个子类，程序是否还能正常运行？”*

如果答案是否定的，那么你就应该考虑调整一下现在的类设计了。调整方式有很多种，有时候你得把大类拆分为更小的类，有时候你得调换类之间的继承关系，有时候你得为父类添加新的方法和属性，就像文章里的第一个场景一样。只要开动脑筋，总会找到合适的办法。

让我们最后再总结一下吧：

- **“L：里氏替换原则”**认为子类应该可以任意替换父类被使用
- 在类的使用方增加具体的类型判断（*isinstance*），通常不是最佳解决方案
- 违反里氏替换原则，通常也会导致违反“开放-关闭”原则
- 考虑什么是类的核心特征，然后为父类增加新的方法和属性可以帮到你
- 子类方法应该和父类同名方法返回同一类型，或者返回支持更多操作的子类型也行
- 子类的方法参数应该和父类同名方法完全一致，或者更为宽松

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【14.写好面向对象代码的原则（下）】](14-write-solid-python-codes-part-3.md)

[<<<上一篇【12.写好面向对象代码的原则（上）】](12-write-solid-python-codes-part-1.md)

## 附录

- 题图来源: Photo by NeONBRAND on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：写好面向对象代码的原则（上）](https://www.zlovezl.cn/articles/write-solid-python-codes-part-1/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)
- [Python 工匠：高效操作文件的三个建议](https://www.zlovezl.cn/articles/three-tips-on-writing-file-related-codes/)


