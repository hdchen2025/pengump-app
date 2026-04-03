import Foundation
import UIKit

// MARK: - 数据结构

struct ScoreRecord: Codable, Equatable {
    let level: Int
    let score: Int
    let stars: Int  // 1-3星
    let date: Date
}

enum OperationRank: Int, Codable, CaseIterable {
    case d = 0
    case c = 1
    case b = 2
    case a = 3
    case s = 4

    var displayText: String {
        switch self {
        case .d:
            return "D"
        case .c:
            return "C"
        case .b:
            return "B"
        case .a:
            return "A"
        case .s:
            return "S"
        }
    }

    var powerValue: Int {
        switch self {
        case .d:
            return 0
        case .c:
            return 80
        case .b:
            return 140
        case .a:
            return 220
        case .s:
            return 320
        }
    }

    var accentColor: UIColor {
        switch self {
        case .d:
            return UIColor(white: 0.70, alpha: 1.0)
        case .c:
            return UIColor(red: 0.54, green: 0.77, blue: 1.0, alpha: 1.0)
        case .b:
            return UIColor(red: 0.37, green: 0.86, blue: 0.56, alpha: 1.0)
        case .a:
            return UIColor(red: 1.0, green: 0.84, blue: 0.38, alpha: 1.0)
        case .s:
            return UIColor(red: 1.0, green: 0.53, blue: 0.30, alpha: 1.0)
        }
    }
}

// MARK: - SaveManager

class SaveManager {
    static let shared = SaveManager()

    private let defaults = UserDefaults.standard
    private let currentSaveDataVersion = 4
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
        static let completedChallenges = "completed_challenges"
        static let bestRanks = "best_ranks"
    }

    // MARK: - 数据属性

    var highestScores: [Int: ScoreRecord] = [:]  // 每关最高分
    var unlockedLevels: Int = 1                   // 已解锁最高关卡
    var completedChallenges: Set<Int> = []
    var bestRanks: [Int: Int] = [:]

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

        if let completed = defaults.array(forKey: Keys.completedChallenges) as? [Int] {
            completedChallenges = Set(completed)
        } else {
            completedChallenges = []
        }

        if let data = defaults.data(forKey: Keys.bestRanks),
           let ranks = try? JSONDecoder().decode([Int: Int].self, from: data) {
            bestRanks = ranks
        } else {
            bestRanks = [:]
        }

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

        // 迁移：旧版本（无版本号）升级到当前版本
        if !hasVersionMarker {
            migrateToCurrentVersion()
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
        defaults.set(Array(completedChallenges).sorted(), forKey: Keys.completedChallenges)
        if let data = try? JSONEncoder().encode(bestRanks) {
            defaults.set(data, forKey: Keys.bestRanks)
        }

        // 兼容写回旧经济字段（免费版主流程不依赖）
        defaults.set(coins, forKey: Keys.coins)
        defaults.set(stamina, forKey: Keys.stamina)
        defaults.set(lastStaminaUpdate, forKey: Keys.lastStaminaUpdate)

        defaults.set(true, forKey: Keys.hasRecord)
        defaults.set(currentSaveDataVersion, forKey: Keys.saveDataVersion)
    }

    private func migrateToCurrentVersion() {
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
            || defaults.object(forKey: Keys.completedChallenges) != nil
            || defaults.object(forKey: Keys.bestRanks) != nil
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
                highestScores[level] = ScoreRecord(
                    level: level,
                    score: score,
                    stars: max(existing.stars, stars),
                    date: Date()
                )
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

    func isChallengeCompleted(_ level: Int) -> Bool {
        completedChallenges.contains(level)
    }

    @discardableResult
    func markChallengeCompleted(_ level: Int) -> Bool {
        let inserted = completedChallenges.insert(level).inserted
        if inserted {
            save()
        }
        return inserted
    }

    var completedChallengeCount: Int {
        completedChallenges.count
    }

    func bestRank(for level: Int) -> OperationRank? {
        guard let rawValue = bestRanks[level] else {
            return nil
        }
        return OperationRank(rawValue: rawValue)
    }

    @discardableResult
    func updateRank(level: Int, rank: OperationRank) -> Bool {
        let currentRawValue = bestRanks[level] ?? 0
        guard rank.rawValue > currentRawValue else {
            return false
        }

        bestRanks[level] = rank.rawValue
        save()
        return true
    }

    func rankCount(_ rank: OperationRank) -> Int {
        bestRanks.values.filter { $0 == rank.rawValue }.count
    }

    var campaignPower: Int {
        let starPower = (1...Levels.totalLevels).reduce(0) { partialResult, level in
            partialResult + stars(for: level) * 100
        }
        let medalPower = completedChallengeCount * 150
        let rankPower = bestRanks.values.reduce(0) { partialResult, rawValue in
            partialResult + (OperationRank(rawValue: rawValue)?.powerValue ?? 0)
        }
        return starPower + medalPower + rankPower
    }

    var rankedLevelCount: Int {
        bestRanks.count
    }

    var campaignDominancePercent: Int {
        let maxStarPower = Levels.totalLevels * 3 * 100
        let maxMedalPower = Levels.totalLevels * 150
        let maxRankPower = Levels.totalLevels * OperationRank.s.powerValue
        let maxPower = maxStarPower + maxMedalPower + maxRankPower
        guard maxPower > 0 else { return 0 }
        let ratio = Double(campaignPower) / Double(maxPower)
        return min(max(Int((ratio * 100).rounded()), 0), 100)
    }

    /// 检查关卡是否已解锁
    func isLevelUnlocked(_ level: Int) -> Bool {
        level <= unlockedLevels
    }

    /// 解锁新关卡
    func unlockLevel(_ level: Int) {
        let cappedLevel = min(level, Levels.totalLevels)
        if cappedLevel > unlockedLevels {
            unlockedLevels = cappedLevel
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
