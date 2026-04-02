import Foundation

// MARK: - 道具类型（free edition compat shim）

enum ItemType: String, CaseIterable {
    case extraPenguin = "extra_penguin"      // 多扔1只企鹅
    case bomb = "bomb"                        // 炸弹
    case reset = "reset"                      // 重置冰块

    var name: String {
        switch self {
        case .extraPenguin: return "多扔1只企鹅"
        case .bomb: return "炸弹道具"
        case .reset: return "重置冰块"
        }
    }

    var emoji: String {
        switch self {
        case .extraPenguin: return "🐧"
        case .bomb: return "💣"
        case .reset: return "🔄"
        }
    }

    var price: Int {
        switch self {
        case .extraPenguin: return 50
        case .bomb: return 80
        case .reset: return 60
        }
    }

    var description: String {
        switch self {
        case .extraPenguin: return "当前关卡+1只企鹅"
        case .bomb: return "发射后自动引爆所有冰块（不触发combo）"
        case .reset: return "重置所有冰块到初始位置（只生效一次）"
        }
    }
}

// MARK: - 道具系统（free edition compat shim）

class ItemSystem {
    static let shared = ItemSystem()

    // 当前持有道具数量
    private(set) var inventory: [ItemType: Int] = [:]

    // 已激活的道具效果（当前关卡有效）
    private(set) var activeEffects: Set<ItemType> = []

    // 回调：道具变化时通知
    var onInventoryChanged: (([ItemType: Int]) -> Void)?

    private init() {
        for item in ItemType.allCases {
            inventory[item] = 0
        }
    }

    // MARK: - 兼容接口

    /// 兼容保留：消耗金币并增加道具数量
    @discardableResult
    func purchase(_ item: ItemType) -> Bool {
        if SaveManager.shared.spendCoins(item.price) {
            inventory[item, default: 0] += 1
            notifyChange()
            return true
        }
        return false
    }

    /// 使用道具，返回是否成功
    @discardableResult
    func use(_ item: ItemType) -> Bool {
        guard (inventory[item] ?? 0) > 0 else { return false }
        inventory[item, default: 0] -= 1
        activeEffects.insert(item)
        notifyChange()
        return true
    }

    // MARK: - 效果检查

    var hasExtraPenguin: Bool {
        activeEffects.contains(.extraPenguin)
    }

    var hasBomb: Bool {
        activeEffects.contains(.bomb)
    }

    func consumeBomb() {
        activeEffects.remove(.bomb)
    }

    var hasReset: Bool {
        activeEffects.contains(.reset)
    }

    func consumeReset() {
        activeEffects.remove(.reset)
    }

    // MARK: - 关卡开始/结束

    /// 开始新关卡时重置道具效果
    func resetForNewLevel() {
        activeEffects.removeAll()
        notifyChange()
    }

    /// 兼容保留（当前仅内存态）
    func loadInventory() {
        // no-op
    }

    // MARK: - 通知

    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onInventoryChanged?(self.inventory)
        }
    }
}
