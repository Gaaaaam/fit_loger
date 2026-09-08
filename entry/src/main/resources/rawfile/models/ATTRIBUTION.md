# FitLoger 肌肉模型

随应用提供的 `body_muscles.glb` 使用真实人体解剖网格，不是椭球占位模型。

## 来源

- **BodyParts3D — The Database Center for Life Science**，原始网格许可为 [CC BY-SA 2.1 Japan](https://creativecommons.org/licenses/by-sa/2.1/jp/)。
- **Z-Anatomy — The libre 3D atlas of anatomy**，Gauthier Kervyn 等贡献者，[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)。[原始项目](https://github.com/Z-Anatomy/Models-of-human-anatomy)。
- 中间网格由 **Johan Bellander / BodyExplorer** 整理、配准和导出。本项目只使用其公开人体数据，未引入其网页应用代码。[中间资产及署名说明](https://github.com/JohanBellander/BodyExplorer)。

## 本项目的修改

筛选训练相关肌肉与必要的骨骼、结缔组织，转换为 Y 向上、Z 朝前、身高 1.8 米的统一坐标；按原始解剖结构分别减面、重算法线，并合并为左右独立的 18 个训练区域。头部使用源头骨轮廓生成无面部细节的外壳，减少解剖图谱的视觉干扰。统一为灰绿色哑光材质，每个可选节点独立材质。派生模型按 CC BY-SA 4.0 提供，保留上述原始来源与许可。

训练区域属于应用分组：上背包括斜方肌中下部、冈下肌、大小圆肌与菱形肌；“斜方肌”选区侧重可见上部。腹斜肌区域也包含前锯肌的侧躯干表面。骨骼、手足和非目标组织提供外形与遮挡，不会被误判为背面的目标肌肉。

## 可复现构建

依赖：Python、numpy、scipy、fast-simplification 0.1.9。工具依赖仅用于离线资产处理，不进入鸿蒙应用运行时。

从上述 BodyExplorer 仓库下载 `public/anatomy.glb` 与 `public/skeleton.glb` 到 `.work/anatomy/`，运行：

```text
python tools/anatomy/build_muscle_glb.py --source-dir .work/anatomy
python tools/anatomy/verify_asset.py
```

源文件的 SHA-256 记录在模型内部和同目录 `muscle_manifest.json`。后者同时列出节点对应的每个原始解剖结构，可用于追溯与替换资产。发布模型时一并保留 `ATTRIBUTION.md`、`LICENSE.txt`、`muscle_manifest.json` 与资产处理脚本。
