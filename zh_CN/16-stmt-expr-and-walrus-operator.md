让我们从两行最简单的 Python 代码开始。

```python
>>> name = 'piglei'
>>> print(f'Hello {name}!')
Hello piglei!
```

这是一个“Hello World”程序，你也许已经见过它无数次，对里面的每个字母都了如指掌。但你可能从未意识到，上面两行代码，刚好对应着 Python 语言里的两个重要概念：**语句（statement）** 和 **表达式（expression）**。

具体来说，`name = 'piglei'` 是一行赋值语句，它将字符串 `'piglei'` 赋给了 `name` 变量。`print(f'Hello {name}!')` 则是一个表达式，它通过调用内置函数 `print` 往屏幕打印信息。

### 表达式的特点

编写代码时，语句和表达式是两类最基本的代码单元。

虽然在日常表达中，我们会把语句和表达式区分开来，但二者并非完全不同——表达式实际上就是一种特殊的语句。和普通语句比起来，表达式的特别之处在于它拥有一个（或多个）返回值。

举例来说，前面的 `print(...)` 表达式就会返回一个值：`None`。你可以像下面这样获取它：

```python
# print 函数总是返回 None
>>> val = print(f'Hello {name}!')
Hello piglei!
>>> val is None
True
```

虽然这么做没啥实际用途，但它足够体现出表达式的独特之处——因为你永远无法对普通语句做出类似的事情。无论是“赋值语句”、“循环语句”，还是一个“条件分支语句”，你永远都无法将其赋值给某个变量，这在语法上无从谈起：

```python
>>> val = (name = 'piglei')
  File "<stdin>", line 1
    val = (name = 'piglei')
                ^
SyntaxError: invalid syntax #1
```

1. 意料之中，抛出了语法错误（`SyntaxError`）

不过，Python 3.8 版本发布以后，表达式和语句间的分界线突然变得前所未有的模糊。上面这行错误代码，只要增加一个冒号就可以变得合法：

```python
>>> val = (name := 'piglei')
>>> val, name
('piglei', 'piglei')
```

这便是“海象操作符（walrus operator）”——`:=`——的威力。

### 海象操作符

也许你会好奇，“海象操作符”这名字是怎么来的，为啥蟒蛇（python）的世界里会突然冒出一头海象（walrus）？假如你把头向左倾斜 90 度，仔细观察 `:=` 符号，就会发现其中的奥秘：它看起来就像一头海象的面部，冒号是鼻孔，等号是它的两根长牙。

使用 `:=` 操作符，可以构建出学名为“赋值表达式（Assignment Expressions）”的东西。在赋值表达式出现前，变量的赋值只能通过语句来完成。它出现后，我们便可在一个表达式内完成赋值，同时返回所赋值的变量。

```python
>>> val = (name := 'piglei')  #1
```

1. `(name := 'piglei')` 就是一个赋值表达式，它同时做到了两件事：将 `'piglei'` 赋值为 `name` 变量；返回 `name` 变量的值。

赋值表达式几乎可以被用在任何你能想到的地方，比如条件分支、循环和列表推导式，等等。

让我们来看几个典型场景。

#### 1. 用于分支语句

有一个函数，功能是从一段字符串中找出第一个以字母“w”开头的单词，如未找到，再尝试找以“w”结尾的。代码可以这么写：

```python
import re

LEADING_W_WORD = re.compile(r'\bw\w*?\b', re.I)
TRAILING_W_WORD = re.compile(r'\b\w*?w\b', re.I)

def find_w_word(s):
    """找到并打印字符串中第一个以 w 开头的单词，如未找到，再试着找 w 结尾的"""
    if LEADING_W_WORD.search(s):
        word = LEADING_W_WORD.search(s).group()
        print(f'Found word starts with "w": {word}')
    elif TRAILING_W_WORD.search(s):
        word = TRAILING_W_WORD.search(s).group()
        print(f'Found word ends with "w": {word}')
```

调用效果如下：

```python
>>> find_w_word('Guido found several examples where a programmer repeated a subexpression')
Found word starts with "w": where
```

上面的代码存在一个小问题，每个负责正则搜索的表达式 `LEADING_W_WORD.search(s)` 分别重复出现了两次：一次在分支判断处，另一次在分支内部。

这种重复会让代码更难维护，也会影响程序的执行性能。因此，大部分时候我们会通过定义变量来消除重复：

