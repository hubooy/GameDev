//
//  FeedbackCenter.swift
//  统一管理音效 + 触感反馈；尊重 GameState 的设置开关
//  音效使用系统短促提示音，无需打包资源
//

import UIKit
import AudioToolbox

enum SoundCue {
    case tap        // 普通操作
    case keyPickup  // 拾取钥匙
    case trap       // 触发陷阱
    case unlock     // 出口解锁
    case clear      // 通关
}

enum HapticCue {
    case light
    case medium
    case heavy
    case success
    case warning
    case failure
}

final class FeedbackCenter {
    static let shared = FeedbackCenter()
    private init() {}

    var hapticsEnabled = true
    var soundEnabled = true

    // 预热生成器：首次触发不会有明显延迟
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notify.prepare()
    }

    func haptic(_ cue: HapticCue) {
        guard hapticsEnabled else { return }
        switch cue {
        case .light:   lightImpact.impactOccurred()
        case .medium:  mediumImpact.impactOccurred()
        case .heavy:   heavyImpact.impactOccurred()
        case .success: notify.notificationOccurred(.success)
        case .warning: notify.notificationOccurred(.warning)
        case .failure: notify.notificationOccurred(.error)
        }
    }

    func sound(_ cue: SoundCue) {
        guard soundEnabled else { return }
        // 选用 iOS 系统音 ID。即便无声开关开启，这些短提示音通常也可发声
        let id: SystemSoundID
        switch cue {
        case .tap:        id = 1104   // SMS sent tick
        case .keyPickup:  id = 1057   // tweet sent
        case .trap:       id = 1053   // error
        case .unlock:     id = 1003   // received tone
        case .clear:      id = 1025   // success-ish
        }
        AudioServicesPlaySystemSound(id)
    }
}
