# 训练日志（Fit Loger）

HarmonyOS NEXT 上的离线训练记录应用。面向自己长期使用：把当天训练记得又快又准，并把数据结构一次打对，方便以后做趋势分析和导出。

包名：`com.fitloger.app`  
当前版本：`1.0.0`  
设备：手机

## 能做什么

- **日历入口**：月视图打点（已训练 / 已计划 / 休息 / 未安排），一键「记录今天」。
- **日详情录入**：按部位或按动作两种视图；添加动作、加组、填重量次数；手动勾选完成。
- **预填与提示**：新组继承上一组（或上次训练的正式组）；卡片显示上次表现；完成时检测重量 / 次数 PR。
- **动作库**：120 条内置动作，覆盖胸、肩、背、手臂、臀、腿、腹、核心、有氧；支持搜索、器械筛选、自建动作。
- **三维选动作**：在人体模型上点选 18 个训练肌群，批量加入当日计划。
- **动作说明**：起始姿势、步骤、计数方式和配图，可在动作卡片或选择器里打开。
- **身体数据**：身高、体重（自重动作会用到体重）。
- **数据安全**：schema 版本迁移前自动备份（保留最近 5 份）；「我的」页可导出 JSON/CSV，也可从 JSON 导入。
- **外观**：浅色 / 暗色主题。

趋势页目前是占位，图表尚未接入主分支。

## 技术栈

| 层 | 选型 |
| --- | --- |
| 系统 | HarmonyOS NEXT，compatible / target SDK `6.0.0(20)` |
| UI | ArkTS + ArkUI |
| 3D | `@kit.ArkGraphics3D`（人体肌群点选） |
| 存储 | `@kit.ArkData` `relationalStore`（SQLite）+ Preferences |
| 构建 | Hvigor / DevEco Studio |
| 校验 | Node.js 脚本（`tools/verify_*.mjs`），不依赖设备 |

无第三方 npm 运行时依赖。业务规则（解析、继承、PR、导出扁平化、肌群推荐等）写在 ArkTS 纯函数里，并用同源 Node 脚本做静态校验。

## 架构

```
EntryAbility
  ├─ WorkoutDatabase.init()     打开 workout.db，按 version 迁移
  └─ AppSettings.init()         主题 / 身高 / 日详情视图
        │
        ▼
     MainPage（底部 Tabs）
        ├─ 日历 → DayDetailPage → 部位/动作 Sheet、动作详情
        │                      └─ MusclePickerPage（3D 人体）
        ├─ 趋势（占位）
        └─ 我的 → BodyMetricsPage
               └─ 导出 / 导入
```

分层约定：

- **pages / components**：ArkUI 交互与局部状态。日详情用内存模型增量更新，不为每次加组整页 reload。
- **db**：只做 RdbStore I/O。`WorkoutRepository` 是唯一业务仓储。
- **common**：可在 Node 侧镜像测试的规则（`WorkoutLogic`、`MuscleLogic`、`DateUtil` 等）。
- **model**：类型、日历/日模型、动作目录、动作说明、肌群枚举。

## 目录

```
fit_loger/
├── AppScope/                          应用标识、图标、显示名
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets
│   │   ├── pages/                     日历、日详情、肌群选择、我的、体重、趋势
│   │   ├── components/                日历格、组行、动作卡、3D 场景、各类 Sheet
│   │   ├── common/                    纯逻辑与相机/手势
│   │   ├── db/                        schema、迁移、备份、导出、种子
│   │   └── model/                     类型、目录、动作说明
│   └── resources/
│       ├── base|dark/                 颜色、部位图、动作 SVG
│       └── rawfile/
│           ├── models/                body_muscles.glb
│           └── exercises/             动作资料许可说明
├── tools/
│   ├── verify_*.mjs                   项目与逻辑校验
│   ├── workout_logic.mjs              与 WorkoutLogic.ets 同源的 Node 实现
│   ├── exercises/                     由 curated.json 生成目录、详情、SVG
│   └── anatomy/                       人体模型许可说明
├── docs/                              设计与实现笔记
├── build-profile.json5                工程与签名配置（密钥不要入库）
└── oh-package.json5
```

