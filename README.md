# 死楼 Dead Building — 垂直切片 v0.1

2D 叙事解谜 · 治愈系恐怖。基于 Godot 4.7.1 / GDScript。
美术与音效全部为本工程程序化生成，原创，无第三方版权风险，可商用上架。

## 运行

```bash
# 方式一：直接运行（无需打开编辑器）
D:\Godot\Godot_v4.7.1-stable_win64.exe --path dead_building

# 方式二：用编辑器打开 dead_building\project.godot，按 F5
```

## 操作

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 移动 |
| E / 空格 / 回车 | 互动 / 推进对话 |
| Tab | 管理员日志 |
| F | 手电开关 |
| Esc | 暂停菜单（3 个存档位 + 读档） |
| 1-3 | 仪式选项快捷键（也可鼠标点） |

## 已实现（P0 全部 + 部分 P1）

- 标题 → 管理员室 → 走廊 → 104 完整 Day1 循环
- 玩家四方向行走 / 碰撞 / 互动提示
- 昼夜相位系统（白天暖黄 / 夜晚冷蓝 + 手电黑暗光照）
- 手电电量（夜间消耗、低电量闪烁、次日回满）
- 104「红裙子」全流程：3 线索 → 真相还原（屏幕中央叙事）→ 镜子事件（她转头微笑）→ 收音机恶意评论 → 短信草稿仪式（三选项，错选项有反馈）→ 红色退潮治愈演出 → 白睡衣鞠躬 → 遗物「红裙子的纽扣」→ 次日自动存档
- 随机异常事件（恶意评论飘过 + 杂音）
- 王大妈 NPC 对话（给钥匙 + 提示）、房东每日电话（含房号 4 规则教学）
- 电梯 4444 彩蛋、走廊白天/夜晚双版本
- 日志系统（左页日志 / 右页线索遗物）、HUD（天数 + 相位 + 电量）
- 存档：3 手槽 + 自动存档（JSON，读档时数字类型已归一化）
- 程序化音效：脚步/纸张/门轴/杂音/风铃/心跳/白天暖垫/夜晚低鸣

## 测试

```bash
# 冒烟测试（17 项：场景加载/状态/存档/104 线索流程）
D:\Godot\Godot_v4.7.1-stable_win64_console.exe --headless --path dead_building -s res://tools/smoke_test.gd

# Day1 完整流程测试（12 项：仪式→治愈→遗物→次日自动存档）
D:\Godot\Godot_v4.7.1-stable_win64_console.exe --headless --path dead_building -s res://tools/flow_test.gd

# 截图（带显示运行，存到 user://）
D:\Godot\Godot_v4.7.1-stable_win64.exe --path dead_building -s res://tools/shot_tool.gd
```

当前全部通过：smoke 17/17，flow 12/12。

## 目录结构

```
dead_building/
├── project.godot
├── assets/
│   ├── sprites/        # 程序化像素画（tools/gen_assets.py 生成）
│   ├── sfx/            # 程序化合成音效（tools/gen_sfx.py 生成）
│   └── fonts/          # NotoSansSC（OFL 许可）
├── src/
│   ├── autoload/       # Game(状态/存档) SceneFlow(转场) Sfx Dialog HUD JournalUI RitualUI PauseMenu
│   ├── player/         # 玩家控制器 + 手电
│   ├── objects/        # Interactable 可互动物
│   └── scenes/         # title / admin_room / corridor / room_104
└── tools/              # smoke_test / flow_test / shot_tool
```

## 下一章计划（P1）

214「外卖员」房间（门口已留悬念文案）→ 334「商人」→ 404/444/4444 → 多结局。
房号异常系统（4 越多耗电越快）骨架已在设定中，待接入。
