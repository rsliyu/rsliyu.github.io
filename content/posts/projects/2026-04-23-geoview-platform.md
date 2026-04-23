---
title: "GeoView：从零搭建遥感影像智能解译平台"
date: 2026-04-23T18:00:00+08:00
draft: false
categories: ["项目实战", "技术笔记"]
tags: ["遥感", "ONNX", "Docker", "Flask", "COG", "STAC", "深度学习", "全栈开发"]
description: "一个人、一周时间，用 COG + STAC + ONNX Runtime 搭建了一个包含 15 个深度学习模型的遥感智能解译平台。完整记录技术选型、架构设计、代码审查和踩坑经历。"
---

## 为什么要做这个平台

做遥感的人，手里都有一堆散装工具——ENVI 看影像、ArcGIS 出图、Python 脚本跑模型、QGIS 画矢量。每次要做一个完整的分析任务，都要在好几个软件之间来回切换，模型训练的权重文件散落在各个目录，结果图片找不到放在哪了。

我想把这些东西收拢到**一个平台**里：上传影像 → 选模型 → 一键推理 → 地图上看结果 → 导出报告。不需要会写代码，浏览器打开就能用。

## 技术选型

### 核心问题：怎么管理遥感影像？

遥感影像动辄几百 MB 甚至几 GB，传统 GeoTIFF 读一个瓦片要扫描整个文件。解决方案是 **COG**（Cloud Optimized GeoTIFF）——内部分块 + 金字塔概览，支持 HTTP Range 请求，读一个 256×256 的瓦片只需要几十 KB 的网络请求。

影像多了还需要目录管理。**STAC**（SpatioTemporal Asset Catalog）是目前遥感数据管理的事实标准——每个影像注册一条元数据，包含时空范围、波段信息、缩略图，前端可以按时间、空间、关键词检索。

### 推理引擎：为什么选 ONNX Runtime

我手里的模型来源很杂：PaddleRS 训练的语义分割、PyTorch 的分类、Ultralytics 的 YOLOv8。如果运行时要同时装 PaddlePaddle + PyTorch，镜像轻松 15 GB+，启动慢，依赖冲突。

最终方案：**构建时转换，运行时只保留 ONNX Runtime**。

```
构建阶段                          运行阶段
┌──────────────┐                 ┌──────────────┐
│ PaddlePaddle │─paddle2onnx──▶ │              │
│ PyTorch      │─torch.onnx───▶ │ ONNX Runtime │ ← 唯一引擎
│ Ultralytics  │─export────────▶│              │
└──────────────┘                 └──────────────┘
  ~15 GB                           ~7 GB
```

多阶段 Docker 构建：第一阶段装 PaddlePaddle + paddle2onnx 转换 PaddleRS 模型，第二阶段装 PyTorch + Ultralytics 导出 YOLOv8 和 SMP 模型，第三阶段只 COPY ONNX 文件，运行时镜像不含任何训练框架。

### 前端：为什么不用 React/Vue

项目是个遥感专业工具，用户量不会太大，不需要复杂的状态管理。用原生 JavaScript + Cesium.js（3D 地球）+ OpenLayers（2D 地图）就够了。

好处是零构建依赖——Nginx 直接托管静态文件，刷新即生效，调试方便。坏处是没有组件化，JS 文件之间靠全局变量通信，后面审查代码的时候重构了不少。

## 架构设计

10 个 Docker 容器，单端口网关：

```
浏览器 (:18080)
    │
    ▼
┌─────────── Nginx ───────────────────────────┐
│  /         → 静态 SPA (Cesium + OL)          │
│  /aiapi/   → AI Engine (Flask :8002)         │
│  /upload/  → Upload API (FastAPI :8004)      │
│  /tiles/   → Tile Service (Flask :8090)      │
│  /titiler/ → TiTiler (:8000)                 │
│  /stac/    → STAC FastAPI (:8081)            │
│  /annotation-api/ → ISAT+SAM (:8000)        │
└──────────────────────────────────────────────┘
    │            │           │
    ▼            ▼           ▼
 PostGIS      MinIO       AI Engine
 (STAC元数据)  (COG存储)    (15个ONNX模型)
```

为什么用单端口？遥感平台部署在内网居多，开太多端口运维头疼。所有流量走 `:18080`，Nginx 按路径分发，CORS、安全头、gzip 压缩统一处理。

