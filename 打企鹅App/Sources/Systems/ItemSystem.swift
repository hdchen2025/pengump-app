import Foundation
import UIKit

// MARK: - 道具类型

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

// MARK: - 道具系统

class ItemSystem {
    static let shared = ItemSystem()

    // 当前持有道具数量
    private(set) var inventory: [ItemType: Int] = [:]

    // 已激活的道具效果（当前关卡有效）
    private(set) var activeEffects: Set<ItemType> = []

    // 回调：道具变化时通知
    var onInventoryChanged: (([ItemType: Int]) -> Void)?

    private init() {
        // 初始化道具数量
        for item in ItemType.allCases {
            inventory[item] = 0
        }
    }

    // MARK: - 购买道具

    /// 购买道具，返回是否成功
    @discardableResult
    func purchase(_ item: ItemType) -> Bool {
        if SaveManager.shared.spendCoins(item.price) {
            inventory[item, default: 0] += 1
            notifyChange()
            return true
        }
        return false
    }

    // MARK: - 使用道具

    /// 使用道具，返回是否成功
    @discardableResult
    func use(_ item: ItemType) -> Bool {
        guard (inventory[item] ?? 0) > 0 else { return false }
        inventory[item]! -= 1
        activeEffects.insert(item)
        notifyChange()
        return true
    }

    // MARK: - 效果检查

    /// 是否有额外企鹅效果
    var hasExtraPenguin: Bool {
        return activeEffects.contains(.extraPenguin)
    }

    /// 是否有炸弹效果（一次性，用过即消除）
    var hasBomb: Bool {
        return activeEffects.contains(.bomb)
    }

    /// 消耗炸弹效果（调用后清除）
    func consumeBomb() {
        activeEffects.remove(.bomb)
    }

    /// 是否有重置效果
    var hasReset: Bool {
        return activeEffects.contains(.reset)
    }

    /// 消耗重置效果
    func consumeReset() {
        activeEffects.remove(.reset)
    }

    // MARK: - 关卡开始/结束

    /// 开始新关卡时重置道具效果
    func resetForNewLevel() {
        activeEffects.removeAll()
        notifyChange()
    }

    /// 加载已购道具数量（从存档恢复）
    func loadInventory() {
        // 暂无持久化道具数量需求，暂时只用于内存
    }

    // MARK: - 通知

    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onInventoryChanged?(self.inventory)
        }
    }

    // MARK: - 商店UI

    /// 创建道具商店面板
    func createShopPanel(in view: UIView, onPurchase: @escaping (ItemType) -> Void, onClose: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        container.tag = 999

        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.tag = 1000

        let titleLabel = UILabel()
        titleLabel.text = "🏪 道具商店"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)

        let coinLabel = UILabel()
        coinLabel.text = "💰 \(SaveManager.shared.coins) 金币"
        coinLabel.font = .systemFont(ofSize: 16, weight: .medium)
        coinLabel.textAlignment = .center
        coinLabel.textColor = .darkGray

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill

        for item in ItemType.allCases {
            let row = createItemRow(item: item, onPurchase: { onPurchase(item) })
            stackView.addArrangedSubview(row)
        }

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(nil, action: #selector(closeShopTapped(_:)), for: .touchUpInside)
        closeButton.addTarget(nil, action: NSSelectorFromString("closeShopAction"), for: .touchUpInside)

        // 保存关闭回调
        panel.accessibilityIdentifier = "shopPanel"
        objc_setAssociatedObject(panel, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(container, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)

        panel.addSubview(titleLabel)
        panel.addSubview(coinLabel)
        panel.addSubview(stackView)
        panel.addSubview(closeButton)
        container.addSubview(panel)

        // SnapKit布局
        panel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(320)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(16)
        }

        coinLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(coinLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(16)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-20)
        }

        // 添加点击背景关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shopBackgroundTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        return container
    }

    private func createItemRow(item: ItemType, onPurchase: @escaping () -> Void) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
        row.layer.cornerRadius = 10

        let emojiLabel = UILabel()
        emojiLabel.text = item.emoji
        emojiLabel.font = .systemFont(ofSize: 28)

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .darkGray

        let descLabel = UILabel()
        descLabel.text = item.description
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .gray
        descLabel.numberOfLines = 2

        let priceLabel = UILabel()
        priceLabel.text = "\(item.price) 💰"
        priceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        priceLabel.textColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)

        let buyButton = UIButton(type: .system)
        buyButton.setTitle("购买", for: .normal)
        buyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)
        buyButton.layer.cornerRadius = 6
        buyButton.tag = item.hashValue
        buyButton.addTarget(nil, action: #selector(buyItemTapped(_:)), for: .touchUpInside)

        // 保存购买回调
        objc_setAssociatedObject(buyButton, "itemType", item, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(buyButton, "purchaseAction", onPurchase, .OBJC_ASSOCIATION_RETAIN)

        let currentCount = inventory[item] ?? 0
        let countLabel = UILabel()
        countLabel.text = "持有: \(currentCount)"
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .gray
        countLabel.tag = 2000 + item.hashValue

        row.addSubview(emojiLabel)
        row.addSubview(nameLabel)
        row.addSubview(descLabel)
        row.addSubview(priceLabel)
        row.addSubview(buyButton)
        row.addSubview(countLabel)

        emojiLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(emojiLabel.snp.right).offset(8)
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(buyButton.snp.left).offset(-8)
        }

        descLabel.snp.makeConstraints { make in
            make.left.equalTo(emojiLabel.snp.right).offset(8)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.right.equalTo(buyButton.snp.left).offset(-8)
        }

        countLabel.snp.makeConstraints { make in
            make.left.equalTo(emojiLabel.snp.right).offset(8)
            make.top.equalTo(descLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-10)
        }

        buyButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }

        row.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(80)
        }

        return row
    }

    @objc private func buyItemTapped(_ sender: UIButton) {
        guard let item = objc_getAssociatedObject(sender, "itemType") as? ItemType else { return }
        if let action = objc_getAssociatedObject(sender, "purchaseAction") as? () -> Void {
            action()
        }
        // 更新持有数量
        if let countLabel = sender.superview?.viewWithTag(2000 + item.hashValue) as? UILabel {
            countLabel.text = "持有: \(inventory[item] ?? 0)"
        }
        // 更新金币显示（通过通知或回调）
    }

    @objc private func closeShopTapped(_ sender: UIButton) {
        if let closeAction = objc_getAssociatedObject(sender.superview ?? UIView(), "closeAction") as? () -> Void {
            closeAction()
        }
    }

    @objc private func shopBackgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        if let panel = gesture.view?.viewWithTag(1000), !panel.frame.contains(location) {
            if let closeAction = objc_getAssociatedObject(gesture.view!, "closeAction") as? () -> Void {
                closeAction()
            }
        }
    }
}

// 关联对象key
private var closeActionKey: UInt8 = 0
