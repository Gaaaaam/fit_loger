# 2026-10-23 图片与有氧器械整合记录

追踪：[GitHub Issue #1](https://github.com/Gaaaaam/fit_loger/issues/1)。

独立整合代码复核通过，未发现 Critical、Important 或 Minor 问题。复核范围为资源/元数据完整性、代码保留与映射一致性；设备交互另行验收。

## 本次整合

将图片工作与有氧器械扩充整理到 `codex/cardio-machines` 分支。代码整合提交：`2019870c5b2e0a2eca59dcbc977ba0edbfc180ef`，合并有氧提交 `6a625bf` 与图片修复提交 `89c55ca`，保留完整历史。

- 125 个内置动作；男女 250 组指导图，共 614 张 WebP。原有 590 张与已审核的 `89c55ca` 逐文件 SHA-256 一致。
- 9 张训练部位分类图片，统一为透明 WebP。
- 新增跑步机、爬楼机、椭圆机、固定单车、划船机，提供 24 张男女指导帧。
- 有氧按段录入时长，按器械选填距离、速度、坡度、档位、频率、功率、心率和面板热量；包含基础趋势及 v4 数据迁移、JSON/CSV 兼容。
- 有氧与力量容量、力量纪录和力量组数目标分开统计；已修复连续编辑保存、快速添加下一段的两处时序问题。
- 本机签名、证书、构建产物、Python 缓存未提交。

## 已执行验证

- [x] 全部 19 个 `tools/verify_*.mjs` 检查通过。
- [x] 22 项 Python 图片管线测试通过。
- [x] 图片资源检查：125 项、614 帧；提示词与目录覆盖：125 项、250 份提示词。
- [x] 最终 HarmonyOS `assembleHap` 构建成功；签名安装包内确有 614 张指导图和 9 张分类新图。
- [x] 2026-10-23 覆盖安装至已连接的华为 ALN-AL00（OpenHarmony-6.1.1.120），安装命令返回成功；未卸载或清空数据。升级前已私下备份数据库及旧记录指纹。

安装包对应代码提交 `2019870`，App 版本维持 `1.0.0 (1000000)`。签名 HAP SHA-256：`f927f839317639fa2ed6a76ade213ac859a4870b8887763554fe1ad42f39fe0c`。HAP 与设备数据备份仅留在本机。

## 后续真机验收

- [ ] 手机解锁后启动验证，并核对 v3→v4 迁移后旧训练记录保持不变（启动命令当前被系统锁屏拦截：10106102）。
- [ ] 按 `docs/qa-cardio.md` 检查两种录入视图、五类器械、连续编辑、导入导出和浅色/暗色主题。
- [ ] 按 `docs/qa-device.md` 完成第二款不同尺寸真机验收；本次仅有一款真机连接。
- [ ] 跟踪原图片审计中保留的 8 项不确定细节：`chest_bb_bench/female`、`chest_bb_bench/male`、`chest_decline_bench/female`、`chest_decline_bench/male`、`chest_incline_db_press/female`、`chest_incline_db_press/male`、`shoulder_machine_reverse_fly/male`、`abs_hanging_knee/female`。这些记录没有被改写为通过。

原图片复核记录的 32 组已确认问题均已关闭。本次核验它们的已审核资源字节与历史一致，没有重新宣称完成全部动作的人工视觉审计。
