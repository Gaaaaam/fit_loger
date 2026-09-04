# 训练日志 App v1 设计文档

- 日期：2026-09-04
- 状态：待实施
- 目标：做出一版可安装到真机、能长期自用的训练记录 app，并把「以后补不回来」的数据地基一次打好

---

## 0. 背景

现有代码已经是一个可运行的训练记录 app：日历页选日期 → 日详情页「选部位 → 选动作 → 加组 → 填重量次数」，数据存本地 SQLite（`relationalStore`）。

本次迭代的目标不是加 AI 功能，而是：**让这个 app 好用到自己愿意天天用，同时把数据结构一次性打对，避免将来想做分析和 AI 时发现历史数据不可用。**

前置讨论已确认的两个方向性判断：

1. **入口保持手机点选。** 语音、传感器自动计数这类「让记录消失」的路线是重投入、回报不确定的赌注，且手机点选的理论下限本来就比语音识别更快。
2. **AI 的价值在判断侧而非交互侧。** 智能预填、自动配重、停滞检测大部分是确定性算法加历史数据就能做，可离线、无延迟、无幻觉。LLM 只在「把算好的数字翻译成人话」这一环不可替代，且属于后续版本。

---

## 1. v1 范围判定原则

唯一的判定标准是：**这件事以后能不能补？**

**以后补不回来的，必须进 v1：**

- **数据字段的缺失。** 从今天开始记录，如果 v1 的 set 上没有强度信号字段，那么前几个月的数据永远没有强度信息。等 v2 加上字段时，e1RM 趋势的起点是一片空白，而这段数据恰好是「进步曲线」最有意义的部分。
- **数据丢失。** 没有备份和导出，真机上任何一次卸载、换机或迁移 bug 都会让训练历史归零。这份历史是后续一切分析的唯一燃料。
- **迁移机制的缺失。** 当前 `WorkoutDatabase.init` 每次启动都执行 `CREATE TABLE IF NOT EXISTS`，没有版本号。schema 一旦变化，真机上那个已有数据的库无法演进，只能删库重来。

**以后随时能补的，推迟：**

- 所有展示层（趋势图、统计页、周报）
- 所有派生指标表（可以从原始记录随时重建）
- 所有 AI 与 LLM 功能
- 所有判断类功能（配重建议、停滞检测）

一句话概括 v1：**把数据入口做爽，把数据结构做对，把数据安全做足。分析和 AI 全部推迟。**

---

## 2. 现状评估

### 2.1 已完成且可保留

- 日历页月视图、有记录的日期打点、月份切换
- 日详情页的部位/动作/组三层录入与删除
- SQLite 四表结构与完整的 CRUD 仓储层
- 37 条内置动作的分部位选择
- 输入防抖保存（`SetRow` 的 280ms debounce）

### 2.2 从代码中发现的问题

按严重程度排序，前四条建议在 v1 修掉。

**P0 — 每次改动都全量 reload 并强制重挂载子组件。**

`DayDetailPage` 的每个操作（加组、删组、加动作）都调用 `reload()` 重新查库、替换整个 `DayModel`，并自增 `viewEpoch`。而 `ForEach` 的 key 包含 `viewEpoch`（`${part.id}#${this.viewEpoch}`），所以所有 `@ObjectLink` 子组件被强制重挂载。

后果是：加完一组马上想输入时，`TextInput` 会失焦、光标丢失。这正好命中「加组 → 立刻填数字」这条最高频路径。`tools/verify_project.mjs` 里针对 `viewEpoch` 的那几条断言说明这个机制是为了绕开嵌套数据不刷新的问题而引入的，但代价过大。

正确做法是局部更新内存模型：`addSet` 成功后直接向 `exercise.sets` 数组 push 一个 `SetItem`（用返回的 rowId），不 reload、不 bump epoch。`@Observed` / `@ObjectLink` 本身支持数组变更驱动更新，原来失效的原因是整个 `day` 对象引用被替换掉了。

**P0 — 加组时插入空行，不继承上一组。**

`WorkoutRepository.addSet` 只写入 `tag` 和 `sort_order`，weight 和 reps 都是 NULL。而现实中「再来一组」九成是同样重量再做一次。这是录入成本最大的单点浪费。

**P1 — tag 选择器占满整行且每组都有。**

