# 人体模型来源与许可

第一版随应用分发的 `body_muscles.glb` 是本项目生成的低面数训练用人体，带有稳定的 `pick_<MuscleKey>[_L|_R]` 节点名，用于 18 个常用训练肌群的点选。它不是 Z-Anatomy 科学解剖网格的直接导出。

预定替换路径（若后续改用 Z-Anatomy 派生模型）：

1. 从 [Z-Anatomy / Models-of-human-anatomy](https://github.com/Z-Anatomy/Models-of-human-anatomy) 取得表层肌肉。
2. 精简网格、统一浅灰哑光材质，只保留本应用 18 个训练区域。
3. 将网格重命名为与本文件相同的 `pick_*` 节点，直接替换 `entry/src/main/resources/rawfile/models/body_muscles.glb`。
4. 派生模型须继续按 CC BY-SA 4.0 署名并随包提供许可文件。

Z-Anatomy 许可：Creative Commons Attribution-ShareAlike 4.0 International。
项目：https://github.com/Z-Anatomy/Models-of-human-anatomy
