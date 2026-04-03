import CoreGraphics
import Foundation

// MARK: - 冰块类型

enum IceBlockType: Int, Codable {
    case normal = 1      // 普通冰块：耐久1
    case cracked = 2     // 裂纹冰块：耐久2
    case explosive = 3   // 爆炸冰块：耐久1，爆炸扩散
}

// MARK: - 单个冰块配置

struct IceBlockConfig {
    let type: IceBlockType
    let x: CGFloat      // 相对于屏幕宽度的比例 0.0-1.0
    let y: CGFloat      // 相对于屏幕高度的比例 0.0-1.0
}

// MARK: - 关卡配置

struct LevelConfig {
    let levelNumber: Int
    let penguinCount: Int
    let targetScore: Int
    let oneStarScore: Int
    let twoStarScore: Int
    let threeStarScore: Int
    let iceBlocks: [IceBlockConfig]
    let hint: String?

    static func == (lhs: LevelConfig, rhs: LevelConfig) -> Bool {
        lhs.levelNumber == rhs.levelNumber
    }
}

enum LevelTheme: Equatable {
    case sunrise
    case glacier
    case aurora
}

enum LevelMotionStyle: Equatable {
    case none
    case glide
    case hover
    case weave
}

enum LevelWindStyle: Equatable {
    case none
    case tailwind
    case headwind
    case gust
}

enum LevelChallengeKind: Equatable {
    case precision(maxShots: Int)
    case combo(minBlocks: Int)
    case survivor(minRemainingPenguins: Int)
    case demolition(minExplosiveBlocks: Int)
}

struct LevelChallengePlan {
    let shortTitle: String
    let detail: String
    let bonusScore: Int
    let kind: LevelChallengeKind
}

struct LevelScorePlan {
    let targetScore: Int
    let oneStarScore: Int
    let twoStarScore: Int
    let threeStarScore: Int
    let perfectScore: Int
}

// MARK: - 15关配置数组

struct Levels {
    /// 根据关卡号获取配置
    static func config(for level: Int) -> LevelConfig {
        return allLevels[min(max(level, 1), 15) - 1]
    }

    /// 总关卡数
    static let totalLevels = 15

    static func theme(for level: Int) -> LevelTheme {
        switch level {
        case 1...5:
            return .sunrise
        case 6...10:
            return .glacier
        default:
            return .aurora
        }
    }

    static func motionStyle(for level: Int) -> LevelMotionStyle {
        switch level {
        case 8, 9, 11, 13:
            return .glide
        case 12:
            return .hover
        case 14, 15:
            return .weave
        default:
            return .none
        }
    }

    static func windStyle(for level: Int) -> LevelWindStyle {
        switch level {
        case 9, 11:
            return .tailwind
        case 10, 14:
            return .headwind
        case 12, 13, 15:
            return .gust
        default:
            return .none
        }
    }