`SetRow` 里 tag 用了一个 `width('100%')`、`height(40)` 的 `Select`，导致每一组占两行高度，而 tag 在绝大多数情况下都是「正式」。空间浪费和视觉噪音都很重，在一屏要看多个动作时尤其难受。

**P1 — `tag` 把两个维度塞进了一个字段。**

`warmup`/`working` 回答「这组算不算训练量」，`drop`/`ramp` 回答「这组用了什么技法」。一个递减组同时也是正式组，但现在只能选一个，所以任何容量统计都会算错。

**P2 — `updateSet` 用字符串拼接构造 SQL。**

```
`UPDATE workout_sets SET weight = ${weightSql}, reps = ${repsSql}, tag = ? WHERE id = ?`
```

`weightSqlValue` / `repsSqlValue` 做了 `Number` 校验，所以没有注入风险，但应该改为参数绑定。更实际的问题是这两个函数对非法输入静默返回 `'NULL'`，用户输错时数据会被静默丢弃而没有任何提示。

**P2 — 一天内同一个部位只能出现一次。**

`addPart` 里有 `WHERE day_id = ? AND part_key = ?` 的去重逻辑，所以无法记录胸背交替这类练法，动作的真实顺序也被部位强行分组打乱。

**P2 — 没有「今天」快捷入口。**

`CalendarPage` 必须在日历网格里找到今天再点进去。最高频的操作应该有一个直达按钮。

**P3 — 删除单组也弹确认对话框，且无法撤销。**

在健身房里（手汗、匆忙、单手操作）确认框既拦不住误触又拖慢正常操作。删除单组更适合做成可撤销的提示条，删除整天保留确认框。

**P3 — 动作名依赖硬编码常量。**

`EXERCISE_CATALOG` 是 ets 常量而非数据库表，`exerciseName` 找不到时会直接把 `chest_bb_bench` 这种 id 显示给用户。同时用户无法添加表里没有的动作——而这在实际使用中一定会遇到。

---

## 3. v1 范围

### 3.1 数据地基（必做，与 AI 无关）

**版本化迁移框架。** 用 `RdbStore.version` 配一个 migration 列表，`init` 时循环执行到最新版本。

```typescript
interface Migration {
  to: number;
  run: (store: relationalStore.RdbStore) => Promise<void>;
}
```

**迁移前自动备份。** 用 `relationalStore.backup()` 备份到带时间戳的文件，成功后保留最近 5 份，更早的删除。这一步成本极低，但它是训练历史唯一的保险。

**数据导出。** 导出全部数据为 JSON（结构化、含所有字段）和 CSV（扁平化，一行一组，便于丢进表格或喂给外部工具）。

导出功能优先级要高，有三个理由：迁移出问题时有救；将来做成产品时本来就需要；最重要的是**它让你在写任何 AI 代码之前就能验证价值**——把数据丢给外部大模型，让它生成一次周报和停滞分析，十分钟就能判断这套东西对自己有没有用，从而决定后面几十小时该不该投。

### 3.2 Schema 完整化（必做）

见第 4 节完整 DDL。四项变更：

1. 新增 `exercises` 表，动作库从硬编码常量搬进数据库，并带上肌群、动作模式、器械、`weight_step`、`is_bodyweight` 等属性
2. 部位从实体降级为动作属性，`day_exercises` 直接挂 `day_id`，删除 `day_parts` 这一层
3. `workout_sets` 补齐 `status` / `completed_at` / `is_warmup` / `rir` / `technique` / `note`
4. 新增 `body_metrics` 表

### 3.3 自建动作（必做）

开放动作库如果没有 UI 入口就等于没开放。动作选择 sheet 底部加一个「新建动作」，填名称、选部位、选器械即可，其余属性留空。`is_builtin = 0`。

同时把动作名的读取从 `exerciseName()` 常量查找改为从库里读，避免 id 泄漏到界面上。

### 3.4 核心体验：预填 + 打勾（必做，v1 最大的收益点）

这是 v1 真正改变使用感受的地方，而且完全不需要模型。

**上次数据提示（最便宜、最有用）。** 动作卡片标题下直接显示上次同动作的表现：

```
杠铃卧推
上次 8月28日：60×5 / 60×5 / 60×4
```

