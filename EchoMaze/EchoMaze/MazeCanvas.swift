//
//  MazeCanvas.swift
//  迷宫渲染：使用 SwiftUI Canvas 高性能绘制
//  声波照亮：以玩家为中心，半径 = f(audioLevel, theme)
//

import SwiftUI

struct MazeCanvas: View {
    let level: LevelData
    let playerPos: GridPos
    let audioLevel: Float       // 0~1
    let cellSize: CGFloat
    let collectedKeys: Set<GridPos>
    let hasAllKeys: Bool
    let stormPhase: Double      // storm 主题阵风相位

    var body: some View {
        Canvas { ctx, size in
            drawMaze(in: ctx, size: size)
        }
        .mask(
            Canvas { ctx, size in
                drawLightMask(in: ctx, size: size)
            }
        )
        .overlay(playerDot)
        .overlay(exitMarker)
    }

    // MARK: - 绘制迷宫主体

    private func drawMaze(in ctx: GraphicsContext, size: CGSize) {
        for row in 0..<level.rows {
            for col in 0..<level.cols {
                let cell = level.grid[row][col]
                let pos = GridPos(col: col, row: row)
                let rect = CGRect(
                    x: CGFloat(col) * cellSize,
                    y: CGFloat(row) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                switch CellType(rawValue: cell) ?? .empty {
                case .wall:
                    let path = Path(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 2)
                    ctx.fill(path, with: .color(level.theme.accentColor.opacity(0.85)))
                case .empty, .start:
                    let path = Path(rect)
                    ctx.fill(path, with: .color(.white.opacity(0.04)))
                case .exit:
                    // 出口：钥匙齐全 → 主题色发光；缺钥匙 → 灰色锁定
                    let path = Path(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 3)
                    let color: Color = hasAllKeys
                        ? level.theme.accentColor.opacity(0.9)
                        : .white.opacity(0.15)
                    ctx.fill(path, with: .color(color))
                    if !hasAllKeys {
                        // 锁图标位置（简单画一个小方块代表锁芯）
                        let lockRect = rect.insetBy(dx: cellSize * 0.38, dy: cellSize * 0.38)
                        ctx.fill(Path(lockRect), with: .color(.white.opacity(0.45)))
                    }
                case .trap:
                    let path = Path(ellipseIn: rect.insetBy(dx: 6, dy: 6))
                    ctx.fill(path, with: .color(.red.opacity(0.7)))
                case .key:
                    if collectedKeys.contains(pos) {
                        // 已拾取：仅地面
                        let path = Path(rect)
                        ctx.fill(path, with: .color(.white.opacity(0.04)))
                    } else {
                        let path = Path(ellipseIn: rect.insetBy(dx: 5, dy: 5))
                        ctx.fill(path, with: .color(.yellow.opacity(0.9)))
                    }
                }
            }
        }
    }

    // MARK: - 照亮蒙版

    private func drawLightMask(in ctx: GraphicsContext, size: CGSize) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        let playerCenter = CGPoint(
            x: (CGFloat(playerPos.col) + 0.5) * cellSize,
            y: (CGFloat(playerPos.row) + 0.5) * cellSize
        )

        let radius = lightRadius()

        let gradient = Gradient(stops: [
            .init(color: .white, location: 0.0),
            .init(color: .white.opacity(0.95), location: 0.55),
            .init(color: .white.opacity(0.3), location: 0.85),
            .init(color: .clear, location: 1.0),
        ])

        let lightRect = CGRect(
            x: playerCenter.x - radius,
            y: playerCenter.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        ctx.fill(
            Path(ellipseIn: lightRect),
            with: .radialGradient(
                gradient,
                center: playerCenter,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    /// 根据音量+主题计算照亮半径
    /// 注意：base 项保持很小，保证不发声时屏幕基本全黑（只看到玩家自身的一圈微光）
    private func lightRadius() -> CGFloat {
        let v = CGFloat(audioLevel)
        let baseCellRadius: CGFloat
        switch level.theme {
        case .ordinary:
            baseCellRadius = 0.4 + v * 4.8
        case .library:
            let bell = max(0, 1 - abs(v - 0.15) / 0.25)
            baseCellRadius = 0.4 + bell * 5.0
        case .concert:
            let amp = max(0, v - 0.5) * 2.0
            baseCellRadius = 0.35 + amp * 5.8
        case .windy:
            baseCellRadius = 0.35 + v * 4.0
        case .cave:
            baseCellRadius = 0.5 + v * 6.0
        case .storm:
            // 阵风：sin 相位扰动 ±35%；base 仍然要小
            let gust = CGFloat(sin(stormPhase)) * 0.35 + 1.0
            baseCellRadius = (0.4 + v * 4.6) * gust
        }
        return max(0.32, baseCellRadius) * cellSize
    }

    // MARK: - 玩家点

    private var playerDot: some View {
        let x = (CGFloat(playerPos.col) + 0.5) * cellSize
        let y = (CGFloat(playerPos.row) + 0.5) * cellSize
        return Circle()
            .fill(Color.white)
            .frame(width: cellSize * 0.5, height: cellSize * 0.5)
            .shadow(color: level.theme.accentColor, radius: 8)
            .position(x: x, y: y)
            .animation(.easeOut(duration: 0.12), value: playerPos)
    }

    // MARK: - 出口微光
    private var exitMarker: some View {
        let x = (CGFloat(level.exitPos.col) + 0.5) * cellSize
        let y = (CGFloat(level.exitPos.row) + 0.5) * cellSize
        return Circle()
            .stroke(
                hasAllKeys ? level.theme.accentColor : Color.white.opacity(0.25),
                lineWidth: hasAllKeys ? 1 : 0.5
            )
            .frame(width: cellSize * 0.9, height: cellSize * 0.9)
            .position(x: x, y: y)
            .opacity(0.6)
    }
}
