# 开发

## 编写文档

book-cli 支持的是markdown文档。

在文档的 `docs` 文件夹中，主要是维护的是以下两个文档：

### 左侧目录 SUMMARY.md

左侧目录是根据 `config.summaryMd` 的配置获取的，默认为默认 SUMMARY.md 文件。

参考项目的文档编写目录

``` markdown
* [介绍](README.md)
* [快速上手](config.md)
* [开发](server.md)
* [部署](build.md)
* [Markdown编写](markdown.md)
* [高亮片段](highlight.md)
* [图标](icons.md)
* [自定义](selfdefined.md)
* [反馈](feedback.md)
```

如果你想定义二级菜单，或者二级目录也可以：

``` markdown
* [介绍](README.md)
* 菜单一
  * [快速上手](menu1/config.md)
* 菜单二
  * [反馈](menu2/feedback.md)
```

将会生成以下目录：

<img src="./images/docs/menu.png"/>


### 主页面

左侧目录是根据 `config.index` 的配置获取的，默认为默认 README.md 文件。

### 内容页面

与 SUMMARY.md 中的目录对应的是各种内容的页面。

## 配置网站logo

请替换 `images/logo.ico` 文件。

## 本地Server

在启动之前，请在根目录下执行（系统只需要执行一次，安装后，不需要再执行了）：

``` bash
npm install
```

### 启动Server

``` bash
npm run server

```
Server启动成功后，访问网址 http://localhost:5000。

注意：此处只是启动一个静态Server，并未做任何处理。