### 数据流

一张影像从上传到看到结果的完整链路：

```
用户上传 TIF
    │
    ▼
Upload API：裁切黑边 → 重投影 4326 → 转 COG → 上传 MinIO → 注册 STAC
    │
    ▼
前端：STAC 检索 → TiTiler 动态瓦片 → 地图展示
    │
    ▼
用户选模型点推理
    │
    ▼
AI Engine：加载 ONNX 模型 → 读取影像 → 推理 → 输出结果图 → 上传 MinIO
    │
    ▼
前端：结果图叠加到地图 → 导出 GeoJSON/报告
```

## 15 个模型

全部通过 ONNX Runtime 推理，覆盖四大任务类型：

| 任务 | 模型 | 来源 | 大小 |
|------|------|------|------|
| 场景分类 | MobileNetV3, PPLCNet, ResNet50, ResNet101, EuroSAT_ResNet50 | PaddleRS / torchgeo | 11~171 MB |
| 目标检测 | YOLOv8n | Ultralytics | 13 MB |
| 语义分割 | BiSeNetV2, DeepLabV3P, HRNet_W18, UNet, UNetPP_ResNet34, DeepLabV3P_EffB3 | PaddleRS / SMP | 9~252 MB |
| 变化检测 | DSAMNet, P2V, DSIFN | PaddleRS | 21~136 MB |

还有三个专项提取端点复用分割模型：建筑物提取 → DeepLabV3P，道路提取 → HRNet_W18，水体提取 → BiSeNetV2。

### ONNX 转换踩坑

PaddleRS 转 ONNX 的成功率大概 50%。21 个模型只有 10 个转成功：

- **paddle2onnx PIR 解析器 bug**：FloatAttribute 类型不匹配，rc=255 直接崩，影响 BIT、ChangeFormer 等 5 个模型
- **不支持的算子**：adaptive_pool2d 在某些模型图中没有 ONNX 对应算子
- **ONNX 图结构错误**：Conv/Concat 通道数不匹配，验证阶段自动删除损坏文件

解决方案很粗暴：转换脚本加 `_validate_onnx()`，转完跑一次推理，失败的直接删目录。最终 10 个 PaddleRS + 4 个 PyTorch + 1 个 Ultralytics = 15 个可用模型。

## 异步任务队列

推理可能要几十秒，不能让前端干等。自己实现了一个轻量级任务队列：

```python
# SQLite 持久化（不引入 Redis/Celery 重依赖）
class TaskQueue:
    def submit(task_type, params) -> task_id
    def get_status(task_id) -> {status, progress, result}
    def cancel(task_id) -> bool
    def list_tasks(status, limit) -> [...]
```

设计要点：

- **SQLite 持久化**：容器重启不丢任务状态，不引入额外中间件
- **业务错误 vs 系统错误**：波段越界（BusinessError）直接失败不重试，网络超时（ConnectionError）重试 3 次
- **超时保护**：每个任务类型有独立的超时阈值，超时后释放线程
- **取消终态保护**：已取消的任务即使 handler 跑完也不会被覆盖为 completed

前端用 `TaskManager` 轮询任务进度，全局浮窗显示进度条和通知 badge。

## 代码审查：一周的重构

平台核心功能搭完后，我花了整整一周做代码审查和重构。这部分工作量比写新功能还大，但对代码质量的提升是质的飞跃。

### JavaScript 重构

最初的 JS 代码很"野"——`var` 满天飞、`console.log` 到处是、每个文件自己封装一套 `fetch` 调用。重构内容：

- **API 路径集中化**：所有接口路径收拢到 `window.API_PATHS`，改一个地方全局生效
- **22 个 fetch/XHR → `Utils.apiRequest`**：统一的请求封装，自动 JSON 序列化、超时处理、错误状态码
- **`var` → `const`/`let`**：从 1235 个 var 干到 0
- **`console.log` → `_log`**：条件日志，URL 带 `?debug` 才输出
- **innerHTML XSS 审计**：78 处 innerHTML 逐一检查，4 处用户数据拼接修复为 `_esc()` 转义

### CSS 审查

28 处硬编码颜色替换为 CSS 变量，新增 5 个 design token。最意外的发现是 20 处乱码注释——`/* 鏁版嵁鍒 */` 这种 mojibake，原因是某个编辑器用 GBK 保存了 UTF-8 文件。