不改变任何交互，只是把已有数据显示出来。老手看一眼就知道今天该上多少。

**加组继承上一组。** `addSet` 的默认值取该动作上一组的 weight 和 reps，`status = 'planned'`。若是该动作第一组，取上次训练同动作的首个正式组。

**复制上次训练。** 空白日给一个「复制上次训练」按钮，列出最近几次训练日供选，一键克隆整个结构——动作、组数、每组的重量次数全部预填，所有 set 为 `planned`。

**逐组打勾。** 这是关键的交互设计。`planned` 状态的组显示为半透明，数字是预填值；练完一组点一下勾，该组变 `done` 并自动写入 `completed_at`。

这一步把「每组填两个数字」变成了「每组点一下」。如果实际做的和预填不一样，就改那个数字——而这正是现实中的少数情况。**录入成本的下降来自默认值变聪明，而不是来自新的输入方式。**

`status` 字段是这套交互的地基：没有它，预填出来的草稿会立刻进入统计，于是任何分析都会以为你已经练完了。而这种污染事后无法回溯，所以它必须在预填功能之前就存在。

**状态转换规则（必须明确，否则交互会自相矛盾）：**

- 用户手动编辑了 weight 或 reps 的组，**自动转为 `done`**。有编辑意图就等于做了，所以手动录入的体感和现在完全一样——填完数字就结束，不需要额外点勾。
- 打勾按钮只是给「预填值正确、无需修改」的情况用的快捷方式，不是新增的必要步骤。
- 打勾可以取消，取消时清空 `completed_at`，状态回到 `planned`。
- 只有「预填出来但从未被触碰」的组会保持 `planned`。它们不参与任何统计，日历也不为只剩 `planned` 组的日期打点。
- `planned` 组不自动删除（可能是计划中还没做完的部分），但日详情页在存在 `planned` 组时显示一个提示，并提供「清理未完成组」的一键操作。

### 3.5 强度信号的轻量录入（必做，但克制）

`rir` 只在**每个动作的最后一组**上显示一个三档 chip：练到力竭 / 还能做 1-2 下 / 还能做 3 下以上。可跳过，默认不填。

只问最后一组的理由：最后一组最接近力竭，信息量最大；一个动作只问一次，成本可以接受。

这里有个必须承认的张力：入口太隐蔽就永远不会填，字段等于白留；入口太显眼就变成负担。选择「每个动作一次」是折中。**并且派生逻辑必须能在 `rir` 为 NULL 时正常工作**（降级为低置信度或排除出趋势），而不是报错或催填。

### 3.6 录入体验修复（必做）

- 修掉 P0 的全量 reload 与强制重挂载，改为局部更新内存模型
- tag 选择器从占满整行的 `Select` 改为紧凑 chip，且只在非默认值时显示
- `updateSet` 改为参数绑定；非法输入给出可见反馈而不是静默丢弃
- 日历页加「记录今天」直达按钮
- 删除单组改为可撤销提示条；删除整天保留确认框

### 3.7 即时正反馈：PR 提示（建议做）

在一组**转为 `done`** 时（无论是打勾还是手动填完数字）用现算 SQL 检查两件事：这个重量是否是该动作历史最重；这个重量下的 reps 是否是历史最多。命中就弹一个轻量提示。

v1 不建派生表，直接查原始记录即可——数据量在几千条以内，SQLite 毫秒级返回。

这是整个 app 里最便宜的爽点：纯本地、零延迟、而且是老手真正在意的东西。

### 3.8 明确推迟到 v2 及以后

- 三级派生事实表（`exercise_session_stats` / `weekly_stats` / `progress_events`）
- 趋势图与统计页
- 自动配重建议、停滞检测、容量失衡提示
- 统一上下文包 `buildContextPack()`
- `user_memory` 记忆表
- LLM 的三个位置：周报叙事、动作属性自动归类、自然语言查询

推迟的依据是这些全部可以从原始记录重建，不存在数据不可回溯的风险。

---

## 4. 数据库设计

目标版本 `version = 1`。所有时间戳为 Unix 毫秒整数，日期为 `YYYY-MM-DD` 文本。

