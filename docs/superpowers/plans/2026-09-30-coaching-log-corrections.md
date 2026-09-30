# 训练记录修正 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让已记录的组能按教练口径使用：RIR 精确到 0–3，旧的合并档不再冒充 RIR 1，e1RM 加上剩余次数，自重和单侧容量按真实负荷计，备注和休息暂停 / AMRAP 能写下来。

**Architecture:** 判断规则留在 `TrendLogic` / `WorkoutLogic` 与同源 Node 脚本里，先改测试再改实现。数据库从 schema 2 升到 3，只给 `workout_sets` 加 `rir_legacy`。备注列原本就在，这次只补界面和保存。导出 JSON 升到 version 3；旧 JSON 导入时把 RIR 1 和 3 标成早期合并档。

**Tech Stack:** HarmonyOS NEXT ArkTS、relationalStore、Node 校验脚本（`tools/verify_*.mjs`）。

## Global Constraints

- 新记录的 RIR 只有 `0`、`1`、`2`、`3`，文案分别是「力竭」「还能做 1 下」「还能做 2 下」「还能做 3 下」。
- 升级前已经写下的 `rir = 1` 或 `rir = 3` 标 `rir_legacy = 1`。界面显示「早期：还能做 1–2 下」或「早期：还能做 3 下以上」，不当成精确 RIR。`rir = 0` 保持精确力竭。
- 用户改选新的 RIR 后，`rir_legacy` 写成 0。
- 精确 RIR 0 或 1、正式组、次数 1–8、非递减 / 递增 / 休息暂停：e1RM 用 Epley，有效次数 = 次数 + RIR。
- 没填 RIR，或早期合并档且 `rir = 1`：仍按原次数估算，并标「估算」。早期 `rir = 3` 和精确 RIR 2、3 不进入 e1RM。
- 自重正式组容量 =（当天或之前最近一次体重 + 额外负重）× 次数。没有可用体重时该组不计入容量。
- `is_unilateral = 1` 的次数按每侧计，容量再乘 2。卡片次数框写「每侧次数」。
- 训练日、动作、组各有一条可选备注，最长 80 字，空备注不占日历打点。
- 组标记补上「休息暂停」和「AMRAP」。休息暂停仍不进入 e1RM，AMRAP 可以进入。
- 不提交 git，除非用户另行要求。

---

### Task 1: RIR 刻度、早期档与 e1RM

**Files:**
- Modify: `tools/trend_logic.mjs`
- Modify: `tools/verify_trend_logic.mjs`
- Modify: `entry/src/main/ets/common/TrendLogic.ets`
- Modify: `entry/src/main/ets/model/types.ets`
- Modify: `entry/src/main/ets/components/SetRow.ets`
- Modify: `entry/src/main/ets/model/DayModels.ets`
- Modify: `entry/src/main/ets/db/schemaSql.ets`
- Modify: `entry/src/main/ets/db/WorkoutDatabase.ets`
- Modify: `entry/src/main/ets/db/WorkoutRepository.ets`
- Modify: `entry/src/main/ets/db/ExportService.ets`
- Modify: `entry/src/main/ets/common/WorkoutLogic.ets`
- Modify: `tools/workout_logic.mjs`
- Modify: `tools/verify_v1_logic.mjs`
- Modify: `entry/src/main/ets/common/TrendGuide.ets`
- Modify: `tools/trend_guide.mjs`
- Modify: `entry/src/main/ets/pages/TrendExerciseDetailPage.ets`
- Modify: `tools/verify_project.mjs`

**Interfaces:**
- Produces: `e1rmEffectiveReps(row)`, `workingLoadKg(row)`, `setVolume(row)`, `sessionRirText(minRir, rirLegacy)`, `rirLegacyForImport(version, rir, storedLegacy)`, `rirLabel(rir, legacy)`
- `TrendSetRow` 增加 `rirLegacy`、`isUnilateral`、`bodyWeightKg`
- `SetItem.rirLegacy`，`ExerciseItem.isUnilateral`，`ExerciseSessionRow.rirLegacy`