```python
def find_w_word_v2(s):
    """找到并打印字符串中第一个以 w 开头的单词，如未找到，再试着找 w 结尾的"""
    l_match = LEADING_W_WORD.search(s) #1
    if l_match:
        word = l_match.group()
        print(f'Found word starts with "w": {word}')
    else:
        t_match = TRAILING_W_WORD.search(s)
        if t_match:
            word = t_match.group()
            print(f'Found word ends with "w": {word}')
```

1. 定义一个变量 `l_match` 保存 `.search()` 返回的匹配结果

但这样虽然消除了重复，却引入了更深的嵌套层级，还是难以让人满意。

有了赋值表达式后，我们可以更进一步，直接在分支判断语句中一次性完成表达式的运算和赋值。于是，代码可以被进一步简化成这样：

```python
def find_w_word_v3(s):
    """找到并打印字符串中第一个以 w 开头的单词，如未找到，再试着找 w 结尾的"""
    if l_match := LEADING_W_WORD.search(s):
        word = l_match.group()
        print(f'Found word starts with "w": {word}')
    elif t_match := TRAILING_W_WORD.search(s):
        word = t_match.group()
        print(f'Found word ends with "w": {word}')
```

修改之后，代码变得更扁平，逻辑也更加紧凑了。

除了 `if` 条件分支，`while` 循环中也可以使用赋值表达式。比如，下面这种模式的循环代码十分常见：

```python
while True:
    chunk = fp.read(2048)
    if not chunk:
        break
    # 继续后续对 chunk 的处理...
```

如果使用赋值表达式，它可以被简化成下面这样：

```python
while chunk := fp.read(2048):
    # 继续后续对 chunk 的处理...
```

#### 2. 消除推导式中的重复

前面演示了在分支语句中使用赋值表达式，除此之外，你也可以在各类推导式中使用它。

举个例子，在构建一个推导式时，我们有时可能会需要同时做到以下两件事：

1. 预计算每个成员，判断结果是否满足要求
2. 如满足，将预计算的结果置入新对象

下面的代码完成了这个功能：

```python
# 仅挑选 func(...) > 100 的成员构建新列表
new_objs = [func(p) for p in objs if func(p) > 100]
```

虽然它满足需求，但也有一个严重的问题：`func(p)` 在每次迭代时会被重复执行两次，这很可能会成为一个潜在的性能隐患。

在以前，如果你想优化这个问题，除了把表达式拆成普通 `for` 循环外没什么其他办法。但有了赋值表达式，代码可被轻松优化成这样：

```python
new_objs = [v for p in objs if (v := func(p)) > 100]
```

重复的函数调用原地消失了。

#### 3. 捕获推导式的中间结果

从某种角度上看，赋值表达式是一种有“副作用”的表达式，它的副作用就是在返回值的同时，完成变量赋值。如果你有意地利用这种副作用，就能完成一些相当出人意料的事情。

让我来举个例子。`any()` 是 Python 的一个内建函数，它接收一个可迭代对象作为参数，在遍历该对象的过程中，如果发现任何布尔值为真的成员，函数就立刻返回 `True`，否则返回 `False`。

一个常见的使用场景如下所示：

```python
def has_lucky_number(nums):
    """判断给定的列表中，是否存在能被 7 整除的数字"""
    return any(n % 7 == 0 for n in nums)
```

调用示例：

```python
>>> has_lucky_number([4, 8, 9])
False
>>> has_lucky_number([4, 8, 21, 9])
True
```

某日，需求变更了。函数不仅需要知道是否存在被 7 整除的数字，还得把这个数字找出来。代码该怎么改？`any(...)` 像是肯定没法再用了，不如写一个平平无奇的 `for` 循环吧。

但其实，如果你使用赋值表达式搭配上 `any` 函数的短路执行特性，下面这几行代码也可以达成使命：

```python
def get_lucky_number(nums):
    """返回列表中能被 7 整除的数字，如没有则返回 None"""
    if any((ret := n) % 7 == 0 for n in nums):
        return ret
    return None
```

调用示例：

```python
>>> get_lucky_number([4, 8, 9])
>>> get_lucky_number([4, 8, 21, 9])
21
```

和之前相比，新代码最主要的修改在于将 `n` 替换成了 `(ret := n)`——一个有副作用的赋值表达式。在 `any` 函数进行循环遍历 `nums` 列表的过程中，当前被迭代的成员 `n` 会被赋到 `ret` 变量上，如其刚好满足条件，就会直接被当做结果返回。

借助赋值表达式的副作用，我们成功捕获了第一个满足条件的成员，只用一行代码就实现了需求。

#### 4. 赋值表达式的限制

从外观上看，赋值表达式和赋值语句极为相似，仅多了一个冒号 `:`。但如果你继续深入，会发现它其实被施加了许多普通赋值语句所没有的限制。

