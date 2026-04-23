---
title: "遥感影像分类：从传统方法到深度学习"
date: 2026-04-23T16:00:00+08:00
categories: ["技术笔记", "遥感"]
tags: ["遥感", "深度学习", "PyTorch", "图像分类", "Python"]
summary: "梳理遥感影像分类的技术演进，从最大似然到ResNet，记录踩过的坑和实战经验。"
author: "李俊昊"
showToc: true
TocOpen: true
weight: 2
---

遥感影像分类是遥感应用中最基础也最核心的任务之一。从最早的目视解译到现在的深度学习，这个领域经历了几代技术更迭。

## 传统分类方法

### 最大似然分类（MLC）

假设每类地物的光谱响应服从多元正态分布，通过计算像元属于各类的概率来分类。优点是理论成熟、实现简单，缺点是需要大量训练样本且对高维数据容易出现协方差矩阵奇异的问题。

### 支持向量机（SVM）

通过寻找最优超平面来分类，在小样本场景下表现优于MLC。核函数的选择很关键——RBF核在大多数场景下效果不错，但参数调优需要经验。

### 随机森林

集成学习方法，抗过拟合能力强，还能输出特征重要性。在遥感分类中用得很多，尤其是多源数据融合的场景。

## 深度学习方法

### 卷积神经网络（CNN）

CNN的出现彻底改变了遥感影像分类的范式。通过卷积层自动提取空间特征，不再依赖人工设计的特征。

```python
import torch
import torch.nn as nn

class RemoteSensingClassifier(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, 3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, 3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d(1),
        )
        self.classifier = nn.Linear(64, num_classes)

    def forward(self, x):
        x = self.features(x)
        x = x.view(x.size(0), -1)
        return self.classifier(x)
```

### ResNet在遥感中的应用

ResNet通过残差连接解决了深层网络的梯度消失问题。在遥感影像分类中，ResNet-50是最常用的backbone。

实际项目中的发现：
- **预训练权重很重要**：用ImageNet预训练的权重初始化，比从头训练收敛快得多
- **数据增强要适度**：旋转、翻转是基础，但过度的颜色抖动会降低光谱信息的有效性
- **多尺度特征融合**：遥感影像中地物尺度差异大，FPN结构很有帮助

## 实战中的坑

### 1. 样本不均衡

遥感数据中不同地物类型的样本数量差异很大。解决方案：加权损失函数、过采样/欠采样、Focal Loss。

### 2. 跨区域泛化

在一个区域训练的模型，到另一个区域效果可能很差。迁移学习和域适应是解决这个问题的方向。

### 3. 标注成本

高质量的遥感标注数据非常昂贵。半监督学习和自监督学习是降低标注成本的有效途径。

---

*本文基于个人在遥感影像分类项目中的实践经验整理，如有错误欢迎指正。*