- [x] **Step 1:** 在 `verify_trend_logic.mjs` 写失败断言：精确 RIR 1 的 `60×5` e1RM 为 `72`；`rirLegacy = 1` 且 `rir = 1` 不算严格 e1RM、按原次数估算；精确 RIR 2 不进入 e1RM。
- [x] **Step 2:** 跑 `node tools/verify_trend_logic.mjs`，确认新断言失败。
- [x] **Step 3:** 实现规则，并让 schema 3 在加列时执行 `UPDATE workout_sets SET rir_legacy = 1 WHERE rir IN (1, 3)`。导入 version < 3 的 JSON 时套用同一规则。
- [x] **Step 4:** 组行改成 0/1/2/3 两行芯片；早期档单独提示，选中态只在 `rirLegacy = 0` 时亮起。
- [x] **Step 5:** 趋势详情用 `sessionRirText`。更新 RIR / e1RM 说明，保留「没填 RIR」「估算」「数据不足」这些校验关键字。

### Task 2: 自重容量与单侧次数

**Files:**
- Modify: `tools/trend_logic.mjs`
- Modify: `tools/verify_trend_logic.mjs`
- Modify: `entry/src/main/ets/common/TrendLogic.ets`
- Modify: `entry/src/main/ets/db/WorkoutRepository.ets`
- Modify: `entry/src/main/ets/components/SetRow.ets`
- Modify: `entry/src/main/ets/components/ExerciseCard.ets`

**Interfaces:**
- Consumes: `setVolume(row)`、`workingLoadKg(row)`
- `loadTrendSets` 带上 `is_unilateral`、`rir_legacy`，并用子查询带上该日之前最近体重

- [x] **Step 1:** 断言：体重 70、额外负重 10、8 次的自重容量是 640；没有体重的自重组容量是 `null`；单侧 20kg × 每侧 10 次的容量是 400。
- [x] **Step 2:** 跑趋势校验，确认失败。
- [x] **Step 3:** 实现 `workingLoadKg` / `setVolume`，查询侧填上字段。
- [x] **Step 4:** 单侧动作的次数占位写成「每侧次数」。

### Task 3: 可选备注

**Files:**
- Modify: `entry/src/main/ets/model/DayModels.ets`
- Modify: `entry/src/main/ets/db/WorkoutRepository.ets`
- Modify: `entry/src/main/ets/pages/DayDetailPage.ets`
- Modify: `entry/src/main/ets/components/ExerciseCard.ets`
- Modify: `entry/src/main/ets/components/SetRow.ets`
- Modify: `entry/src/main/ets/common/WorkoutLogic.ets`
- Modify: `tools/workout_logic.mjs`
- Modify: `tools/verify_v1_logic.mjs`

**Interfaces:**
- Produces: `trimNote(text)`，最长 80
- `WorkoutRepository.saveDayNote(date, note)`、`saveExerciseNote(exerciseRowId, note)`
- 组备注继续走已有的 `writeSet`

- [x] **Step 1:** 断言 `trimNote` 会去掉首尾空白并截到 80 字。
- [x] **Step 2:** 日详情、动作卡、组行各加一行可选输入。空日备注不制造日历打点：没有动作且备注为空时删掉空的训练日。
- [x] **Step 3:** 复制训练不复制备注。

### Task 4: 休息暂停与 AMRAP

**Files:**
- Modify: `entry/src/main/ets/components/SetRow.ets`
- Modify: `tools/verify_project.mjs`

- [x] **Step 1:** 标记面板加入「休息暂停」「AMRAP」，说明文字写明选择标记不会完成这一组。
- [x] **Step 2:** `verify_project.mjs` 改为要求 schema 3、导出 version 3、`rir_legacy`，以及上述界面文案。

### Task 5: 校验

- [x] 跑 `node tools/verify_trend_logic.mjs`、`node tools/verify_v1_logic.mjs`、`node tools/verify_trend_guide.mjs`、`node tools/verify_project.mjs`。
- [x] 四条都通过后再结束。不创建 git commit。
