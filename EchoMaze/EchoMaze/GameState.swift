//
//  GameState.swift
//  全局状态：场景切换、关卡进度、解锁记录、用户设置
//

import SwiftUI
import Combine

final class GameState: ObservableObject {
    @Published var scene: AppScene = .home
    @Published var unlockedLevelIndex: Int = 0
    @Published var levelStars: [String: Int] = [:]
    @Published var levelBestTime: [String: Double] = [:]   // 每关最佳用时
    @Published var totalRuns: Int = 0                       // 累计游玩次数

    // 用户设置
    @Published var hapticsEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published var soundEnabled: Bool = true {
        didSet { saveSettings() }
    }

    private let storageKey = "EchoMaze.progress.v2"
    private let settingsKey = "EchoMaze.settings.v1"

    init() {
        load()
        loadSettings()
    }

    func goHome() {
        withAnimation { scene = .home }
    }

    func openLevelSelect() {
        withAnimation { scene = .levelSelect }
    }

    func openSettings() {
        withAnimation { scene = .settings }
    }

    func startLevel(_ level: LevelData) {
        withAnimation { scene = .playing(level) }
    }

    func finishLevel(_ partial: PartialLevelResult) {
        totalRuns += 1

        // 仅成功时更新星数 / 最佳用时
        var isNewBest = false
        var finalStars = partial.stars
        if partial.success {
            let prev = levelStars[partial.level.id] ?? 0
            if partial.stars > prev {
                levelStars[partial.level.id] = partial.stars
            } else {
                finalStars = prev
            }
            let prevBest = levelBestTime[partial.level.id]
            if prevBest == nil || partial.elapsedSeconds < prevBest! {
                levelBestTime[partial.level.id] = partial.elapsedSeconds
                isNewBest = prevBest != nil  // 第一次通关不算"刷新"
            }
            let idx = LevelLibrary.shared.allLevels.firstIndex(where: { $0.id == partial.level.id }) ?? 0
            if idx >= unlockedLevelIndex {
                unlockedLevelIndex = idx + 1
            }
        }
        save()

        let result = LevelResult(
            level: partial.level,
            success: partial.success,
            elapsedSeconds: partial.elapsedSeconds,
            stars: finalStars,
            isNewBest: isNewBest,
            cause: partial.cause
        )
        withAnimation { scene = .result(result) }
    }

    // MARK: - Persistence

    private func save() {
        let payload: [String: Any] = [
            "unlocked": unlockedLevelIndex,
            "stars": levelStars,
            "bestTime": levelBestTime,
            "totalRuns": totalRuns
        ]
        UserDefaults.standard.set(payload, forKey: storageKey)
    }

    private func load() {
        guard let payload = UserDefaults.standard.dictionary(forKey: storageKey) else { return }
        unlockedLevelIndex = payload["unlocked"] as? Int ?? 0
        levelStars = payload["stars"] as? [String: Int] ?? [:]
        levelBestTime = payload["bestTime"] as? [String: Double] ?? [:]
        totalRuns = payload["totalRuns"] as? Int ?? 0
    }

    private func saveSettings() {
        let payload: [String: Any] = [
            "haptics": hapticsEnabled,
            "sound": soundEnabled
        ]
        UserDefaults.standard.set(payload, forKey: settingsKey)
    }

    private func loadSettings() {
        guard let payload = UserDefaults.standard.dictionary(forKey: settingsKey) else { return }
        hapticsEnabled = payload["haptics"] as? Bool ?? true
        soundEnabled = payload["sound"] as? Bool ?? true
    }
}

/// 中间结果：GameView 计算阶段使用，GameState 加工后再发布 LevelResult
struct PartialLevelResult {
    let level: LevelData
    let success: Bool
    let elapsedSeconds: Double
    let stars: Int
    let cause: FailCause?
}
