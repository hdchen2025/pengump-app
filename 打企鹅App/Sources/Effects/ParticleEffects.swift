import SpriteKit

// MARK: - 粒子特效管理器

class ParticleEffects {
    static let shared = ParticleEffects()

    private init() {}

    // MARK: - 冰块爆炸粒子（蓝色冰晶向外扩散）

    func createExplosionParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // 发射参数
        emitter.particleBirthRate = 150
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        // 速度参数
        emitter.particleSpeed = 250
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2

        // 尺寸参数
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.15

        // 颜色参数（冰蓝色）
        emitter.particleColor = UIColor(red: 0.5, green: 0.85, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(red: 0.7, green: 0.95, blue: 1.0, alpha: 1.0),
                UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0),
                UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 0.5)
            ],
            times: [0, 0.3, 1.0]
        )

        // 旋转
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 2.0

        // 阿尔法衰减
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5

        // 形状
        emitter.particleShape = SKShapeNode(circleOfRadius: 4).path
        emitter.particleSpherical = false

        return emitter
    }

    // MARK: - 星星爆发粒子（金色粒子爆发，用于通关获得星星）

    func createStarBurstParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 80
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3

        emitter.particleSpeed = 300
        emitter.particleSpeedRange = 150
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2

        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.2

        // 金色
        emitter.particleColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0),
                UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0),
                UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 0.0)
            ],
            times: [0, 0.5, 1.0]
        )

        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 5.0

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.2

        // 星形
        emitter.particleShape = createStarShape()
        emitter.particleSpherical = false

        return emitter
    }

    // MARK: - 企鹅飞行轨迹粒子（白色轨迹）

    func createPenguinTrailParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 30
        emitter.numParticlesToEmit = 0  // 持续发射
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.15

        emitter.particleSpeed = 5
        emitter.particleSpeedRange = 3
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2

        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.25

        // 白色带透明
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 0.8
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(white: 1.0, alpha: 0.7),
                UIColor(white: 1.0, alpha: 0.3),
                UIColor(white: 1.0, alpha: 0.0)
            ],
            times: [0, 0.5, 1.0]
        )

        emitter.particleRotationSpeed = 0

        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -1.5

        emitter.particleShape = SKShapeNode(circleOfRadius: 3).path
        emitter.particleSpherical = false

        // 跟随源移动
        emitter.particleTargetNodeLifetime = 0

        return emitter
    }

    // MARK: - Combo特效粒子（连击时显示的彩色粒子）

    func createComboParticle(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2

        emitter.particleSpeed = 180
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2

        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.3

        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0

        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3.0

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0

        emitter.particleShape = SKShapeNode(rectOf: CGSize(width: 6, height: 6)).path
        emitter.particleSpherical = false

        return emitter
    }

    // MARK: - 火焰粒子（用于火焰企鹅皮肤）

    func createFireParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 50
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 30
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 0.3

        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.3

        emitter.particleColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0),
                UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0),
                UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 0.0)
            ],
            times: [0, 0.4, 1.0]
        )

        emitter.particleRotationSpeed = 0

        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.5

        emitter.particleShape = SKShapeNode(circleOfRadius: 5).path
        emitter.particleSpherical = false

        return emitter
    }

    // MARK: - 购买成功粒子（购买道具时显示）

    func createPurchaseParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.7
        emitter.particleLifetimeRange = 0.2

        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2

        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.06
        emitter.particleScaleSpeed = -0.15

        emitter.particleColor = UIColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0

        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 2.0

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.3

        emitter.particleShape = SKShapeNode(circleOfRadius: 4).path
        emitter.particleSpherical = false

        return emitter
    }

    // MARK: - 星星形状Path

    private func createStarShape() -> CGPath {
        let path = CGMutablePath()
        let points = 5
        let outerRadius: CGFloat = 6
        let innerRadius: CGFloat = 3

        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let x = cos(angle) * radius
            let y = sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - 辅助方法：在指定位置播放粒子特效

    /// 在场景中播放冰块爆炸特效
    func playExplosion(at position: CGPoint, in scene: SKScene) {
        let emitter = createExplosionParticle()
        emitter.position = position
        emitter.zPosition = 50
        scene.addChild(emitter)

        // 自动移除
        let wait = SKAction.wait(forDuration: 1.5)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    /// 在场景中播放星星爆发特效
    func playStarBurst(at position: CGPoint, in scene: SKScene) {
        let emitter = createStarBurstParticle()
        emitter.position = position
        emitter.zPosition = 55
        scene.addChild(emitter)

        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    /// 在节点上附加企鹅飞行轨迹
    func attachTrail(to node: SKNode) -> SKEmitterNode {
        let emitter = createPenguinTrailParticle()
        emitter.position = CGPoint(x: 0, y: 0)
        emitter.name = "trailEmitter"
        node.addChild(emitter)
        return emitter
    }

    /// 播放Combo特效
    func playCombo(at position: CGPoint, comboLevel: Int, in scene: SKScene) {
        let color: UIColor
        if comboLevel >= 5 {
            color = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)  // 金色
        } else if comboLevel >= 4 {
            color = UIColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 1.0)  // 紫色
        } else if comboLevel >= 3 {
            color = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)  // 蓝色
        } else {
            color = UIColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0)  // 绿色
        }

        let emitter = createComboParticle(color: color)
        emitter.position = position
        emitter.zPosition = 60
        scene.addChild(emitter)

        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    /// 播放购买成功特效
    func playPurchase(at position: CGPoint, in scene: SKScene) {
        let emitter = createPurchaseParticle()
        emitter.position = position
        emitter.zPosition = 65
        scene.addChild(emitter)

        let wait = SKAction.wait(forDuration: 1.5)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
}
