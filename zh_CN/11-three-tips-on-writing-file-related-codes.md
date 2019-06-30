#  Python 工匠：高效操作文件的三个建议

## 前言

> 这是 “Python 工匠”系列的第 11 篇文章。[[查看系列所有文章]](https://github.com/piglei/one-python-craftsman)

<div style="text-align: center; color: #999; margin: 14px 0 14px;font-size: 12px;">
<img src="https://www.zlovezl.cn/static/uploaded/2019/06/devon-divine-1348025-unsplash_1280.jpg" width="100%" />
</div>

在这个世界上，人们每天都在用 Python 完成着不同的工作。而文件操作，则是大家最常需要解决的任务之一。使用 Python，你可以轻松为他人生成精美的报表，也可以用短短几行代码快速解析、整理上万份数据文件。

当我们编写与文件相关的代码时，通常会关注这些事情：**我的代码是不是足够快？我的代码有没有事半功倍的完成任务？** 在这篇文章中，我会与你分享与之相关的几个编程建议。我会向你推荐一个被低估的 Python 标准库模块、演示一个读取大文件的最佳方式、最后再分享我对函数设计的一点思考。

下面，让我们进入第一个“模块安利”时间吧。

> **注意：**因为不同操作系统的文件系统大不相同，本文的主要编写环境为 Mac OS/Linux 系统，其中一些代码可能并不适用于 Windows 系统。

## 建议一：使用 pathlib 模块

如果你需要在 Python 里进行文件处理，那么标准库中的 `os` 和 `os.path` 兄弟俩一定是你无法避开的两个模块。在这两个模块里，有着非常多与文件路径处理、文件读写、文件状态查看相关的工具函数。

让我用一个例子来展示一下它们的使用场景。有一个目录里装了很多数据文件，但是它们的后缀名并不统一，既有 `.txt`，又有 `.csv`。我们需要把其中以 `.txt` 结尾的文件都修改为 `.csv` 后缀名。

我们可以写出这样一个函数：

```python
import os
import os.path


def unify_ext_with_os_path(path):
    """统一目录下的 .txt 文件名后缀为 .csv
    """
    for filename in os.listdir(path):
        basename, ext = os.path.splitext(filename)
        if ext == '.txt':
            abs_filepath = os.path.join(path, filename)
            os.rename(abs_filepath, os.path.join(path, f'{basename}.csv'))
```

让我们看看，上面的代码一共用到了哪些与文件处理相关的函数：
  
- [`os.listdir(path)`](https://docs.python.org/3/library/os.html#os.listdir)：列出 path 目录下的所有文件*（含文件夹）*
- [`os.path.splitext(filename)`](https://docs.python.org/3/library/os.path.html#os.path.splitext)：切分文件名里面的基础名称和后缀部分
- [`os.path.join(path, filename)`](https://docs.python.org/3/library/os.path.html#os.path.join)：组合需要操作的文件名为绝对路径
- [`os.rename(...)`](https://docs.python.org/3/library/os.html#os.rename)：重命名某个文件

上面的函数虽然可以完成需求，但说句实话，即使在写了很多年 Python 代码后，我依然觉得：**这些函数不光很难记，而且最终的成品代码也不怎么讨人喜欢。** 

### 使用 pathlib 模块改写代码

为了让文件处理变得更简单，Python 在 3.4 版本引入了一个新的标准库模块：[pathlib](https://docs.python.org/3/library/pathlib.html)。它基于面向对象思想设计，封装了非常多与文件操作相关的功能。如果使用它来改写上面的代码，结果会大不相同。

使用 pathlib 模块后的代码：

```python
from pathlib import Path

def unify_ext_with_pathlib(path):
    for fpath in Path(path).glob('*.txt'):
        fpath.rename(fpath.with_suffix('.csv'))
```

和旧代码相比，新函数只需要两行代码就完成了工作。而这两行代码主要做了这么几件事：

1. 首先使用 [Path(path)](https://docs.python.org/3/library/pathlib.html#pathlib.Path) 将字符串路径转换为 `Path` 对象
2. 调用 [.glob('*.txt')](https://docs.python.org/3/library/pathlib.html#pathlib.Path.glob) 对路径下所有内容进行模式匹配并以生成器方式返回，结果仍然是 `Path` 对象，所以我们可以接着做后面的操作
3. 使用 [.with_suffix('.csv')](https://docs.python.org/3/library/pathlib.html#pathlib.PurePath.with_suffix) 直接获取使用新后缀名的文件全路径
4. 调用 [.rename(target)](https://docs.python.org/3/library/pathlib.html#pathlib.Path.rename) 完成重命名

相比 `os` 和 `os.path`，引入 `pathlib` 模块后的代码明显更精简，也更有整体统一感。所有文件相关的操作都是一站式完成。

### 其他用法

除此之外，pathlib 模块还提供了很多有趣的用法。比如使用 `/` 运算符来组合文件路径：

```python
# 😑 旧朋友：使用 os.path 模块
>>> import os.path
>>> os.path.join('/tmp', 'foo.txt')
'/tmp/foo.txt'

# ✨ 新潮流：使用 / 运算符
>>> from pathlib import Path
>>> Path('/tmp') / 'foo.txt'
PosixPath('/tmp/foo.txt')
```

或者使用 `.read_text()` 来快速读取文件内容：

```python
# 标准做法，使用 with open(...) 打开文件
>>> with open('foo.txt') as file:
...     print(file.read())
...
foo

# 使用 pathlib 可以让这件事情变得更简单
>>> from pathlib import Path
>>> print(Path('foo.txt').read_text())
foo

```

除了我在文章里介绍的这些，pathlib 模块还提供了非常多有用的方法，强烈建议去 [官方文档]((https://docs.python.org/3/library/pathlib.html#module-pathlib)) 详细了解一下。

如果上面这些都不足以让你动心，那么我再多给你一个使用 pathlib 的理由：[PEP-519](https://www.python.org/dev/peps/pep-0519/) 里定义了一个专门用于“文件路径”的新对象协议，这意味着从该 PEP 生效后的 Python 3.6 版本起，pathlib 里的 Path 对象，可以和以前绝大多数只接受字符串路径的标准库函数兼容使用：

```python
>>> p = Path('/tmp')
# 可以直接对 Path 类型对象 p 进行 join
>>> os.path.join(p, 'foo.txt')
'/tmp/foo.txt'
```

所以，无需犹豫，赶紧把 pathlib 模块用起来吧。

> **Hint:** 如果你使用的是更早的 Python 版本，可以尝试安装 [pathlib2](https://pypi.org/project/pathlib2/) 模块 。

## 建议二：掌握如何流式读取大文件

几乎所有人都知道，在 Python 里读取文件有一种“标准做法”：首先使用 `with open(fine_name)` 上下文管理器的方式获得一个文件对象，然后使用 `for` 循环迭代它，逐行获取文件里的内容。

下面是一个使用这种“标准做法”的简单示例函数：

```python
def count_nine(fname):
    """计算文件里包含多少个数字 '9'
    """
    count = 0
    with open(fname) as file:
        for line in file:
            count += line.count('9')
    return count
```

假如我们有一个文件 `small_file.txt`，那么使用这个函数可以轻松计算出 9 的数量。

```python
# small_file.txt
feiowe9322nasd9233rl
aoeijfiowejf8322kaf9a

# OUTPUT: 3
print(count_nine('small_file.txt'))
```

为什么这种文件读取方式会成为标准？这是因为它有两个好处：

1. `with` 上下文管理器会自动关闭打开的文件描述符
2. 在迭代文件对象时，内容是一行一行返回的，不会占用太多内存

### 标准做法的缺点

但这套标准做法并非没有缺点。如果被读取的文件里，根本就没有任何换行符，那么上面的第二个好处就不成立了。**当代码执行到 `for line in file` 时，line 将会变成一个非常巨大的字符串对象，消耗掉非常可观的内存。**

让我们来做个试验：有一个 **5GB** 大的文件 `big_file.txt`，它里面装满了和 `small_file.txt` 一样的随机字符串。只不过它存储内容的方式稍有不同，所有的文本都被放在了同一行里：

```raw
# FILE: big_file.txt
df2if283rkwefh... <剩余 5GB 大小> ...
```

如果我们继续使用前面的 `count_nine` 函数去统计这个大文件里 `9` 的个数。那么在我的笔记本上，这个过程会足足花掉 **65** 秒，并在执行过程中吃掉机器 **2GB** 内存 [[注1]]((#annot1))。

### 使用 read 方法分块读取

为了解决这个问题，我们需要暂时把这个“标准做法”放到一边，使用更底层的 `file.read()` 方法。与直接循环迭代文件对象不同，每次调用 `file.read(chunk_size)` 会直接返回从当前位置往后读取 `chunk_size` 大小的文件内容，不必等待任何换行符出现。

所以，如果使用 `file.read()` 方法，我们的函数可以改写成这样:

```python
def count_nine_v2(fname):
    """计算文件里包含多少个数字 '9'，每次读取 8kb
    """
    count = 0
    block_size = 1024 * 8
    with open(fname) as fp:
        while True:
            chunk = fp.read(block_size)
            # 当文件没有更多内容时，read 调用将会返回空字符串 ''
            if not chunk:
                break
            count += chunk.count('9')
    return count
```

在新函数中，我们使用了一个 `while` 循环来读取文件内容，每次最多读取 8kb 大小，这样可以避免之前需要拼接一个巨大字符串的过程，把内存占用降低非常多。

### 利用生成器解耦代码

假如我们在讨论的不是 Python，而是其他编程语言。那么可以说上面的代码已经很好了。但是如果你认真分析一下 `count_nine_v2` 函数，你会发现在循环体内部，存在着两个独立的逻辑：**数据生成（read 调用与 chunk 判断）** 与 **数据消费**。而这两个独立逻辑被耦合在了一起。

正如我在[《编写地道循环》](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)里所提到的，为了提升复用能力，我们可以定义一个新的 `chunked_file_reader` 生成器函数，由它来负责所有与“数据生成”相关的逻辑。这样 `count_nine_v3` 里面的主循环就只需要负责计数即可。

```python
def chunked_file_reader(fp, block_size=1024 * 8):
    """生成器函数：分块读取文件内容
    """
    while True:
        chunk = fp.read(block_size)
        # 当文件没有更多内容时，read 调用将会返回空字符串 ''
        if not chunk:
            break
        yield chunk


def count_nine_v3(fname):
    count = 0
    with open(fname) as fp:
        for chunk in chunked_file_reader(fp):
            count += chunk.count('9')
    return count
```

进行到这一步，代码似乎已经没有优化的空间了，但其实不然。[iter(iterable)](https://docs.python.org/3/library/functions.html#iter) 是一个用来构造迭代器的内建函数，但它还有一个更少人知道的用法。当我们使用 `iter(callable, sentinel)` 的方式调用它时，会返回一个特殊的对象，迭代它将不断产生可调用对象 callable 的调用结果，直到结果为 setinel 时，迭代终止。

```python
def chunked_file_reader(file, block_size=1024 * 8):
    """生成器函数：分块读取文件内容，使用 iter 函数
    """
    # 首先使用 partial(fp.read, block_size) 构造一个新的无需参数的函数
    # 循环将不断返回 fp.read(block_size) 调用结果，直到其为 '' 时终止
    for chunk in iter(partial(file.read, block_size), ''):
        yield chunk
```

最终，只需要两行代码，我们就完成了一个可复用的分块文件读取函数。那么，这个函数在性能方面的表现如何呢？

和一开始的 **2GB 内存/耗时 65 秒** 相比，使用生成器的版本只需要 **7MB 内存 / 12 秒** 就能完成计算。效率提升了接近 4 倍，内存占用更是不到原来的 1%。

## 建议三：设计接受文件对象的函数

统计完文件里的 “9” 之后，让我们换一个需求。现在，我想要统计每个文件里出现了多少个英文元音字母*（aeiou）*。只要对之前的代码稍作调整，很快就可以写出新函数 `count_vowels`。

```python
def count_vowels(filename):
    """统计某个文件中，包含元音字母(aeiou)的数量
    """
    VOWELS_LETTERS = {'a', 'e', 'i', 'o', 'u'}
    count = 0
    with open(filename, 'r') as fp:
        for line in fp:
            for char in line:
                if char.lower() in VOWELS_LETTERS:
                    count += 1
    return count


# OUTPUT: 16
print(count_vowels('small_file.txt'))
```

和之前“统计 9”的函数相比，新函数变得稍微复杂了一些。为了保证程序的正确性，我需要为它写一些单元测试。但当我准备写测试时，却发现这件事情非常麻烦，主要问题点如下：

1. 函数接收文件路径作为参数，所以我们需要传递一个实际存在的文件
2. 为了准备测试用例，我要么提供几个样板文件，要么写一些临时文件
3. 而文件是否能被正常打开、读取，也成了我们需要测试的边界情况

**如果，你发现你的函数难以编写单元测试，那通常意味着你应该改进它的设计。**上面的函数应该如何改进呢？答案是：*让函数依赖“文件对象”而不是文件路径*。

修改后的函数代码如下：

```python
def count_vowels_v2(fp):
    """统计某个文件中，包含元音字母(aeiou)的数量
    """
    VOWELS_LETTERS = {'a', 'e', 'i', 'o', 'u'}
    count = 0
    for line in fp:
        for char in line:
            if char.lower() in VOWELS_LETTERS:
                count += 1
    return count


# 修改函数后，打开文件的职责被移交给了上层函数调用者
with open('small_file.txt') as fp:
    print(count_vowels_v2(fp))
```

**这个改动带来的主要变化，在于它提升了函数的适用面。**因为 Python 是“鸭子类型”的，虽然函数需要接受文件对象，但其实我们可以把任何实现了文件协议的 “类文件对象（file-like object）” 传入 `count_vowels_v2` 函数中。

而 Python 中有着非常多“类文件对象”。比如 io 模块内的 [StringIO](https://docs.python.org/3/library/io.html#io.StringIO) 对象就是其中之一。它是一种基于内存的特殊对象，拥有和文件对象几乎一致的接口设计。

利用 StringIO，我们可以非常方便的为函数编写单元测试。

```python
# 注意：以下测试函数需要使用 pytest 执行
import pytest
from io import StringIO


@pytest.mark.parametrize(
    "content,vowels_count", [
        # 使用 pytest 提供的参数化测试工具，定义测试参数列表
        # (文件内容, 期待结果)
        ('', 0),
        ('Hello World!', 3),
        ('HELLO WORLD!', 3),
        ('你好，世界', 0),
    ]
)
def test_count_vowels_v2(content, vowels_count):
    # 利用 StringIO 构造类文件对象 "file"
    file = StringIO(content)
    assert count_vowels_v2(file) == vowels_count
```

使用 pytest 运行测试可以发现，函数可以通过所有的用例：

```raw
❯ pytest vowels_counter.py
====== test session starts ======
collected 4 items

vowels_counter.py ... [100%]

====== 4 passed in 0.06 seconds ======
```

而让编写单元测试变得更简单，并非修改函数依赖后的唯一好处。除了 StringIO 外，subprocess 模块调用系统命令时用来存储标准输出的 [PIPE](https://docs.python.org/3/library/subprocess.html#subprocess.PIPE) 对象，也是一种“类文件对象”。这意味着我们可以直接把某个命令的输出传递给 `count_vowels_v2` 函数来计算元音字母数：

```python
import subprocess

# 统计 /tmp 下面所有一级子文件名（目录名）有多少元音字母
p = subprocess.Popen(['ls', '/tmp'], stdout=subprocess.PIPE, encoding='utf-8')

# p.stdout 是一个流式类文件对象，可以直接传入函数
# OUTPUT: 42
print(count_vowels_v2(p.stdout))
```

正如之前所说，将函数参数修改为“文件对象”，最大的好处是提高了函数的 **适用面** 和 **可组合性**。通过依赖更为抽象的“类文件对象”而非文件路径，给函数的使用方式开启了更多可能，StringIO、PIPE 以及任何其他满足协议的对象都可以成为函数的客户。

不过，这样的改造并非毫无缺点，它也会给调用方带来一些不便。假如调用方就是想要使用文件路径，那么就必须得自行处理文件的打开操作。

### 如何编写兼容二者的函数

有没有办法即拥有“接受文件对象”的灵活性，又能让传递文件路径的调用方更方便？答案是：*有，而且标准库中就有这样的例子。*

打开标准库里的 `xml.etree.ElementTree` 模块，翻开里面的 `ElementTree.parse` 方法。你会发现这个方法即可以使用文件对象调用，也接受字符串的文件路径。而它实现这一点的手法也非常简单易懂：

```
def parse(self, source, parser=None):
    """*source* is a file name or file object, *parser* is an optional parser
    """
    close_source = False
    # 通过判断 source 是否有 "read" 属性来判定它是不是“类文件对象”
    # 如果不是，那么调用 open 函数打开它并负担起在函数末尾关闭它的责任
    if not hasattr(source, "read"):
        source = open(source, "rb")
        close_source = True
```

使用这种基于“鸭子类型”的灵活检测方式，`count_vowels_v2` 函数也同样可以被改造得更方便，我在这里就不再重复啦。

## 总结

文件操作我们在日常工作中经常需要接触的领域，使用更方便的模块、利用生成器节约内存以及编写适用面更广的函数，可以让我们编写出更高效的代码。

让我们最后再总结一下吧：

- 使用 pathlib 模块可以简化文件和目录相关的操作，并让代码更直观
- [PEP-519](https://www.python.org/dev/peps/pep-0519/) 定义了表示“文件路径”的标准协议，Path 对象实现了这个协议
- 通过定义生成器函数来分块读取大文件可以节约内存
- 使用 `iter(callable, sentinel)` 可以在一些特定场景简化代码
- 难以编写测试的代码，通常也是需要改进的代码
- 让函数依赖“类文件对象”可以提升函数的适用面和可组合性

看完文章的你，有没有什么想吐槽的？请留言或者在 [项目 Github Issues](https://github.com/piglei/one-python-craftsman) 告诉我吧。

[>>>下一篇【12.写好面向对象代码的原则（上）】](12-write-solid-python-codes-part-1.md)

[<<<上一篇【10.做一个精通规则的玩家】](10-a-good-player-know-the-rules.md)

## 附录

- 题图来源: Photo by Devon Divine on Unsplash
- 更多系列文章地址：https://github.com/piglei/one-python-craftsman

系列其他文章：

- [所有文章索引 [Github]](https://github.com/piglei/one-python-craftsman)
- [Python 工匠：编写条件分支代码的技巧](https://www.zlovezl.cn/articles/python-else-block-secrets/)
- [Python 工匠：异常处理的三个好习惯](https://www.zlovezl.cn/articles/three-rituals-of-exceptions-handling/)
- [Python 工匠：编写地道循环的两个建议](https://www.zlovezl.cn/articles/two-tips-on-loop-writing/)


## 注解

1. <a id="annot1"></a>视机器空闲内存的多少，这个过程可能会消耗比 2GB 更多的内存。


