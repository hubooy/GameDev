//
//  LevelSelectView.swift
//  关卡选择列表
//

import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var gameState: GameState
    private let levels = LevelLibrary.shared.allLevels

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button {
                        gameState.goHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("章节")
                        .font(.system(size: 14, weight: .regular))
                        .tracking(8)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // 列表
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                            LevelCard(
                                index: index,
                                level: level,
                                locked: index > gameState.unlockedLevelIndex,
                                stars: gameState.levelStars[level.id] ?? 0
                            )
                            .onTapGesture {
                                guard index <= gameState.unlockedLevelIndex else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                    return
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                gameState.startLevel(level)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct LevelCard: View {
    let index: Int
    let level: LevelData
    let locked: Bool
    let stars: Int

    var body: some View {
        HStack(spacing: 16) {
            // 编号
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 32, weight: .ultraLight, design: .serif))
                .foregroundStyle(locked ? .white.opacity(0.2) : level.theme.accentColor.opacity(0.9))
                .frame(width: 50)

            // 主题信息
            VStack(alignment: .leading, spacing: 6) {
                Text(level.theme.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(locked ? .white.opacity(0.3) : .white)
                    .tracking(2)

                Text(locked ? "未解锁" : level.theme.subtitle)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.white.opacity(locked ? 0.2 : 0.5))
                    .tracking(1)

                // 星星
                if !locked && stars > 0 {
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i < stars ? level.theme.accentColor : .white.opacity(0.2))
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // 状态图标
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(locked ? 0.25 : 0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            locked
                                ? Color.white.opacity(0.06)
                                : level.theme.accentColor.opacity(0.3),
                            lineWidth: 0.5
                        )
                )
        )
        .opacity(locked ? 0.7 : 1.0)
    }
}
