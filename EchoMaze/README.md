# 回声迷宫 EchoMaze - iOS 项目

> SwiftUI + AVAudioEngine 实现，通过麦克风实时音量驱动"声波照亮"玩法。

## 在 Xcode 中导入

1. 打开 Xcode → **File → New → Project → iOS App**
   - Product Name: `EchoMaze`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - 部署目标: **iOS 17.0+**（项目使用 `onChange(of:_:)` 新签名）

2. 删除 Xcode 自动生成的 `ContentView.swift` 与 `EchoMazeApp.swift`

3. 把 `EchoMaze/` 文件夹下所有 `.swift` 文件拖进 Xcode 工程（勾选 "Copy items if needed"）

4. 在 **Target → Info** 添加键：
   - `Privacy - Microphone Usage Description` → 描述见 `Info.plist`
   - 或直接用本项目的 Info.plist 覆盖

5. 真机运行（**模拟器无法测试麦克风**）

## 文件结构

```
EchoMaze/
├── EchoMazeApp.swift       # App 入口，同步设置到 FeedbackCenter
├── RootView.swift          # 场景路由
├── GameState.swift         # 全局状态 + 进度存档 + 设置
│
├── AudioEngine.swift       # 麦克风音量采集（核心驱动）
├── FeedbackCenter.swift    # 音效 + 触感反馈统一出口
│
├── LevelData.swift         # 关卡模型 + 失败原因枚举
├── LevelLibrary.swift      # 6 个内置关卡
│
├── HomeView.swift          # 首页（含通关进度统计）
├── LevelSelectView.swift   # 关卡选择
├── SettingsView.swift      # 设置（触感 / 音效 / 清除进度）
├── GameView.swift          # 游戏主界面（计时、移动、陷阱、钥匙、暂停）
├── MazeCanvas.swift        # Canvas 迷宫渲染 + 声波照亮蒙版
├── ResultView.swift        # 结算页（星数 + 用时 + NEW BEST）
├── UIComponents.swift      # 音量条（含警戒线）、方向键
│
└── Info.plist
```

## 核心机制

| 模块 | 关键点 |
| :-- | :-- |
| **音量采集** | `AVAudioEngine.inputNode.installTap` → RMS → dB → 归一化 0~1 → 双段平滑 |
| **照亮渲染** | SwiftUI `Canvas` + `mask` 径向渐变，半径 = f(音量, 主题) |
| **主题差异化** | 6 种主题映射不同 `lightRadius()` 曲线 —— 线性 / 钟形 / 阈值 / 衰减 / 增益 / 阵风扰动 |
| **关卡数据** | 二维 `[[Int]]`，0=空 1=墙 2=起点 3=出口 4=陷阱 5=钥匙 |
| **存档** | `UserDefaults` 记录解锁、星数、最佳用时、总游玩次数、设置 |
| **反馈** | `FeedbackCenter` 统一封装触感（`UIImpactFeedbackGenerator`）+ 音效（`AudioServicesPlaySystemSound`），受设置开关控制 |

## 玩法机制（v1.1）

- **陷阱**：踩到红色陷阱格 → 直接失败
- **钥匙**：地图上有钥匙时，必须全部拾取后出口才会解锁
- **图书馆音量警报**：在图书馆主题下，音量超过阈值（0.55）→ 立即失败，音量条上有红色警戒线
- **暂停**：游戏中点击左上角暂停按钮，可继续 / 重玩 / 退出
- **操作**：滑动屏幕移动，或使用底部方向键
- **评星**：在 `targetSeconds` 内 3 星，1.5 倍内 2 星，否则 1 星

## 关卡一览

| # | 主题 | 玩法关键 |
| :-: | :-- | :-- |
| 01 | 回声平原 | 教学：自由发声 |
| 02 | 寂静图书馆 | 小声 + 1 钥匙 + 大声陷阱 |
| 03 | 喧嚣演唱会 | 大声 + 1 钥匙 |
| 04 | 穿堂风洞 | 持续发声 + 陷阱 |
| 05 | 幽深洞穴 | 余韵悠长 + 2 钥匙 |
| 06 | 风暴之夜 | 阵风扰动 + 双钥匙 + 双陷阱 |

## 真机测试要点

- **请用真机**，模拟器没有麦克风
- 第一次启动会请求麦克风权限
- 安静环境下对手机说话/吹气，应看到光圈随音量扩张
- 6 个关卡分别试试，体会"主题差异化"的设计意图

## 设计亮点

1. **主题即玩法**：每个场景不只是换皮，而是改变"声音→照亮"的映射函数。图书馆要小声、演唱会要大喊，强迫玩家切换发声策略。
2. **极简视觉**：纯黑底 + 单一主题色 + 衬线字距大写，刻意拉开和市场上花哨休闲游戏的差距。
3. **传播钩子**（待扩展位）：通关时可保存玩家的发声波形为可分享的"声纹"。

## 路线图

- [x] 完整场景流程：首页 → 关卡选择 → 游戏 → 结算
- [x] 麦克风权限请求与实时音量监测
- [x] 6 种主题关卡 + 主题专属照亮曲线
- [x] 星数评级、解锁、本地存档
- [x] Canvas 高性能迷宫绘制
- [x] 陷阱触发判定
- [x] 钥匙拾取逻辑 + 出口锁定
- [x] 音效与触感反馈（含开关）
- [x] 滑动操控
- [x] 暂停菜单
- [x] 最佳用时记录 + NEW BEST 标识
- [x] 设置页（触感 / 音效 / 重置进度）
- [ ] 摇杆替代方向键
- [ ] 通关录音波形分享
- [ ] 自定义关卡编辑器
- [ ] 排行榜 / GameCenter 接入
