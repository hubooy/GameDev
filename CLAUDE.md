# CLAUDE.md

为 Claude Code 提供本仓库的开发指引与项目结构总览。

## 仓库定位

`GameDev` 是一个游戏开发实验仓库。当前唯一活跃项目是 **EchoMaze（回声迷宫）**，一款基于 SwiftUI + AVAudioEngine 的 iOS 麦克风互动游戏。

## 目录结构

```
GameDev/
├── README.md              # 仓库总览
├── CLAUDE.md              # 本文件
└── EchoMaze/
    ├── README.md          # EchoMaze 项目说明
    └── EchoMaze/          # Swift 源码目录
        ├── EchoMazeApp.swift
        ├── RootView.swift
        ├── GameState.swift
        ├── AudioEngine.swift
        ├── FeedbackCenter.swift
        ├── LevelData.swift
        ├── LevelLibrary.swift
        ├── HomeView.swift
        ├── LevelSelectView.swift
        ├── SettingsView.swift
        ├── GameView.swift
        ├── MazeCanvas.swift
        ├── ResultView.swift
        ├── UIComponents.swift
        └── Info.plist
```

## 构建 / 运行

EchoMaze 没有提交 `.xcodeproj`，仓库只保留源文件骨架。开发者按以下步骤导入：

1. Xcode → New → iOS App，命名 `EchoMaze`，SwiftUI / Swift，部署目标 iOS 17.0+
2. 删除 Xcode 自动生成的 `ContentView.swift` 与 `EchoMazeApp.swift`
3. 把 `EchoMaze/EchoMaze/` 下所有 `.swift` 拖入工程
4. **不要拖入仓库的 `Info.plist`**（Xcode 14+ 默认自动合成 Info.plist，再拖一份会触发
   "Multiple commands produce Info.plist" 编译错误）。改为在 Target → **Info** 标签页
   手动添加 `Privacy - Microphone Usage Description`，文案参考仓库 `Info.plist`。
   仓库里的 `Info.plist` 仅作为配置参考保留。
5. **真机** 运行（模拟器无麦克风）

> 由于没有 xcodeproj，没有 `swift build` 或 CI 测试命令可在本仓库直接跑。验证方式是在 Xcode 内打开后看是否能编译。

## 架构关键点

- **状态流**：`GameState`（`ObservableObject`）以 `AppScene` 枚举驱动 `RootView` 切换 home / levelSelect / playing / result / settings。
- **音频驱动**：`AudioEngine` 用 `AVAudioEngine` 安装 tap，每个 buffer 算 RMS → dB → 0~1 归一化，再做攻击/释放双段平滑后 `@Published` 出 `level: Float`。
- **照亮渲染**：`MazeCanvas` 用 SwiftUI `Canvas` 绘制墙体，再用同尺寸 Canvas mask 一个径向渐变圆。半径函数 `lightRadius()` 根据 `LevelTheme` 切换 6 条不同曲线，是"主题即玩法"的核心实现位。
- **关卡数据**：`LevelLibrary.shared.allLevels`，硬编码 `[[Int]]` 网格；图例 `0=空 1=墙 2=起点 3=出口 4=陷阱 5=钥匙`。
- **反馈**：`FeedbackCenter`（单例）统一封装 `UIImpactFeedbackGenerator` + `AudioServicesPlaySystemSound`，受 `GameState.hapticsEnabled` / `soundEnabled` 开关控制，`EchoMazeApp` 中用 `onChange` 同步。
- **存档**：`UserDefaults` 两个 key：
  - `EchoMaze.progress.v2` —— 解锁索引、星数、最佳用时、总游玩次数
  - `EchoMaze.settings.v1` —— 触感 / 音效开关

## 编码约定

- 主题色定义在 `LevelTheme.accentColor`；新增主题需要同步：`displayName`、`subtitle`、`accentColor`、`MazeCanvas.lightRadius()` 分支
- 新失败原因要在 `FailCause` 加 case，并在 `ResultView.causeText` 补对应文案
- 文本风格：纯中文，"开 始" 这种带空格的间距风格是设计语言的一部分，**不要**自动去除空格
- UI 元素优先用 `tracking()` 控制字距，营造极简衬线视觉
- 不要新增依赖；保持纯 SwiftUI + AVFoundation + AudioToolbox

## 常见任务备忘

- **新增关卡**：在 `LevelLibrary.allLevels` 数组追加 `LevelData`，注意网格四周一圈必须是墙
- **新增主题玩法**：先在 `LevelTheme` 加 case → 写 `lightRadius()` 分支 → 必要时在 `GameView.handleAudioTick` 加特殊判定
- **调整触发音量阈值**：`LevelData.loudTrapThreshold` 当前为常量 0.55，若需逐关配置可改为存储属性
- **真机测试要点**：必须真机；首启请求麦克风权限；竖屏锁定

## Git 工作流

- 默认开发分支：`claude/vibrant-franklin-E1uEb`（用户当前 Claude Code on the web 会话指定）
- 主分支：`main`
- 默认远端：GitHub `hubooy/gamedev`
