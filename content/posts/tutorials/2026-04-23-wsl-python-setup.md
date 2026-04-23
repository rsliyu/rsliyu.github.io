---
title: "WSL开发环境配置：从零搭建Python+GIS开发环境"
date: 2026-04-23T19:00:00+08:00
categories: ["新手指南", "环境配置"]
tags: ["WSL", "Python", "Linux", "开发环境", "GIS"]
summary: "在WSL2中搭建完整的Python开发环境，涵盖venv、GDAL、PyTorch等。"
author: "李俊昊"
showToc: true
TocOpen: true
weight: 1
---

WSL2是Windows用户的Linux开发环境最佳选择，提供了完整的Linux内核，可以直接使用apt安装软件包。

## 安装WSL2

```powershell
wsl --install
```

安装完成后重启电脑，打开Ubuntu终端设置用户名和密码。

## 基础环境配置

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget build-essential libgdal-dev gdal-bin
```

## Python环境管理

推荐用venv而不是conda，更轻量：

```bash
python3 -m venv ~/venv/main
source ~/venv/main/bin/activate
pip install --upgrade pip
```

## 常用包安装

```bash
# GIS核心
pip install geopandas shapely fiona pyproj rasterio

# AI/ML
pip install torch torchvision scikit-learn

# Web开发
pip install fastapi uvicorn sqlalchemy
```

## 常见问题

1. **内存不足**：通过`~/.wslconfig`调整，`[wsl2] memory=8GB`
2. **磁盘空间**：WSL2的vhdx文件会自动增长但不会自动压缩，需手动`wsl --shutdown`后压缩
3. **网络问题**：配置代理或使用国内镜像源

---

*本文基于个人在WSL2环境配置中的实践经验整理。*