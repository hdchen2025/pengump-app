import Foundation
import UIKit

// MARK: - 体力系统

class StaminaSystem {
    static let shared = StaminaSystem()

    // 体力上限
    let maxStamina: Int = 30

    // 恢复间隔（秒）= 5分钟
    private let recoveryInterval: TimeInterval = 300

    // 恢复Timer
    private var recoveryTimer: Timer?

    // 回调：体力变化时通知
    var onStaminaChanged: ((Int, Int) -> Void)?  // (current, max)

    // 回调：体力耗尽时通知
    var onStaminaEmpty: (() -> Void)?

    private init() {}

    // MARK: - 当前体力

    var currentStamina: Int {
        return SaveManager.shared.stamina
    }

    var isEmpty: Bool {
        return currentStamina <= 0
    }

    // MARK: - 消耗体力

    /// 消耗1点体力，返回是否成功
    @discardableResult
    func consume() -> Bool {
        if currentStamina > 0 {
            _ = SaveManager.shared.consumeStamina()
            notifyChange()
            return true
        } else {
            onStaminaEmpty?()
            return false
        }
    }

    // MARK: - 后台恢复

    /// 启动体力恢复定时器
    func startRecoveryTimer() {
        stopRecoveryTimer()

        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopRecoveryTimer() {
        recoveryTimer?.invalidate()
        recoveryTimer = nil
    }

    private func tick() {
        guard currentStamina < maxStamina else {
            stopRecoveryTimer()
            return
        }

        // 每秒检查一次是否需要恢复
        if let recoveryTime = SaveManager.shared.staminaRecoveryTime(),
           recoveryTime == "0:00" {
            // 刚好恢复1点
            SaveManager.shared.stamina = min(SaveManager.shared.stamina + 1, maxStamina)
            SaveManager.shared.lastStaminaUpdate = Date()
            SaveManager.shared.save()
            notifyChange()
        }
    }

    // MARK: - 通知

    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onStaminaChanged?(self.currentStamina, self.maxStamina)
        }
    }

    // MARK: - UI生成

    /// 生成体力图标数组（filledCount个❤️ + emptyCount个🖤）
    func staminaIcons() -> [String] {
        let filled = min(currentStamina, maxStamina)
        let empty = maxStamina - filled
        var icons: [String] = []
        for _ in 0..<filled {
            icons.append("❤️")
        }
        for _ in 0..<empty {
            icons.append("🖤")
        }
        return icons
    }

    /// 简化版：只显示数字
    func staminaText() -> String {
        return "\(currentStamina)/\(maxStamina)"
    }
}
