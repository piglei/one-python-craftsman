# Python 工匠：使用装饰器的技巧

## 前言

> 这是 “Python 工匠”系列的第 8 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/05/clem-onojeghuo-142120-unsplash_w1280.jpg" width="100%" />
</div>

装饰器*（Decorator）* 是 Python 里的一种特殊工具，它为我们提供了一种在函数外部修改函数的灵活能力。它有点像一顶画着独一无二 `@` 符号的神奇帽子，只要将它戴在函数头顶上，就能悄无声息的改变函数本身的行为。

你可能已经和装饰器打过不少交道了。在做面向对象编程时，我们就经常会用到 `@staticmethod` 和 `@classmethod` 两个内置装饰器。此外，如果你接触过 [click](https://click.palletsprojects.com/en/7.x/) 模块，就更不会对装饰器感到陌生。click 最为人所称道的参数定义接口 `@click.option(...)` 就是利用装饰器实现的。

除了用装饰器，我们也经常需要自己写一些装饰器。在这篇文章里，我将从 `最佳实践` 和 `常见错误` 两个方面，来与你分享有关装饰器的一些小知识。

## 最佳实践

### 1. 尝试用类来实现装饰器

绝大多数装饰器都是基于函数和 [闭包](https://en.wikipedia.org/wiki/Closure_(computer_programming)) 实现的，但这并非制造装饰器的唯一方式。事实上，Python 对某个对象是否能通过装饰器（`@decorator`）形式使用只有一个要求：**decorator 必须是一个“可被调用（callable）的对象**。

```python
# 使用 callable 可以检测某个对象是否“可被调用”
>>> def foo(): pass
...
>>> type(foo)
<class 'function'>
>>> callable(foo)
True
```

函数自然是“可被调用”的对象。但除了函数外，我们也可以让任何一个类（class）变得“可被调用”（callable）。办法很简单，只要自定义类的 `__call__` 魔法方法即可。

```
class Foo:
    def __call__(self):
        print("Hello, __call___")

foo = Foo()

# OUTPUT: True
print(callable(foo))
# 调用 foo 实例
# OUTPUT: Hello, __call__
foo()
```

基于这个特性，我们可以很方便的使用类来实现装饰器。

下面这段代码，会定义一个名为 `@delay(duration)` 的装饰器，使用它装饰过的函数在每次执行前，都会等待额外的 `duration` 秒。同时，我们也希望为用户提供无需等待马上执行的 `eager_call` 接口。

```python
import time
import functools


class DelayFunc:
    def __init__(self,  duration, func):
        self.duration = duration
        self.func = func

    def __call__(self, *args, **kwargs):
        print(f'Wait for {self.duration} seconds...')
        time.sleep(self.duration)
        return self.func(*args, **kwargs)

    def eager_call(self, *args, **kwargs):
        print('Call without delay')
        return self.func(*args, **kwargs)


def delay(duration):
    """装饰器：推迟某个函数的执行。同时提供 .eager_call 方法立即执行
    """
    # 此处为了避免定义额外函数，直接使用 functools.partial 帮助构造
    # DelayFunc 实例
    return functools.partial(DelayFunc, duration)
```

如何使用装饰器的样例代码：

```
@delay(duration=2)
def add(a, b):
    return a + b


# 这次调用将会延迟 2 秒
add(1, 2)
# 这次调用将会立即执行
add.eager_call(1, 2)
```

`@delay(duration)` 就是一个基于类来实现的装饰器。当然，如果你非常熟悉 Python 里的函数和闭包，上面的 `delay` 装饰器其实也完全可以只用函数来实现。所以，为什么我们要用类来做这件事呢？

与纯函数相比，我觉得使用类实现的装饰器在**特定场景**下有几个优势：

- 实现有状态的装饰器时，操作类属性比操作闭包内变量更符合直觉、不易出错
- 实现为函数扩充接口的装饰器时，使用类包装函数，比直接为函数对象追加属性更易于维护
- 更容易实现一个同时兼容装饰器与上下文管理器协议的对象（参考 [unitest.mock.patch](https://docs.python.org/3/library/unittest.mock.html#unittest.mock.patch)）

### 2. 使用 wrapt 模块编写更扁平的装饰器

在写装饰器的过程中，你有没有碰到过什么不爽的事情？不管你有没有，反正我有。我经常在写代码的时候，被下面两件事情搞得特别难受：

1. 实现带参数的装饰器时，层层嵌套的函数代码特别难写、难读
2. 因为函数和类方法的不同，为前者写的装饰器经常没法直接套用在后者上

比如，在下面的例子里，我实现了一个生成随机数并注入为函数参数的装饰器。

```python
import random


def provide_number(min_num, max_num):
    """装饰器：随机生成一个在 [min_num, max_num] 范围的整数，追加为函数的第一个位置参数
    """
    def wrapper(func):
        def decorated(*args, **kwargs):
            num = random.randint(min_num, max_num)
            # 将 num 作为第一个参数追加后调用函数
            return func(num, *args, **kwargs)
        return decorated
    return wrapper
    


@provide_number(1, 100)
def print_random_number(num):
    print(num)

# 输出 1-100 的随机整数
# OUTPUT: 72
print_random_number()
```

`@provide_number` 装饰器功能看上去很不错，但它有着我在前面提到的两个问题：**嵌套层级深、无法在类方法上使用。**如果直接用它去装饰类方法，会出现下面的情况：

```
class Foo:
    @provide_number(1, 100)
    def print_random_number(self, num):
        print(num)

# OUTPUT: <__main__.Foo object at 0x104047278>
Foo().print_random_number()
```

`Foo` 类实例中的 `print_random_number` 方法将会输出类实例 `self` ，而不是我们期望的随机数 `num`。

之所以会出现这个结果，是因为类方法*（method）*和函数*（function）*二者在工作机制上有着细微不同。如果要修复这个问题，`provider_number` 装饰器在修改类方法的位置参数时，必须聪明的跳过藏在 `*args` 里面的类实例 `self` 变量，才能正确的将 `num` 作为第一个参数注入。

这时，就应该是 [wrapt](https://pypi.org/project/wrapt/) 模块闪亮登场的时候了。`wrapt` 模块是一个专门帮助你编写装饰器的工具库。利用它，我们可以非常方便的改造 `provide_number` 装饰器，完美解决*“嵌套层级深”*和*“无法通用”*两个问题，

```python
import wrapt

def provide_number(min_num, max_num):
    @wrapt.decorator
    def wrapper(wrapped, instance, args, kwargs):
        # 参数含义：
        #
        # - wrapped：被装饰的函数或类方法
        # - instance：
        #   - 如果被装饰者为普通类方法，该值为类实例
        #   - 如果被装饰者为 classmethod 类方法，该值为类
        #   - 如果被装饰者为类/函数/静态方法，该值为 None
        #
        # - args：调用时的位置参数（注意没有 * 符号）
        # - kwargs：调用时的关键字参数（注意没有 ** 符号）
        #
        num = random.randint(min_num, max_num)
        # 无需关注 wrapped 是类方法或普通函数，直接在头部追加参数
        args = (num,) + args
        return wrapped(*args, **kwargs)
    return wrapper
    
<... 应用装饰器部分代码省略 ...>
    
# OUTPUT: 48
Foo().print_random_number()
```

使用 `wrapt` 模块编写的装饰器，相比原来拥有下面这些优势：

- 嵌套层级少：使用 `@wrapt.decorator` 可以将两层嵌套减少为一层
- 更简单：处理位置与关键字参数时，可以忽略类实例等特殊情况
- 更灵活：针对 `instance` 值进行条件判断后，更容易让装饰器变得通用

## 常见错误

### 1. “装饰器”并不是“装饰器模式”

[“设计模式”](https://en.wikipedia.org/wiki/Software_design_pattern)是一个在计算机世界里鼎鼎大名的词。假如你是一名 Java 程序员，而你一点设计模式都不懂，那么我打赌你找工作的面试过程一定会度过的相当艰难。

但写 Python 时，我们极少谈起“设计模式”。虽然 Python 也是一门支持面向对象的编程语言，但它的 [鸭子类型](https://en.wikipedia.org/wiki/Duck_typing) 设计以及出色的动态特性决定了，大部分设计模式对我们来说并不是必需品。所以，很多 Python 程序员在工作很长一段时间后，可能并没有真正应用过几种设计模式。

不过 [*“装饰器模式（Decorator Pattern）”*](https://en.wikipedia.org/wiki/Decorator_pattern) 是个例外。因为 Python 的“装饰器”和“装饰器模式”有着一模一样的名字，我不止一次听到有人把它们俩当成一回事，认为使用“装饰器”就是在实践“装饰器模式”。但事实上，**它们是两个完全不同的东西。**

“装饰器模式”是一个完全基于“面向对象”衍生出的编程手法。它拥有几个关键组成：**一个统一的接口定义**、**若干个遵循该接口的类**、**类与类之间一层一层的包装**。最终由它们共同形成一种*“装饰”*的效果。

而 Python 里的“装饰器”和“面向对象”没有任何直接联系，**它完全可以只是发生在函数和函数间的把戏。**事实上，“装饰器”并没有提供某种无法替代的功能，它仅仅就是一颗[“语法糖”](https://en.wikipedia.org/wiki/Syntactic_sugar)而已。下面这段使用了装饰器的代码：

```python
@log_time
@cache_result
def foo(): pass
```

基本完全等同于下面这样：

```
def foo(): pass

foo = log_time(cache_result(foo))
```

**装饰器最大的功劳，在于让我们在某些特定场景时，可以写出更符合直觉、易于阅读的代码**。它只是一颗“糖”，并不是某个面向对象领域的复杂编程模式。

> Hint: 在 Python 官网上有一个 [实现了装饰器模式的例子](https://wiki.python.org/moin/DecoratorPattern)，你可以读读这个例子来更好的了解它。

### 2. 记得用 functools.wraps() 装饰内层函数

下面是一个简单的装饰器，专门用来打印函数调用耗时：

```python
import time


def timer(wrapped):
    """装饰器：记录并打印函数耗时"""
    def decorated(*args, **kwargs):
        st = time.time()
        ret = wrapped(*args, **kwargs)
        print('execution take: {} seconds'.format(time.time() - st))
        return ret
    return decorated


@timer
def random_sleep():
    """随机睡眠一小会"""
    time.sleep(random.random())
```

`timer` 装饰器虽然没有错误，但是使用它装饰函数后，函数的原始签名就会被破坏。也就是说你再也没办法正确拿到 `random_sleep` 函数的名称、文档内容了，所有签名都会变成内层函数 `decorated` 的值：

```python
print(random_sleep.__name__)
# 输出 'decorated'
print(random_sleep.__doc__)
# 输出 None
```

这虽然只是个小问题，但在某些时候也可能会导致难以察觉的 bug。幸运的是，标准库 `functools` 为它提供了解决方案，你只需要在定义装饰器时，用另外一个装饰器再装饰一下内层 `decorated` 函数就行。

听上去有点绕，但其实就是新增一行代码而已：

```python
def timer(wrapped):
    # 将 wrapper 函数的真实签名赋值到 decorated 上
    @functools.wraps(wrapped)
    def decorated(*args, **kwargs):
        # <...> 已省略
    return decorated
```

这样处理后，`timer` 装饰器就不会影响它所装饰的函数了。

```python
print(random_sleep.__name__)
# 输出 'random_sleep'
print(random_sleep.__doc__)
# 输出 '随机睡眠一小会'
```

### 3. 修改外层变量时记得使用 nonlocal

装饰器是对函数对象的一个高级应用。在编写装饰器的过程中，你会经常碰到内层函数需要修改外层函数变量的情况。就像下面这个装饰器一样：

```python
import functools

def counter(func):
    """装饰器：记录并打印调用次数"""
    count = 0
    @functools.wraps(func)
    def decorated(*args, **kwargs):
        # 次数累加
        count += 1
        print(f"Count: {count}")
        return func(*args, **kwargs)
    return decorated

@counter
def foo():
    pass

foo()
```

为了统计函数调用次数，我们需要在 `decorated` 函数内部修改外层函数定义的 `count` 变量的值。但是，上面这段代码是有问题的，在执行它时解释器会报错:

```raw
Traceback (most recent call last):
  File "counter.py", line 22, in <module>
    foo()
  File "counter.py", line 11, in decorated
    count += 1
UnboundLocalError: local variable 'count' referenced before assignment
```

这个错误是由 `counter` 与 `decorated` 函数互相嵌套的作用域引起的。

当解释器执行到 `count += 1` 时，并不知道 `count` 是一个在外层作用域定义的变量，它把 `count` 当做一个局部变量，并在当前作用域内查找。最终却没有找到有关 `count` 变量的任何定义，然后抛出错误。

为了解决这个问题，我们需要通过 `nonlocal` 关键字告诉解释器：**“count 变量并不属于当前的 local 作用域，去外面找找吧”**，之前的错误就可以得到解决。

```python
def decorated(*args, **kwargs):
    nonlocal count
    count += 1
    # <... 已省略 ...>
```

> Hint：如果要了解更多有关 nonlocal 关键字的历史，可以查阅 [PEP-3104](https://www.python.org/dev/peps/pep-3104/)

## 总结

在这篇文章里，我与你分享了有关装饰器的一些技巧与小知识。

一些要点总结：

- 一切 callable 的对象都可以被用来实现装饰器
- 混合使用函数与类，可以更好的实现装饰器
- wrapt 模块很有用，用它可以帮助我们用更简单的代码写出复杂装饰器
- “装饰器”只是语法糖，它不是“装饰器模式”
- 装饰器会改变函数的原始签名，你需要 `functools.wraps`
- 在内层函数修改外层函数的变量时，需要使用 `nonlocal` 关键字

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【9.一个关于模块的小故事】](9-a-story-on-cyclic-imports.md)

[<<<上一篇【7.编写地道循环的两个建议】](7-two-tips-on-loop-writing.md)


## 附录

- 题图来源: Photo by Clem Onojeghuo on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：异常处理的三个好习惯](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


