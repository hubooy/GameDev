//
//  GameView.swift
//  游戏主界面 —— 核心玩法
//  扩展项：钥匙拾取、陷阱判定、滑动操控、暂停、最佳用时、storm 主题阵风
//

import SwiftUI

struct GameView: View {
    let level: LevelData
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioEngine: AudioEngine

    @State private var playerPos: GridPos
    @State private var startTime: Date = Date()
    @State private var elapsed: Double = 0
    @State private var timer: Timer?
    @State private var showHint: Bool = true
    @State private var showPermissionAlert: Bool = false
    @State private var collectedKeys: Set<GridPos> = []
    @State private var isPaused: Bool = false
    @State private var stormPhase: Double = 0   // storm 主题阵风相位
    @State private var loudWarningFlash: Double = 0
    @State private var failGuardArmed: Bool = false // 给 0.4s 缓冲再开始判定 trap/loud

    init(level: LevelData) {
        self.level = level
        self._playerPos = State(initialValue: level.startPos)
    }

    private var totalKeys: Int { level.keyCount }
    private var hasAllKeys: Bool { totalKeys == 0 || collectedKeys.count >= totalKeys }
    private var bestTime: Double? { gameState.levelBestTime[level.id] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                mazeArea
                Spacer()
                bottomBar
            }

