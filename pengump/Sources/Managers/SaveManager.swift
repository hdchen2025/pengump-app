import Foundation

// MARK: - 数据结构

struct ScoreRecord: Codable, Equatable {
    let level: Int
    let score: Int
    let stars: Int  // 1-3星
    let date: Date
}

// MARK: - SaveManager

class SaveManager {
    static let shared = SaveManager()

    private let defaults = UserDefaults.standard
    private let currentSaveDataVersion = 2
    private let maxStaminaValue = 30

    // UserDefaults keys
    private enum Keys {
        static let saveDataVersion = "save_data_version"
        static let highestScores = "highest_scores"
        static let unlockedLevels = "unlocked_levels"
        static let coins = "coins"
        static let stamina = "stamina"
        static let lastStaminaUpdate = "last_stamina_update"
        static let hasRecord = "has_record"
    }

    // MARK: - 数据属性

    var highestScores: [Int: ScoreRecord] = [:]  // 每关最高分
    var unlockedLevels: Int = 1                   // 已解锁最高关卡

    // 兼容旧经济字段（免费版主流程不依赖）
    var coins: Int = 0
    var stamina: Int = 30
    var lastStaminaUpdate: Date = Date()

    // MARK: - 初始化

    private init() {}

    // MARK: - 加载 / 保存

    func load() {
        let hasRecord = defaults.bool(forKey: Keys.hasRecord)
        let hasVersionMarker = defaults.object(forKey: Keys.saveDataVersion) != nil

        // 加载每关最高分
        if let data = defaults.data(forKey: Keys.highestScores),
           let scores = try? JSONDecoder().decode([Int: ScoreRecord].self, from: data) {
            highestScores = scores
        } else {
            highestScores = [:]
        }

        // 加载已解锁关卡
        unlockedLevels = defaults.integer(forKey: Keys.unlockedLevels)
        if unlockedLevels <= 0 { unlockedLevels = 1 }

        // 兼容读取旧经济字段（但不驱动免费版主流程）
        coins = defaults.integer(forKey: Keys.coins)
        let persistedStamina = defaults.integer(forKey: Keys.stamina)
        stamina = persistedStamina > 0 ? min(persistedStamina, maxStaminaValue) : maxStaminaValue

        if let date = defaults.object(forKey: Keys.lastStaminaUpdate) as? Date {
            lastStaminaUpdate = date
        } else {
            lastStaminaUpdate = Date()
        }

        // 首次安装初始化（避免覆盖已有历史分数/关卡）
        let isFreshInstall = !hasRecord && !hasAnyLegacyData()
        if isFreshInstall {
            stamina = maxStaminaValue
            coins = 100
            defaults.set(true, forKey: Keys.hasRecord)
        }

        // 迁移：旧版本（无版本号）升级到 v2
        if !hasVersionMarker {
            migrateToV2()
        } else {
            let savedVersion = defaults.integer(forKey: Keys.saveDataVersion)
            if savedVersion < currentSaveDataVersion {
                defaults.set(currentSaveDataVersion, forKey: Keys.saveDataVersion)
            }
        }
    }

    func save() {
        // 保存每关最高分
        if let data = try? JSONEncoder().encode(highestScores) {
            defaults.set(data, forKey: Keys.highestScores)
        }

        defaults.set(unlockedLevels, forKey: Keys.unlockedLevels)

        // 兼容写回旧经济字段（免费版主流程不依赖）
        defaults.set(coins, forKey: Keys.coins)
        defaults.set(stamina, forKey: Keys.stamina)
        defaults.set(lastStaminaUpdate, forKey: Keys.lastStaminaUpdate)

        defaults.set(true, forKey: Keys.hasRecord)
        defaults.set(currentSaveDataVersion, forKey: Keys.saveDataVersion)
    }

    private func migrateToV2() {
        // 不清空任何历史关卡与分数，仅补版本标记
        defaults.set(currentSaveDataVersion, forKey: Keys.saveDataVersion)

        // 若旧存档存在任意记录，补齐 hasRecord 标记
        if hasAnyLegacyData() {
            defaults.set(true, forKey: Keys.hasRecord)
        }
    }

    private func hasAnyLegacyData() -> Bool {
        return defaults.object(forKey: Keys.hasRecord) != nil
            || defaults.object(forKey: Keys.highestScores) != nil
            || defaults.object(forKey: Keys.unlockedLevels) != nil
            || defaults.object(forKey: Keys.coins) != nil
            || defaults.object(forKey: Keys.stamina) != nil
            || defaults.object(forKey: Keys.lastStaminaUpdate) != nil
    }

    // MARK: - 关卡分数操作

    /// 更新关卡最高分（仅当新分数更高时更新）
    func updateScore(level: Int, score: Int, stars: Int) {
        let record = ScoreRecord(level: level, score: score, stars: stars, date: Date())

        if let existing = highestScores[level] {
            if score > existing.score {
                highestScores[level] = record
            } else if stars > existing.stars {
                // 星级更高时也更新
                highestScores[level] = ScoreRecord(level: level, score: max(score, existing.score), stars: stars, date: existing.date)
            }
        } else {
            highestScores[level] = record
        }

        save()
    }

    /// 获取关卡记录
    func record(for level: Int) -> ScoreRecord? {
        highestScores[level]
    }

    /// 获取关卡星级
    func stars(for level: Int) -> Int {
        highestScores[level]?.stars ?? 0
    }

    /// 检查关卡是否已解锁
    func isLevelUnlocked(_ level: Int) -> Bool {
        level <= unlockedLevels
    }

    /// 解锁新关卡
    func unlockLevel(_ level: Int) {
        if level > unlockedLevels {
            unlockedLevels = level
            save()
        }
    }

    // MARK: - 金币操作（兼容保留）

    func addCoins(_ amount: Int) {
        coins += amount
        save()
    }

    func spendCoins(_ amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            save()
            return true
        }
        return false
    }

    // MARK: - 体力操作（兼容保留，主路径停用门槛）

    func consumeStamina() -> Bool {
        // 免费版不再使用体力门槛；保留方法签名避免调用方崩溃
        // 仅在兼容字段偏离预期时落盘，避免每次调用都产生无意义写盘。
        guard stamina != maxStaminaValue else {
            return true
        }

        stamina = maxStaminaValue
        lastStaminaUpdate = Date()
        save()
        return true
    }

    /// 根据离线时间恢复体力（免费版主路径停用）
    func recoverStamina() {
        // no-op: 仅保留兼容入口
    }

    /// 格式化体力恢复时间（免费版主路径停用）
    func staminaRecoveryTime() -> String? {
        nil
    }

    // MARK: - 排行榜

    /// 获取前10名分数记录（按分数降序）
    func topScores(limit: Int = 10) -> [ScoreRecord] {
        Array(highestScores.values
            .sorted { $0.score > $1.score }
            .prefix(limit))
    }
}
