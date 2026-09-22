# 设计系统（最小集）

现行颜色在 `entry/src/main/resources/base|dark/element/color.json`。本批只要求 3D 选肌页改用资源，不要求全 App 立刻改完字号。

## 颜色

| Token | 用途 |
| --- | --- |
| `page_bg` / `card_bg` | 主界面底、卡片 |
| `accent` / `accent_soft` / `text_on_accent` | 主按钮、轻按钮、按钮字 |
| `text_primary` / `text_secondary` | 主/次文字 |
| `danger` | 错误与删除 |
| `chip_bg` / `divider` | 输入底、分割线 |
| `dot_trained` / `dot_planned` / `dot_missed` | 日历打点 |
| `scene_bg` / `scene_ink` / `scene_muted` | 3D 页舞台底、主字、次字 |
| `scene_panel` | 3D 页底部面板与 Sheet |
| `scene_soft` / `scene_stroke` / `scene_disabled` | 次按钮、描边、禁用主按钮 |

强调色只有 `accent`。3D 页不得再写 `#21795E`。

## 字号阶梯（`float.json`）

| Token | 值 | 用途 |
| --- | --- | --- |
| `font_caption` | 12fp | 辅助说明 |
| `font_body` | 14fp | 正文、列表 |
| `font_title` | 17fp | 区块标题 |
| `font_hero` | 24fp | 页标题 |

旧页面仍有 11–26 的字面量，后续改页时再收。

## 间距与圆角

| Token | 值 |
| --- | --- |
| `space_page` | 16vp |
| `radius_sm` | 8vp |
| `radius_md` | 12vp |
| `radius_lg` | 16vp |
| `radius_xl` | 22vp |

3D 页优先引用这些 float；主界面可继续用现有 8/16 字面量，直到下一轮统一。
