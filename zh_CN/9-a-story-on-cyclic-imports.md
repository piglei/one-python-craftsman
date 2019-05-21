# Python 工匠：一个关于模块的小故事

## 前言

> 这是 “Python 工匠”系列的第 9 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/05/ricardo-gomez-angel-669574-unsplash_w1280.jpg" width="100%" />
</div>

模块（Module）是我们用来组织 Python 代码的基本单位。很多功能强大的复杂站点，都由成百上千个独立模块共同组成。

虽然模块有着不可替代的用处，但它有时也会给我们带来麻烦。比如，当你接手一个新项目后，刚展开项目目录。第一眼就看到了攀枝错节、难以理解的模块结构，那你肯定会想： *“这项目也太难搞了。”* 😂

在这篇文章里，我准备了一个和模块有关的小故事与你分享。

## 一个关于模块的小故事

小 R 是一个刚从学校毕业的计算机专业学生。半个月前，他面试进了一家互联网公司做 Python 开发，负责一个与用户活动积分有关的小项目。项目的主要功能是查询站点活跃用户，并为他们发送有关活动积分的通知： *“亲爱的用户，您好，您当前的活动积分为 x”*。

项目主要由 `notify_users.py` 脚本和 `fancy_site` 包组成，结构与各文件内容如下：

```text
├── fancy_site
│   ├── __init__.py
│   ├── marketing.py        # 与市场活动有关的内容
│   └── users.py            # 与用户有关的内容
└── notify_users.py     # 脚本：发送积分通知
```

文件 `notify_users.py`：

```python
from fancy_site.users import list_active_users
from fancy_site.marketing import query_user_points


def main():
    """获取所有的活跃用户，将积分情况发送给他们"""
    users = get_active_users()
    points = list_user_points(users)
    for user in users:
        user.add_notification(... ...)
        #  <... 已省略 ...>
```

文件 `fancy_site/users.py`：

```python
from typing import List


class User:
    # <... 已省略 ...>

    def add_notification(self, message: str):
        """为用户发送新通知"""
        pass


def list_active_users() -> List[User]:
    """查询所有活跃用户"""
    pass
```

文件：`fancy_site/marketing.py`：

```python
from typing import List
from .users import User


def query_user_points(users: List[User]) -> List[int]:
    """批量查询用户活动积分"""


def send_sms(phone_number: str, message: str):
    """为某手机号发送短信"""
```

只要在项目目录下执行 `python notify_user.py`，就能实现给所有活跃用户发送通知。

### 需求变更

但有一天，产品经理找过来说，光给用户发站内信通知还不够，容易被用户忽略。除了站内信以外，我们还需要同时给用户推送一条短信通知。

琢磨了五秒钟后，小 R 跟产品经理说：*“这个需求可以做！”*。毕竟给手机号发送短信的 `send_sms()` 函数早就已经有人写好了。他只要先给 `add_notification` 方法添加一个可选参数 `enable_sms=False`，当传值为 `True` 时调用 `fancy_site.marketing` 模块里的 `send_sms` 函数就行。

一切听上去根本没有什么难度可言，十分钟后，小 R 就把 `user.py` 改成了下面这样：

```python
# 导入 send_sms 模块的发送短信函数
from .marketing import send_sms


class User:
    # <...> 相关初始化代码已省略

    def add_notification(self, message: str, enable_sms=False):
        """为用户添加新通知"""
        if enable_sms:
            send_sms(user.mobile_number, ... ...)
```

但是，当他修改完代码，再次执行 `notify_users.py` 脚本时，程序却报错了：

```raw
Traceback (most recent call last):
  File "notify_users.py", line 2, in <module>
    from fancy_site.users import list_active_users
  File .../fancy_site/users.py", line 3, in <module>
    from .marketing import send_sms
  File ".../fancy_site/marketing.py", line 3, in <module>
    from .users import User
ImportError: cannot import name 'User' from 'fancy_site.users' (.../fancy_site/users.py)
```

错误信息说，无法从 `fancy_site.users` 模块导入 `User` 对象。

### 解决环形依赖问题

