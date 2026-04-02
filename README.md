# 🐧 打企鹅 App - 项目说明

> 复古像素风弹道射击游戏，iOS 独占

---

## 📁 项目结构

```
打企鹅App/
├── 打企鹅App/
│   ├── project.yml          # XcodeGen 配置（代码骨架生成）
│   ├── Podfile              # CocoaPods 依赖
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── AppDelegate.swift
│   │   │   └── SceneDelegate.swift
│   │   ├── Scenes/
│   │   │   ├── Game/       # 游戏主场景（SpriteKit）
│   │   │   ├── Menu/       # 主菜单
│   │   │   └── LevelSelect/# 关卡选择
│   │   ├── Sprites/        # 精灵图资源
│   │   ├── Physics/        # 物理系统
│   │   ├── Systems/        # 游戏系统
│   │   ├── UI/            # UI组件
│   │   ├── Managers/       # 管理器
│   │   └── Resources/      # 音效/关卡配置
│   └── Assets.xcassets/    # 资源目录
└── 产品设计方案.md
```

---

## 🚀 如何在 Mac 上运行

### 第一步：安装 Xcode

1. 打开 **Mac App Store**，搜索 "Xcode"
2. 点击安装（约 30GB，需要 Apple ID）
3. 首次启动会安装额外组件

### 第二步：安装 CocoaPods 依赖

打开终端，运行：

```bash
cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Chd/Obsidian/Obsidian vault path 找不到？
# 实际路径请查看项目目录
cd ~/.openclaw/workspace/projects/打企鹅App/打企鹅App

pod install
```

> 💡 如果提示 `xcode-select` 错误，先运行：
> ```bash
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```

### 第三步：打开项目

```bash
open 打企鹅App.xcworkspace
```

> ⚠️ 务必用 `.xcworkspace`（不是 `.xcodeproj`），否则 SnapKit 和 Firebase 不会加载

### 第四步：在模拟器中运行

1. Xcode 中左上角选择 **iPhone 15**（或任何模拟器）
2. 点击 ▶️ 运行

---

## 🛠 已配置的工具链

| 工具 | 用途 | 状态 |
|---|---|---|
| **XcodeGen** | 代码骨架自动生成 | ✅ 已安装 |
| **CocoaPods** | 依赖管理 | ✅ 已安装 |
| **SnapKit** | Auto Layout 布局 | 待 pod install |
| **Firebase Auth** | 登录系统 | 待 pod install |
| **Firebase Firestore** | 排行榜数据 | 待 pod install |

---

## 🎮 当前可运行的 Demo

游戏骨架已完成以下功能：

- ✅ 主菜单界面（开始游戏 / 设置）
- ✅ 关卡选择界面（15关选择器）
- ✅ SpriteKit 游戏场景
- ✅ 弹弓拉伸瞄准交互
- ✅ 轨迹预测线（抛物线）
- ✅ 企鹅物理发射
- ✅ 冰块碰撞
- ✅ 分数显示
- ✅ 通关/失败判定

---

## 📋 下一步待开发（按优先级）

| 优先级 | 任务 | 预计工时 |
|---|---|---|
| 🔴 高 | 像素精灵美术资源（企鹅/冰块/弹弓） | 1-2天 |
| 🔴 高 | 15关关卡详细配置 | 1天 |
| 🟡 中 | 爆炸/撞击特效动画 | 0.5天 |
| 🟡 中 | 体力系统（30点上限） | 0.5天 |
| 🟡 中 | 计分 + Combo 连击 | 0.5天 |
| 🟡 中 | Firebase 登录 + 排行榜 | 1天 |
| 🟢 低 | 广告接入（AppLovin） | 1天 |
| 🟢 低 | IAP 内购（月卡/皮肤） | 1天 |
| 🟢 低 | App Store 上架材料 | 1天 |

---

## 📦 像素素材获取建议

| 素材 | 推荐方案 | 费用 |
|---|---|---|
| 企鹅精灵（站立/飞/撞/胜利） | 代码绘制（已有基础）+ Aseprite 细化 | 免费 |
| 冰块精灵（普通/裂纹/爆炸） | Aseprite 画（教程：B站搜索"像素画入门"） | 免费 |
| 弹弓/背景 | itch.io 免费像素素材包 | 免费 |
| 企鹅皮肤（5种） | Aseprite 配色变体 | 免费 |
| UI 按钮/图标 | pixelart-icons (GitHub) | 免费 |

**如需购买**：淘宝/itch.io 搜索 "pixel art game asset penguin"，¥20-50 可买整套像素素材包。

---

## 📱 App Store 上架清单

- [ ] Apple Developer 账号注册（¥688/年）
- [ ] App Store Connect 创建应用
- [ ] 截图（6.5寸 + 5.5寸各至少1张）
- [ ] 应用描述 + 关键词
- [ ] 隐私政策 URL（可用 GitHub Pages 免费托管）
- [ ] 年龄分级（建议 4+）
- [ ] 提交审核（约 1-2 天通过）

---

*本文档由 OpenClaw AI 助手自动生成 | 2026-04-02*
