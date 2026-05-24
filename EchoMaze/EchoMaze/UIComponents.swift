//
//  UIComponents.swift
//  方向键、音量条等通用组件
//

import SwiftUI

// MARK: - 音量条
struct VolumeBar: View {
    let level: Float
    let accent: Color
    /// 警戒阈值（0~1），用于 library 主题。设为 nil 则不显示
    var dangerThreshold: Float? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                // 主条
                let isOver = (dangerThreshold != nil) && level > dangerThreshold!
                Capsule()
                    .fill(LinearGradient(
                        colors: isOver
                            ? [.red.opacity(0.7), .red]
                            : [accent.opacity(0.6), accent],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(4, geo.size.width * CGFloat(level)))
                    .animation(.linear(duration: 0.05), value: level)

                // 警戒线
                if let t = dangerThreshold {
                    Rectangle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 1.5, height: 14)
                        .offset(x: geo.size.width * CGFloat(t) - 0.75, y: 0)
                }
            }
        }
    }
}

// MARK: - 方向键
struct DPad: View {
    let onPress: (Direction) -> Void

    var body: some View {
        VStack(spacing: 8) {
            arrowButton(.up, icon: "chevron.up")
            HStack(spacing: 8) {
                arrowButton(.left, icon: "chevron.left")
                Color.clear.frame(width: 60, height: 60)
                arrowButton(.right, icon: "chevron.right")
            }
            arrowButton(.down, icon: "chevron.down")
        }
    }

    private func arrowButton(_ dir: Direction, icon: String) -> some View {
        Button {
            onPress(dir)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                )
        }
    }
}
