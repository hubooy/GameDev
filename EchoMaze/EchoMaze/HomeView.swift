//
//  HomeView.swift
//  首页：标题 + 开始按钮 + 设置入口 + 进度统计
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameState: GameState
    @State private var pulse: CGFloat = 0.7

    private var totalLevels: Int { LevelLibrary.shared.allLevels.count }
    private var clearedLevels: Int {
        LevelLibrary.shared.allLevels.filter { (gameState.levelStars[$0.id] ?? 0) > 0 }.count
    }
    private var totalStars: Int {
        gameState.levelStars.values.reduce(0, +)
    }

    var body: some View {
        ZStack {
            BackgroundAura(color: .yellow.opacity(0.18))

            // 右上角：设置按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        FeedbackCenter.shared.haptic(.light)
                        gameState.openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            VStack(spacing: 28) {
                Spacer()

                // 标题
                VStack(spacing: 12) {
                    Text("ECHO")
                        .font(.system(size: 64, weight: .black, design: .serif))
                        .tracking(8)
                        .foregroundStyle(.white)

                    Text("MAZE")
                        .font(.system(size: 64, weight: .ultraLight, design: .serif))
                        .tracking(24)
                        .foregroundStyle(.white.opacity(0.85))

                    Text("回 · 声 · 迷 · 宫")
                        .font(.system(size: 13, weight: .light))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 4)
                }

                // 进度
                if clearedLevels > 0 {
                    HStack(spacing: 20) {
                        statItem("通关", "\(clearedLevels)/\(totalLevels)")
                        statItem("星数", "\(totalStars)/\(totalLevels * 3)")
                        statItem("游玩", "\(gameState.totalRuns)")
                    }
                    .padding(.top, 4)
                }

                Spacer()

                // 提示
                VStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                        .scaleEffect(pulse)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                    Text("用声音照亮黑暗")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(2)
                }
                .padding(.bottom, 8)

                Button {
                    FeedbackCenter.shared.haptic(.medium)
                    gameState.openLevelSelect()
                } label: {
                    HStack(spacing: 12) {
                        Text("开 始")
                            .tracking(8)
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(Color.white))
                }
                .padding(.horizontal, 48)

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { pulse = 1.05 }
    }

    private func statItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

struct BackgroundAura: View {
    let color: Color
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [color, .black.opacity(0)],
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
    }
}
