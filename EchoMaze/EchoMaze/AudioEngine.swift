//
//  AudioEngine.swift
//  麦克风音量监测 —— 核心驱动力
//  使用 AVAudioEngine 实时采集音量，输出 0~1 归一化能量值
//

import Foundation
import AVFoundation
import Combine

final class AudioEngine: ObservableObject {

    /// 当前音量 0...1（已平滑）
    @Published private(set) var level: Float = 0
    /// 是否已授权
    @Published private(set) var isAuthorized: Bool = false
    /// 是否正在采集
    @Published private(set) var isRunning: Bool = false

    private let engine = AVAudioEngine()
    private var smoothing: Float = 0  // 低通平滑

    // MARK: - 权限

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    completion(granted)
                }
            }
        }
    }

    // MARK: - 启停

    func start() {
        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)

            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.process(buffer: buffer)
            }

            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            print("AudioEngine start error: \(error)")
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        DispatchQueue.main.async { [weak self] in
            self?.level = 0
            self?.smoothing = 0
        }
    }

    // MARK: - 信号处理

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // 计算 RMS
        var sum: Float = 0
        for i in 0..<frameLength {
            let s = channelData[i]
            sum += s * s
        }
        let rms = sqrt(sum / Float(frameLength))

        // 转 dB 再归一化到 0~1
        // RMS≈0.001(-60dB) -> 0, RMS≈0.5(-6dB) -> 1
        let db = 20 * log10(max(rms, 0.00001))
        let normalized = max(0, min(1, (db + 60) / 54))  // -60dB~-6dB 映射到 0~1

        // 平滑（低通）—— 上升快，下降稍慢
        let attack: Float = 0.6
        let release: Float = 0.25
        let coef = normalized > smoothing ? attack : release
        smoothing += (normalized - smoothing) * coef

        let display = smoothing
        DispatchQueue.main.async { [weak self] in
            self?.level = display
        }
    }
}
