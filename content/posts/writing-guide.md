---
title: "写作规范"
date: 2026-04-23
draft: false
---

# 博客写作规范

## Front Matter 模板

每篇文章必须包含以下 Front Matter：

```yaml
---
title: "文章标题"
date: 2026-04-23
draft: false
categories: ["技术笔记"]      # 必须，对应 content/posts/ 下的分类
tags: ["Python", "FastAPI"]   # 必须，便于检索
description: "一句话摘要"      # 必须，用于 SEO 和列表展示
cover:
  image: "images/cover.jpg"   # 可选，封面图
  alt: "封面图描述"
  hidden: false                # true 则不在列表中显示封面
---
```

## 分类体系

| 分类 | 路径 | 内容 |
|------|------|------|
| 技术笔记 > 遥感 | `tech/remote-sensing/` | 遥感影像、变化检测、GEE 等 |
| 技术笔记 > AI/ML | `tech/ai-ml/` | PyTorch、YOLO、模型训练 |
| 技术笔记 > GIS 开发 | `tech/gis/` | MapLibre、GeoServer、WebGIS |
| 技术笔记 > 全栈开发 | `tech/fullstack/` | FastAPI、Vue3、Docker |
| 项目实战 | `projects/` | 完整项目记录 |
| 思考随笔 | `thoughts/` | 技术思考、行业观察 |
| 教程 | `tutorials/` | 手把手入门指南 |

## 文件命名

- 格式：`YYYY-MM-DD-简短英文标题.md`
- 示例：`2026-04-23-hugo-blog-setup.md`
- 全小写，单词间用连字符 `-`

## 内容规范

### 标题
- 一级标题（`#`）仅用于文章主标题，正文不使用
- 正文从二级标题（`##`）开始
- 标题层级不超过三级

### 中英文混排
- 英文单词两侧加空格：`使用 FastAPI 框架`
- 专有名词保持原样：`GitHub`、`PyTorch`、`Vue3`
- 数字与中文之间加空格：`共 3 个文件`

### 代码块
- 使用 fenced code block（` ``` `）并标注语言
- 关键代码加注释
- 长代码块折叠或分段讲解

### 图片
- 放置在 `static/images/` 下
- 文件名有意义：`fastapi-architecture.png`
- 必须加 alt 文字
- 宽度建议不超过 800px

### 链接
- 内部链接使用 Hugo 相对路径
- 外部链接加 `[链接文字](url)` 格式
- 重要参考文献放在文末

## 文章结构模板

```markdown
---
title: "标题"
date: 2026-04-23
categories: ["技术笔记"]
tags: ["标签1", "标签2"]
description: "一句话摘要"
---

## 背景

为什么写这篇文章，解决什么问题。

## 方案

核心内容，分步骤讲解。

## 实现

代码、配置、操作步骤。

## 效果

截图、性能数据、对比。

## 总结

关键要点回顾。

## 参考

- [链接1](url)
- [链接2](url)
```

## 发布流程

1. 在对应分类目录下创建 `.md` 文件
2. 填写完整 Front Matter
3. 本地预览：`hugo server -D`
4. 确认无误后 `draft: false`
5. 构建部署：`hugo --minify` → 推送 gh-pages
