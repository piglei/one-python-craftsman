# Markdown

本系统主要是用于markdown文件的解析，并且对其中的 code 做高亮处理。

## Markdown文件解析

Markdown文件解析是使用 `marked` 插件， 插件地址： [https://www.npmjs.com/package/marked](https://www.npmjs.com/package/marked)。

## 代码高亮

代码高亮使用 `prismjs` 插件， 插件地址 [https://prismjs.com](https://prismjs.com)。

如果你想替换代码高亮的种类，请参考prismjs官网的选项，生成js与css文件替换 `css/prism.css` 与  `js/prism.js`  文件。

如果你想替换代码高亮的主题色， 请参考prismjs官网的选项，生成css文件替换 `css/prism.css` 文件。

以下是目前代码中使用的代码列表，以供查阅，如需扩展，请按照上述说明修改。

- markup
- css
- c-like
- javascript
- c
- csharp
- basic
- cpp
- clojure
- css
- docker
- git
- go
- groovy
- less
- haxe
- http
- icon
- java
- json
- markdown
- nginx
- objectivec
- perl
- insertBefore
- sql
- scss
- python
- typescript
- plsql
- yaml
- vbnet