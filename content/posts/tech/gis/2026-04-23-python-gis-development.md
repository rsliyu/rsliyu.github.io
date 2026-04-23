---
title: "用Python做GIS：从GeoPandas到空间数据库"
date: 2026-04-23T17:00:00+08:00
categories: ["技术笔记", "GIS"]
tags: ["GIS", "Python", "GeoPandas", "PostGIS", "空间分析"]
summary: "Python GIS开发实战经验，从GeoPandas快速上手到PostGIS生产部署。"
author: "李俊昊"
showToc: true
TocOpen: true
weight: 3
---

GIS开发经历了从桌面端到Web端、从商业软件到开源生态的转变。Python作为GIS开发的主力语言，拥有丰富的库和工具链。

## GeoPandas：快速上手

```python
import geopandas as gpd
from shapely.geometry import Point

gdf = gpd.read_file("buildings.shp")
point = Point(108.94, 34.26)
buffer = point.buffer(0.005)
nearby = gdf[gdf.geometry.intersects(buffer)]
```

GeoPandas的优势是开发效率高，但处理大数据时性能是个问题。

## PostGIS：生产级空间数据库

```sql
CREATE INDEX idx_buildings_geom ON buildings USING GIST(geom);

SELECT name, ST_Distance(
    geom::geography,
    ST_SetSRID(ST_MakePoint(108.94, 34.26), 4326)::geography
) AS distance
FROM buildings
ORDER BY geom <-> ST_SetSRID(ST_MakePoint(108.94, 34.26), 4326)
LIMIT 10;
```

## 实际项目中的选择

| 场景 | 推荐方案 |
|------|----------|
| 快速原型/小数据 | GeoPandas |
| 大数据批处理 | Dask-GeoPandas |
| 生产环境/多用户 | PostGIS |
| Web服务 | PostGIS + GeoServer |
| 云原生 | PMTiles + 静态托管 |

## 踩过的坑

1. **坐标系问题**：每个环节都要确认坐标系
2. **几何有效性**：`gdf.geometry.make_valid()`
3. **空间索引**：一定要建GIST索引

---

*本文基于个人在GIS开发项目中的实践经验整理。*