```sql
CREATE TABLE exercises (
  id                TEXT PRIMARY KEY,          -- 内置用语义 id，自建用 'usr_' + 时间戳
  name              TEXT NOT NULL,
  aliases           TEXT,                      -- 逗号分隔，供搜索与将来的 AI 匹配
  part_key          TEXT NOT NULL,             -- 主部位，仅用于 UI 分组
  primary_muscles   TEXT,                      -- 逗号分隔
  secondary_muscles TEXT,
  movement_pattern  TEXT,                      -- push/pull/hinge/squat/lunge/carry/isolation
  equipment         TEXT,                      -- barbell/dumbbell/machine/cable/bodyweight
  is_unilateral     INTEGER NOT NULL DEFAULT 0,
  is_bodyweight     INTEGER NOT NULL DEFAULT 0,-- 为 1 时 weight 语义是「额外负重」
  weight_step       REAL NOT NULL DEFAULT 2.5, -- 该动作的最小加重单位
  is_builtin        INTEGER NOT NULL DEFAULT 1,
  is_archived       INTEGER NOT NULL DEFAULT 0,
  created_at        INTEGER
);
CREATE INDEX idx_exercises_part ON exercises(part_key, is_archived);

CREATE TABLE workout_days (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  date       TEXT NOT NULL UNIQUE,
  note       TEXT,
  created_at INTEGER
);

CREATE TABLE day_exercises (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  day_id      INTEGER NOT NULL,
  exercise_id TEXT NOT NULL,
  sort_order  INTEGER NOT NULL,
  note        TEXT
);
CREATE INDEX idx_day_exercises_day ON day_exercises(day_id, sort_order);
CREATE INDEX idx_day_exercises_ex  ON day_exercises(exercise_id);

CREATE TABLE workout_sets (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  day_exercise_id INTEGER NOT NULL,
  weight          REAL,
  reps            INTEGER,
  is_warmup       INTEGER NOT NULL DEFAULT 0,
  technique       TEXT,                        -- NULL / drop / ramp / rest_pause / amrap
  rir             INTEGER,                     -- 0=力竭, 1=还能做1~2下, 3=还能做3下以上, NULL=未记录
  status          TEXT NOT NULL DEFAULT 'done',-- 'planned' | 'done'
  completed_at    INTEGER,
  note            TEXT,
  sort_order      INTEGER NOT NULL
);
CREATE INDEX idx_workout_sets_de ON workout_sets(day_exercise_id, sort_order);

CREATE TABLE body_metrics (
  date       TEXT PRIMARY KEY,
  weight_kg  REAL,
  note       TEXT,
  created_at INTEGER
);
```

### 字段说明

**`weight_step`** 是将来自动配重建议的必要输入，在 v1 就已经有用：让录入时的加减按钮变聪明，杠铃 +2.5、哑铃 +2、绳索按档位 +5。

**`is_bodyweight`** 解决俯卧撑和引体向上的语义混乱。现在这两类动作的 `weight` 要么是 NULL 要么是负重值，两种含义混在一个字段里。标记之后，`weight` 统一表示「额外负重」，真实强度 = 体重 + 额外负重，这也是 `body_metrics` 存在的理由。

**`rir` 的三档编码**存代表值 0 / 1 / 3，语义分别是「力竭」「还能做 1~2 下」「还能做 3 下以上」。这样 `rir <= 1` 就能表达「接近力竭」，便于查询。

**`status`** 只有两个值。`planned` 的组不参与任何统计聚合，所有聚合查询都必须带 `WHERE status = 'done'`。

**外键**在 DDL 里不声明，由应用层保证一致性（沿用现有代码的做法，避免 `relationalStore` 上的外键开关差异带来意外）。

---

## 5. 迁移方案

### 5.1 两种情形

**全新安装。** 直接执行第 4 节全部 DDL，灌入内置动作，`store.version = 1`。

**已有旧库。** 真机或模拟器上可能已经有旧 schema 的 `workout.db`（`version` 为 0 且存在 `workout_days` 表）。虽然里面大概只有测试数据，仍建议写这个迁移分支——逻辑简单，而且是验证 migration 框架本身的最好机会，同时不会误删已录的数据。

### 5.2 legacy → v1 的步骤