## 数据模型

Schema 版本：`CURRENT_VERSION = 1`（见 `entry/src/main/ets/db/schemaSql.ets`）。

| 表 | 作用 |
| --- | --- |
| `exercises` | 动作库（内置 + 自建），含部位、肌群、器械、`weight_step`、是否自重 |
| `workout_days` | 训练日，`date` 为 `YYYY-MM-DD` |
| `day_exercises` | 当天动作，直接挂 `day_id`（部位是动作属性，不是中间表） |
| `workout_sets` | 组：重量、次数、热身、技法、RIR、`planned`/`done`、完成时间 |
| `body_metrics` | 按日体重 |

要点：

- 统计与日历「已训练」只认 `status = 'done'`。
- 旧 `tag` 拆成 `is_warmup` + `technique`；历史库启动时会备份再迁移。
- 自建动作 id 形如 `usr_<timestamp>`，`is_builtin = 0`。
- 时间戳为 Unix 毫秒；缺失的 RIR / `completed_at` 保持空，不编造默认值。

## 主要交互

1. 日历点某一天（或「记录今天」）进入日详情。
2. **按部位**：选部位 → 选动作 → 加组。空日可「复制上次训练」。
3. **按动作**：打开 3D 人体，点肌群后勾选推荐动作，一次加入。
4. 输入重量/次数会防抖保存（约 280ms），**不会**自动标成完成；勾选圆圈才记 `done` 和 `completed_at`。
5. 删单组可短暂撤销；删整天仍需确认。
6. 「我的」里改主题、身高、体重，以及备份导出。

## 本地开发

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（HarmonyOS NEXT / API 20）。
2. 打开本仓库根目录。
3. 在 DevEco 中配置本机调试签名（`build-profile.json5` 的 `signingConfigs` 指向本机证书；`.p12` / `.p7b` / `.cer` 已在 `.gitignore` 中忽略）。
4. 选择手机或模拟器，运行 `entry` 模块。

启动时 `EntryAbility` 会初始化数据库并套用已保存主题；失败时仍会进入主界面。

### 动作资源

动作目录、中文说明和 SVG 可由精选数据再生成：

```bash
node tools/exercises/generate.mjs
```

源数据在 `tools/exercises/curated.json`。上游参考 [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db)（Unlicense）；本应用不使用上游照片，配图为原创矢量图。人体模型说明见 `entry/src/main/resources/rawfile/models/ATTRIBUTION.md`。

## 校验

不需要 DevEco 也可跑这些 Node 检查（建议 Node 20+）：

```bash
node tools/verify_project.mjs
node tools/verify_v1_logic.mjs
node tools/verify_calendar.mjs
node tools/verify_catalog.mjs
node tools/verify_categories.mjs
node tools/verify_editing.mjs
node tools/verify_workout_modes.mjs
node tools/verify_muscle.mjs
node tools/verify_scene.mjs
```

它们会核对必需文件、schema、动作数量、日历打点、录入状态机、肌群点选与相机约束等。真机行为仍需在 DevEco 里编译安装后确认。

## 许可与署名

- 应用模块声明：Apache-2.0（`entry/oh-package.json5`）。
- 动作文字资料：free-exercise-db，Unlicense；详见 `entry/src/main/resources/rawfile/exercises/ATTRIBUTION.md`。
- 人体模型：见 `entry/src/main/resources/rawfile/models/ATTRIBUTION.md`。

## 后续方向

- 趋势页：容量、e1RM、体重曲线（仓库中有 `trends` 分支在推进）。
- 有氧按时长/距离记录（当前跳绳、开合跳等仍按次数）。
- 配重建议、停滞检测等判断类功能（设计上先靠历史数据，不依赖在线模型）。