### Python 后端审查

这是重点，查出了不少安全和健壮性问题：

| 问题 | 风险 | 修复 |
|------|------|------|
| `_training_handler` 返回 `model_path` 绝对路径 | 信息泄漏 | pipeline 接口剥离内部路径 |
| `/api/result` 用 `in` 子串匹配文件名 | 文件碰撞 | 改为精确前缀匹配 + 路径遍历校验 |
| Upload API S3 客户端模块级创建 | 启动崩溃 | 懒初始化 `_get_s3()` |
| `/api/datasets` 异常返回 200 | 前端误判成功 | 改为 HTTP 500 |
| Tile Service 错误响应暴露 `str(e)` | 内部信息泄漏 | 通用错误消息 + 服务端日志 |
| 限流器不清理空 IP key | 内存泄漏 | 过期后 pop 空 key |
| 工具箱 API 返回 `result_path` | 路径泄漏 | 同步响应中 pop 内部路径 |

### 测试体系

审查完写了一套回归测试，确保修复不被撤回：

```bash
$ python -m pytest tests/ -v
# 40 passed in 0.37s

# test_frontend_syntax.py     — 前端语法 + apiRequest 覆盖 (11)
# test_security_fixes.py      — 安全修复回归 (15)
# test_backend_regression.py  — 后端审查回归 (14)
```

都是静态分析测试，不需要启动任何服务，< 1 秒跑完。核心思路是用 AST 解析 Python 源码，断言"某个函数里必须有 `.pop('model_path'`"、"错误响应里不能有 `str(e)`"这类规则。

## Docker 部署优化

### Healthcheck 全覆盖

给 6 个服务加了 Docker healthcheck，`docker compose ps` 能看到每个容器的健康状态。`web` 服务的 `depends_on` 全部升级为 `condition: service_healthy`，确保 Nginx 启动时所有上游服务已就绪。

### 构建优化

- `.dockerignore`：排除 `data/`、`models/`、`.git`，构建上下文从 2 GB 降到 200 MB
- `Dockerfile.tile` 的 `pip install` 从内联参数改为 `requirements-tile.txt`，利用 Docker 层缓存
- 移除 `docker-compose.yml` 中废弃的 `version: "3.8"`

### 安全加固

Nginx 配置了完整的安全头：

```nginx
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; ...
```

后端层面：API Key 认证、推理限流（每 IP 每分钟 10 次）、路径遍历防护、错误脱敏（生产模式不返回堆栈）。

## 最终效果

一个命令启动全部 10 个容器：

```bash
cp .env.example .env  # 改密码和 Cesium Token
docker compose up -d
# http://localhost:18080
```

功能覆盖：

- **数据管理**：上传 TIF → 自动转 COG → STAC 注册 → 3D 地球浏览
- **智能推理**：7 个推理接口 + 批量推理 + 实时进度
- **工具箱**：NDVI/NDWI/NDBI/EVI 指数计算、波段运算、影像裁剪
- **模型训练**：超参配置 → 训练进度 → loss 曲线 → 模型导出
- **样本标注**：ISAT + SAM 交互标注 → COCO 格式导出

## 回顾

这个项目从第一行代码到 40/40 测试全绿，大概花了两周。有几个体会：

1. **COG + STAC 是遥感数据管理的正确答案**。比起传统文件目录管理，它让前端可以像浏览网页一样浏览遥感影像，瓦片按需加载，不用把整个文件下载下来
2. **ONNX Runtime 统一推理引擎的价值远超预期**。不用关心模型是哪个框架训练的，运行时镜像小了一半，冷启动快了几倍
3. **代码审查不能跳过**。写新功能很兴奋，但审查代码才能让项目从"能跑"升级到"能用"。那一周的重构查出了 10 个安全/健壮性问题，任何一个在生产环境都可能是事故
4. **测试是给未来的自己留的保险**。40 个回归测试跑一次不到 1 秒，但能保证每次改代码不会引入回归

项目开源在 GitHub，如果你也在做遥感平台相关的工作，欢迎交流。

---

*技术栈：ONNX Runtime · Flask · FastAPI · Cesium.js · OpenLayers · PostgreSQL + PostGIS · MinIO · Docker Compose*