小 R 仔细分析了一下错误，发现错误是因为 `users` 与 `marketing` 模块之间产生的环形依赖关系导致的。

当程序在 `notify_users.py` 文件导入 `fancy_site.users` 模块时，`users` 模块发现自己需要从 `marketing` 模块那里导入 `send_sms` 函数。而解释器在加载 `marketing` 模块的过程中，又反过来发现自己需要依赖 `users` 模块里面的 `User` 对象。

如此一来，整个模块依赖关系成为了环状，程序自然也就没法执行下去了。

![modules_before](https://www.zlovezl.cn/static/uploaded/2019/05/modules_before.png)

不过，没有什么问题能够难倒一个可以正常访问 Google 的程序员。小 R 随便上网一搜，发现这样的问题很好解决。因为 Python 的 import 语句非常灵活，他只需要 **把在 users 模块内导入 send_sms 函数的语句挪到 `add_notification` 方法内，延缓 import 语句的执行就行啦。**

```python
class User:
    # <...> 相关初始化代码已省略

    def add_notification(self, message: str, send_sms=False):
        """为用户添加新通知"""
        # 延缓 import 语句执行
        from .marketing import send_sms
```

改动一行代码后，大功告成。小 R 简单测试后，发现一切正常，然后把代码推送了上去。不过小 R 还没来得及为自己点个赞，意料之外的事情发生了。

这段明明几乎完美的代码改动在 **Code Review** 的时候被审计人小 C 拒绝了。

### 小 C 的疑问

小 R 的同事小 C 是一名有着多年经验的 Python 程序员，他对小 R 说：“使用延迟 import，虽然可以马上解决包导入问题。但这个小问题背后隐藏了更多的信息。比如，**你有没有想过 send_sms 函数，是不是已经不适合放在 marketing 模块里了？”**

被小 C 这么一问，聪明的小 R 马上意识到了问题所在。要在 `users` 模块内发送短信，重点不在于用延迟导入解决环形依赖。而是要以此为契机，**发现当前模块间依赖关系的不合理，拆分/合并模块，创建新的分层与抽象，最终消除环形依赖。**

认识清楚问题后，他很快提交了新的代码修改。在新代码中，他创建了一个专门负责通知与消息类的工具模块 `msg_utils`，然后把 `send_sms` 函数挪到了里面。之后 `users` 模块内就可以毫无困难的从 `msg_utils` 模块中导入 `send_sms` 函数了。

```python
from .msg_utils import send_sms
```

新的模块依赖关系如下图所示：

![modules_afte](https://www.zlovezl.cn/static/uploaded/2019/05/modules_after.png)

在新的模块结构中，整个项目被整齐的分为三层，模块间的依赖关系也变得只有**单向流动**。之前在函数内部 `import` 的“延迟导入”技巧，自然也就没有用武之地了。

小 R 修改后的代码获得了大家的认可，很快就被合并到了主分支。故事暂告一段落，那么这个故事告诉了我们什么道理呢？

## 总结

模块间的循环依赖是一个在大型 Python 项目中很常见的问题，越复杂的项目越容易碰到这个问题。当我们在参与这些项目时，**如果对模块结构、分层、抽象缺少应有的重视。那么项目很容易就会慢慢变得复杂无比、难以维护。**

所以，合理的模块结构与分层非常重要。它可以大大降低开发人员的心智负担和项目维护成本。这也是我为什么要和你分享这个简单故事的原因。“在函数内延迟 import” 的做法当然没有错，但我们更应该关注的是：**整个项目内的模块依赖关系与分层是否合理。**

最后，让我们再尝试从 小 R 的故事里强行总结出几个道理吧：

- 合理的模块结构与分层可以降低项目的开发维护成本
- 合理的模块结构不是一成不变的，应该随着项目发展调整
- 遇到问题时，不要选**“简单但有缺陷”**的那个方案，要选**“麻烦但正确”**的那个
- 整个项目内的模块间依赖关系流向，应该是单向的，不能有环形依赖存在

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

## 附录

- 题图来源: Photo by Ricardo Gomez Angel on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：异常处理的三个好习惯](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)



