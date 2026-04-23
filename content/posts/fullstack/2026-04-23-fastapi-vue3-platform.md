---
title: "FastAPI + Vue3：智慧农业数据平台架构实践"
date: 2026-04-23
draft: false
categories: ["技术笔记", "全栈开发"]
tags: ["FastAPI", "Vue3", "DataV", "智慧农业", "架构设计"]
description: "从零搭建智慧农业数据平台的技术选型、架构设计和踩坑记录，覆盖后端 FastAPI、前端 Vue3 + DataV 大屏。"
---

## 为什么要做这个平台

西安有几个农业相关的数据平台需要建设——生鲜乳收购统计、动物强制免疫数据管理。这些系统有一个共同特点：**数据来源多、格式杂、需要可视化大屏展示**。

市面上的低代码平台（如宜搭、简道云）能解决 80% 的需求，但剩下 20% 的定制化需求（GIS 地图、遥感数据接入、复杂报表）搞不定。最终决定自己搭。

## 技术选型

### 后端：FastAPI

选 FastAPI 的理由很直接：

- **Python 生态**：遥感处理用 rasterio、模型推理用 PyTorch，都在 Python 里
- **自动文档**：Swagger/OpenAPI 自动生成，甲方验收时省事
- **异步支持**：数据导入接口支持 `async`，大文件上传不阻塞
- **类型安全**：Pydantic 模型做数据校验，减少脏数据

### 前端：Vue3 + DataV

- **Vue3 Composition API**：逻辑复用方便，比 Options API 清晰
- **DataV**：阿里开源的数据可视化组件库，大屏效果好
- **Element Plus**：后台管理 UI 组件丰富

### 数据库：SQLite → PostgreSQL

开发阶段用 SQLite（零配置），生产环境切 PostgreSQL（支持空间扩展 PostGIS）。

## 整体架构

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Vue3 前端   │────▶│  FastAPI 后端  │────▶│  PostgreSQL  │
│  + DataV 大屏│◀────│  + JWT Auth   │◀────│  + PostGIS   │
└─────────────┘     └──────┬───────┘     └─────────────┘
                           │
                    ┌──────┴───────┐
                    │  文件存储      │
                    │  (本地/MinIO)  │
                    └──────────────┘
```

### 目录结构

```
project/
├── backend/
│   ├── app/
│   │   ├── api/          # 路由
│   │   │   ├── auth.py   # 认证
│   │   │   ├── data.py   # 数据 CRUD
│   │   │   └── stats.py  # 统计接口
│   │   ├── models/       # SQLAlchemy 模型
│   │   ├── schemas/      # Pydantic 模型
│   │   ├── core/         # 配置、安全
│   │   └── main.py       # FastAPI 入口
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── views/        # 页面
│   │   ├── components/   # 组件
│   │   ├── api/          # 接口封装
│   │   └── router/       # 路由
│   └── package.json
└── docker-compose.yml
```

## 关键设计决策

### 1. 认证方案：JWT

```python
# 后端：JWT Token 签发
from datetime import timedelta
from jose import jwt

def create_access_token(data: dict, expires_delta: timedelta):
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
```

前端登录后存 `localStorage`，Axios 拦截器自动带 `Authorization: Bearer xxx`。

### 2. 数据导入：Excel 批量上传

甲方最喜欢 Excel。设计了一个通用的 Excel 导入接口：

```python
@router.post("/import")
async def import_excel(file: UploadFile):
    df = pd.read_excel(file.file)
    # 数据校验
    errors = validate_dataframe(df)
    if errors:
        return {"success": False, "errors": errors}
    # 批量写入
    records = df.to_dict("records")
    await db.execute(insert(Model).values(records))
    return {"success": True, "count": len(records)}
```

### 3. 大屏设计：DataV 组件

大屏是甲方验收的重点。用了 DataV 的几个核心组件：

- **Decoration**：边框装饰，科技感
- **Charts**：ECharts 封装，图表展示
- **ScrollBoard**：数据滚动列表
- **DigitalFlop**：数字翻牌效果

配色用深色主题（`#0F172A` 背景 + 青蓝色系），和遥感/科技风格统一。

## 踩坑记录

### 坑 1：CORS 问题

Vue3 开发服务器（`localhost:5173`）和 FastAPI（`localhost:8080`）端口不同，需要配置 CORS：

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 坑 2：大文件上传超时

Excel 文件超过 10MB 时，Nginx 默认配置会拒绝。需要调整：

```nginx
client_max_body_size 50m;
proxy_read_timeout 300s;
```

### 坑 3：SQLite 并发写入

SQLite 不支持高并发写入。多个用户同时导入数据时会报 `database is locked`。解决方案：生产环境切 PostgreSQL，或者用 `aiosqlite` 的 WAL 模式临时顶一下。

## 部署

最终用 Docker Compose 一键部署：

```yaml
services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/app

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
```

## 总结

智慧农业平台的技术栈并不复杂，核心是**理解业务需求**。甲方要的不是最先进的技术，是能稳定运行、数据准确、界面好看的系统。

FastAPI + Vue3 这套组合，开发效率高、学习成本低、部署简单，非常适合中小型数据平台。如果你也在做类似的项目，可以参考这个架构。