            // 图书馆类关卡音量过大警告闪烁
            if loudWarningFlash > 0 {
                Color.red.opacity(loudWarningFlash * 0.25)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if showHint {
                hintOverlay
            }

            if isPaused {
                pauseOverlay
            }
        }
        .onAppear { onAppearSetup() }
        .onDisappear { onDisappearCleanup() }
        .onChange(of: audioEngine.level) { _, newValue in
            handleAudioTick(newValue)
        }
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    handleSwipe(value.translation)
                }
        )
        .alert("需要麦克风权限", isPresented: $showPermissionAlert) {
            Button("好") { gameState.goHome() }
        } message: {
            Text("请在系统设置中允许访问麦克风，否则无法游玩。")
        }
    }

    // MARK: - 顶部栏
    private var topBar: some View {
        HStack {
            Button {
                togglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(level.theme.displayName)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 10) {
                    Text(String(format: "%.1fs", elapsed))
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundStyle(level.theme.accentColor.opacity(0.8))
                    if let best = bestTime {
                        Text("· 最佳 \(String(format: "%.1fs", best))")
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                // 钥匙进度
                if totalKeys > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<totalKeys, id: \.self) { i in
                            Image(systemName: i < collectedKeys.count ? "key.fill" : "key")
                                .font(.system(size: 9))
                                .foregroundStyle(
                                    i < collectedKeys.count
                                        ? Color.yellow
                                        : .white.opacity(0.25)
                                )
                        }
                    }
                    .padding(.top, 1)
                }
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - 迷宫绘制区
    private var mazeArea: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) - 24
            let cellSize = size / CGFloat(max(level.cols, level.rows))

            ZStack {
                MazeCanvas(
                    level: level,
                    playerPos: playerPos,
                    audioLevel: audioEngine.level,
                    cellSize: cellSize,
                    collectedKeys: collectedKeys,
                    hasAllKeys: hasAllKeys,
                    stormPhase: stormPhase
                )
            }
            .frame(width: CGFloat(level.cols) * cellSize,
                   height: CGFloat(level.rows) * cellSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 底部栏（音量条 + 操作）
    private var bottomBar: some View {
        VStack(spacing: 16) {
            VolumeBar(
                level: audioEngine.level,
                accent: level.theme.accentColor,
                dangerThreshold: level.theme == .library ? level.loudTrapThreshold : nil
            )
            .frame(height: 8)
            .padding(.horizontal, 32)

            // 提示语：滑动操控
            Text("滑动屏幕移动")
                .font(.system(size: 10, weight: .light))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.3))

            // 保留 D-Pad 作为辅助控制（部分玩家偏好按钮）
            DPad { dir in
                move(dir)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - 提示遮罩
    private var hintOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(level.theme.accentColor)

                Text(level.hint)
                    .font(.system(size: 15, weight: .regular))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if totalKeys > 0 {
                    Text("收集 \(totalKeys) 把钥匙后出口才会开启")
                        .font(.system(size: 11, weight: .light))
                        .tracking(2)
                        .foregroundStyle(.yellow.opacity(0.7))
                }

                Button {
                    FeedbackCenter.shared.haptic(.light)
                    withAnimation(.easeOut(duration: 0.3)) { showHint = false }
                    startTimer()
                    // 给 0.4s 缓冲再开始陷阱/警报判定，避免开局误触
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        failGuardArmed = true
                    }
                } label: {
                    Text("开 始")
                        .tracking(6)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(level.theme.accentColor))
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }

    // MARK: - 暂停遮罩
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("暂 停")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .tracking(8)
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    pauseButton("继 续") { togglePause() }
                    pauseButton("重 玩") { restart() }
                    pauseButton("退 出") { gameState.openLevelSelect() }
                }
                .padding(.horizontal, 60)
            }
        }
        .transition(.opacity)
    }

    private func pauseButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button {
            FeedbackCenter.shared.haptic(.light)
            action()
        } label: {
            Text(text)
                .tracking(6)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
        }
    }

    // MARK: - 生命周期

    private func onAppearSetup() {
        audioEngine.requestPermission { granted in
            if granted {
                audioEngine.start()
            } else {
                showPermissionAlert = true
            }
        }

        // storm 主题：阵风相位推进
        if level.theme == .storm {
            Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { t in
                guard !isPaused, !showHint else { return }
                stormPhase += 0.08
                if case .playing = gameState.scene { /* keep going */ } else { t.invalidate() }
            }
        }
    }

    private func onDisappearCleanup() {
        timer?.invalidate()
        audioEngine.stop()
    }

    private func startTimer() {
        startTime = Date()
        timer?.invalidate()
        var pausedAccumulated: Double = 0
        var lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let now = Date()
            if isPaused {
                pausedAccumulated += now.timeIntervalSince(lastTick)
            } else {
                elapsed = now.timeIntervalSince(startTime) - pausedAccumulated
            }
            lastTick = now
        }
    }

    private func togglePause() {
        FeedbackCenter.shared.haptic(.light)
        withAnimation(.easeOut(duration: 0.2)) { isPaused.toggle() }
    }

    private func restart() {
        playerPos = level.startPos
        collectedKeys = []
        elapsed = 0
        isPaused = false
        showHint = true
        failGuardArmed = false
    }

    // MARK: - 音量驱动事件

    private func handleAudioTick(_ value: Float) {
        guard failGuardArmed, !isPaused, !showHint else { return }
        // 图书馆：音量过大警报 → 失败
        if level.theme == .library && value > level.loudTrapThreshold {
            withAnimation(.easeOut(duration: 0.15)) { loudWarningFlash = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.4)) { loudWarningFlash = 0 }
            }
            FeedbackCenter.shared.haptic(.failure)
            FeedbackCenter.shared.sound(.trap)
            finishLevel(success: false, cause: .loudAlert)
        }
    }

    // MARK: - 输入：滑动 / 方向键

    private func handleSwipe(_ translation: CGSize) {
        let dx = translation.width
        let dy = translation.height
        let dir: Direction
        if abs(dx) > abs(dy) {
            dir = dx > 0 ? .right : .left
        } else {
            dir = dy > 0 ? .down : .up
        }
        move(dir)
    }

    private func move(_ dir: Direction) {
        guard !isPaused, !showHint else { return }
        var newCol = playerPos.col
        var newRow = playerPos.row
        switch dir {
        case .up:    newRow -= 1
        case .down:  newRow += 1
        case .left:  newCol -= 1
        case .right: newCol += 1
        }

        guard newRow >= 0, newRow < level.rows,
              newCol >= 0, newCol < level.cols else { return }
        let cell = level.grid[newRow][newCol]
        guard cell != CellType.wall.rawValue else {
            FeedbackCenter.shared.haptic(.light)
            return
        }

        FeedbackCenter.shared.haptic(.light)
        withAnimation(.easeOut(duration: 0.12)) {
            playerPos = GridPos(col: newCol, row: newRow)
        }

        let newPos = GridPos(col: newCol, row: newRow)

        // 钥匙拾取
        if cell == CellType.key.rawValue && !collectedKeys.contains(newPos) {
            collectedKeys.insert(newPos)
            FeedbackCenter.shared.haptic(.medium)
            FeedbackCenter.shared.sound(.keyPickup)
            if collectedKeys.count == totalKeys && totalKeys > 0 {
                FeedbackCenter.shared.haptic(.success)
                FeedbackCenter.shared.sound(.unlock)
            }
        }

        // 陷阱判定：直接踩到陷阱 → 失败
        if cell == CellType.trap.rawValue {
            FeedbackCenter.shared.haptic(.failure)
            FeedbackCenter.shared.sound(.trap)
            finishLevel(success: false, cause: .trap)
            return
        }

        // 出口
        if newCol == level.exitPos.col && newRow == level.exitPos.row {
            if hasAllKeys {
                FeedbackCenter.shared.haptic(.success)
                FeedbackCenter.shared.sound(.clear)
                finishLevel(success: true, cause: nil)
            } else {
                // 钥匙不齐：出口锁定，给个警告但允许停留
                FeedbackCenter.shared.haptic(.warning)
            }
        }
    }

    private func finishLevel(success: Bool, cause: FailCause?) {
        timer?.invalidate()
        audioEngine.stop()

        let stars: Int
        if !success { stars = 0 }
        else if elapsed <= Double(level.targetSeconds) { stars = 3 }
        else if elapsed <= Double(level.targetSeconds) * 1.5 { stars = 2 }
        else { stars = 1 }

        let partial = PartialLevelResult(
            level: level,
            success: success,
            elapsedSeconds: elapsed,
            stars: stars,
            cause: cause
        )
        gameState.finishLevel(partial)
    }
}

enum Direction {
    case up, down, left, right
}
