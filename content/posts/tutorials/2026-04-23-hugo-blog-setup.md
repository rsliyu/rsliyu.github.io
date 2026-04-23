---
title: "Hugo + PaperMod + GitHub Pages：零成本搭建个人博客"
date: 2026-04-23
draft: false
categories: ["教程"]
tags: ["Hugo", "PaperMod", "GitHub Pages", "博客", "静态站点"]
description: "从零开始，用 Hugo 静态站点生成器 + PaperMod 主题 + GitHub Pages 托管，搭建一个暗色科技风的个人技术博客。"
---

## 为什么选 Hugo

个人博客的技术方案很多，最终选 Hugo 的理由：

- **快**。几百篇文章的站点，构建时间在秒级。Jekyll 和 Hexo 在同等规模下慢得多
- **单二进制**。不需要 Node.js 环境（Hexo 需要），不需要 Ruby（Jekyll 需要），一个 `hugo` 命令搞定一切
- **Go 模板**。模板语法比 Jinja2 简洁，学习曲线平缓
- **PaperMod 主题**。Hugo 生态中最流行的暗色主题之一，开箱即用

## 环境搭建

### 安装 Hugo

```bash
# Linux（WSL 也适用）
wget https://github.com/gohugoio/hugo/releases/download/v0.147.4/hugo_extended_0.147.4_linux-amd64.deb
sudo dpkg -i hugo_extended_0.147.4_linux-amd64.deb
hugo version
```

注意要装 **extended** 版本，支持 SCSS 编译。

### 创建站点

```bash
hugo new site blog
cd blog
git init
```

### 安装 PaperMod 主题

```bash
git submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
```

## 配置

核心配置文件 `hugo.toml`：

```toml
baseURL = "https://你的用户名.github.io/"
languageCode = "zh-cn"
title = "你的博客名"
theme = "PaperMod"

[params]
  defaultTheme = "dark"          # 强制暗色主题
  disableThemeToggle = true      # 隐藏主题切换按钮
  ShowReadingTime = true         # 显示阅读时间
  ShowCodeCopyButtons = true     # 代码块复制按钮
  ShowToc = true                 # 目录

  [params.profileMode]
    enabled = true
    title = "👋 你好"
    subtitle = "你的介绍"

[outputs]
  home = ["HTML", "RSS", "JSON"]  # JSON 用于搜索索引

[markup.highlight]
  style = "dracula"               # 代码高亮主题
```

### 暗色主题的关键设置

PaperMod 的主题切换机制比较特殊。如果要用自定义深色样式，必须：

1. 设置 `defaultTheme = "dark"`
2. 设置 `disableThemeToggle = true`
3. 自定义 CSS 要用 `:root[data-theme="dark"]` 选择器覆盖主题变量

```css
/* assets/css/extended/custom.css */
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+SC&display=swap');

:root[data-theme="dark"] {
  --theme: #0F172A;
  --entry: #1E293B;
  --primary: #38BDF8;
  --content: #E2E8F0;
  font-family: 'Noto Sans SC', sans-serif;
}
```

## 目录结构

```
blog/
├── content/
│   ├── posts/           # 文章
│   │   ├── tech/        # 技术笔记
│   │   ├── projects/    # 项目实战
│   │   └── tutorials/   # 教程
│   ├── about.md         # 关于页
│   └── archives/        # 归档页
├── assets/css/extended/  # 自定义 CSS
├── static/images/        # 图片
├── themes/PaperMod/      # 主题（git submodule）
└── hugo.toml             # 配置文件
```

## 本地预览

```bash
hugo server -D    # -D 显示草稿
# 访问 http://localhost:1313
```

## 部署到 GitHub Pages

### 方案 1：GitHub Actions（推荐）

需要 GitHub PAT 有 `workflow` 权限。在 `.github/workflows/hugo.yml` 中配置自动构建。

### 方案 2：手动构建（PAT 权限不足时的备选）

```bash
# 构建
hugo --minify

# 推送到 gh-pages 分支
cd public
git init
git checkout -b gh-pages
git add .
git commit -m "deploy"
git remote add origin git@github.com:用户名/用户名.github.io.git
git push -f origin gh-pages
```

### 方案 3：一键部署脚本

写个 shell 脚本简化流程：

```bash
#!/bin/bash
# deploy.sh
hugo --minify
cd public
git add -A
git commit -m "deploy: $(date +%Y-%m-%d_%H:%M)"
git push -f origin gh-pages
cd ..
echo "✅ 部署完成"
```

## 常见问题

### Q: 主题样式不生效？

检查 PaperMod 子模块是否初始化：
```bash
git submodule init
git submodule update
```

### Q: 自定义 CSS 被主题覆盖？

PaperMod 的 CSS 通过 Hugo 资产管道编译，选择器优先级很高。自定义 CSS 需要用更具体的选择器，或者放在 `assets/css/extended/` 目录下（PaperMod 会自动加载）。

### Q: 中文搜索不工作？

PaperMod 内置搜索依赖 JSON 索引。确保 `hugo.toml` 中配置了：
```toml
[outputs]
  home = ["HTML", "RSS", "JSON"]
```

## 总结

Hugo + PaperMod + GitHub Pages 这套方案的核心优势是**零成本、低维护**。写 Markdown 推文章，`hugo --minify` 构建，推送到 GitHub 就上线。不需要服务器，不需要数据库，不需要域名（免费的 `github.io` 域名够用）。

如果你也想搭一个技术博客，这套方案值得一试。
