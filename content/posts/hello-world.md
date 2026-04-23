---
title: "Hello World — 从零搭建博客"
date: 2026-04-23
draft: false
tags: ["博客", "Hugo"]
summary: "用 Hugo + GitHub Pages 搭建个人博客的记录"
---

## 为什么建博客？

作为一个遥感+AI全栈开发者，平时积累了不少技术笔记和踩坑记录，一直散落在各个地方。建个博客，把有价值的东西沉淀下来。

## 技术选型

- **Hugo** — 静态站点生成器，速度快，Markdown 写作友好
- **PaperMod** — 简洁好看的主题
- **GitHub Pages** — 零成本托管，自动部署

## 搭建过程

整个过程非常简单，核心就三步：

```bash
# 1. 安装 Hugo
hugo new site blog

# 2. 安装主题
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod

# 3. 生成静态页面
hugo --minify
```

然后推送到 GitHub，配置 Pages 就完成了。

## 接下来

计划写一些关于：
- 遥感影像处理的实战经验
- FastAPI + Vue3 项目开发心得
- AI 模型训练的踩坑记录
- 工具链和效率提升

Stay tuned! 🚀
