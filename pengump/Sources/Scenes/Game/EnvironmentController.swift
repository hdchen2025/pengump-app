import SpriteKit

struct EnvironmentProfile {
    let name: String
    let skyColor: SKColor
    let horizonColor: SKColor
    let groundColor: SKColor
    let accentColor: SKColor
    let bounce: CGFloat
    let friction: CGFloat
}

enum EnvironmentFeatureKind {
    case fishBoost
    case iceSpring

    var label: String {
        switch self {
        case .fishBoost:
            return "鱼群助推"
        case .iceSpring:
            return "冰裂弹板"
        }
    }
}

struct EnvironmentFeature {
    let id: String
    let kind: EnvironmentFeatureKind
    let worldX: CGFloat
}

final class EnvironmentController {
    private let profiles: [(threshold: CGFloat, profile: EnvironmentProfile)] = [
        (
            0,
            EnvironmentProfile(
                name: "雪地起跑区",
                skyColor: SKColor(red: 0.84, green: 0.95, blue: 1.0, alpha: 1.0),
                horizonColor: SKColor(red: 0.72, green: 0.9, blue: 0.96, alpha: 1.0),
                groundColor: SKColor(red: 0.9, green: 0.96, blue: 1.0, alpha: 1.0),
                accentColor: SKColor(red: 0.16, green: 0.48, blue: 0.84, alpha: 1.0),
                bounce: 0.34,
                friction: 0.92
            )
        ),
        (
            550,
            EnvironmentProfile(
                name: "冰山裂谷区",
                skyColor: SKColor(red: 0.66, green: 0.86, blue: 0.98, alpha: 1.0),
                horizonColor: SKColor(red: 0.48, green: 0.76, blue: 0.94, alpha: 1.0),
                groundColor: SKColor(red: 0.82, green: 0.92, blue: 0.98, alpha: 1.0),
                accentColor: SKColor(red: 0.05, green: 0.62, blue: 0.86, alpha: 1.0),
                bounce: 0.42,
                friction: 0.95
            )
        ),
        (
            1300,
            EnvironmentProfile(
                name: "极光高空区",
                skyColor: SKColor(red: 0.2, green: 0.22, blue: 0.4, alpha: 1.0),
                horizonColor: SKColor(red: 0.14, green: 0.56, blue: 0.56, alpha: 1.0),
                groundColor: SKColor(red: 0.68, green: 0.86, blue: 0.94, alpha: 1.0),
                accentColor: SKColor(red: 0.4, green: 0.95, blue: 0.76, alpha: 1.0),
                bounce: 0.48,
                friction: 0.97
            )
        ),
        (
            2600,
            EnvironmentProfile(
                name: "传说区",
                skyColor: SKColor(red: 0.1, green: 0.08, blue: 0.2, alpha: 1.0),
                horizonColor: SKColor(red: 0.52, green: 0.44, blue: 0.92, alpha: 1.0),
                groundColor: SKColor(red: 0.8, green: 0.88, blue: 0.96, alpha: 1.0),
                accentColor: SKColor(red: 1.0, green: 0.8, blue: 0.32, alpha: 1.0),
                bounce: 0.52,
                friction: 0.985
            )
        )
    ]

    func profile(for distance: CGFloat) -> EnvironmentProfile {
        profiles.last(where: { distance >= $0.threshold })?.profile ?? profiles[0].profile
    }

    func biomeIndex(for distance: CGFloat) -> Int {
        max(0, profiles.lastIndex(where: { distance >= $0.threshold }) ?? 0)
    }

    func groundHeight(at worldX: CGFloat) -> CGFloat {
        let base: CGFloat = 122
        let softWave = sin(worldX * 0.005) * 10
        let rollingWave = sin(worldX * 0.011 + 0.8) * 18
        let ridge = sin(worldX * 0.0019 + 1.7) * 22
        return base + softWave + rollingWave + ridge
    }

    func surface(at distance: CGFloat) -> GroundSurface {
        let profile = profile(for: distance)
        return GroundSurface(bounce: profile.bounce, friction: profile.friction)
    }

    func features(in range: ClosedRange<CGFloat>, challenge: DailyChallenge? = nil) -> [EnvironmentFeature] {
        let chunkSize: CGFloat = 240
        let startChunk = max(1, Int(floor(range.lowerBound / chunkSize)) - 1)
        let endChunk = Int(ceil(range.upperBound / chunkSize)) + 1
        var features: [EnvironmentFeature] = []
        let fishFrequency = challenge?.modifier == .fishFestival ? 2 : 3
        let springFrequency = challenge?.modifier == .springFestival ? 2 : 4
        let springStartBiome = challenge?.modifier == .springFestival ? 0 : 1

        for chunk in startChunk...endChunk {
            let baseX = CGFloat(chunk) * chunkSize
            let distance = max(0, (baseX - 170) * 0.42)
            let biome = biomeIndex(for: distance)

            if chunk >= 2 && chunk % fishFrequency == fishFrequency - 1 {
                features.append(
                    EnvironmentFeature(
                        id: "fish-\(chunk)",
                        kind: .fishBoost,
                        worldX: baseX + 92
                    )
                )
            }

            if biome >= springStartBiome && chunk % springFrequency == springFrequency - 2 {
                features.append(
                    EnvironmentFeature(
                        id: "spring-\(chunk)",
                        kind: .iceSpring,
                        worldX: baseX + 148
                    )
                )
            }
        }

        return features.filter { range.contains($0.worldX) }
    }
}
