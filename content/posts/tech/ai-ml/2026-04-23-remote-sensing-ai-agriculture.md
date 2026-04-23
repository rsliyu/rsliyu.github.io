---
title: "遥感+AI：农业保险中的深度学习应用"
date: 2026-04-23T18:00:00+08:00
categories: ["技术笔记", "AI/ML"]
tags: ["AI", "深度学习", "遥感", "农业保险", "Python"]
summary: "遥感技术在农业保险中的实际应用，从灾害评估到作物识别。"
author: "李俊昊"
showToc: true
TocOpen: true
weight: 2
---

农业保险是一个典型的"遥感+AI"落地场景。传统农险依赖人工查勘，效率低、成本高、主观性强。遥感+AI的组合正在改变这个局面。

## 应用场景

### 1. 灾害评估

洪涝、干旱、冰雹等灾害发生后，遥感可以快速评估受灾范围和程度。

```python
def calculate_flood_extent(pre_event, post_event, threshold=-0.3):
    with rasterio.open(pre_event) as pre:
        ndwi_pre = (pre.read(3) - pre.read(5)) / (pre.read(3) + pre.read(5))
    with rasterio.open(post_event) as post:
        ndwi_post = (post.read(3) - post.read(5)) / (post.read(3) + post.read(5))
    
    delta = ndwi_post - ndwi_pre
    return delta < threshold
```

### 2. 作物识别

不同作物的光谱特征和物候特征不同。通过NDVI时序曲线，可以有效区分不同作物类型。

### 3. 面积核实

遥感可以提供客观的面积测量结果，是农险承保面积核实的最佳方案。

## 技术挑战

- **云覆盖**：多时相数据融合、SAR数据补充
- **分辨率矛盾**：数据融合算法
- **样本获取**：主动学习、半监督学习

## 实际项目经验

使用Sentinel-2数据进行冬小麦面积核实，总体精度达到85%。关键发现：NDVI时序曲线的峰值位置对区分冬小麦和春小麦很有效，红边波段对植被识别贡献显著。

---

*本文基于个人在农业保险遥感项目中的实践经验整理。*