import Foundation

// MARK: - 数据结构

struct ScoreRecord: Codable, Equatable {
    let level: Int
    let score: Int
    let stars: Int  // 1-3星
    let date: Date
}

struct DistanceRecord: Codable, Equatable {
    let distance: Int
    let date: Date
    let perfectRelease: Bool
    let highestBiome: Int
}

enum AchievementID: String, Codable, CaseIterable {
    case tenThrows
    case threePerfects
    case fourInteractions
    case reachAurora
    case reachLegend

    var title: String {
        switch self {
        case .tenThrows:
            return "远投新秀"
        case .threePerfects:
            return "完美手感"
        case .fourInteractions:
            return "连锁高手"
        case .reachAurora:
            return "极光访客"
        case .reachLegend:
            return "传说破空者"
        }
    }

    var detail: String {
        switch self {
        case .tenThrows:
            return "累计完成 10 次远投"
        case .threePerfects:
            return "累计打出 3 次完美出手"
        case .fourInteractions:
            return "单局触发 4 次地形互动"
        case .reachAurora:
            return "冲进极光高空区"
        case .reachLegend:
            return "冲进传说区"
        }
    }
}

struct AchievementProgressSummary {
    let title: String
    let detail: String
    let progressText: String
}

struct DistanceRunOutcome {
    let challenge: DailyChallenge
    let didSetDailyChallengeRecord: Bool
    let didCompleteDailyChallenge: Bool
    let newlyUnlockedAchievements: [AchievementID]
}

enum DailyChallengeModifier: String, Codable, CaseIterable {
    case tailwind
    case moonGravity
    case fishFestival
    case springFestival

    var title: String {
        switch self {
        case .tailwind:
            return "顺风远投日"
        case .moonGravity:
            return "月球低重力日"
        case .fishFestival:
            return "鱼群狂欢日"
        case .springFestival:
            return "弹板狂欢日"
        }
    }

    var detail: String {
        switch self {
        case .tailwind:
            return "出手初速更高，适合冲更远纪录。"
        case .moonGravity:
            return "低重力飞行，更容易挂长滞空。"
        case .fishFestival:
            return "鱼群更多，更容易打出连锁助推。"
        case .springFestival:
            return "弹板更多，更容易打出高抛反转。"
        }
    }
}

struct DailyChallenge: Equatable {
    let dateKey: String
    let modifier: DailyChallengeModifier

    var key: String { dateKey }
    var title: String { modifier.title }
    var detail: String { modifier.detail }
    var targetDistance: Int {
        switch modifier {
        case .tailwind:
            return 800
        case .moonGravity:
            return 1500
        case .fishFestival:
            return 300
        case .springFestival:
            return 800
        }
    }