```sql
-- 1. 备份（代码层 relationalStore.backup()）

-- 2. 重命名旧表，腾出表名
ALTER TABLE day_exercises RENAME TO day_exercises_legacy;
ALTER TABLE workout_sets  RENAME TO workout_sets_legacy;

-- 3. 执行第 4 节全部 DDL（workout_days 已存在，仅 ALTER 补 note / created_at）
ALTER TABLE workout_days ADD COLUMN note TEXT;
ALTER TABLE workout_days ADD COLUMN created_at INTEGER;

-- 4. 灌入 37 条内置动作

-- 5. 迁移动作：把 day_parts 这一层展平掉
INSERT INTO day_exercises (id, day_id, exercise_id, sort_order)
SELECT e.id,
       p.day_id,
       e.exercise_id,
       ROW_NUMBER() OVER (PARTITION BY p.day_id ORDER BY p.sort_order, p.id, e.sort_order, e.id) - 1
FROM day_exercises_legacy e
JOIN day_parts p ON p.id = e.day_part_id;

-- 6. 迁移组：从旧 tag 派生新字段
INSERT INTO workout_sets
  (id, day_exercise_id, weight, reps, is_warmup, technique, rir, status, completed_at, note, sort_order)
SELECT id,
       exercise_row_id,
       weight,
       reps,
       CASE WHEN tag = 'warmup' THEN 1 ELSE 0 END,
       CASE WHEN tag IN ('drop','ramp') THEN tag ELSE NULL END,
       NULL,        -- 历史数据没有强度信号，保持 NULL
       'done',      -- 历史记录都是已完成
       NULL,        -- 历史数据没有完成时间，保持 NULL
       NULL,
       sort_order
FROM workout_sets_legacy;

-- 7. 保留 day_parts / *_legacy 表，暂不删除
```

如果 `relationalStore` 底层 SQLite 不支持窗口函数（需 3.25+），第 5 步改为在应用层读出全部行、按 `(part.sort_order, part.id, ex.sort_order, ex.id)` 排序后重新计算 `sort_order` 再逐条写入。数据量小，性能无差异。

### 5.3 两条必须守死的规则

**旧表不急着删。** `day_parts` 和两张 `_legacy` 表全部保留。SQLite 的 `DROP COLUMN` 要 3.35+ 才支持，而且删了就无法回滚。等新代码在真机上跑稳几个月再清理。

**绝不为缺失数据编造默认值。** 历史 set 没有 `rir` 和 `completed_at`，就让它们保持 NULL。诱惑很大——填个默认值图表就好看了、也不用处理 NULL 分支了。但那等于往数据里注入假事实，然后所有基于它的分析和建议都建立在假数据上。派生逻辑必须能处理 NULL：标为低置信度或排除出趋势，而不是当成 0。

---

## 6. UI 与录入流程调整

### 6.1 部位降级后界面怎么变

**视觉上几乎不变。** 日详情页仍按部位分组显示，`PartSection` 组件保留。分组方式从「读 `day_parts` 表」变成「读出该日全部动作，按 `exercises.part_key` 分组」，组的排序按该部位第一个动作的 `sort_order`。

**「添加部位」按钮消失**，合并为一个「添加动作」按钮。点击后仍是两步 sheet：先选部位（**这一步不落库，纯筛选**），再选动作，选完才写入 `day_exercises`。

这顺手解决了「加了部位却忘了加动作，留下一个空 section」的问题。

**一个要承认的取舍：** 数据层现在保留了动作的真实顺序，但按部位分组显示会把同部位的动作聚到一起，所以胸背交替这类练法在界面上看不出真实顺序。v1 接受这个取舍（分组视图符合现有习惯），将来可以加一个「按实际顺序」的视图开关，数据层已经支持。

### 6.2 组的行内布局

一行放下：`planned` 勾选框、重量输入、次数输入、以及一个紧凑的 tag chip（仅当非「正式」时显示）。原来占满整行的 `Select` 去掉。

`rir` 的三档 chip 只出现在每个动作的最后一组下方，且可跳过。

### 6.3 日历页

顶部加「记录今天」直达按钮。有记录的日期打点逻辑不变，但查询要改为只统计有 `done` 组的日期，避免只剩预填草稿的日子也被打点。

---

## 7. 关键设计约束

这些是跨版本的长期规则，实施时不要为了省事绕过。

