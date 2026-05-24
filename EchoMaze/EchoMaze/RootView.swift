//
//  RootView.swift
//  场景路由：首页 / 关卡选择 / 游戏 / 结算 / 设置
//

import SwiftUI

enum AppScene {
    case home
    case levelSelect
    case playing(LevelData)
    case result(LevelResult)
    case settings
}

struct RootView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameState.scene {
            case .home:
                HomeView()
                    .transition(.opacity)
            case .levelSelect:
                LevelSelectView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .playing(let level):
                GameView(level: level)
                    .transition(.opacity)
            case .result(let result):
                ResultView(result: result)
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: sceneID)
    }

    private var sceneID: String {
        switch gameState.scene {
        case .home: return "home"
        case .levelSelect: return "select"
        case .playing(let l): return "play_\(l.id)"
        case .result: return "result"
        case .settings: return "settings"
        }
    }
}
