//
//  LevelData.swift
//  关卡数据结构
//

import Foundation
import SwiftUI

/// 关卡场景类型 —— 不同场景对应不同的音量约束玩法
enum LevelTheme: String, Codable {
    case ordinary    // 普通：自由发声
    case library     // 图书馆：必须小声
    case concert     // 演唱会：必须大喊
    case windy       // 风洞：声音衰减快
    case cave        // 洞穴：有回响
    case storm       // 风暴夜：随机阵风扰动
}

/// 单元格类型
enum CellType: Int, Codable {
    case empty = 0
    case wall = 1
    case start = 2
    case exit = 3
    case trap = 4   // 陷阱（被照到 + 玩家踩到会触发）
    case key = 5    // 钥匙
}

struct LevelData: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let displayName: String
    let theme: LevelTheme
    let cols: Int
    let rows: Int
    let grid: [[Int]]              // [row][col] -> CellType.rawValue
    let startPos: GridPos
    let exitPos: GridPos
    let targetSeconds: Int         // 目标通关时间（用于评星）
    let hint: String               // 一句话提示

    /// 触发陷阱的音量阈值（仅 library 关卡：声音大于此值且站在陷阱格 -> 失败）
    var loudTrapThreshold: Float { 0.55 }

    /// 关卡内钥匙总数
    var keyCount: Int {
        var count = 0
        for row in grid {
            for cell in row where cell == CellType.key.rawValue {
                count += 1
            }
        }
        return count
    }

    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        lhs.id == rhs.id
    }
}

struct GridPos: Codable, Hashable, Equatable {
    let col: Int
    let row: Int
}

struct LevelResult {
    let level: LevelData
    let success: Bool
    let elapsedSeconds: Double
    let stars: Int  // 0-3
    let isNewBest: Bool
    let cause: FailCause?  // 失败原因（成功时为 nil）
}

enum FailCause: String {
    case trap      // 踩到陷阱
    case loudAlert // 在图书馆类关卡发出过大音量
    case timeout   // 超时（保留扩展位）
}

extension LevelTheme {
    var displayName: String {
        switch self {
        case .ordinary: return "回声平原"
        case .library:  return "寂静图书馆"
        case .concert:  return "喧嚣演唱会"
        case .windy:    return "穿堂风洞"
        case .cave:     return "幽深洞穴"
        case .storm:    return "风暴之夜"
        }
    }

    var subtitle: String {
        switch self {
        case .ordinary: return "自由发声，照亮前路"
        case .library:  return "保持低语 · 大声会触发警报"
        case .concert:  return "必须呐喊 · 微弱的声音照不到"
        case .windy:    return "声音衰减快 · 持续发声"
        case .cave:     return "余韵悠长 · 一次发声可探更远"
        case .storm:    return "阵风扰动 · 照亮范围反复抖动"
        }
    }

    /// 主色调
    var accentColor: Color {
        switch self {
        case .ordinary: return Color(red: 0.95, green: 0.85, blue: 0.45)
        case .library:  return Color(red: 0.65, green: 0.85, blue: 1.00)
        case .concert:  return Color(red: 1.00, green: 0.45, blue: 0.55)
        case .windy:    return Color(red: 0.70, green: 1.00, blue: 0.85)
        case .cave:     return Color(red: 0.75, green: 0.55, blue: 1.00)
        case .storm:    return Color(red: 0.55, green: 0.70, blue: 0.95)
        }
    }
}
