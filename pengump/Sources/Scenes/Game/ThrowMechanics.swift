import CoreGraphics
import Foundation
import SpriteKit

enum ReleaseJudgement: String {
    case early = "早了"
    case nice = "不错"
    case perfect = "完美"
    case over = "过头"

    var accentColor: CGColor {
        switch self {
        case .early:
            return SKColor(red: 1.0, green: 0.78, blue: 0.42, alpha: 1.0).cgColor
        case .nice:
            return SKColor(red: 1.0, green: 0.95, blue: 0.84, alpha: 1.0).cgColor
        case .perfect:
            return SKColor(red: 0.44, green: 0.96, blue: 0.76, alpha: 1.0).cgColor
        case .over:
            return SKColor(red: 0.96, green: 0.62, blue: 0.52, alpha: 1.0).cgColor
        }
    }
}

struct ThrowReleaseResult {
    let velocity: CGVector
    let judgement: ReleaseJudgement
}

enum ThrowMechanics {
    static let orbitRadius: CGFloat = 118
    static let restAngle: CGFloat = -.pi * 0.58
    static let startAngle: CGFloat = -.pi * 0.82
    static let maxHoldDuration: TimeInterval = 2.2

    static func angularSpeed(for holdDuration: TimeInterval) -> CGFloat {
        let clamped = min(max(holdDuration, 0), maxHoldDuration)
        switch clamped {
        case ..<0.38:
            return 2.4 + CGFloat(clamped / 0.38) * 4.0
        case ..<1.05:
            let cycle = CGFloat((clamped - 0.38) / 0.67)
            return 6.3 + sin(cycle * .pi * 2) * 0.45
        default:
            let overflow = CGFloat(clamped - 1.05)
            return min(9.8, 7.1 + overflow * 2.7 + sin(CGFloat(clamped) * 12.0) * 0.8)
        }
    }

    static func orbitAngle(after holdDuration: TimeInterval) -> CGFloat {
        let clamped = min(max(holdDuration, 0), maxHoldDuration)
        let phase = CGFloat(clamped) * angularSpeed(for: clamped) * 0.58
        return startAngle + phase + wobble(for: clamped)
    }

    static func linearSpeed(for holdDuration: TimeInterval) -> CGFloat {
        angularSpeed(for: holdDuration) * orbitRadius
    }

    static func wobble(for holdDuration: TimeInterval) -> CGFloat {
        guard holdDuration > 1.0 else { return 0 }
        return sin(CGFloat(holdDuration) * 14.0) * min(0.18, CGFloat(holdDuration - 1.0) * 0.12)
    }

    static func tangentialDirection(for orbitAngle: CGFloat) -> CGVector {
        let raw = CGVector(dx: max(0.26, -sin(orbitAngle)), dy: cos(orbitAngle))
        let length = max(0.001, hypot(raw.dx, raw.dy))
        return CGVector(dx: raw.dx / length, dy: raw.dy / length)
    }

    static func releaseJudgement(for directionAngle: CGFloat, speed: CGFloat, holdDuration: TimeInterval) -> ReleaseJudgement {
        let degrees = directionAngle * 180 / .pi
        let angularVelocity = speed / orbitRadius

        if angularVelocity < 4.0 || degrees < 16 {
            return .early
        }

        if angularVelocity > 8.6 || degrees > 65 || holdDuration > 1.95 {
            return .over
        }

        if (28...46).contains(degrees) && (5.6...7.4).contains(angularVelocity) {
            return .perfect
        }

        return .nice
    }

    static func release(for holdDuration: TimeInterval) -> ThrowReleaseResult {
        release(for: orbitAngle(after: holdDuration), holdDuration: holdDuration)
    }

    static func release(for orbitAngle: CGFloat, holdDuration: TimeInterval) -> ThrowReleaseResult {
        let direction = tangentialDirection(for: orbitAngle)
        let tangentialSpeed = linearSpeed(for: holdDuration)
        let judgement = releaseJudgement(
            for: atan2(direction.dy, direction.dx),
            speed: tangentialSpeed,
            holdDuration: holdDuration
        )

        let multiplier: CGFloat
        switch judgement {
        case .early:
            multiplier = 0.88
        case .nice:
            multiplier = 1.0
        case .perfect:
            multiplier = 1.16
        case .over:
            multiplier = 1.05
        }

        let launchSpeed = max(960, (880 + tangentialSpeed * 0.98) * multiplier)
        return ThrowReleaseResult(
            velocity: CGVector(dx: direction.dx * launchSpeed, dy: direction.dy * launchSpeed),
            judgement: judgement
        )
    }
}
