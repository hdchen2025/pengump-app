import CoreGraphics
import Foundation

struct FlightBody {
    var position: CGPoint
    var velocity: CGVector
    var isGrounded: Bool = false
    var groundedDuration: TimeInterval = 0
    var elapsedTime: TimeInterval = 0
    var airTime: TimeInterval = 0
    var flapsRemaining: Int = 1
}

struct FlightStepResult {
    var didBounce: Bool = false
    var didStop: Bool = false
    var consumedFlap: Bool = false
}

struct GroundSurface {
    let bounce: CGFloat
    let friction: CGFloat
}

struct FlightController {
    private let gravity: CGFloat = 1550
    private let airDrag: CGFloat = 0.998
    private let slideDrag: CGFloat = 0.985
    private let stopSpeed: CGFloat = 36
    private let flapBoost = CGVector(dx: 480, dy: 690)

    mutating func useFlap(on body: inout FlightBody) -> Bool {
        guard body.flapsRemaining > 0 else { return false }
        body.flapsRemaining -= 1
        body.velocity.dx += flapBoost.dx
        body.velocity.dy = max(body.velocity.dy + flapBoost.dy, flapBoost.dy)
        body.isGrounded = false
        body.groundedDuration = 0
        return true
    }

    mutating func applyFishBoost(on body: inout FlightBody) {
        body.velocity.dx += 430
        body.velocity.dy = max(body.velocity.dy, 120)
        body.isGrounded = false
        body.groundedDuration = 0
    }

    mutating func applyIceSpring(on body: inout FlightBody) {
        body.velocity.dy = max(abs(body.velocity.dy) * 0.62, 660)
        body.velocity.dx *= 1.08
        body.isGrounded = false
        body.groundedDuration = 0
    }

    mutating func step(body: inout FlightBody, dt: CGFloat, groundHeight: CGFloat, surface: GroundSurface) -> FlightStepResult {
        var result = FlightStepResult()
        body.elapsedTime += TimeInterval(dt)

        if !body.isGrounded {
            body.airTime += TimeInterval(dt)
            body.velocity.dy -= gravity * dt
            body.velocity.dx *= airDrag
            body.velocity.dy *= airDrag
        } else {
            body.velocity.dx *= slideDrag
        }

        body.position.x += body.velocity.dx * dt
        body.position.y += body.velocity.dy * dt

        if body.position.y <= groundHeight {
            body.position.y = groundHeight
            if abs(body.velocity.dy) > 170 {
                body.velocity.dy = abs(body.velocity.dy) * surface.bounce
                body.velocity.dx *= surface.friction
                body.isGrounded = false
                body.groundedDuration = 0
                result.didBounce = true
            } else {
                body.velocity.dy = 0
                body.velocity.dx *= surface.friction
                body.isGrounded = true
                body.groundedDuration += TimeInterval(dt)
                if abs(body.velocity.dx) < stopSpeed && body.groundedDuration > 0.45 {
                    result.didStop = true
                }
            }
        } else {
            body.isGrounded = false
            body.groundedDuration = 0
        }

        if body.elapsedTime > 18 {
            result.didStop = true
        }

        return result
    }
}