    static func today(date: Date = Date(), calendar: Calendar = .current) -> DailyChallenge {
        let dateKey = dayKey(for: date, calendar: calendar)
        let year = calendar.component(.year, from: date)
        let ordinal = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = abs(year * 397 + ordinal * 17)
        let modifier = DailyChallengeModifier.allCases[seed % DailyChallengeModifier.allCases.count]
        return DailyChallenge(dateKey: dateKey, modifier: modifier)
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - SaveManager

class SaveManager {
    static let shared = SaveManager()

    private static let achievementOrder: [AchievementID] = [
        .tenThrows,
        .threePerfects,
        .fourInteractions,
        .reachAurora,
        .reachLegend
    ]

    private let defaults = UserDefaults.standard
    private let currentSaveDataVersion = 4
    private let maxStaminaValue = 30
    private let maxStoredDistanceRecords = 60

    // UserDefaults keys
    private enum Keys {
        static let saveDataVersion = "save_data_version"
        static let highestScores = "highest_scores"
        static let unlockedLevels = "unlocked_levels"
        static let coins = "coins"
        static let stamina = "stamina"
        static let lastStaminaUpdate = "last_stamina_update"
        static let hasRecord = "has_record"
        static let bestDistance = "best_distance"
        static let distanceRecords = "distance_records"
        static let totalThrows = "total_throws"
        static let perfectReleaseCount = "perfect_release_count"
        static let highestBiomeReached = "highest_biome_reached"
        static let dailyChallengeBestByDate = "daily_challenge_best_by_date"
        static let unlockedAchievements = "unlocked_achievements"
        static let bestInteractionCount = "best_interaction_count"
        static let longestAirTime = "longest_air_time"
    }

    // MARK: - 数据属性

    var highestScores: [Int: ScoreRecord] = [:]  // 每关最高分
    var unlockedLevels: Int = 1                   // 已解锁最高关卡
    var bestDistance: Int = 0
    var distanceRecords: [DistanceRecord] = []
    var totalThrows: Int = 0
    var perfectReleaseCount: Int = 0
    var highestBiomeReached: Int = 0
    var dailyChallengeBestByDate: [String: Int] = [:]
    var unlockedAchievements: [AchievementID] = []
    var bestInteractionCount: Int = 0
    var longestAirTime: TimeInterval = 0
    var latestDistanceRecord: DistanceRecord? {
        distanceRecords.last
    }
    var unlockedAchievementCount: Int {
        unlockedAchievements.count
    }

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
        var shouldPersistLoadedState = false

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

        bestDistance = defaults.integer(forKey: Keys.bestDistance)
        totalThrows = defaults.integer(forKey: Keys.totalThrows)
        perfectReleaseCount = defaults.integer(forKey: Keys.perfectReleaseCount)
        highestBiomeReached = defaults.integer(forKey: Keys.highestBiomeReached)
        bestInteractionCount = defaults.integer(forKey: Keys.bestInteractionCount)
        longestAirTime = defaults.double(forKey: Keys.longestAirTime)
        if let data = defaults.data(forKey: Keys.dailyChallengeBestByDate),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyChallengeBestByDate = decoded
        } else {
            dailyChallengeBestByDate = [:]
        }
        let previousDailyChallengeCount = dailyChallengeBestByDate.count
        if let data = defaults.data(forKey: Keys.unlockedAchievements),
           let decoded = try? JSONDecoder().decode([AchievementID].self, from: data) {
            unlockedAchievements = Self.achievementOrder.filter(decoded.contains)
        } else {
            unlockedAchievements = []
        }
        trimDailyChallengeHistory()
        shouldPersistLoadedState = shouldPersistLoadedState || dailyChallengeBestByDate.count != previousDailyChallengeCount

        if let data = defaults.data(forKey: Keys.distanceRecords),
           let decoded = try? JSONDecoder().decode([DistanceRecord].self, from: data) {
            distanceRecords = decoded
        } else {
            distanceRecords = []
        }
        if distanceRecords.count > maxStoredDistanceRecords {
            distanceRecords = Array(distanceRecords.suffix(maxStoredDistanceRecords))
        }

        bestDistance = max(bestDistance, distanceRecords.map(\.distance).max() ?? 0)
        totalThrows = max(totalThrows, distanceRecords.count)
        perfectReleaseCount = max(perfectReleaseCount, distanceRecords.filter(\.perfectRelease).count)
        highestBiomeReached = max(highestBiomeReached, distanceRecords.map(\.highestBiome).max() ?? 0)
        let previousUnlockedAchievementCount = unlockedAchievements.count
        unlockAchievementsIfNeeded()
        shouldPersistLoadedState = shouldPersistLoadedState || unlockedAchievements.count != previousUnlockedAchievementCount

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
            shouldPersistLoadedState = true
        }

        // 迁移：旧版本（无版本号）升级到 v2
        if !hasVersionMarker {
            migrateToV2()
            shouldPersistLoadedState = true
        } else {
            let savedVersion = defaults.integer(forKey: Keys.saveDataVersion)
            if savedVersion < currentSaveDataVersion {
                defaults.set(currentSaveDataVersion, forKey: Keys.saveDataVersion)
                shouldPersistLoadedState = true
            }
        }

