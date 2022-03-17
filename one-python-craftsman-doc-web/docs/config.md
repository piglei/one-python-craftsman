# 快速上手

## 项目

我们提供以下三种方案初始化项目：

### 下载代码
建议从 book-cli 的 [github](https://github.com/vvpvvp/book-cli) 中下载代码至本地。

### Fork

在github中直接fork项目。

### 项目拷贝
使用命令拷贝项目，以下为示例代码：

``` bash
  git clone --depth=1 https://github.com/vvpvvp/book-cli.git my-project
  git remote set-url origin my-project-github-address
  git push
```
当然，你也可以通过其他方式初始化项目，简单的来说，就是代码拷贝。

## 配置

根目录下 `config.js` 文件

``` javascript
var CONFIG = {
  // 网页 title
  title: 'Book-Cli',
  
  // 网页 keywords
  keywords: 'book, book-cli, doc, example',

  // 网页 description
  description: 'Init html book with markdown files.',

  // 链接是否打开新的窗口
  openNewWindow: true,

  // 页面右上角的 github 链接
  github: 'https://github.com/vvpvvp/book-cli',

  // 左侧目录的md文件
  summaryMd: 'SUMMARY.md',

  // 网页默认访问的md文件
  index: 'README.md'
}
```