    static func challengePlan(for level: Int) -> LevelChallengePlan {
        switch level {
        case 1:
            return LevelChallengePlan(shortTitle: "精准出手", detail: "2 发内通关", bonusScore: 120, kind: .precision(maxShots: 2))
        case 2:
            return LevelChallengePlan(shortTitle: "连锁入门", detail: "单发击碎 2 块", bonusScore: 140, kind: .combo(minBlocks: 2))
        case 3:
            return LevelChallengePlan(shortTitle: "留有余力", detail: "保留 1 只企鹅", bonusScore: 140, kind: .survivor(minRemainingPenguins: 1))
        case 4:
            return LevelChallengePlan(shortTitle: "快刀斩乱麻", detail: "3 发内通关", bonusScore: 150, kind: .precision(maxShots: 3))
        case 5:
            return LevelChallengePlan(shortTitle: "裂纹清扫", detail: "单发击碎 3 块", bonusScore: 160, kind: .combo(minBlocks: 3))
        case 6:
            return LevelChallengePlan(shortTitle: "稳扎稳打", detail: "保留 2 只企鹅", bonusScore: 180, kind: .survivor(minRemainingPenguins: 2))
        case 7:
            return LevelChallengePlan(shortTitle: "爆破专家", detail: "引爆 2 个爆炸块", bonusScore: 220, kind: .demolition(minExplosiveBlocks: 2))
        case 8:
            return LevelChallengePlan(shortTitle: "快节奏", detail: "4 发内通关", bonusScore: 200, kind: .precision(maxShots: 4))
        case 9:
            return LevelChallengePlan(shortTitle: "顺风连锁", detail: "单发击碎 4 块", bonusScore: 220, kind: .combo(minBlocks: 4))
        case 10:
            return LevelChallengePlan(shortTitle: "堡垒余震", detail: "保留 2 只企鹅", bonusScore: 220, kind: .survivor(minRemainingPenguins: 2))
        case 11:
            return LevelChallengePlan(shortTitle: "空中爆破", detail: "引爆 2 个爆炸块", bonusScore: 260, kind: .demolition(minExplosiveBlocks: 2))
        case 12:
            return LevelChallengePlan(shortTitle: "倒塔连爆", detail: "单发击碎 5 块", bonusScore: 260, kind: .combo(minBlocks: 5))
        case 13:
            return LevelChallengePlan(shortTitle: "精英余裕", detail: "保留 3 只企鹅", bonusScore: 280, kind: .survivor(minRemainingPenguins: 3))
        case 14:
            return LevelChallengePlan(shortTitle: "火线连爆", detail: "引爆 3 个爆炸块", bonusScore: 320, kind: .demolition(minExplosiveBlocks: 3))
        default:
            return LevelChallengePlan(shortTitle: "王城连锁", detail: "引爆 4 个爆炸块", bonusScore: 360, kind: .demolition(minExplosiveBlocks: 4))
        }
    }

    static func levelBadge(for level: Int) -> String {
        let challenge = challengePlan(for: level).shortTitle
        switch windStyle(for: level) {
        case .tailwind:
            return "\(challenge) · 顺风"
        case .headwind:
            return "\(challenge) · 逆风"
        case .gust:
            return "\(challenge) · 阵风"
        case .none:
            switch motionStyle(for: level) {
            case .glide:
                return "\(challenge) · 滑行靶"
            case .hover:
                return "\(challenge) · 悬浮靶"
            case .weave:
                return "\(challenge) · 变轨靶"
            case .none:
                return challenge
            }
        }
    }

    static func scorePlan(for config: LevelConfig) -> LevelScorePlan {
        let baseScore = config.iceBlocks.reduce(0) { partialResult, block in
            partialResult + blockScore(for: block.type)
        }
        let perfectScore = baseScore
            + config.penguinCount * GameScore.remainingPenguinBonus
            + levelClearBonus(for: config.levelNumber)

        let oneStar = max(Int(Double(perfectScore) * 0.45), baseScore / 2)
        let twoStar = max(Int(Double(perfectScore) * 0.65), oneStar + 120)
        let threeStar = max(Int(Double(perfectScore) * 0.85), twoStar + 120)

        return LevelScorePlan(
            targetScore: twoStar,
            oneStarScore: oneStar,
            twoStarScore: twoStar,
            threeStarScore: threeStar,
            perfectScore: perfectScore
        )
    }

    static func blockScore(for type: IceBlockType) -> Int {
        switch type {
        case .normal:
            return GameScore.normalIceBlock
        case .cracked:
            return GameScore.crackedIceBlock
        case .explosive:
            return GameScore.explosiveIceBlock
        }
    }

    static func levelClearBonus(for level: Int) -> Int {
        GameScore.clearBonusBase + level * GameScore.clearBonusStep
    }

