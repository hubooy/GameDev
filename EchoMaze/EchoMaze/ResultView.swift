//
//  ResultView.swift
//  关卡结算
//

import SwiftUI

struct ResultView: View {
    let result: LevelResult
    @EnvironmentObject var gameState: GameState
    @State private var starAppear: [Bool] = [false, false, false]
    @State private var buttonsArmed: Bool = false   // 出现后短暂禁用，避免上一屏的连点穿透

    var body: some View {
        ZStack {
            BackgroundAura(color: result.level.theme.accentColor.opacity(0.2))

            VStack(spacing: 28) {
                Spacer()

                // 标题
                VStack(spacing: 8) {
                    Text(result.success ? "通 关" : "失 败")
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .tracking(12)
                        .foregroundStyle(.white)
                    Text(result.level.theme.displayName)
                        .font(.system(size: 12, weight: .light))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.5))

                    if let cause = result.cause {
                        Text(causeText(cause))
                            .font(.system(size: 11, weight: .light))
                            .tracking(2)
                            .foregroundStyle(.red.opacity(0.7))
                            .padding(.top, 4)
                    }
                }

                // 星星
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < result.stars ? "star.fill" : "star")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(
                                i < result.stars
                                    ? result.level.theme.accentColor
                                    : .white.opacity(0.15)
                            )
                            .scaleEffect(starAppear[i] ? 1 : 0.3)
                            .opacity(starAppear[i] ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6)
                                    .delay(0.2 + Double(i) * 0.15),
                                value: starAppear[i]
                            )
                    }
                }

                // 用时
                VStack(spacing: 4) {
                    Text("用 时")
                        .font(.system(size: 10, weight: .light))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(String(format: "%.1fs", result.elapsedSeconds))
                        .font(.system(size: 28, weight: .ultraLight, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))

                    if result.isNewBest {
                        Text("NEW BEST")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(6)
                            .foregroundStyle(result.level.theme.accentColor)
                            .padding(.top, 2)
                    } else if let best = gameState.levelBestTime[result.level.id], result.success {
                        Text(String(format: "最佳 %.1fs", best))
                            .font(.system(size: 10, weight: .light))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }

                Spacer()

                // 按钮组
                HStack(spacing: 12) {
                    Button {
                        guard buttonsArmed else { return }
                        FeedbackCenter.shared.haptic(.light)
                        gameState.openLevelSelect()
                    } label: {
                        Text("章 节")
                            .tracking(4)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .disabled(!buttonsArmed)

                    Button {
                        guard buttonsArmed else { return }
                        FeedbackCenter.shared.haptic(.medium)
                        gameState.startLevel(result.level)
                    } label: {
                        Text(result.success ? "再 玩" : "重 试")
                            .tracking(4)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(result.level.theme.accentColor))
                    }
                    .disabled(!buttonsArmed)
                }
                .opacity(buttonsArmed ? 1 : 0.5)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            for i in 0..<min(result.stars, 3) {
                starAppear[i] = true
            }
            // 出现 0.5s 后再允许点击，吃掉从 GameView 穿透过来的连点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    buttonsArmed = true
                }
            }
        }
    }

    private func causeText(_ cause: FailCause) -> String {
        switch cause {
        case .trap:      return "踩 中 陷 阱"
        case .loudAlert: return "音 量 过 大 · 触 发 警 报"
        case .timeout:   return "时 间 耗 尽"
        }
    }
}