1. **`status` 必须先于预填存在。** 否则预填草稿会污染统计，且污染不可回溯。
2. **所有聚合查询必须带 `status = 'done'`。**
3. **绝不为缺失数据编造默认值。** NULL 就是 NULL。
4. **派生数据是缓存不是数据源。** v1 虽然还没有派生表，但从现在起就不要往任何聚合结果里写入无法从原始记录重建的信息。
5. **迁移前必须备份。**
6. **AI 不做算术。** 将来接入 LLM 时，所有数字必须由 SQL 算好后喂给它，模型只负责归纳和表达。
7. **AI 是异步增强层，不在关键路径上。** 健身房常常没信号，录入必须完全离线可用。

---

## 8. 实施顺序

分四批，每批都可以独立装到真机上验证。

**第一批：地基（无风险，不改任何界面）**
1. migration 框架 + `store.version`
2. 迁移前自动备份
3. 数据导出（JSON + CSV）

**第二批：schema 与仓储层**
4. 执行 legacy → v1 迁移
5. 仓储层适配新表结构（`day_parts` 相关方法删除，新增 `day_exercises` 直挂 `day_id` 的读写）
6. 更新 `tools/verify_project.mjs`——它目前断言数据库里存在 `day_parts` 表、断言仓储层有 `addPart`/`deletePart` 方法，schema 变更后会失败

**第三批：录入体验（收益最大）**
7. 修掉全量 reload 与强制重挂载（P0）
8. 上次数据提示
9. 加组继承上一组
10. 预填 + 逐组打勾
11. 复制上次训练
12. 行内布局重排、tag chip、`rir` chip
13. 日历页「记录今天」

**第四批：收尾**
14. 自建动作
15. PR 即时提示
16. 删除交互改为可撤销
17. `body_metrics` 录入入口（简单的一页，一周填一次）

第一批和第二批做完就应该先装一次真机，确认迁移和备份没问题、老数据完整，再动第三批。

---

## 9. 验收标准

v1 算完成的判据：

- 真机安装后能连续记录两周不出现数据丢失或崩溃
- 从空白日「复制上次训练」到全部打勾完成一次训练，比现在的录入方式明显更快
- 导出的 JSON 能完整还原所有记录，包括 `status`、`rir`、`completed_at`
- 卸载重装前导出、重装后导入，数据一致
- 手动把 `store.version` 改回 0 重跑一次，迁移幂等、数据不重不丢
- 一天内可以记录同一部位的多个不连续动作段（验证部位降级生效）

---

## 10. 附录：已推迟设计的完整记录

以下内容在前置讨论中已经设计完成，v1 不实施，记录下来避免将来重复推导。

### 10.1 三级派生事实层

```sql
-- 第 1 级：某动作在某天的表现，单一事实来源
CREATE TABLE exercise_session_stats (
  date TEXT, exercise_id TEXT,
  top_weight REAL, best_e1rm REAL,
  work_sets INTEGER, total_reps INTEGER,
  volume_load REAL, min_rir INTEGER,
  PRIMARY KEY (date, exercise_id)
);

-- 第 2 级：周度容量
CREATE TABLE weekly_stats (
  iso_week TEXT, part_key TEXT,
  work_sets INTEGER, volume_load REAL, sessions INTEGER,
  PRIMARY KEY (iso_week, part_key)
);

-- 第 3 级：事件层，AI 的叙事素材
CREATE TABLE progress_events (
  id INTEGER PRIMARY KEY,
  date TEXT, type TEXT,   -- pr_weight / pr_e1rm / stall / volume_imbalance
  exercise_id TEXT, payload TEXT,
  consumed INTEGER DEFAULT 0
);
```

维护方式：应用层在写入后增量重算受影响的 `(date, exercise_id)`，并保留全量重建入口。不用 SQLite 触发器（逻辑复杂、无法测试）。

### 10.2 指标选择的结论

**e1RM 只能做同一动作的纵向比较，不能跨动作比绝对值。** 公式（Epley `w × (1 + reps/30)`）假设所有人力量-耐力曲线相同、且默认该组是力竭的。前者导致跨人跨动作不可比，后者意味着**没有 RIR 的 e1RM 基本是噪声**。但公式偏差对同一人同一动作是系统性的，求差时抵消，所以纵向趋势可信。

