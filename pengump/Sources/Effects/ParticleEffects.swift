import SpriteKit

class ParticleEffects {

    static let shared = ParticleEffects()

    // MARK: - Explosion Particle (Ice Break)

    func createExplosionParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        return emitter
    }

    func playExplosion(at position: CGPoint, in scene: SKScene) {
        let emitter = createExplosionParticle()
        emitter.position = position
        scene.addChild(emitter)
        let wait = SKAction.wait(forDuration: 0.8)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    // MARK: - Star Burst Particle (Level Complete)

    func createStarBurstParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.06
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5
        emitter.particleColor = .yellow
        emitter.particleColorBlendFactor = 1.0
        return emitter
    }

    func playStarBurst(at position: CGPoint, in scene: SKScene) {
        let emitter = createStarBurstParticle()
        emitter.position = position
        scene.addChild(emitter)
        let wait = SKAction.wait(forDuration: 1.2)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    // MARK: - Penguin Trail Particle

    func createPenguinTrailParticle() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 20
        emitter.numParticlesToEmit = 0  // infinite
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.1
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 5
        emitter.emissionAngleRange = .pi / 4
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.04
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -2.0
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0
        return emitter
    }

    func attachTrail(to node: SKNode) -> SKEmitterNode {
        let emitter = createPenguinTrailParticle()
        emitter.targetNode = node
        return emitter
    }

    func playCombo(at position: CGPoint, in scene: SKScene) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 180
        emitter.particleSpeedRange = 60
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        scene.addChild(emitter)
        let wait = SKAction.wait(forDuration: 0.9)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
}
