# 🐧 打企鹅 - Hit Penguin

> 复古像素风弹道射击休闲游戏。用弹弓瞄准企鹅，击碎冰块，挑战15个趣味关卡！

**打企鹅**是一款iOS平台的像素风弹道射击游戏。玩家通过拉伸弹弓瞄准目标，发射石块击碎冰块并击中企鹅，获取分数。简单易上手，老少皆宜，适合碎片时间休闲娱乐。

---

## 🎮 功能特点

| 功能 | 说明 |
|---|---|
| 🎯 **弹弓物理玩法** | 拉伸弹弓控制角度和力度，实时显示抛物线轨迹预测 |
| 🐧 **像素美术风格** | 精美像素企鹅、冰块、特效动画，致敬经典弹道游戏 |
| 📊 **15个趣味关卡** | 从简单到挑战，丰富的关卡设计 |
| 💯 **计分与Combo系统** | 击碎冰块、连续击中获得更高分数 |
| ⚡ **体力系统** | 30点体力上限，合理分配每一发射击 |
| 🎵 **音效与音乐** | 背景音乐 + 丰富的游戏音效 |
| 🌐 **多语言支持** | 简体中文 / English 随时切换 |
| 🚫 **无内购干扰** | 可选去广告内购，不影响游戏核心体验 |
| 📱 **原生iOS体验** | 基于 SpriteKit 开发，流畅60fps |

---

## 🛠 技术栈

| 类别 | 技术 |
|---|---|
| **平台** | iOS 14.0+ |
| **语言** | Swift 5 |
| **游戏引擎** | Apple SpriteKit |
| **UI布局** | SnapKit (Auto Layout) |
| **广告** | Google AdMob |
| **构建工具** | XcodeGen + CocoaPods |
| **数据分析** | Firebase Analytics |

---

## 🚀 安装说明

### 环境要求

- macOS 12.0+（Monterey 及以上）
- Xcode 14.0+（App Store 免费下载）
- iOS 14.0+ 模拟器或真机

### 快速开始

```bash
# 1. 进入项目目录
cd 打企鹅App/打企鹅App

# 2. 安装依赖（CocoaPods）
pod install

# 3. 打开工作空间（注意是 .xcworkspace）
open 打企鹅App.xcworkspace

# 4. 在 Xcode 中选择模拟器（如 iPhone 15）
#    然后按 ⌘+R 或点击 ▶️ 运行
```

> ⚠️ **重要**：请务必使用 `.xcworkspace` 打开项目，而非 `.xcodeproj`，否则 SnapKit 和 AdMob 等依赖库不会加载。

---

## 📁 项目结构

```
打企鹅App/
├── Sources/
│   ├── App/               # AppDelegate / SceneDelegate
│   ├── Scenes/
│   │   ├── Game/          # 游戏主场景（SpriteKit）
│   │   ├── Menu/          # 主菜单
│   │   ├── LevelSelect/   # 关卡选择
│   │   └── Settings/      # 设置页
│   │   └── About/         # 关于页面（隐私政策）
│   ├── Sprites/           # 精灵图资源
│   ├── Physics/           # 物理系统
│   ├── Systems/           # 游戏系统
│   ├── Managers/          # 管理器（Audio / Ad / Game）
│   ├── Effects/           # 特效
│   ├── Extensions/        # Swift扩展
│   └── Resources/         # 资源（音效/LaunchScreen）
├── Assets.xcassets/       # App图标、颜色资源
└── project.yml            # XcodeGen 配置
```

---

## 📱 App Store 上架清单

- [x] App Store 图标（1024×1024 AppIcon）
- [x] 启动画面（LaunchScreen.storyboard）
- [x] 隐私政策页面（HTML富文本内嵌）
- [x] Info.plist 完整配置
- [x] 版本号 1.0.0
- [ ] Apple Developer 账号注册（¥688/年）
- [ ] App Store Connect 创建应用条目
- [ ] 6.5寸 + 5.5寸 截图（各至少1张）
- [ ] 应用描述（170字符）+ 关键词（100字符）
- [ ] 隐私政策 URL（可用 GitHub Pages 托管）
- [ ] 年龄分级（建议 4+）
- [ ] 提交审核（约 1-2 天通过）

---

## 📄 License

MIT License

Copyright (c) 2025 HitPenguin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

*Made with ❤️ by OpenClaw AI · 打企鹅开发团队 · 2025*
