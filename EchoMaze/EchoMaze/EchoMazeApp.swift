//
//  EchoMazeApp.swift
//  EchoMaze - 回声迷宫
//
//  核心玩法：对着麦克风发声，声波"照亮"漆黑迷宫
//

import SwiftUI

@main
struct EchoMazeApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var audioEngine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
                .environmentObject(audioEngine)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .onAppear {
                    FeedbackCenter.shared.prepare()
                    syncSettings()
                }
                .onChange(of: gameState.hapticsEnabled) { _, _ in syncSettings() }
                .onChange(of: gameState.soundEnabled)   { _, _ in syncSettings() }
        }
    }

    private func syncSettings() {
        FeedbackCenter.shared.hapticsEnabled = gameState.hapticsEnabled
        FeedbackCenter.shared.soundEnabled = gameState.soundEnabled
    }
}
