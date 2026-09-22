# 人体模型来源与许可

随应用分发的 `body_muscles.glb` 使用真实解剖网格，来源于 [Johan Bellander / BodyExplorer](https://github.com/JohanBellander/BodyExplorer) 的 `public/anatomy.glb`、`public/skeleton.glb` 及结构映射。

原始数据署名：

- **BodyParts3D**，© The Database Center for Life Science，采用 [CC Attribution-Share Alike 2.1 Japan](https://creativecommons.org/licenses/by-sa/2.1/jp/deed.en)。
- **Z-Anatomy**，Gauthier Kervyn，采用 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)。
- 网格前处理、合并与对齐：Johan Bellander / BodyExplorer。

FitLoger 对网格进行了训练肌群筛选、坐标归一化、减面、法线重算、区域合并、材质替换及头部外形简化。挡在胸/腿前方的肋间肌、缝匠肌、内收肌、胫骨前肌等并入邻近可点选训练区；头、手、脚仍作为不可点选遮挡。派生模型采用 CC BY-SA 4.0，并保留以上原始署名。此模型用于训练动作导航，不是医学解剖教学模型。

重建入口：`tools/anatomy/build_muscle_glb.py`（numpy、scipy、fast-simplification 0.1.9）。将上述来源文件和 `mesh_mapping.json` 放入 `.work/anatomy` 后运行脚本。GLB 与 `muscle_manifest.json` 记录原始文件 SHA-256 和保留的解剖结构；18 个训练区域按 `pick_<MuscleKey>_L/R` 命名，模型高 1.8 个单位，正面朝 +Z。