比如，它在作为整句独立使用时，两边必须添加括号：

```
>>> x := 1
SyntaxError: invalid syntax
>>> (x := 1)
1
```

此外，赋值表达式也无法直接操作对象属性（或字典的键）：

```python
# 普通赋值语句
>>> s.foo = 'bar'
>>> d['foo'] = 'bar'

# 赋值表达式无法做到
>>> (s.foo := 'bar')
SyntaxError: cannot use assignment expressions with attribute
>>> (d['foo'] := 'bar')
SyntaxError: cannot use assignment expressions with subscript
```

诸如此类的限制，是语言设计者为避免人们滥用赋值表达式而为之。但即便有着这些限制，赋值表达式这个 Python 3.8 中增加的新语法，已然为人们在 Python 中“遣词造句”，带来了巨大的可能性和想象空间。

> 如果你想了解更多关于”赋值表达式“的细节，建议阅读官方 PEP： [PEP 572 – Assignment Expressions](https://peps.python.org/pep-0572/)。

### 其他建议

下面是关于”赋值表达式“的两个使用建议。

#### 1. “更紧凑”不等于“更好”

正如前面所展示的，我们可以像玩积木一样组合使用赋值表达式，写出更精炼、更紧凑的代码。但对于代码而言，“更紧凑”不能和“更好”画上等号。关于这点，我很喜欢 Tim Peters 举过的[一个简单例子](https://peps.python.org/pep-0572/#appendix-a-tim-peters-s-findings)。

Tim Peters 说自己不喜欢“匆匆忙忙”的代码，讨厌将概念上无关的逻辑写到同一行代码里。比方说，与其像下面这样写：

```python
i = j = count = nerrors = 0
```

他更倾向于改成这样：

```python
i = j = 0
count = 0
nerrors = 0
```

第一种写法虽然紧凑，但其实忽视了一件重要的事：这几个变量分属 3 类不同用途（分别是循环索引值、个数和错误数量），它们只是碰巧都为 `0` 而已。将代码拆成 3 行以后，虽没那么紧凑，但概念上实际变得更清晰了。

在使用赋值表达式时，我们尤其需要避免掉进盲目追求“精炼”和“紧凑”的陷阱里，多多关注每行代码在逻辑上的联系，而不要整日盯着**字面意义上**的精简。

#### 2. 宜少不宜多

赋值表达式是 Python 3.8 引入的新特性，已经发布 3 年有余。但就自身感受而言，除了在一些 Python 教程文章中，我在其他项目里极少见到它的身影。

人们很少使用赋值表达式，我猜主要出于两方面的原因。

其一，Python 3.8 仍是一个相对较新的版本，许多项目尚未完成版本升级。其二，赋值表达式本身非常灵活，适用场景非常多，使用起来难以把控尺度，因此许多开发者对其抱着较为警惕的态度。再加上它本身也不提供任何普通语句做不到的独特功能——不是雪中送炭，只是锦上添花——因此大家不愿尝鲜。

上面的第一类原因，随着时间的推移会慢慢得到解决。我们主要看第二类。

我认为，大部分开发者的担忧确实有一定道理，赋值表达式在将代码变得紧凑的同时，也带来了更高的理解成本和上手门槛。而且平心而论，一些用了赋值表达式的代码，真的会给我一种“*这么写是不是过于聪明了？*”的感觉。

拿之前的这段代码为例：

```python
if any((ret := n) % 7 == 0 for n in nums):
    return ret
```

如果是一个私人脚本，也许我会愿意把代码写成上面那样。但在多人参与的真实项目里，我目前可能更愿意用一段平平无奇的 `for` 循环替代它。很多时候，相比“聪明”的代码，“笨”代码才是我们更需要的东西，它们能为项目的参与者省去许多沟通和维护上的成本。

总体而言，关于是否应该在项目中使用赋值表达式，我的建议是：

- 在分支语句的消除重复场景，使用赋值表达式
- 在推导式的消除重复场景，使用赋值表达式
- 其他情况下，优先使用普通赋值语句，哪怕这意味着更多代码和少量重复（比如“获取第一个满足条件的成员”场景）

希望以上的内容对你有所帮助。

> 这篇文章属于“Python 工匠”系列，如果你喜欢它，也欢迎了解我的书[《Python工匠：案例、技巧与工程实践》\[试读\]](https://www.piglei.com/book/index.html) | [\[书评\]](https://book.douban.com/subject/35723705/)，其中有大量同样风格的 Python 编程进阶知识。
