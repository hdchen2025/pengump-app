import SpriteKit
import UIKit

// MARK: - 物理常量

struct GamePhysics {
    static let maxPullDistance: CGFloat = 120
    static let minPullDistance: CGFloat = 20
    static let launchSpeedMultiplier: CGFloat = 0.15
    static let maxLaunchSpeed: CGFloat = 18
    static let gravity: CGFloat = 0.25
    static let airResistance: CGFloat = 0.99
    static let bounceDecay: CGFloat = 0.72
    static let stopThreshold: CGFloat = 0.55
    static let explosionRadius: CGFloat = 104
    static let explosionDamageRatio: CGFloat = 0.75
    static let collisionCooldown: TimeInterval = 0.12
}

// MARK: - 得分常量

struct GameScore {
    static let normalIceBlock: Int = 100
    static let crackedIceBlock: Int = 200
    static let explosiveIceBlock: Int = 300
    static let comboMultiplier: Double = 1.5
    static let remainingPenguinBonus: Int = 250
    static let clearBonusBase: Int = 150
    static let clearBonusStep: Int = 25
}

// MARK: - 企鹅飞行状态

enum PenguinFlightState {
    case ready
    case aiming
    case flying
    case stopped
}

// MARK: - 冰块节点

final class IceBlockNode: SKSpriteNode {
    var durability: Int = 1
    var maxDurability: Int = 1
    var blockType: IceBlockType = .normal
    var isBreaking: Bool = false

    convenience init(type: IceBlockType, size: CGSize) {
        let color = IceBlockNode.colorForType(type)
        self.init(color: color, size: size)
        self.blockType = type
        self.maxDurability = IceBlockNode.durabilityForType(type)
        self.durability = self.maxDurability
        self.name = "iceBlock"
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupAppearance(type: type)
        setupPhysics(size: size)
    }

    private static func durabilityForType(_ type: IceBlockType) -> Int {
        switch type {
        case .normal, .explosive:
            return 1
        case .cracked:
            return 2
        }
    }

    private static func colorForType(_ type: IceBlockType) -> UIColor {
        switch type {
        case .normal:
            return UIColor(red: 0.72, green: 0.9, blue: 1.0, alpha: 0.95)
        case .cracked:
            return UIColor(red: 0.55, green: 0.8, blue: 0.97, alpha: 0.95)
        case .explosive:
            return UIColor(red: 1.0, green: 0.48, blue: 0.45, alpha: 0.95)
        }
    }

    private func setupAppearance(type: IceBlockType) {
        let blockShape = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 5)
        blockShape.fillColor = IceBlockNode.colorForType(type)
        blockShape.strokeColor = UIColor(white: 1.0, alpha: 0.7)
        blockShape.lineWidth = 2
        blockShape.name = "blockShape"
        addChild(blockShape)

        let highlight = SKShapeNode(rectOf: CGSize(width: size.width * 0.58, height: 5), cornerRadius: 2)
        highlight.fillColor = UIColor(white: 1.0, alpha: 0.55)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: size.height * 0.28)
        highlight.name = "highlight"
        addChild(highlight)

        switch type {
        case .cracked:
            addCrackLines()
        case .explosive:
            addExplosiveMarker()
        case .normal:
            break
        }
    }

    private func addCrackLines() {
        let crackColor = UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 0.8)
        for index in 0..<3 {
            let crack = SKShapeNode()
            let path = CGMutablePath()
            let startX = CGFloat.random(in: -size.width * 0.3 ... 0)
            let startY = CGFloat.random(in: -size.height * 0.2 ... size.height * 0.3)
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: startX + CGFloat.random(in: 10...20), y: startY + CGFloat.random(in: 10...20)))
            path.addLine(to: CGPoint(x: startX + CGFloat.random(in: 15...25), y: startY + CGFloat.random(in: 5...15)))
            crack.path = path
            crack.strokeColor = crackColor
            crack.lineWidth = 1.5
            crack.name = "crack-\(index)"
            crack.zPosition = 1
            addChild(crack)
        }
    }

    private func addExplosiveMarker() {
        let marker = SKShapeNode(circleOfRadius: 10)
        marker.fillColor = UIColor(red: 1.0, green: 0.67, blue: 0.12, alpha: 0.95)
        marker.strokeColor = UIColor(red: 0.82, green: 0.28, blue: 0.08, alpha: 1.0)
        marker.lineWidth = 2
        marker.name = "explosiveMarker"
        addChild(marker)

        let exclLabel = SKLabelNode(text: "!")
        exclLabel.fontSize = 14
        exclLabel.fontColor = .white
        exclLabel.fontName = "AvenirNext-Bold"
        exclLabel.position = CGPoint(x: 0, y: -5)
        marker.addChild(exclLabel)
    }

    private func setupPhysics(size: CGSize) {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width - 2, height: size.height - 2), center: .zero)
        physicsBody?.isDynamic = false
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
    }

    func takeDamage(_ amount: Int) -> Bool {
        durability -= amount
        if durability <= 0 {
            return true
        }

        if blockType == .cracked || blockType == .explosive {
            enumerateChildNodes(withName: "crack-*") { node, _ in
                node.removeFromParent()
            }
            childNode(withName: "explosiveMarker")?.removeFromParent()
            if let shape = childNode(withName: "blockShape") as? SKShapeNode {
                shape.fillColor = IceBlockNode.colorForType(.normal)
            }
        }
        flash()
        return false
    }

    func flash() {
        let whiteFlash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.85, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        run(whiteFlash)
    }

    func playBreakAnimation(completion: @escaping () -> Void) {
        guard !isBreaking else { return }
        isBreaking = true

        let whiteFlash = SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.05)
        let shrink = SKAction.group([
            SKAction.scale(to: 0.08, duration: 0.16),
            SKAction.fadeOut(withDuration: 0.16)
        ])
        run(SKAction.sequence([whiteFlash, shrink, .removeFromParent()])) {
            completion()
        }

        spawnFragments()
    }

    private func spawnFragments() {
        let fragmentSize: CGFloat = 12
        let directions: [(CGFloat, CGFloat)] = [(-1, 1), (1, 1), (-1, -1), (1, -1)]
        for (dx, dy) in directions {
            let fragment = SKShapeNode(rectOf: CGSize(width: fragmentSize, height: fragmentSize), cornerRadius: 2)
            fragment.fillColor = color
            fragment.strokeColor = UIColor(white: 1.0, alpha: 0.4)
            fragment.lineWidth = 1
            fragment.position = position
            fragment.zPosition = zPosition - 1
            fragment.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: fragmentSize, height: fragmentSize))
            fragment.physicsBody?.isDynamic = true
            fragment.physicsBody?.mass = 0.1
            fragment.physicsBody?.applyImpulse(CGVector(dx: dx * 3, dy: dy * 3))
            fragment.physicsBody?.applyAngularImpulse(dx * 0.5)
            scene?.addChild(fragment)

            let fadeOut = SKAction.sequence([
                .wait(forDuration: 0.3),
                .fadeOut(withDuration: 0.3),
                .removeFromParent()
            ])
            fragment.run(fadeOut)
        }
    }
}

