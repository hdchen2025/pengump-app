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

    // UserDefaults keys
    private enum Keys {
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
    var coins: Int = 0                            // 金币余额
    var stamina: Int = 30                         // 当前体力
    var lastStaminaUpdate: Date = Date()          // 上次体力更新时间

    // MARK: - 初始化

    private init() {}

    // MARK: - 加载 / 保存

    func load() {
        // 检查是否真的有存档（用 hasRecord 标记）
        let hasRecord = defaults.bool(forKey: Keys.hasRecord)

        // 加载每关最高分
        if let data = defaults.data(forKey: Keys.highestScores),
           let scores = try? JSONDecoder().decode([Int: ScoreRecord].self, from: data) {
            highestScores = scores
        }

        // 加载已解锁关卡
        unlockedLevels = defaults.integer(forKey: Keys.unlockedLevels)
        if unlockedLevels == 0 { unlockedLevels = 1 }

        // 加载金币
        coins = defaults.integer(forKey: Keys.coins)

        if !hasRecord {
            // 首次安装：初始化体力为30，新手金币为100
            stamina = 30
            coins = 100
            defaults.set(true, forKey: Keys.hasRecord)
        } else {
            // 有存档，正常读取体力（体力为0表示耗尽状态，等recoverStamina补算）
            stamina = defaults.integer(forKey: Keys.stamina)
        }

        // 加载上次体力更新时间
        if let date = defaults.object(forKey: Keys.lastStaminaUpdate) as? Date {
            lastStaminaUpdate = date
        } else {
            lastStaminaUpdate = Date()
        }
    }

    func save() {
        // 保存每关最高分
        if let data = try? JSONEncoder().encode(highestScores) {
            defaults.set(data, forKey: Keys.highestScores)
        }

        defaults.set(unlockedLevels, forKey: Keys.unlockedLevels)
        defaults.set(coins, forKey: Keys.coins)
        defaults.set(stamina, forKey: Keys.stamina)
        defaults.set(lastStaminaUpdate, forKey: Keys.lastStaminaUpdate)
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
        return highestScores[level]
    }

    /// 获取关卡星级
    func stars(for level: Int) -> Int {
        return highestScores[level]?.stars ?? 0
    }

    /// 检查关卡是否已解锁
    func isLevelUnlocked(_ level: Int) -> Bool {
        return level <= unlockedLevels
    }

    /// 解锁新关卡
    func unlockLevel(_ level: Int) {
        if level > unlockedLevels {
            unlockedLevels = level
            save()
        }
    }

    // MARK: - 金币操作

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

    // MARK: - 体力操作

    func consumeStamina() -> Bool {
        guard stamina > 0 else { return false }
        stamina -= 1
        lastStaminaUpdate = Date()
        save()
        return true
    }

    /// 根据离线时间恢复体力（每5分钟+1点）
    func recoverStamina() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastStaminaUpdate)
        let minutesPassed = Int(elapsed / 300)  // 300秒 = 5分钟
        if minutesPassed > 0 && stamina < 30 {
            let recovered = min(30 - stamina, minutesPassed)
            stamina += recovered
            lastStaminaUpdate = lastStaminaUpdate.addingTimeInterval(TimeInterval(recovered * 300))
            save()
        }
    }

    /// 格式化体力恢复时间
    func staminaRecoveryTime() -> String? {
        guard stamina >= 30 else {
            let elapsed = Date().timeIntervalSince(lastStaminaUpdate)
            let secondsSinceUpdate = Int(elapsed)
            let secondsUntilNext = max(0, 300 - secondsSinceUpdate)
            let minutes = secondsUntilNext / 60
            let seconds = secondsUntilNext % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return nil
    }

    // MARK: - 排行榜

    /// 获取前10名分数记录（按分数降序）
    func topScores(limit: Int = 10) -> [ScoreRecord] {
        return Array(highestScores.values
            .sorted { $0.score > $1.score }
            .prefix(limit))
    }
}