        if shouldPersistLoadedState {
            save()
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
        defaults.set(bestDistance, forKey: Keys.bestDistance)
        defaults.set(totalThrows, forKey: Keys.totalThrows)
        defaults.set(perfectReleaseCount, forKey: Keys.perfectReleaseCount)
        defaults.set(highestBiomeReached, forKey: Keys.highestBiomeReached)
        defaults.set(bestInteractionCount, forKey: Keys.bestInteractionCount)
        defaults.set(longestAirTime, forKey: Keys.longestAirTime)
        if let data = try? JSONEncoder().encode(dailyChallengeBestByDate) {
            defaults.set(data, forKey: Keys.dailyChallengeBestByDate)
        }
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            defaults.set(data, forKey: Keys.unlockedAchievements)
        }

        if let data = try? JSONEncoder().encode(distanceRecords) {
            defaults.set(data, forKey: Keys.distanceRecords)
        }

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
            || defaults.object(forKey: Keys.bestDistance) != nil
            || defaults.object(forKey: Keys.distanceRecords) != nil
            || defaults.object(forKey: Keys.totalThrows) != nil
            || defaults.object(forKey: Keys.perfectReleaseCount) != nil
            || defaults.object(forKey: Keys.highestBiomeReached) != nil
            || defaults.object(forKey: Keys.dailyChallengeBestByDate) != nil
            || defaults.object(forKey: Keys.unlockedAchievements) != nil
            || defaults.object(forKey: Keys.bestInteractionCount) != nil
            || defaults.object(forKey: Keys.longestAirTime) != nil
    }

    // MARK: - 关卡分数操作

    /// 更新关卡最高分（仅当新分数更高时更新）
    func updateScore(level: Int, score: Int, stars: Int) {
        let record = ScoreRecord(level: level, score: score, stars: stars, date: Date())

        if let existing = highestScores[level] {
            let mergedScore = max(score, existing.score)
            let mergedStars = max(stars, existing.stars)

            if mergedScore > existing.score || mergedStars > existing.stars {
                highestScores[level] = ScoreRecord(level: level, score: mergedScore, stars: mergedStars, date: Date())
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

    func currentDailyChallenge(referenceDate: Date = Date()) -> DailyChallenge {
        DailyChallenge.today(date: referenceDate)
    }

    @discardableResult
    func recordDistanceRun(
        distance: Int,
        perfectRelease: Bool,
        highestBiome: Int,
        interactionCount: Int = 0,
        airTime: TimeInterval = 0,
        challenge: DailyChallenge? = nil
    ) -> DistanceRunOutcome {
        let challenge = challenge ?? currentDailyChallenge()
        let record = DistanceRecord(
            distance: max(0, distance),
            date: Date(),
            perfectRelease: perfectRelease,
            highestBiome: max(0, highestBiome)
        )

        distanceRecords.append(record)
        if distanceRecords.count > maxStoredDistanceRecords {
            distanceRecords.removeFirst(distanceRecords.count - maxStoredDistanceRecords)
        }

        bestDistance = max(bestDistance, record.distance)
        totalThrows += 1
        if perfectRelease {
            perfectReleaseCount += 1
        }
        self.highestBiomeReached = max(self.highestBiomeReached, record.highestBiome)
        bestInteractionCount = max(bestInteractionCount, interactionCount)
        longestAirTime = max(longestAirTime, airTime)
        let previousChallengeBest = dailyChallengeBest(for: challenge)
        let didSetDailyChallengeRecord = record.distance > previousChallengeBest
        if didSetDailyChallengeRecord {
            dailyChallengeBestByDate[challenge.key] = record.distance
            trimDailyChallengeHistory()
        }
        let didCompleteDailyChallenge = previousChallengeBest < challenge.targetDistance
            && max(previousChallengeBest, record.distance) >= challenge.targetDistance
        let newlyUnlockedAchievements = unlockAchievementsIfNeeded()
        save()
        return DistanceRunOutcome(
            challenge: challenge,
            didSetDailyChallengeRecord: didSetDailyChallengeRecord,
            didCompleteDailyChallenge: didCompleteDailyChallenge,
            newlyUnlockedAchievements: newlyUnlockedAchievements
        )
    }

    func dailyChallengeBest(for challenge: DailyChallenge? = nil) -> Int {
        let challenge = challenge ?? currentDailyChallenge()
        return dailyChallengeBestByDate[challenge.key] ?? 0
    }

    func recordDailyChallenge(distance: Int, for challenge: DailyChallenge? = nil) {
        let challenge = challenge ?? currentDailyChallenge()
        let normalizedDistance = max(0, distance)
        let currentBest = dailyChallengeBestByDate[challenge.key] ?? 0
        guard normalizedDistance > currentBest else { return }

        dailyChallengeBestByDate[challenge.key] = normalizedDistance
        trimDailyChallengeHistory()
        save()
    }

    @discardableResult
    func registerDistanceRun(
        distance: Int,
        perfectRelease: Bool,
        highestBiome: Int,
        interactionCount: Int = 0,
        airTime: TimeInterval = 0,
        challenge: DailyChallenge? = nil
    ) -> DistanceRunOutcome {
        recordDistanceRun(
            distance: distance,
            perfectRelease: perfectRelease,
            highestBiome: highestBiome,
            interactionCount: interactionCount,
            airTime: airTime,
            challenge: challenge
        )
    }

    func topDistanceRecords(limit: Int = 10) -> [DistanceRecord] {
        Array(distanceRecords
            .sorted { lhs, rhs in
                if lhs.distance == rhs.distance {
                    return lhs.date > rhs.date
                }
                return lhs.distance > rhs.distance
            }
            .prefix(limit))
    }

    func recentDistanceRecords(limit: Int = 10) -> [DistanceRecord] {
        Array(distanceRecords.suffix(limit).reversed())
    }

    func nextAchievementProgressSummary() -> AchievementProgressSummary? {
        for achievement in Self.achievementOrder where !unlockedAchievements.contains(achievement) {
            return progressSummary(for: achievement)
        }
        return nil
    }

    private func trimDailyChallengeHistory(limit: Int = 30) {
        guard dailyChallengeBestByDate.count > limit else { return }

        let sortedKeys = dailyChallengeBestByDate.keys.sorted()
        let removeCount = sortedKeys.count - limit
        for key in sortedKeys.prefix(removeCount) {
            dailyChallengeBestByDate.removeValue(forKey: key)
        }
    }

    @discardableResult
    private func unlockAchievementsIfNeeded() -> [AchievementID] {
        var newlyUnlocked: [AchievementID] = []

        for achievement in Self.achievementOrder where !unlockedAchievements.contains(achievement) {
            guard isAchievementUnlocked(achievement) else { continue }
            unlockedAchievements.append(achievement)
            newlyUnlocked.append(achievement)
        }

        return newlyUnlocked
    }

    private func isAchievementUnlocked(_ achievement: AchievementID) -> Bool {
        switch achievement {
        case .tenThrows:
            return totalThrows >= 10
        case .threePerfects:
            return perfectReleaseCount >= 3
        case .fourInteractions:
            return bestInteractionCount >= 4
        case .reachAurora:
            return highestBiomeReached >= 2
        case .reachLegend:
            return highestBiomeReached >= 3
        }
    }

    private func progressSummary(for achievement: AchievementID) -> AchievementProgressSummary {
        switch achievement {
        case .tenThrows:
            return AchievementProgressSummary(
                title: achievement.title,
                detail: achievement.detail,
                progressText: "\(min(totalThrows, 10))/10"
            )
        case .threePerfects:
            return AchievementProgressSummary(
                title: achievement.title,
                detail: achievement.detail,
                progressText: "\(min(perfectReleaseCount, 3))/3"
            )
        case .fourInteractions:
            return AchievementProgressSummary(
                title: achievement.title,
                detail: achievement.detail,
                progressText: "\(min(bestInteractionCount, 4))/4"
            )
        case .reachAurora:
            return AchievementProgressSummary(
                title: achievement.title,
                detail: achievement.detail,
                progressText: "\(min(highestBiomeReached, 2))/2 区"
            )
        case .reachLegend:
            return AchievementProgressSummary(
                title: achievement.title,
                detail: achievement.detail,
                progressText: "\(min(highestBiomeReached, 3))/3 区"
            )
        }
    }
}