private struct LevelPalette {
    let sky: UIColor
    let horizon: UIColor
    let glow: UIColor
    let accent: UIColor
    let snow: UIColor
}

private struct VictoryBonusSummary {
    let remainingPenguinBonus: Int
    let clearBonus: Int

    var total: Int {
        remainingPenguinBonus + clearBonus
    }
}

// MARK: - 游戏主场景

final class GameScene: SKScene {

    private let currentLevel: Int
    private let levelConfig: LevelConfig
    private let levelTheme: LevelTheme
    private let scorePlan: LevelScorePlan

    private var penguinsRemaining: Int
    private var score: Int = 0
    private var roundComboCount: Int = 0
    private var flightState: PenguinFlightState = .ready
    private var launchTime: TimeInterval = 0
    private var shotsFired: Int = 0
    private var hasPresentedResult = false
    private var iceBlocks: [IceBlockNode] = []
    private var lastBlockHitTimes: [ObjectIdentifier: TimeInterval] = [:]

    private var backgroundNode = SKNode()
    private var slingshotBase: SKNode!
    private var leftBandNode: SKShapeNode!
    private var rightBandNode: SKShapeNode!
    private var penguinNode: SKSpriteNode?
    private var trajectoryLine: SKShapeNode!
    private var activePenguin: SKSpriteNode?
    private var penguinQueue: [SKSpriteNode] = []
    private var slingshotAnchorLeft: CGPoint = .zero
    private var slingshotAnchorRight: CGPoint = .zero
    private var trailEmitter: SKEmitterNode?
    private var resultOverlay: SKNode?

    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var penguinCountLabel: SKLabelNode!
    private var targetLabel: SKLabelNode!
    private var bestScoreLabel: SKLabelNode!
    private var hintLabel: SKLabelNode?
    private var ruleLabel: SKLabelNode?