**`volume_load`（Σ weight × reps）不适合当进步主判据。** 它把重量和次数当成等价物（60×5 和 30×10 都是 300），并且奖励做轻的——想让这个数字涨，最容易的办法是降重量加次数。降级为辅助指标，只用于看总负荷趋势和检测急性负荷突增（近 1 周相对近 4 周均值突增 50% 以上，作为伤病风险提示）。

**进步判据按动作类型分层：**

- 大复合动作（按 `movement_pattern` + `equipment` 识别出的深蹲/卧推/硬拉/推举/划船）：看 e1RM 趋势，只采纳 `rir IS NOT NULL AND rir <= 1 AND reps <= 8` 的组。因为 v1 只在每个动作的末组记录 `rir`，这个条件实际上等价于「末组接近力竭且在低次数区间时才产生一个 e1RM 数据点」；末组若是 back-off 组或 `rir = 3`，该次训练就不产生数据点。宁可数据点稀疏，也不要用噪声填满趋势线。
- 孤立与小肌群动作：不算 e1RM，看 top set 重量和同重量下的 reps 变化
- 自重动作：看总 reps，或代入体重后的 e1RM

**容量主指标是每部位每周的正式组数**（`is_warmup = 0 AND status = 'done'`）。理由是训练学上的容量参考区间本来就用组数定义，而不是用 volume load。

这里要修正一个早期设想：曾经打算用「有效组数」（按 `rir` 过滤掉远离力竭的组）作为容量指标，但这与 v1 的录入设计冲突——`rir` 只在每个动作的末组记录，绝大多数组的 `rir` 是 NULL，任何逐组的 `rir` 过滤都会退化成「只剩末组」。所以 `rir` 的正确用途不是过滤容量，而是作为该动作当次努力程度的标记（`min_rir`），用于 e1RM 的置信度判定和停滞检测。如果将来改成逐组记录 `rir`，再引入有效组数的概念。

**训练密度**（负荷 ÷ 训练时长）在有了 `completed_at` 之后可算，回答「是不是练得越来越拖」，属于锦上添花。

### 10.3 关于噪声的诚实前提

所有指标在数据量少时都是噪声。力量表现的周间自然波动本身就有 ±5%，来源是睡眠、饮食、压力这些根本没记录的变量。

因此停滞检测必须用足够长的窗口（4 周是合理下限）并用趋势拟合，而不是点对点比较。否则系统会几乎每周都说「你停滞了」，两次之后就再也不会有人看它。

**AI 原生功能翻车最常见的方式不是算错，而是话说得太满、太频繁。**

### 10.4 统一上下文包

将来所有 LLM 功能消费同一个包，而不是各自拼 prompt：

```
buildContextPack(scope) → {
  profile:        体重趋势、训练年限
  memory:         伤病、偏好、目标
  recentVolume:   最近 4 周各部位周组数
  keyLifts:       主要动作的 e1RM 近 12 周趋势（按周降采样）
  recentSessions: 最近 14 天训练概要
  pendingEvents:  未消费的 progress_events
}
```

这样加一个 AI 功能不需要重新设计数据通路，也不会出现两个功能对同一份数据给出不同结论。token 预算也因为结构固定而可控。

### 10.5 记忆表

```sql
CREATE TABLE user_memory (
  id INTEGER PRIMARY KEY,
  kind TEXT,          -- injury / preference / goal / constraint
  content TEXT,       -- 自然语言原文：'右肩有伤，避免过顶推'
  structured TEXT,
  source TEXT,        -- 'user_explicit' | 'ai_inferred'
  confidence REAL,
  is_active INTEGER DEFAULT 1,
  created_at INTEGER
);
```

这是「记得你」的地方，也是普通记录 app 和 AI 原生 app 差别最大的地方。`source` 和 `confidence` 是可信度设计：AI 自己推断出的记忆必须标明来源，且必须在界面上可见、可删。用户能看到 AI 记住了什么并纠正它，是信任的前提。

### 10.6 LLM 值得用的三个位置

1. **周报/月报的自然语言叙事**——把算好的数字翻译成人话并给建议。异步生成、失败无损、每周一次成本可忽略。
2. **动作属性自动归类**——用户新建动作时补全肌群、动作模式。一次性调用，结果缓存进库。
3. **自然语言查询**——「我深蹲今年涨了多少」。可选，锦上添花。