    /// 全部15关配置
    static let allLevels: [LevelConfig] = [

        // ============================================================
        // 第1关 - 企鹅的第一次飞行（入门）
        // ============================================================
        LevelConfig(
            levelNumber: 1,
            penguinCount: 3,
            targetScore: 500,
            oneStarScore: 500,
            twoStarScore: 650,
            threeStarScore: 800,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.72, y: 0.65),
                IceBlockConfig(type: .normal, x: 0.65, y: 0.50),
                IceBlockConfig(type: .normal, x: 0.79, y: 0.50)
            ],
            hint: "拖动企鹅瞄准，松手发射！"
        ),

        // ============================================================
        // 第2关 - 排列的艺术（入门）
        // ============================================================
        LevelConfig(
            levelNumber: 2,
            penguinCount: 3,
            targetScore: 800,
            oneStarScore: 800,
            twoStarScore: 1040,
            threeStarScore: 1280,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.60, y: 0.60),
                IceBlockConfig(type: .normal, x: 0.68, y: 0.60),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.60),
                IceBlockConfig(type: .normal, x: 0.64, y: 0.48)
            ],
            hint: "利用弹跳可以一次击中多个！"
        ),

        // ============================================================
        // 第3关 - 高塔挑战（入门）
        // ============================================================
        LevelConfig(
            levelNumber: 3,
            penguinCount: 3,
            targetScore: 1200,
            oneStarScore: 1200,
            twoStarScore: 1560,
            threeStarScore: 1920,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.70, y: 0.40),
                IceBlockConfig(type: .normal, x: 0.70, y: 0.53),
                IceBlockConfig(type: .cracked, x: 0.70, y: 0.66),
                IceBlockConfig(type: .normal, x: 0.62, y: 0.40),
                IceBlockConfig(type: .normal, x: 0.78, y: 0.40)
            ],
            hint: nil
        ),

        // ============================================================
        // 第4关 - 星星的诱惑（简单）
        // ============================================================
        LevelConfig(
            levelNumber: 4,
            penguinCount: 4,
            targetScore: 1800,
            oneStarScore: 1800,
            twoStarScore: 2340,
            threeStarScore: 2880,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.65, y: 0.65),
                IceBlockConfig(type: .normal, x: 0.73, y: 0.65),
                IceBlockConfig(type: .normal, x: 0.69, y: 0.52),
                IceBlockConfig(type: .cracked, x: 0.60, y: 0.42),
                IceBlockConfig(type: .cracked, x: 0.78, y: 0.42)
            ],
            hint: nil
        ),

        // ============================================================
        // 第5关 - 裂纹冰块（简单）
        // ============================================================
        LevelConfig(
            levelNumber: 5,
            penguinCount: 4,
            targetScore: 2500,
            oneStarScore: 2500,
            twoStarScore: 3250,
            threeStarScore: 4000,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.60, y: 0.68),
                IceBlockConfig(type: .cracked, x: 0.68, y: 0.68),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.68),
                IceBlockConfig(type: .cracked, x: 0.64, y: 0.55),
                IceBlockConfig(type: .normal, x: 0.72, y: 0.55),
                IceBlockConfig(type: .cracked, x: 0.68, y: 0.42)
            ],
            hint: nil
        ),

        // ============================================================
        // 第6关 - 冰山的秘密（简单）
        // ============================================================
        LevelConfig(
            levelNumber: 6,
            penguinCount: 4,
            targetScore: 3500,
            oneStarScore: 3500,
            twoStarScore: 4550,
            threeStarScore: 5600,
            iceBlocks: [
                // 底部宽
                IceBlockConfig(type: .normal, x: 0.55, y: 0.40),
                IceBlockConfig(type: .normal, x: 0.63, y: 0.40),
                IceBlockConfig(type: .normal, x: 0.71, y: 0.40),
                IceBlockConfig(type: .normal, x: 0.79, y: 0.40),
                // 中层
                IceBlockConfig(type: .cracked, x: 0.59, y: 0.53),
                IceBlockConfig(type: .cracked, x: 0.67, y: 0.53),
                IceBlockConfig(type: .cracked, x: 0.75, y: 0.53),
                // 顶层
                IceBlockConfig(type: .normal, x: 0.63, y: 0.66),
                IceBlockConfig(type: .normal, x: 0.71, y: 0.66)
            ],
            hint: nil
        ),

        // ============================================================
        // 第7关 - 爆炸危机（中等）
        // ============================================================
        LevelConfig(
            levelNumber: 7,
            penguinCount: 5,
            targetScore: 4500,
            oneStarScore: 4500,
            twoStarScore: 5850,
            threeStarScore: 7200,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.60, y: 0.70),
                IceBlockConfig(type: .explosive, x: 0.68, y: 0.70),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.70),
                IceBlockConfig(type: .normal, x: 0.64, y: 0.57),
                IceBlockConfig(type: .cracked, x: 0.72, y: 0.57),
                IceBlockConfig(type: .normal, x: 0.60, y: 0.44),
                IceBlockConfig(type: .cracked, x: 0.68, y: 0.44),
                IceBlockConfig(type: .explosive, x: 0.76, y: 0.44)
            ],
            hint: nil
        ),

        // ============================================================
        // 第8关 - 移动的靶子（中等）
        // ============================================================
        LevelConfig(
            levelNumber: 8,
            penguinCount: 5,
            targetScore: 5500,
            oneStarScore: 5500,
            twoStarScore: 7150,
            threeStarScore: 8800,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.60, y: 0.68),
                IceBlockConfig(type: .normal, x: 0.70, y: 0.68),
                IceBlockConfig(type: .cracked, x: 0.80, y: 0.68),
                IceBlockConfig(type: .normal, x: 0.65, y: 0.55),
                IceBlockConfig(type: .cracked, x: 0.75, y: 0.55),
                IceBlockConfig(type: .normal, x: 0.70, y: 0.42),
                IceBlockConfig(type: .explosive, x: 0.60, y: 0.42),
                IceBlockConfig(type: .cracked, x: 0.80, y: 0.42)
            ],
            hint: nil
        ),

        // ============================================================
        // 第9关 - 三星通关（中等）
        // ============================================================
        LevelConfig(
            levelNumber: 9,
            penguinCount: 5,
            targetScore: 6500,
            oneStarScore: 6500,
            twoStarScore: 8450,
            threeStarScore: 10400,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.55, y: 0.70),
                IceBlockConfig(type: .cracked, x: 0.63, y: 0.70),
                IceBlockConfig(type: .normal, x: 0.71, y: 0.70),
                IceBlockConfig(type: .cracked, x: 0.79, y: 0.70),
                IceBlockConfig(type: .normal, x: 0.59, y: 0.57),
                IceBlockConfig(type: .normal, x: 0.67, y: 0.57),
                IceBlockConfig(type: .cracked, x: 0.75, y: 0.57),
                IceBlockConfig(type: .normal, x: 0.63, y: 0.44),
                IceBlockConfig(type: .explosive, x: 0.71, y: 0.44),
                IceBlockConfig(type: .normal, x: 0.67, y: 0.31)
            ],
            hint: nil
        ),

        // ============================================================
        // 第10关 - 坚固的堡垒（困难）
        // ============================================================
        LevelConfig(
            levelNumber: 10,
            penguinCount: 5,
            targetScore: 8000,
            oneStarScore: 8000,
            twoStarScore: 10400,
            threeStarScore: 12800,
            iceBlocks: [
                // 底层基础
                IceBlockConfig(type: .cracked, x: 0.52, y: 0.38),
                IceBlockConfig(type: .normal, x: 0.60, y: 0.38),
                IceBlockConfig(type: .normal, x: 0.68, y: 0.38),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.38),
                IceBlockConfig(type: .cracked, x: 0.84, y: 0.38),
                // 第二层
                IceBlockConfig(type: .normal, x: 0.56, y: 0.51),
                IceBlockConfig(type: .cracked, x: 0.64, y: 0.51),
                IceBlockConfig(type: .cracked, x: 0.72, y: 0.51),
                IceBlockConfig(type: .normal, x: 0.80, y: 0.51),
                // 第三层
                IceBlockConfig(type: .normal, x: 0.60, y: 0.64),
                IceBlockConfig(type: .explosive, x: 0.68, y: 0.64),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.64),
                // 顶层
                IceBlockConfig(type: .cracked, x: 0.64, y: 0.77),
                IceBlockConfig(type: .cracked, x: 0.72, y: 0.77)
            ],
            hint: nil
        ),

        // ============================================================
        // 第11关 - 天空中的冰（困难）
        // ============================================================
        LevelConfig(
            levelNumber: 11,
            penguinCount: 6,
            targetScore: 10000,
            oneStarScore: 10000,
            twoStarScore: 13000,
            threeStarScore: 16000,
            iceBlocks: [
                IceBlockConfig(type: .normal, x: 0.55, y: 0.75),
                IceBlockConfig(type: .cracked, x: 0.65, y: 0.75),
                IceBlockConfig(type: .normal, x: 0.75, y: 0.75),
                IceBlockConfig(type: .explosive, x: 0.60, y: 0.62),
                IceBlockConfig(type: .normal, x: 0.70, y: 0.62),
                IceBlockConfig(type: .cracked, x: 0.55, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.65, y: 0.49),
                IceBlockConfig(type: .cracked, x: 0.75, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.60, y: 0.36),
                IceBlockConfig(type: .explosive, x: 0.70, y: 0.36),
                IceBlockConfig(type: .cracked, x: 0.65, y: 0.23),
                IceBlockConfig(type: .normal, x: 0.55, y: 0.23),
                IceBlockConfig(type: .normal, x: 0.75, y: 0.23),
                IceBlockConfig(type: .cracked, x: 0.85, y: 0.36)
            ],
            hint: nil
        ),

        // ============================================================
        // 第12关 - 倒金字塔（困难）
        // ============================================================
        LevelConfig(
            levelNumber: 12,
            penguinCount: 6,
            targetScore: 12000,
            oneStarScore: 12000,
            twoStarScore: 15600,
            threeStarScore: 19200,
            iceBlocks: [
                // 顶层（倒三角顶在上方）
                IceBlockConfig(type: .cracked, x: 0.65, y: 0.25),
                IceBlockConfig(type: .cracked, x: 0.73, y: 0.25),
                // 第二层
                IceBlockConfig(type: .normal, x: 0.60, y: 0.37),
                IceBlockConfig(type: .explosive, x: 0.68, y: 0.37),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.37),
                // 第三层
                IceBlockConfig(type: .cracked, x: 0.55, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.63, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.71, y: 0.49),
                IceBlockConfig(type: .cracked, x: 0.79, y: 0.49),
                // 第四层
                IceBlockConfig(type: .normal, x: 0.52, y: 0.61),
                IceBlockConfig(type: .cracked, x: 0.60, y: 0.61),
                IceBlockConfig(type: .cracked, x: 0.68, y: 0.61),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.61),
                IceBlockConfig(type: .normal, x: 0.84, y: 0.61),
                // 底部
                IceBlockConfig(type: .explosive, x: 0.56, y: 0.73),
                IceBlockConfig(type: .normal, x: 0.64, y: 0.73),
                IceBlockConfig(type: .normal, x: 0.72, y: 0.73),
                IceBlockConfig(type: .explosive, x: 0.80, y: 0.73)
            ],
            hint: nil
        ),

        // ============================================================
        // 第13关 - 极限挑战（精英）
        // ============================================================
        LevelConfig(
            levelNumber: 13,
            penguinCount: 7,
            targetScore: 15000,
            oneStarScore: 15000,
            twoStarScore: 19500,
            threeStarScore: 24000,
            iceBlocks: [
                IceBlockConfig(type: .cracked, x: 0.50, y: 0.72),
                IceBlockConfig(type: .normal, x: 0.58, y: 0.72),
                IceBlockConfig(type: .explosive, x: 0.66, y: 0.72),
                IceBlockConfig(type: .normal, x: 0.74, y: 0.72),
                IceBlockConfig(type: .cracked, x: 0.82, y: 0.72),
                IceBlockConfig(type: .normal, x: 0.54, y: 0.59),
                IceBlockConfig(type: .cracked, x: 0.62, y: 0.59),
                IceBlockConfig(type: .normal, x: 0.70, y: 0.59),
                IceBlockConfig(type: .cracked, x: 0.78, y: 0.59),
                IceBlockConfig(type: .explosive, x: 0.58, y: 0.46),
                IceBlockConfig(type: .normal, x: 0.66, y: 0.46),
                IceBlockConfig(type: .normal, x: 0.74, y: 0.46),
                IceBlockConfig(type: .cracked, x: 0.62, y: 0.33),
                IceBlockConfig(type: .cracked, x: 0.70, y: 0.33),
                IceBlockConfig(type: .normal, x: 0.66, y: 0.20),
                IceBlockConfig(type: .explosive, x: 0.54, y: 0.20),
                IceBlockConfig(type: .normal, x: 0.78, y: 0.20),
                IceBlockConfig(type: .cracked, x: 0.86, y: 0.33)
            ],
            hint: nil
        ),

        // ============================================================
        // 第14关 - 冰与火之歌（精英）
        // ============================================================
        LevelConfig(
            levelNumber: 14,
            penguinCount: 7,
            targetScore: 20000,
            oneStarScore: 20000,
            twoStarScore: 26000,
            threeStarScore: 32000,
            iceBlocks: [
                IceBlockConfig(type: .explosive, x: 0.52, y: 0.75),
                IceBlockConfig(type: .cracked, x: 0.60, y: 0.75),
                IceBlockConfig(type: .normal, x: 0.68, y: 0.75),
                IceBlockConfig(type: .cracked, x: 0.76, y: 0.75),
                IceBlockConfig(type: .explosive, x: 0.84, y: 0.75),
                IceBlockConfig(type: .normal, x: 0.56, y: 0.62),
                IceBlockConfig(type: .cracked, x: 0.64, y: 0.62),
                IceBlockConfig(type: .normal, x: 0.72, y: 0.62),
                IceBlockConfig(type: .cracked, x: 0.80, y: 0.62),
                IceBlockConfig(type: .cracked, x: 0.52, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.60, y: 0.49),
                IceBlockConfig(type: .explosive, x: 0.68, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.76, y: 0.49),
                IceBlockConfig(type: .cracked, x: 0.84, y: 0.49),
                IceBlockConfig(type: .normal, x: 0.56, y: 0.36),
                IceBlockConfig(type: .cracked, x: 0.64, y: 0.36),
                IceBlockConfig(type: .normal, x: 0.72, y: 0.36),
                IceBlockConfig(type: .cracked, x: 0.80, y: 0.36)
            ],
            hint: nil
        ),

        // ============================================================
        // 第15关 - 最终Boss：企鹅王的城堡（精英）
        // ============================================================
        LevelConfig(
            levelNumber: 15,
            penguinCount: 8,
            targetScore: 25000,
            oneStarScore: 25000,
            twoStarScore: 32500,
            threeStarScore: 40000,
            iceBlocks: [
                // 底部护甲层
                IceBlockConfig(type: .cracked, x: 0.48, y: 0.32),
                IceBlockConfig(type: .cracked, x: 0.56, y: 0.32),
                IceBlockConfig(type: .explosive, x: 0.64, y: 0.32),
                IceBlockConfig(type: .explosive, x: 0.72, y: 0.32),
                IceBlockConfig(type: .cracked, x: 0.80, y: 0.32),
                IceBlockConfig(type: .cracked, x: 0.88, y: 0.32),
                // 第二层
                IceBlockConfig(type: .normal, x: 0.52, y: 0.44),
                IceBlockConfig(type: .cracked, x: 0.60, y: 0.44),
                IceBlockConfig(type: .normal, x: 0.68, y: 0.44),
                IceBlockConfig(type: .cracked, x: 0.76, y: 0.44),
                IceBlockConfig(type: .normal, x: 0.84, y: 0.44),
                // 第三层
                IceBlockConfig(type: .cracked, x: 0.56, y: 0.56),
                IceBlockConfig(type: .normal, x: 0.64, y: 0.56),
                IceBlockConfig(type: .explosive, x: 0.72, y: 0.56),
                IceBlockConfig(type: .normal, x: 0.80, y: 0.56),
                // 第四层
                IceBlockConfig(type: .normal, x: 0.60, y: 0.68),
                IceBlockConfig(type: .cracked, x: 0.68, y: 0.68),
                IceBlockConfig(type: .cracked, x: 0.76, y: 0.68),
                // 顶层
                IceBlockConfig(type: .explosive, x: 0.64, y: 0.80),
                IceBlockConfig(type: .explosive, x: 0.72, y: 0.80)
            ],
            hint: nil
        )
    ]
}