    init(level: Int) {
        currentLevel = level
        levelConfig = Levels.config(for: level)
        levelTheme = Levels.theme(for: level)
        scorePlan = Levels.scorePlan(for: levelConfig)
        penguinsRemaining = levelConfig.penguinCount
        super.init(size: .zero)
        backgroundColor = palette.sky
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMove(to view: SKView) {
        setupPauseNotifications()
        setupBackground()
        setupPhysicsWorld()
        setupSlingshot()
        setupPenguinQueue()
        setupTrajectoryLine()
        setupUI()
        setupIceBlocks()
        setupGround()
        reloadSlingshot()
    }

    private var palette: LevelPalette {
        switch levelTheme {
        case .sunrise:
            return LevelPalette(
                sky: UIColor(red: 0.96, green: 0.88, blue: 0.73, alpha: 1),
                horizon: UIColor(red: 0.76, green: 0.91, blue: 0.97, alpha: 1),
                glow: UIColor(red: 1.0, green: 0.74, blue: 0.45, alpha: 0.36),
                accent: UIColor(red: 0.98, green: 0.63, blue: 0.33, alpha: 1),
                snow: UIColor(white: 1.0, alpha: 0.8)
            )
        case .glacier:
            return LevelPalette(
                sky: UIColor(red: 0.75, green: 0.89, blue: 0.97, alpha: 1),
                horizon: UIColor(red: 0.5, green: 0.79, blue: 0.94, alpha: 1),
                glow: UIColor(red: 0.62, green: 0.91, blue: 1.0, alpha: 0.28),
                accent: UIColor(red: 0.25, green: 0.62, blue: 0.88, alpha: 1),
                snow: UIColor(white: 1.0, alpha: 0.92)
            )
        case .aurora:
            return LevelPalette(
                sky: UIColor(red: 0.16, green: 0.2, blue: 0.37, alpha: 1),
                horizon: UIColor(red: 0.24, green: 0.48, blue: 0.65, alpha: 1),
                glow: UIColor(red: 0.44, green: 0.98, blue: 0.84, alpha: 0.26),
                accent: UIColor(red: 0.56, green: 0.95, blue: 0.72, alpha: 1),
                snow: UIColor(white: 0.94, alpha: 0.85)
            )
        }
    }

    // MARK: - 场景搭建

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -GamePhysics.gravity * 60)
        physicsWorld.speed = 1
    }

    private func setupBackground() {
        addChild(backgroundNode)

        let skyNode = SKSpriteNode(color: palette.sky, size: CGSize(width: frame.width, height: frame.height))
        skyNode.position = CGPoint(x: frame.midX, y: frame.midY)
        skyNode.zPosition = -30
        backgroundNode.addChild(skyNode)

        let horizonNode = SKSpriteNode(color: palette.horizon, size: CGSize(width: frame.width, height: frame.height * 0.45))
        horizonNode.position = CGPoint(x: frame.midX, y: frame.height * 0.22)
        horizonNode.zPosition = -29
        backgroundNode.addChild(horizonNode)

        for (index, size, offsetX, offsetY) in [
            (0, CGFloat(260), frame.width * 0.18, frame.height * 0.8),
            (1, CGFloat(200), frame.width * 0.82, frame.height * 0.72)
        ] {
            let glow = SKShapeNode(circleOfRadius: size / 2)
            glow.fillColor = palette.glow
            glow.strokeColor = .clear
            glow.position = CGPoint(x: offsetX, y: offsetY)
            glow.zPosition = -28 + CGFloat(index)
            backgroundNode.addChild(glow)
        }

        addIceberg(at: CGPoint(x: frame.width * 0.18, y: frame.height * 0.12), size: CGSize(width: 170, height: 90), depth: -24)
        addIceberg(at: CGPoint(x: frame.width * 0.48, y: frame.height * 0.1), size: CGSize(width: 250, height: 110), depth: -23)
        addIceberg(at: CGPoint(x: frame.width * 0.82, y: frame.height * 0.11), size: CGSize(width: 190, height: 80), depth: -22)

        spawnSnow()
    }

    private func addIceberg(at position: CGPoint, size: CGSize, depth: CGFloat) {
        let hill = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width / 2, y: -size.height / 2))
        path.addLine(to: CGPoint(x: -size.width * 0.2, y: size.height * 0.2))
        path.addLine(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width * 0.22, y: size.height * 0.16))
        path.addLine(to: CGPoint(x: size.width / 2, y: -size.height / 2))
        path.closeSubpath()
        hill.path = path
        hill.fillColor = palette.snow.withAlphaComponent(0.88)
        hill.strokeColor = UIColor(white: 1.0, alpha: 0.45)
        hill.lineWidth = 2
        hill.position = position
        hill.zPosition = depth
        backgroundNode.addChild(hill)
    }

    private func spawnSnow() {
        for index in 0..<12 {
            let flake = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.2))
            flake.fillColor = palette.snow
            flake.strokeColor = .clear
            flake.position = CGPoint(
                x: CGFloat.random(in: 30...(frame.width - 30)),
                y: CGFloat.random(in: frame.height * 0.4...(frame.height - 20))
            )
            flake.alpha = CGFloat.random(in: 0.45...0.95)
            flake.zPosition = -15
            backgroundNode.addChild(flake)

            let drift = SKAction.sequence([
                .moveBy(x: CGFloat((index % 2 == 0 ? 1 : -1) * 12), y: -18, duration: Double.random(in: 2.6...4.1)),
                .moveBy(x: CGFloat((index % 2 == 0 ? -1 : 1) * 12), y: 18, duration: Double.random(in: 2.6...4.1))
            ])
            flake.run(.repeatForever(drift))
        }
    }

    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: frame.width, height: 40))
        ground.fillColor = UIColor(red: 0.86, green: 0.92, blue: 0.96, alpha: 1)
        ground.strokeColor = UIColor(red: 0.72, green: 0.84, blue: 0.91, alpha: 1)
        ground.lineWidth = 2
        ground.position = CGPoint(x: frame.width / 2, y: 20)
        ground.name = "ground"
        ground.zPosition = 2
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 40))
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }

    private func setupSlingshot() {
        let baseX = frame.width * 0.18
        let baseY = frame.height * 0.22
        let postWidth: CGFloat = 12
        let postHeight: CGFloat = 100
        let forkHeight: CGFloat = 40
        let forkWidth: CGFloat = 50

        let leftArm = SKShapeNode(rectOf: CGSize(width: postWidth, height: forkHeight), cornerRadius: 3)
        leftArm.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        leftArm.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1)
        leftArm.lineWidth = 2
        leftArm.position = CGPoint(x: -forkWidth / 2, y: postHeight / 2 + forkHeight / 2)
        leftArm.zPosition = 10

        let rightArm = SKShapeNode(rectOf: CGSize(width: postWidth, height: forkHeight), cornerRadius: 3)
        rightArm.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        rightArm.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1)
        rightArm.lineWidth = 2
        rightArm.position = CGPoint(x: forkWidth / 2, y: postHeight / 2 + forkHeight / 2)
        rightArm.zPosition = 10

        let post = SKShapeNode(rectOf: CGSize(width: postWidth, height: postHeight), cornerRadius: 3)
        post.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        post.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1)
        post.lineWidth = 2
        post.zPosition = 10

        slingshotBase = SKNode()
        slingshotBase.addChild(leftArm)
        slingshotBase.addChild(rightArm)
        slingshotBase.addChild(post)
        slingshotBase.position = CGPoint(x: baseX, y: baseY)
        addChild(slingshotBase)

        slingshotAnchorLeft = CGPoint(x: baseX - forkWidth / 2, y: baseY + postHeight / 2 + forkHeight)
        slingshotAnchorRight = CGPoint(x: baseX + forkWidth / 2, y: baseY + postHeight / 2 + forkHeight)

        leftBandNode = SKShapeNode()
        leftBandNode.strokeColor = UIColor(red: 0.65, green: 0.38, blue: 0.12, alpha: 1)
        leftBandNode.lineWidth = 4
        leftBandNode.lineCap = .round
        leftBandNode.zPosition = 5
        addChild(leftBandNode)

        rightBandNode = SKShapeNode()
        rightBandNode.strokeColor = UIColor(red: 0.65, green: 0.38, blue: 0.12, alpha: 1)
        rightBandNode.lineWidth = 4
        rightBandNode.lineCap = .round
        rightBandNode.zPosition = 5
        addChild(rightBandNode)

        updateBandPositions(penguinPos: CGPoint(x: baseX, y: slingshotAnchorLeft.y))
    }

    private func updateBandPositions(penguinPos: CGPoint) {
        let leftPath = CGMutablePath()
        leftPath.move(to: slingshotAnchorLeft)
        let midLeft = CGPoint(
            x: (slingshotAnchorLeft.x + penguinPos.x) / 2,
            y: (slingshotAnchorLeft.y + penguinPos.y) / 2 - 5
        )
        leftPath.addQuadCurve(to: penguinPos, control: midLeft)
        leftBandNode.path = leftPath

        let rightPath = CGMutablePath()
        rightPath.move(to: slingshotAnchorRight)
        let midRight = CGPoint(
            x: (slingshotAnchorRight.x + penguinPos.x) / 2,
            y: (slingshotAnchorRight.y + penguinPos.y) / 2 - 5
        )
        rightPath.addQuadCurve(to: penguinPos, control: midRight)
        rightBandNode.path = rightPath
    }

    private func setupPenguinQueue() {
        let queueY = frame.height * 0.1
        let startX = frame.width * 0.06
        let spacing: CGFloat = 42

        for index in 0..<penguinsRemaining {
            let penguin = createPenguinNode()
            penguin.position = CGPoint(x: startX + CGFloat(index) * spacing, y: queueY)
            penguin.alpha = 0.55
            penguin.setScale(0.82)
            addChild(penguin)
            penguinQueue.append(penguin)
        }
    }

    private func createPenguinNode() -> SKSpriteNode {
        let penguin = SKSpriteNode()
        penguin.name = "penguin"

        let body = SKShapeNode(ellipseOf: CGSize(width: 26, height: 30))
        body.fillColor = UIColor(red: 0.31, green: 0.81, blue: 0.77, alpha: 1)
        body.strokeColor = UIColor(red: 0.17, green: 0.47, blue: 0.45, alpha: 1)
        body.lineWidth = 2
        penguin.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 16, height: 20))
        belly.fillColor = .white
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -3)
        penguin.addChild(belly)

        let leftEye = SKShapeNode(circleOfRadius: 4)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -6, y: 6)
        penguin.addChild(leftEye)

        let leftPupil = SKShapeNode(circleOfRadius: 2)
        leftPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 1, y: 0)
        leftEye.addChild(leftPupil)

        let rightEye = SKShapeNode(circleOfRadius: 4)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 6, y: 6)
        penguin.addChild(rightEye)

        let rightPupil = SKShapeNode(circleOfRadius: 2)
        rightPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 1, y: 0)
        rightEye.addChild(rightPupil)

        let leftBlush = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        leftBlush.fillColor = UIColor(red: 1, green: 0.42, blue: 0.62, alpha: 0.5)
        leftBlush.strokeColor = .clear
        leftBlush.position = CGPoint(x: -10, y: 0)
        penguin.addChild(leftBlush)

        let rightBlush = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        rightBlush.fillColor = UIColor(red: 1, green: 0.42, blue: 0.62, alpha: 0.5)
        rightBlush.strokeColor = .clear
        rightBlush.position = CGPoint(x: 10, y: 0)
        penguin.addChild(rightBlush)

        let beak = SKShapeNode(ellipseOf: CGSize(width: 8, height: 5))
        beak.fillColor = UIColor(red: 1, green: 0.9, blue: 0.43, alpha: 1)
        beak.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1)
        beak.lineWidth = 1
        beak.position = CGPoint(x: 0, y: -1)
        penguin.addChild(beak)

        let leftWing = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
        leftWing.fillColor = UIColor(red: 0.31, green: 0.81, blue: 0.77, alpha: 1)
        leftWing.strokeColor = UIColor(red: 0.17, green: 0.47, blue: 0.45, alpha: 1)
        leftWing.lineWidth = 1.5
        leftWing.position = CGPoint(x: -14, y: 0)
        leftWing.zRotation = 0.2
        penguin.addChild(leftWing)

        let rightWing = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
        rightWing.fillColor = UIColor(red: 0.31, green: 0.81, blue: 0.77, alpha: 1)
        rightWing.strokeColor = UIColor(red: 0.17, green: 0.47, blue: 0.45, alpha: 1)
        rightWing.lineWidth = 1.5
        rightWing.position = CGPoint(x: 14, y: 0)
        rightWing.zRotation = -0.2
        penguin.addChild(rightWing)

        let feather = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 2)
        feather.fillColor = UIColor(red: 1, green: 0.9, blue: 0.43, alpha: 1)
        feather.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1)
        feather.lineWidth = 1
        feather.position = CGPoint(x: 0, y: 17)
        penguin.addChild(feather)

        return penguin
    }

    private func reloadSlingshot() {
        guard !hasPresentedResult else { return }
        guard penguinNode == nil, activePenguin == nil, penguinsRemaining > 0 else { return }

        let launchPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let penguin = createPenguinNode()
        penguin.position = launchPos
        penguin.zPosition = 20
        addChild(penguin)
        penguinNode = penguin
        updateBandPositions(penguinPos: launchPos)
        flightState = .ready
    }

    private func setupTrajectoryLine() {
        trajectoryLine = SKShapeNode()
        trajectoryLine.strokeColor = UIColor.gray.withAlphaComponent(0.45)
        trajectoryLine.lineWidth = 2
        trajectoryLine.isHidden = true
        trajectoryLine.zPosition = 15
        addChild(trajectoryLine)
    }

    private func setupUI() {
        let backButton = makeButtonNode(width: 88, height: 34, name: "backButton", color: UIColor(white: 0.25, alpha: 0.8))
        backButton.position = CGPoint(x: 56, y: frame.height - 30)
        addChild(backButton)

        let backLabel = SKLabelNode(text: "← 返回")
        backLabel.fontSize = 13
        backLabel.fontColor = .white
        backLabel.fontName = "AvenirNext-DemiBold"
        backLabel.verticalAlignmentMode = .center
        backLabel.position = CGPoint(x: 0, y: 0)
        backButton.addChild(backLabel)

        scoreLabel = makeHUDLabel(fontSize: 24, color: titleColor)
        scoreLabel.text = "分数: 0"
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.height - 44)
        addChild(scoreLabel)

        levelLabel = makeHUDLabel(fontSize: 18, color: secondaryTextColor)
        levelLabel.text = "第 \(currentLevel) 关"
        levelLabel.position = CGPoint(x: frame.midX, y: frame.height - 72)
        addChild(levelLabel)

        targetLabel = makeHUDLabel(fontSize: 14, color: secondaryTextColor)
        targetLabel.text = "目标: \(scorePlan.targetScore)"
        targetLabel.position = CGPoint(x: frame.midX, y: frame.height - 96)
        addChild(targetLabel)

        penguinCountLabel = makeHUDLabel(fontSize: 20, color: titleColor)
        penguinCountLabel.text = "🐧 × \(penguinsRemaining)"
        penguinCountLabel.position = CGPoint(x: frame.width - 58, y: frame.height - 42)
        addChild(penguinCountLabel)

        let bestScore = SaveManager.shared.record(for: currentLevel)?.score ?? 0
        bestScoreLabel = makeHUDLabel(fontSize: 13, color: secondaryTextColor)
        bestScoreLabel.text = "最佳: \(bestScore)"
        bestScoreLabel.position = CGPoint(x: frame.width - 58, y: frame.height - 68)
        addChild(bestScoreLabel)

        if let ruleText = ruleText() {
            let label = makeHUDLabel(fontSize: 12, color: palette.accent)
            label.text = ruleText
            label.position = CGPoint(x: frame.width - 76, y: frame.height - 92)
            addChild(label)
            ruleLabel = label
        }

        let hintText = combinedHintText()
        if !hintText.isEmpty {
            let label = makeHUDLabel(fontSize: 16, color: secondaryTextColor.withAlphaComponent(0.9))
            label.text = hintText
            label.position = CGPoint(x: frame.midX, y: frame.height * 0.46)
            label.alpha = 0
            addChild(label)
            hintLabel = label
            label.run(.sequence([
                .wait(forDuration: 0.5),
                .fadeIn(withDuration: 0.4),
                .wait(forDuration: 2.8),
                .fadeOut(withDuration: 0.8)
            ]))
        }
    }

    private var titleColor: UIColor {
        levelTheme == .aurora ? UIColor(white: 0.97, alpha: 1) : UIColor(red: 0.2, green: 0.23, blue: 0.33, alpha: 1)
    }

    private var secondaryTextColor: UIColor {
        levelTheme == .aurora ? UIColor(red: 0.84, green: 0.93, blue: 0.98, alpha: 1) : UIColor(red: 0.34, green: 0.42, blue: 0.52, alpha: 1)
    }

    private func makeHUDLabel(fontSize: CGFloat, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        return label
    }

    private func makeButtonNode(width: CGFloat, height: CGFloat, name: String, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        node.fillColor = color
        node.strokeColor = UIColor(white: 1, alpha: 0.35)
        node.lineWidth = 1.5
        node.name = name
        return node
    }

    private func combinedHintText() -> String {
        let baseHint = levelConfig.hint ?? ""
        switch Levels.motionStyle(for: currentLevel) {
        case .none:
            return baseHint
        case .glide:
            return baseHint.isEmpty ? "移动靶会左右滑行，等一拍再出手。" : "\(baseHint)  移动靶会左右滑行。"
        case .hover:
            return baseHint.isEmpty ? "悬浮靶会上下浮动，抓住停顿瞬间。" : "\(baseHint)  悬浮靶会上下浮动。"
        }
    }

    private func ruleText() -> String? {
        switch Levels.motionStyle(for: currentLevel) {
        case .none:
            return nil
        case .glide:
            return "移动靶"
        case .hover:
            return "悬浮靶"
        }
    }

    private func setupIceBlocks() {
        iceBlocks.removeAll()
        for (index, config) in levelConfig.iceBlocks.enumerated() {
            let blockSize: CGFloat = 48
            let block = IceBlockNode(type: config.type, size: CGSize(width: blockSize, height: blockSize))
            block.position = CGPoint(x: frame.width * config.x, y: frame.height * config.y)
            block.zPosition = 8
            addChild(block)
            applyMotionIfNeeded(to: block, index: index)
            iceBlocks.append(block)
        }
    }

    private func applyMotionIfNeeded(to block: IceBlockNode, index: Int) {
        switch Levels.motionStyle(for: currentLevel) {
        case .none:
            return
        case .glide:
            let amplitude: CGFloat = currentLevel >= 13 ? 26 : 18
            let move = SKAction.sequence([
                .moveBy(x: amplitude * (index.isMultiple(of: 2) ? 1 : -1), y: 0, duration: 1.8 + Double(index % 3) * 0.18),
                .moveBy(x: amplitude * (index.isMultiple(of: 2) ? -1 : 1), y: 0, duration: 1.8 + Double(index % 3) * 0.18)
            ])
            block.run(.repeatForever(move), withKey: "targetMotion")
        case .hover:
            let amplitude: CGFloat = currentLevel >= 15 ? 22 : 16
            let move = SKAction.sequence([
                .moveBy(x: 0, y: amplitude * (index.isMultiple(of: 2) ? 1 : -1), duration: 1.4 + Double(index % 4) * 0.16),
                .moveBy(x: 0, y: amplitude * (index.isMultiple(of: 2) ? -1 : 1), duration: 1.4 + Double(index % 4) * 0.16)
            ])
            block.run(.repeatForever(move), withKey: "targetMotion")
        }
    }

    // MARK: - 触摸控制

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let overlay = resultOverlay {
            let overlayLocation = touch.location(in: overlay)
            if didTap(nodeNamed: "nextButton", at: overlayLocation, in: overlay) {
                goToNextLevel()
                return
            }
            if didTap(nodeNamed: "retryButton", at: overlayLocation, in: overlay) {
                retryLevel()
                return
            }
            if didTap(nodeNamed: "resultBackButton", at: overlayLocation, in: overlay) {
                dismiss(animated: true)
                return
            }
            return
        }

        if didTap(nodeNamed: "backButton", at: location, in: self) {
            dismiss(animated: true)
            return
        }

        if flightState == .ready,
           let penguin = penguinNode,
           penguin.frame.insetBy(dx: -20, dy: -20).contains(location) {
            flightState = .aiming
            trajectoryLine.isHidden = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard flightState == .aiming, let touch = touches.first else { return }

        let location = touch.location(in: self)
        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = location.x - anchorPos.x
        let dy = location.y - anchorPos.y
        var distance = sqrt(dx * dx + dy * dy)
        distance = min(distance, GamePhysics.maxPullDistance)

        var angle = atan2(dy, dx)
        let maxAngle: CGFloat = .pi * 0.88
        angle = min(max(angle, -maxAngle), maxAngle)

        let pullX = anchorPos.x + cos(angle) * distance
        let pullY = anchorPos.y + sin(angle) * distance
        let pulledPosition = CGPoint(x: pullX, y: pullY)

        penguinNode?.position = pulledPosition
        updateBandPositions(penguinPos: pulledPosition)

        if distance >= GamePhysics.minPullDistance {
            drawTrajectory()
            trajectoryLine.isHidden = false
        } else {
            trajectoryLine.isHidden = true
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard flightState == .aiming else { return }

        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = anchorPos.x - (penguinNode?.position.x ?? anchorPos.x)
        let dy = anchorPos.y - (penguinNode?.position.y ?? anchorPos.y)
        let distance = sqrt(dx * dx + dy * dy)

        trajectoryLine.isHidden = true

        if distance < GamePhysics.minPullDistance {
            let restore = SKAction.move(to: anchorPos, duration: 0.2)
            restore.timingMode = .easeOut
            penguinNode?.run(restore)
            updateBandPositions(penguinPos: anchorPos)
            flightState = .ready
            return
        }

        launchPenguin()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func didTap(nodeNamed name: String, at location: CGPoint, in container: SKNode) -> Bool {
        var candidate: SKNode? = container.atPoint(location)
        while let node = candidate {
            if node.name == name {
                return true
            }
            candidate = node.parent
        }
        return false
    }

    // MARK: - 发射逻辑

    private func drawTrajectory() {
        guard let penguin = penguinNode else { return }

        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = anchorPos.x - penguin.position.x
        let dy = anchorPos.y - penguin.position.y

        var speed = sqrt(dx * dx + dy * dy) * GamePhysics.launchSpeedMultiplier
        speed = min(speed, GamePhysics.maxLaunchSpeed)

        let angle = atan2(dy, dx)
        var velocityX = cos(angle) * speed
        var velocityY = sin(angle) * speed
        var x = penguin.position.x
        var y = penguin.position.y

        let path = CGMutablePath()
        path.move(to: CGPoint(x: x, y: y))

        for _ in 0..<16 {
            velocityX *= GamePhysics.airResistance
            velocityY = velocityY * GamePhysics.airResistance - GamePhysics.gravity
            x += velocityX * 3
            y += velocityY * 3
            if y < 0 {
                break
            }
            path.addLine(to: CGPoint(x: x, y: y))
        }

        trajectoryLine.path = path
    }

    private func launchPenguin() {
        guard let penguin = penguinNode else { return }

        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = anchorPos.x - penguin.position.x
        let dy = anchorPos.y - penguin.position.y

        var speed = sqrt(dx * dx + dy * dy) * GamePhysics.launchSpeedMultiplier
        speed = min(speed, GamePhysics.maxLaunchSpeed)

        let angle = atan2(dy, dx)
        let velocityX = cos(angle) * speed
        let velocityY = sin(angle) * speed

        let body = SKPhysicsBody(circleOfRadius: 16)
        body.isDynamic = true
        body.mass = 1
        body.linearDamping = 0.22
        body.friction = 0.3
        body.restitution = 0.7
        body.usesPreciseCollisionDetection = true
        penguin.physicsBody = body
        penguin.physicsBody?.applyImpulse(CGVector(dx: velocityX, dy: velocityY))
        penguin.physicsBody?.allowsRotation = true

        activePenguin = penguin
        penguinNode = nil
        flightState = .flying
        roundComboCount = 0
        launchTime = CACurrentMediaTime()
        shotsFired += 1
        lastBlockHitTimes.removeAll()

        trailEmitter = ParticleEffects.shared.attachTrail(to: penguin)
        if let trailEmitter {
            penguin.addChild(trailEmitter)
        }

        animateBandsRelease()
        AudioManager.shared.playLaunchSound()
        AudioManager.shared.playPenguinFlySound()

        penguinsRemaining -= 1
        updatePenguinCountDisplay()
        updateQueueDisplayAfterLaunch()

        if let ruleLabel, ruleLabel.alpha > 0.1 {
            ruleLabel.run(.fadeAlpha(to: 0.25, duration: 0.25))
        }
    }

    private func updateQueueDisplayAfterLaunch() {
        guard !penguinQueue.isEmpty else { return }
        penguinQueue.removeFirst()
        let queueY = frame.height * 0.1
        let startX = frame.width * 0.06
        let spacing: CGFloat = 42

        for (index, penguin) in penguinQueue.enumerated() {
            let move = SKAction.move(to: CGPoint(x: startX + CGFloat(index) * spacing, y: queueY), duration: 0.25)
            move.timingMode = .easeOut
            penguin.run(move)
        }
    }

    private func animateBandsRelease() {
        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        leftBandNode.run(.sequence([
            .fadeAlpha(to: 0.25, duration: 0.06),
            .fadeAlpha(to: 1.0, duration: 0.12)
        ]))
        rightBandNode.run(.sequence([
            .fadeAlpha(to: 0.25, duration: 0.06),
            .fadeAlpha(to: 1.0, duration: 0.12)
        ]))
        updateBandPositions(penguinPos: anchorPos)
    }

    // MARK: - 每帧更新

    override func update(_ currentTime: TimeInterval) {
        guard !hasPresentedResult,
              let penguin = activePenguin,
              let body = penguin.physicsBody else {
            return
        }

        let velocityX = body.velocity.dx
        let velocityY = body.velocity.dy
        let speed = sqrt(velocityX * velocityX + velocityY * velocityY)
        if speed > 1 {
            penguin.zRotation = atan2(velocityY, velocityX)
        }

        if penguin.position.x < 20 {
            penguin.position.x = 20
            body.velocity.dx = abs(body.velocity.dx) * GamePhysics.bounceDecay
        }
        if penguin.position.x > frame.width - 20 {
            penguin.position.x = frame.width - 20
            body.velocity.dx = -abs(body.velocity.dx) * GamePhysics.bounceDecay
        }
        if penguin.position.y > frame.height - 20 {
            penguin.position.y = frame.height - 20
            body.velocity.dy = -abs(body.velocity.dy) * GamePhysics.bounceDecay
        }

        let timeSinceLaunch = currentTime - launchTime
        let shouldStopForTimeout = timeSinceLaunch > 10 && speed < GamePhysics.stopThreshold
        let shouldStopNearGround = speed < GamePhysics.stopThreshold && penguin.position.y < slingshotBase.position.y + 50
        let shouldStopOffscreen = penguin.position.y < -40

        if shouldStopForTimeout || shouldStopNearGround || shouldStopOffscreen {
            finishCurrentFlight()
        }
    }

    private func finishCurrentFlight() {
        activePenguin?.physicsBody = nil
        activePenguin?.removeFromParent()
        activePenguin = nil
        flightState = .stopped
        onPenguinStopped()
    }

    // MARK: - 物理碰撞

    override func didSimulatePhysics() {
        checkPenguinCollisions()
    }

    private func checkPenguinCollisions() {
        guard !hasPresentedResult,
              let penguin = activePenguin,
              let body = penguin.physicsBody else {
            return
        }

        let penguinSpeed = sqrt(body.velocity.dx * body.velocity.dx + body.velocity.dy * body.velocity.dy)
        let timestamp = CACurrentMediaTime()

        for block in iceBlocks where !block.isBreaking && block.parent != nil {
            let identifier = ObjectIdentifier(block)
            if let lastHitTime = lastBlockHitTimes[identifier], timestamp - lastHitTime < GamePhysics.collisionCooldown {
                continue
            }

            let distance = hypot(penguin.position.x - block.position.x, penguin.position.y - block.position.y)
            if distance > 42 {
                continue
            }

            lastBlockHitTimes[identifier] = timestamp

            let damage = max(1, Int(penguinSpeed / 4.2))
            let destroyed = block.takeDamage(damage)
            bouncePenguinAway(from: block, speed: penguinSpeed)

            if destroyed {
                destroyBlock(block, triggerLinkedExplosion: true)
            } else {
                AudioManager.shared.playIceHitSound()
            }

            break
        }
    }

    private func bouncePenguinAway(from block: IceBlockNode, speed: CGFloat) {
        guard let penguin = activePenguin, let body = penguin.physicsBody else { return }

        var normal = CGVector(dx: penguin.position.x - block.position.x, dy: penguin.position.y - block.position.y)
        let magnitude = sqrt(normal.dx * normal.dx + normal.dy * normal.dy)
        if magnitude > 0.001 {
            normal.dx /= magnitude
            normal.dy /= magnitude
        } else {
            normal = CGVector(dx: 1, dy: 1)
        }

        let newSpeed = max(4, speed * GamePhysics.bounceDecay)
        body.velocity = CGVector(dx: normal.dx * newSpeed, dy: normal.dy * newSpeed)
    }

    private func destroyBlock(_ block: IceBlockNode, triggerLinkedExplosion: Bool) {
        guard block.parent != nil, !block.isBreaking else { return }

        roundComboCount += 1
        let blockPosition = block.position
        let isExplosiveBlock = block.blockType == .explosive

        addScoreForBlock(block)
        AudioManager.shared.playIceBreakSound()
        ParticleEffects.shared.playExplosion(at: blockPosition, in: self)

        if roundComboCount >= 2 {
            showComboEffect(count: roundComboCount, at: blockPosition)
            ParticleEffects.shared.playCombo(at: blockPosition, in: self)
            AudioManager.shared.playComboSound()
        }

        let blockRef = block
        block.playBreakAnimation { [weak self] in
            self?.iceBlocks.removeAll { $0 === blockRef }
            self?.checkLevelComplete()
        }

        if isExplosiveBlock && triggerLinkedExplosion {
            triggerExplosion(at: blockPosition, collidedBlock: block)
        }
    }

    private func triggerExplosion(at position: CGPoint, collidedBlock: IceBlockNode?) {
        let blast = SKShapeNode(circleOfRadius: GamePhysics.explosionRadius)
        blast.fillColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.35)
        blast.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.0, alpha: 0.82)
        blast.lineWidth = 3
        blast.position = position
        blast.zPosition = 30
        blast.alpha = 0
        addChild(blast)

        AudioManager.shared.playExplosionSound()

        let expand = SKAction.scale(to: 1.45, duration: 0.16)
        expand.timingMode = .easeOut
        blast.run(.sequence([
            .fadeIn(withDuration: 0.03),
            .group([expand, .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))

        for block in iceBlocks where !block.isBreaking && block.parent != nil {
            if let collidedBlock, block === collidedBlock {
                continue
            }
            let distance = hypot(block.position.x - position.x, block.position.y - position.y)
            if distance >= GamePhysics.explosionRadius || distance <= 0 {
                continue
            }

            let damage = max(1, Int(ceil(Double(block.maxDurability) * Double(GamePhysics.explosionDamageRatio))))
            let destroyed = block.takeDamage(damage)
            if destroyed {
                destroyBlock(block, triggerLinkedExplosion: false)
            } else {
                AudioManager.shared.playIceHitSound()
            }
        }
    }

    private func addScoreForBlock(_ block: IceBlockNode) {
        var baseScore = Levels.blockScore(for: block.blockType)
        if roundComboCount >= 2 {
            baseScore = Int(Double(baseScore) * GameScore.comboMultiplier)
        }

        score += baseScore
        updateScoreDisplay()
        showScorePopup(amount: baseScore, at: block.position)
    }

    private func updateScoreDisplay() {
        scoreLabel.text = "分数: \(score)"
    }

    private func updatePenguinCountDisplay() {
        penguinCountLabel.text = "🐧 × \(max(0, penguinsRemaining))"
    }

    private func showScorePopup(amount: Int, at position: CGPoint) {
        let popup = SKLabelNode(fontNamed: "AvenirNext-Bold")
        popup.text = "+\(amount)"
        popup.fontSize = 18
        popup.fontColor = .white
        popup.position = CGPoint(x: position.x, y: position.y + 30)
        popup.zPosition = 50
        popup.alpha = 0
        addChild(popup)

        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        rise.timingMode = .easeOut
        popup.run(.sequence([
            .group([.fadeIn(withDuration: 0.1), rise]),
            .fadeOut(withDuration: 0.8),
            .removeFromParent()
        ]))
    }

    private func showComboEffect(count: Int, at position: CGPoint) {
        let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        comboLabel.text = "Combo ×\(count)!"
        comboLabel.fontSize = 24
        comboLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        comboLabel.zPosition = 60
        comboLabel.alpha = 0
        comboLabel.fontColor = count >= 4
            ? UIColor(red: 0.85, green: 0.42, blue: 1, alpha: 1)
            : count >= 3
            ? UIColor(red: 0.36, green: 0.64, blue: 1, alpha: 1)
            : UIColor(red: 0.34, green: 0.86, blue: 0.42, alpha: 1)
        addChild(comboLabel)

        comboLabel.setScale(0.5)
        comboLabel.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.1),
                .sequence([
                    .scale(to: 1.2, duration: 0.15),
                    .scale(to: 1.0, duration: 0.1)
                ])
            ]),
            .wait(forDuration: 0.45),
            .fadeOut(withDuration: 0.45),
            .removeFromParent()
        ]))
    }

    // MARK: - 回合结束

    private func onPenguinStopped() {
        trailEmitter?.removeFromParent()
        trailEmitter = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.checkLevelComplete()
        }
    }

    // MARK: - 关卡判定

    private func checkLevelComplete() {
        guard !hasPresentedResult else { return }

        let activeBlocks = iceBlocks.filter { !$0.isBreaking && $0.parent != nil }
        if activeBlocks.isEmpty {
            showResult(success: true)
        } else if penguinsRemaining <= 0, activePenguin == nil {
            showResult(success: false)
        } else if activePenguin == nil {
            reloadSlingshot()
        }
    }

    private func showResult(success: Bool) {
        guard !hasPresentedResult else { return }
        hasPresentedResult = true

        freezeGameplay()

        let bonusSummary = success ? applyVictoryBonuses() : VictoryBonusSummary(remainingPenguinBonus: 0, clearBonus: 0)
        let stars = success ? calculateStars() : 0
        let previousBest = SaveManager.shared.record(for: currentLevel)?.score ?? 0

        if success {
            AudioManager.shared.playGameWinSound()
            SaveManager.shared.updateScore(level: currentLevel, score: score, stars: stars)
            SaveManager.shared.unlockLevel(min(currentLevel + 1, Levels.totalLevels))
        } else {
            AudioManager.shared.playGameFailSound()
            SaveManager.shared.updateScore(level: currentLevel, score: score, stars: 0)
        }

        bestScoreLabel.text = "最佳: \(max(previousBest, score))"

        let overlay = SKNode()
        overlay.zPosition = 100
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        resultOverlay = overlay
        addChild(overlay)

        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: frame.size)
        dim.position = .zero
        dim.zPosition = -1
        overlay.addChild(dim)

        let panel = SKShapeNode(rectOf: CGSize(width: min(frame.width * 0.82, 340), height: 310), cornerRadius: 24)
        panel.fillColor = UIColor(white: 1, alpha: 0.13)
        panel.strokeColor = UIColor(white: 1, alpha: 0.24)
        panel.lineWidth = 2
        panel.position = .zero
        overlay.addChild(panel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = success ? "通关成功" : "挑战失败"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 108)
        titleLabel.alpha = 0
        panel.addChild(titleLabel)

        let resultScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resultScoreLabel.text = "总分 \(score)"
        resultScoreLabel.fontSize = 28
        resultScoreLabel.fontColor = palette.accent
        resultScoreLabel.position = CGPoint(x: 0, y: 60)
        resultScoreLabel.alpha = 0
        panel.addChild(resultScoreLabel)

        let targetSummary = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        targetSummary.text = "目标 \(scorePlan.targetScore) · 用时 \(shotsFired) 发"
        targetSummary.fontSize = 15
        targetSummary.fontColor = UIColor(white: 0.92, alpha: 1)
        targetSummary.position = CGPoint(x: 0, y: 26)
        targetSummary.alpha = 0
        panel.addChild(targetSummary)

        if success {
            let bonusLine1 = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            bonusLine1.text = "剩余企鹅奖励 +\(bonusSummary.remainingPenguinBonus)"
            bonusLine1.fontSize = 15
            bonusLine1.fontColor = UIColor(white: 0.96, alpha: 1)
            bonusLine1.position = CGPoint(x: 0, y: -10)
            bonusLine1.alpha = 0
            panel.addChild(bonusLine1)

            let bonusLine2 = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            bonusLine2.text = "通关奖励 +\(bonusSummary.clearBonus)"
            bonusLine2.fontSize = 15
            bonusLine2.fontColor = UIColor(white: 0.96, alpha: 1)
            bonusLine2.position = CGPoint(x: 0, y: -34)
            bonusLine2.alpha = 0
            panel.addChild(bonusLine2)

            bonusLine1.run(.sequence([.wait(forDuration: 0.42), .fadeIn(withDuration: 0.24)]))
            bonusLine2.run(.sequence([.wait(forDuration: 0.52), .fadeIn(withDuration: 0.24)]))
        } else {
            let tipLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            tipLabel.text = "试试压低角度，优先打掉底层支点。"
            tipLabel.fontSize = 15
            tipLabel.fontColor = UIColor(white: 0.96, alpha: 1)
            tipLabel.position = CGPoint(x: 0, y: -22)
            tipLabel.alpha = 0
            panel.addChild(tipLabel)
            tipLabel.run(.sequence([.wait(forDuration: 0.42), .fadeIn(withDuration: 0.24)]))
        }

        let starsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        starsLabel.text = success ? String(repeating: "★", count: max(stars, 1)) : "未通关"
        starsLabel.fontSize = 28
        starsLabel.fontColor = success && stars > 0 ? UIColor(red: 1, green: 0.88, blue: 0.36, alpha: 1) : UIColor(white: 0.78, alpha: 1)
        starsLabel.position = CGPoint(x: 0, y: -68)
        starsLabel.alpha = 0
        panel.addChild(starsLabel)

        let primaryButtonTitle: String
        let primaryButtonName: String
        if success {
            primaryButtonTitle = currentLevel < Levels.totalLevels ? "下一关" : "完成冒险"
            primaryButtonName = "nextButton"
        } else {
            primaryButtonTitle = "重新挑战"
            primaryButtonName = "retryButton"
        }

        let primaryButton = makeOverlayButton(
            name: primaryButtonName,
            title: primaryButtonTitle,
            color: success ? UIColor(red: 0.26, green: 0.72, blue: 0.44, alpha: 1) : UIColor(red: 0.79, green: 0.36, blue: 0.34, alpha: 1),
            position: CGPoint(x: 0, y: -118)
        )
        primaryButton.alpha = 0
        panel.addChild(primaryButton)

        let backButton = makeOverlayButton(
            name: "resultBackButton",
            title: "返回选关",
            color: UIColor(white: 0.34, alpha: 0.92),
            position: CGPoint(x: 0, y: -166)
        )
        backButton.alpha = 0
        panel.addChild(backButton)

        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        titleLabel.run(.sequence([.wait(forDuration: 0.16), fadeIn]))
        resultScoreLabel.run(.sequence([.wait(forDuration: 0.28), fadeIn]))
        targetSummary.run(.sequence([.wait(forDuration: 0.36), fadeIn]))
        starsLabel.run(.sequence([.wait(forDuration: 0.62), fadeIn]))
        primaryButton.run(.sequence([.wait(forDuration: 0.78), fadeIn]))
        backButton.run(.sequence([.wait(forDuration: 0.88), fadeIn]))

        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                guard let self else { return }
                ParticleEffects.shared.playStarBurst(at: CGPoint(x: self.frame.midX, y: self.frame.midY + 12), in: self)
            }
        }
    }

    private func freezeGameplay() {
        trajectoryLine.isHidden = true
        trailEmitter?.removeFromParent()
        trailEmitter = nil
        activePenguin?.physicsBody = nil
        activePenguin = nil
        penguinNode?.removeAllActions()
        flightState = .stopped
    }

    private func applyVictoryBonuses() -> VictoryBonusSummary {
        let summary = VictoryBonusSummary(
            remainingPenguinBonus: max(0, penguinsRemaining) * GameScore.remainingPenguinBonus,
            clearBonus: Levels.levelClearBonus(for: currentLevel)
        )
        score += summary.total
        updateScoreDisplay()
        return summary
    }

    private func makeOverlayButton(name: String, title: String, color: UIColor, position: CGPoint) -> SKShapeNode {
        let button = makeButtonNode(width: 180, height: 40, name: name, color: color)
        button.position = position

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = title
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        return button
    }

    private func calculateStars() -> Int {
        if score >= scorePlan.threeStarScore { return 3 }
        if score >= scorePlan.twoStarScore { return 2 }
        if score >= scorePlan.oneStarScore { return 1 }
        return 0
    }

    private func goToNextLevel() {
        let nextLevel = currentLevel + 1
        guard nextLevel <= Levels.totalLevels else {
            dismiss(animated: true)
            return
        }

        let nextScene = GameScene(level: nextLevel)
        nextScene.scaleMode = .resizeFill
        nextScene.size = size
        view?.presentScene(nextScene, transition: .fade(withDuration: 0.3))
    }

    private func retryLevel() {
        let scene = GameScene(level: currentLevel)
        scene.scaleMode = .resizeFill
        scene.size = size
        view?.presentScene(scene, transition: .fade(withDuration: 0.3))
    }

    private func dismiss(animated: Bool) {
        guard let viewController = owningViewController() else {
            view?.window?.rootViewController?.dismiss(animated: animated)
            return
        }
        viewController.dismiss(animated: animated)
    }

    private func owningViewController() -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }

    // MARK: - Pause / Resume

    @objc private func appDidBecomeActive() {
        isPaused = false
        physicsWorld.speed = 1
    }

    @objc private func appWillResignActive() {
        isPaused = true
        physicsWorld.speed = 0
    }

    private func setupPauseNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
}
