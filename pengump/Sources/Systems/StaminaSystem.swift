import Foundation

// MARK: - 体力系统（免费版兼容壳）

class StaminaSystem {
    static let shared = StaminaSystem()

    // 体力上限（兼容展示）
    let maxStamina: Int = 30

    // 回调：体力变化时通知
    var onStaminaChanged: ((Int, Int) -> Void)?  // (current, max)

    // 回调：体力耗尽时通知（免费版不触发）
    var onStaminaEmpty: (() -> Void)?

    private init() {}

    // MARK: - 当前体力

    var currentStamina: Int {
        maxStamina
    }

    var isEmpty: Bool {
        false
    }

    // MARK: - 消耗体力

    /// 消耗1点体力，返回是否成功（免费版恒为成功）
    @discardableResult
    func consume() -> Bool {
        notifyChange()
        return true
    }

    // MARK: - 后台恢复（免费版停用）

    /// 启动体力恢复定时器（兼容 no-op）
    func startRecoveryTimer() {
        // no-op
    }

    func stopRecoveryTimer() {
        // no-op
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
        Array(repeating: "❤️", count: maxStamina)
    }

    /// 简化版：只显示数字
    func staminaText() -> String {
        "\(currentStamina)/\(maxStamina)"
    }
}
