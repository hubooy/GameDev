//
//  SettingsView.swift
//  设置：触感 / 音效开关、清除进度
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        FeedbackCenter.shared.haptic(.light)
                        gameState.goHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("设 置")
                        .font(.system(size: 14, weight: .regular))
                        .tracking(8)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        section("反馈") {
                            toggleRow(title: "触感反馈", icon: "hand.tap", binding: $gameState.hapticsEnabled)
                            toggleRow(title: "音效", icon: "speaker.wave.2", binding: $gameState.soundEnabled)
                        }

                        section("进度") {
                            statRow(title: "累计游玩", value: "\(gameState.totalRuns) 次", icon: "gamecontroller")
                            statRow(
                                title: "总星数",
                                value: "\(gameState.levelStars.values.reduce(0, +)) / \(LevelLibrary.shared.allLevels.count * 3)",
                                icon: "star"
                            )
                            Button {
                                FeedbackCenter.shared.haptic(.warning)
                                showResetConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .light))
                                    Text("清除进度")
                                        .font(.system(size: 13, weight: .regular))
                                        .tracking(2)
                                    Spacer()
                                }
                                .foregroundStyle(.red.opacity(0.8))
                                .padding(16)
                                .background(rowBackground)
                            }
                        }

                        section("关于") {
                            aboutRow(title: "版本", value: "1.1.0")
                            aboutRow(title: "玩法", value: "声波照亮迷宫")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("清除全部进度？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                resetProgress()
            }
        } message: {
            Text("将删除解锁记录、星数和最佳用时，无法恢复。")
        }
    }

    // MARK: - 小组件

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .light))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.leading, 4)
            VStack(spacing: 8) {
                content()
            }
        }
    }

    private func toggleRow(title: String, icon: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.white.opacity(0.7))
        }
        .padding(16)
        .background(rowBackground)
    }

    private func statRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
        .background(rowBackground)
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(16)
        .background(rowBackground)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }

    private func resetProgress() {
        gameState.unlockedLevelIndex = 0
        gameState.levelStars = [:]
        gameState.levelBestTime = [:]
        gameState.totalRuns = 0
        UserDefaults.standard.removeObject(forKey: "EchoMaze.progress.v2")
        FeedbackCenter.shared.haptic(.success)
    }
}
