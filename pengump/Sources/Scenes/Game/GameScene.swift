import SpriteKit
import AVFoundation

// MARK: - 物理常量

struct GamePhysics {
    static let maxPullDistance: CGFloat = 120.0
    static let minPullDistance: CGFloat = 20.0
    static let launchSpeedMultiplier: CGFloat = 0.15
    static let maxLaunchSpeed: CGFloat = 18.0
    static let gravity: CGFloat = 0.25
    static let airResistance: CGFloat = 0.99
    static let rubberBandElasticity: CGFloat = 0.4
    static let bounceDecay: CGFloat = 0.7
    static let stopThreshold: CGFloat = 0.5
    static let explosionRadius: CGFloat = 100.0
    static let explosionDamageRatio: CGFloat = 0.5
}

// MARK: - 得分常量

struct GameScore {
    static let normalIceBlock: Int = 100
    static let crackedIceBlock: Int = 200
    static let explosiveIceBlock: Int = 300
    static let comboMultiplier: Double = 1.5
    static let remainingPenguinBonus: Int = 200
}

// MARK: - 企鹅飞行状态

enum PenguinFlightState {
    case ready
    case aiming
    case flying
    case stopped
}

// MARK: - 冰块节点

class IceBlockNode: SKSpriteNode {
    var durability: Int = 1
    var maxDurability: Int = 1
    var blockType: IceBlockType = .normal
    var isBreaking: Bool = false

    convenience init(type: IceBlockType, size: CGSize) {
        let color = IceBlockNode.colorForType(type)
        self.init(color: color, size: size)
        self.blockType = type
        self.maxDurability = type.rawValue
        self.durability = self.maxDurability
        self.name = "iceBlock"
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupAppearance(type: type)
        setupPhysics(size: size)
    }

    private static func colorForType(_ type: IceBlockType) -> UIColor {
        switch type {
        case .normal:
            return UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.9)
        case .cracked:
            return UIColor(red: 0.5, green: 0.75, blue: 0.95, alpha: 0.9)
        case .explosive:
            return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.9)
        }
    }

    private func setupAppearance(type: IceBlockType) {
        let blockShape = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 4)
        blockShape.fillColor = IceBlockNode.colorForType(type)
        blockShape.strokeColor = UIColor(white: 1.0, alpha: 0.6)
        blockShape.lineWidth = 2
        blockShape.name = "blockShape"
        addChild(blockShape)

        let highlight = SKShapeNode(rectOf: CGSize(width: size.width * 0.6, height: 5), cornerRadius: 2)
        highlight.fillColor = UIColor(white: 1.0, alpha: 0.5)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: size.height * 0.3)
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
        for _ in 0..<3 {
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
            crack.name = "crack"
            crack.zPosition = 1
            addChild(crack)
        }
    }

    private func addExplosiveMarker() {
        let marker = SKShapeNode(circleOfRadius: 10)
        marker.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)
        marker.strokeColor = UIColor(red: 0.8, green: 0.2, blue: 0.0, alpha: 1.0)
        marker.lineWidth = 2
        marker.name = "explosiveMarker"
        addChild(marker)

        let exclLabel = SKLabelNode(text: "!")
        exclLabel.fontSize = 14
        exclLabel.fontColor = .white
        exclLabel.fontName = "BoldSystem"
        exclLabel.name = "exclLabel"
        exclLabel.position = CGPoint(x: 0, y: -5)
        marker.addChild(exclLabel)
    }

    private func setupPhysics(size: CGSize) {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width - 2, height: size.height - 2), center: .zero)
        physicsBody?.isDynamic = true
        physicsBody?.mass = 1.0
        physicsBody?.friction = 0.5
        physicsBody?.restitution = 0.2
        physicsBody?.categoryBitMask = 0b0001
        physicsBody?.collisionBitMask = 0b0010 | 0b0100 | 0b1000
        physicsBody?.contactTestBitMask = 0b0010
    }

    func takeDamage(_ amount: Int) -> Bool {
        durability -= amount
        if durability <= 0 {
            return true
        } else {
            if blockType == .cracked || blockType == .explosive {
                childNode(withName: "crack")?.removeFromParent()
                childNode(withName: "explosiveMarker")?.removeFromParent()
                if let shape = childNode(withName: "blockShape") as? SKShapeNode {
                    shape.fillColor = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.9)
                }
            }
            flash()
            return false
        }
    }

    func flash() {
        let whiteFlash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        run(whiteFlash)
    }

    func playBreakAnimation(completion: @escaping () -> Void) {
        guard !isBreaking else { return }
        isBreaking = true

        let whiteFlash = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05)
        let shrink = SKAction.group([
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.fadeOut(withDuration: 0.15)
        ])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([whiteFlash, shrink, remove])
        run(sequence) { completion() }

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
            fragment.position = self.position
            fragment.zPosition = self.zPosition - 1

            fragment.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: fragmentSize, height: fragmentSize))
            fragment.physicsBody?.isDynamic = true
            fragment.physicsBody?.mass = 0.1
            fragment.physicsBody?.applyImpulse(CGVector(dx: dx * 3, dy: dy * 3))
            fragment.physicsBody?.applyAngularImpulse(dx * 0.5)

            scene?.addChild(fragment)

            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            fragment.run(fadeOut)
        }
    }
}

// MARK: - 游戏主场景

class GameScene: SKScene {

    // MARK: - 游戏配置

    private let physics = GamePhysics.self
    private let scoreConfig = GameScore.self

    // MARK: - 游戏状态

    private var currentLevel: Int = 1
    private var penguinsRemaining: Int = 3
    private var score: Int = 0
    private var roundComboCount: Int = 0
    private var flightState: PenguinFlightState = .ready
    private var launchTime: TimeInterval = 0

    // MARK: - 关卡配置

    private var levelConfig: LevelConfig!
    private var iceBlocks: [IceBlockNode] = []
    private var iceBlockInitialPositions: [CGPoint] = []

    // MARK: - 节点引用

    private var slingshotBase: SKNode!
    private var leftBandNode: SKShapeNode!
    private var rightBandNode: SKShapeNode!
    private var penguinNode: SKSpriteNode!
    private var trajectoryLine: SKShapeNode!
    private var activePenguin: SKSpriteNode?
    private var penguinQueue: [SKSpriteNode] = []
    private var slingshotAnchorLeft: CGPoint = .zero
    private var slingshotAnchorRight: CGPoint = .zero
    private var trailEmitter: SKEmitterNode?

    // MARK: - UI节点

    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var penguinCountLabel: SKLabelNode!
    private var hintLabel: SKLabelNode!
    private var resultOverlay: SKNode?

    // MARK: - 初始化

    init(level: Int) {
        self.currentLevel = level
        self.levelConfig = Levels.config(for: level)
        self.penguinsRemaining = levelConfig.penguinCount
        super.init(size: .zero)
        self.backgroundColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        // 重置道具效果（跨关卡残留bug修复）
        ItemSystem.shared.resetForNewLevel()
        setupPauseNotifications()

        setupPhysicsWorld()
        setupSlingshot()
        setupPenguinQueue()
        setupTrajectoryLine()
        setupUI()
        setupIceBlocks()
        setupGround()
        reloadSlingshot()
    }

    // MARK: - 场景搭建

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -physics.gravity * 60)
        physicsWorld.speed = 1.0
    }

    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: frame.width, height: 40))
        ground.fillColor = UIColor(red: 0.85, green: 0.92, blue: 0.95, alpha: 1.0)
        ground.strokeColor = UIColor(red: 0.7, green: 0.85, blue: 0.9, alpha: 1.0)
        ground.lineWidth = 2
        ground.position = CGPoint(x: frame.width / 2, y: 20)
        ground.name = "ground"
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 40))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0b1000
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
        leftArm.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
        leftArm.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        leftArm.lineWidth = 2
        leftArm.position = CGPoint(x: -forkWidth / 2, y: postHeight / 2 + forkHeight / 2)
        leftArm.zPosition = 10

        let rightArm = SKShapeNode(rectOf: CGSize(width: postWidth, height: forkHeight), cornerRadius: 3)
        rightArm.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
        rightArm.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
        rightArm.lineWidth = 2
        rightArm.position = CGPoint(x: forkWidth / 2, y: postHeight / 2 + forkHeight / 2)
        rightArm.zPosition = 10

        let post = SKShapeNode(rectOf: CGSize(width: postWidth, height: postHeight), cornerRadius: 3)
        post.fillColor = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
        post.strokeColor = UIColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0)
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
        leftBandNode.strokeColor = UIColor(red: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)
        leftBandNode.lineWidth = 4
        leftBandNode.lineCap = .round
        leftBandNode.zPosition = 5
        addChild(leftBandNode)

        rightBandNode = SKShapeNode()
        rightBandNode.strokeColor = UIColor(red: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)
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
        let queueY = frame.height * 0.10
        let startX = frame.width * 0.06
        let spacing: CGFloat = 42

        for i in 0..<penguinsRemaining {
            let penguin = createPenguinNode()
            penguin.position = CGPoint(x: startX + CGFloat(i) * spacing, y: queueY)
            penguin.alpha = 0.6
            penguin.setScale(0.85)
            addChild(penguin)
            penguinQueue.append(penguin)
        }
    }

    private func createPenguinNode() -> SKSpriteNode {
        let penguin = SKSpriteNode()
        penguin.name = "penguin"

        let body = SKShapeNode(ellipseOf: CGSize(width: 26, height: 30))
        body.fillColor = UIColor(red: 0.306, green: 0.804, blue: 0.769, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.173, green: 0.467, blue: 0.451, alpha: 1.0)
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
        leftPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 1, y: 0)
        leftEye.addChild(leftPupil)

        let rightEye = SKShapeNode(circleOfRadius: 4)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 6, y: 6)
        penguin.addChild(rightEye)

        let rightPupil = SKShapeNode(circleOfRadius: 2)
        rightPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 1, y: 0)
        rightEye.addChild(rightPupil)

        let leftBlush = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        leftBlush.fillColor = UIColor(red: 1.0, green: 0.42, blue: 0.616, alpha: 0.5)
        leftBlush.strokeColor = .clear
        leftBlush.position = CGPoint(x: -10, y: 0)
        penguin.addChild(leftBlush)

        let rightBlush = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        rightBlush.fillColor = UIColor(red: 1.0, green: 0.42, blue: 0.616, alpha: 0.5)
        rightBlush.strokeColor = .clear
        rightBlush.position = CGPoint(x: 10, y: 0)
        penguin.addChild(rightBlush)

        let beak = SKShapeNode(ellipseOf: CGSize(width: 8, height: 5))
        beak.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.427, alpha: 1.0)
        beak.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0)
        beak.lineWidth = 1
        beak.position = CGPoint(x: 0, y: -1)
        penguin.addChild(beak)

        let leftWing = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
        leftWing.fillColor = UIColor(red: 0.306, green: 0.804, blue: 0.769, alpha: 1.0)
        leftWing.strokeColor = UIColor(red: 0.173, green: 0.467, blue: 0.451, alpha: 1.0)
        leftWing.lineWidth = 1.5
        leftWing.position = CGPoint(x: -14, y: 0)
        leftWing.zRotation = 0.2
        penguin.addChild(leftWing)

        let rightWing = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
        rightWing.fillColor = UIColor(red: 0.306, green: 0.804, blue: 0.769, alpha: 1.0)
        rightWing.strokeColor = UIColor(red: 0.173, green: 0.467, blue: 0.451, alpha: 1.0)
        rightWing.lineWidth = 1.5
        rightWing.position = CGPoint(x: 14, y: 0)
        rightWing.zRotation = -0.2
        penguin.addChild(rightWing)

        let feather = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 2)
        feather.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.427, alpha: 1.0)
        feather.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0)
        feather.lineWidth = 1
        feather.position = CGPoint(x: 0, y: 17)
        penguin.addChild(feather)

        return penguin
    }

    private func reloadSlingshot() {
        guard penguinNode == nil || flightState == .ready else { return }
        guard penguinsRemaining > 0 else { return }

        penguinNode = createPenguinNode()
        let launchPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        penguinNode.position = launchPos
        penguinNode.zPosition = 20
        addChild(penguinNode)
        updateBandPositions(penguinPos: launchPos)
        flightState = .ready
    }

    private func setupTrajectoryLine() {
        trajectoryLine = SKShapeNode()
        trajectoryLine.strokeColor = UIColor.gray.withAlphaComponent(0.4)
        trajectoryLine.lineWidth = 2
        trajectoryLine.isHidden = true
        trajectoryLine.zPosition = 15
        addChild(trajectoryLine)
    }

    private func setupUI() {
        let backBtn = SKShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 6)
        backBtn.fillColor = UIColor(white: 0.3, alpha: 0.8)
        backBtn.strokeColor = UIColor(white: 0.5, alpha: 0.8)
        backBtn.lineWidth = 1
        backBtn.position = CGPoint(x: 50, y: frame.height - 28)
        backBtn.name = "backButton"
        addChild(backBtn)

        let backLabel = SKLabelNode(text: "← 返回")
        backLabel.fontSize = 13
        backLabel.fontColor = .white
        backLabel.name = "backLabel"
        backLabel.position = CGPoint(x: 0, y: -4)
        backBtn.addChild(backLabel)

        scoreLabel = SKLabelNode(text: "分数: 0")
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        scoreLabel.fontName = "BoldSystem"
        scoreLabel.name = "scoreLabel"
        scoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 40)
        addChild(scoreLabel)

        levelLabel = SKLabelNode(text: "第 \(currentLevel) 关")
        levelLabel.fontSize = 18
        levelLabel.fontColor = UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        levelLabel.name = "levelLabel"
        levelLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 68)
        addChild(levelLabel)

        penguinCountLabel = SKLabelNode(text: "🐧 × \(penguinsRemaining)")
        penguinCountLabel.fontSize = 20
        penguinCountLabel.name = "countLabel"
        penguinCountLabel.position = CGPoint(x: frame.width - 55, y: frame.height - 40)
        addChild(penguinCountLabel)

        let targetLabel = SKLabelNode(text: "目标: \(levelConfig.targetScore)")
        targetLabel.fontSize = 14
        targetLabel.fontColor = UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)
        targetLabel.name = "targetLabel"
        targetLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 92)
        addChild(targetLabel)

        if let hint = levelConfig.hint {
            hintLabel = SKLabelNode(text: hint)
            hintLabel.fontSize = 16
            hintLabel.fontColor = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.8)
            hintLabel.name = "hintLabel"
            hintLabel.position = CGPoint(x: frame.width / 2, y: frame.height * 0.45)
            hintLabel.alpha = 0
            addChild(hintLabel)

            hintLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeIn(withDuration: 0.5),
                SKAction.wait(forDuration: 3.0),
                SKAction.fadeOut(withDuration: 1.0)
            ]))
        }
    }

    private func setupIceBlocks() {
        iceBlocks.removeAll()
        iceBlockInitialPositions.removeAll()
        for config in levelConfig.iceBlocks {
            let blockSize: CGFloat = 48
            let block = IceBlockNode(type: config.type, size: CGSize(width: blockSize, height: blockSize))
            let pos = CGPoint(x: frame.width * config.x, y: frame.height * config.y)
            block.position = pos
            block.zPosition = 8
            addChild(block)
            iceBlocks.append(block)
            iceBlockInitialPositions.append(pos)
        }
    }

    // MARK: - 触摸控制

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // 结果页面触摸处理
        if let overlay = resultOverlay {
            let overlayLocation = touch.location(in: overlay)
            if let nextBtn = overlay.childNode(withName: "nextButton"),
               nextBtn.frame.insetBy(dx: -10, dy: -10).contains(overlayLocation) {
                goToNextLevel()
                return
            }
            if let retryBtn = overlay.childNode(withName: "retryButton"),
               retryBtn.frame.insetBy(dx: -10, dy: -10).contains(overlayLocation) {
                retryLevel()
                return
            }
            if let backBtn = overlay.childNode(withName: "resultBackButton"),
               backBtn.frame.insetBy(dx: -10, dy: -10).contains(overlayLocation) {
                dismiss(animated: true)
                return
            }
            return
        }

        // 返回按钮
        if let backBtn = childNode(withName: "backButton"),
           backBtn.frame.insetBy(dx: -10, dy: -10).contains(location) {
            dismiss(animated: true)
            return
        }

        // 开始瞄准
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
        distance = min(distance, physics.maxPullDistance)

        var angle = atan2(dy, dx)
        let maxAngle: CGFloat = .pi * 0.85
        if angle > 0 { angle = min(angle, maxAngle) }
        else { angle = max(angle, -maxAngle) }

        let pullX = anchorPos.x - cos(angle) * distance
        let pullY = anchorPos.y - sin(angle) * distance
        let clampedPos = CGPoint(x: pullX, y: pullY)

        penguinNode?.position = clampedPos
        updateBandPositions(penguinPos: clampedPos)

        if distance >= physics.minPullDistance {
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

        if distance < physics.minPullDistance {
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

    // MARK: - 发射逻辑

    private func drawTrajectory() {
        guard let penguin = penguinNode else { return }

        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = anchorPos.x - penguin.position.x
        let dy = anchorPos.y - penguin.position.y

        var speed = sqrt(dx * dx + dy * dy) * physics.launchSpeedMultiplier
        speed = min(speed, physics.maxLaunchSpeed)

        let angle = atan2(dy, dx)
        var vx = cos(angle) * speed
        var vy = sin(angle) * speed

        var x = penguin.position.x
        var y = penguin.position.y

        let path = CGMutablePath()
        var firstPoint = true

        for _ in 0..<15 {
            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            vx *= physics.airResistance
            vy = vy * physics.airResistance - physics.gravity
            x += vx * 3
            y += vy * 3
            if y < 0 { break }
        }

        trajectoryLine.path = path
    }

    private func launchPenguin() {
        guard let penguin = penguinNode else { return }

        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)
        let dx = anchorPos.x - penguin.position.x
        let dy = anchorPos.y - penguin.position.y

        var speed = sqrt(dx * dx + dy * dy) * physics.launchSpeedMultiplier
        speed = min(speed, physics.maxLaunchSpeed)

        let angle = atan2(dy, dx)
        let vx = cos(angle) * speed
        let vy = sin(angle) * speed

        penguin.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        penguin.physicsBody?.isDynamic = true
        penguin.physicsBody?.mass = 1.0
        penguin.physicsBody?.categoryBitMask = 0b0010
        penguin.physicsBody?.collisionBitMask = 0b0001 | 0b0100 | 0b1000
        penguin.physicsBody?.contactTestBitMask = 0b0001
        penguin.physicsBody?.applyImpulse(CGVector(dx: vx, dy: vy))
        penguin.physicsBody?.allowsRotation = true

        activePenguin = penguin
        penguinNode = nil
        flightState = .flying
        roundComboCount = 0
        launchTime = CACurrentMediaTime()

        // 附加飞行轨迹粒子
        trailEmitter = ParticleEffects.shared.attachTrail(to: penguin)
        penguin.addChild(trailEmitter!)

        // 皮筋弹回动画
        animateBandsRelease()

        // 播放发射音效
        AudioManager.shared.playLaunchSound()

        // 更新队列
        penguinsRemaining -= 1
        updatePenguinCountDisplay()
        if !penguinQueue.isEmpty {
            penguinQueue.removeFirst()
            let queueY = frame.height * 0.10
            let startX = frame.width * 0.06
            let spacing: CGFloat = 42
            for (i, p) in penguinQueue.enumerated() {
                let move = SKAction.move(to: CGPoint(x: startX + CGFloat(i) * spacing, y: queueY), duration: 0.3)
                move.timingMode = .easeOut
                p.run(move)
            }
        }
    }

    private func animateBandsRelease() {
        let anchorPos = CGPoint(x: slingshotBase.position.x, y: slingshotAnchorLeft.y)

        let shrinkLeft = SKAction.move(to: CGPoint(
            x: (slingshotAnchorLeft.x + anchorPos.x) / 2,
            y: slingshotAnchorLeft.y - 10
        ), duration: 0.08)
        shrinkLeft.timingMode = .easeIn

        let shrinkRight = SKAction.move(to: CGPoint(
            x: (slingshotAnchorRight.x + anchorPos.x) / 2,
            y: slingshotAnchorRight.y - 10
        ), duration: 0.08)
        shrinkRight.timingMode = .easeIn

        let restoreLeft = SKAction.move(to: slingshotAnchorLeft, duration: 0.12)
        restoreLeft.timingMode = .easeOut

        let restoreRight = SKAction.move(to: slingshotAnchorRight, duration: 0.12)
        restoreRight.timingMode = .easeOut

        leftBandNode.run(SKAction.sequence([shrinkLeft, restoreLeft]))
        rightBandNode.run(SKAction.sequence([shrinkRight, restoreRight]))
        updateBandPositions(penguinPos: anchorPos)
    }

    // MARK: - 每帧更新

    override func update(_ currentTime: TimeInterval) {
        guard let penguin = activePenguin,
              let pb = penguin.physicsBody else { return }

        // 企鹅旋转跟随速度方向
        let vx = pb.velocity.dx
        let vy = pb.velocity.dy
        let speed = sqrt(vx * vx + vy * vy)
        if speed > 1.0 {
            let angle = atan2(vy, vx)
            penguin.zRotation = angle
        }

        // 边界反弹（左/右/上）
        if penguin.position.x < 20 {
            penguin.position.x = 20
            pb.velocity.dx = abs(pb.velocity.dx) * physics.bounceDecay
        }
        if penguin.position.x > frame.width - 20 {
            penguin.position.x = frame.width - 20
            pb.velocity.dx = -abs(pb.velocity.dx) * physics.bounceDecay
        }
        if penguin.position.y > frame.height - 20 {
            penguin.position.y = frame.height - 20
            pb.velocity.dy = -abs(pb.velocity.dy) * physics.bounceDecay
        }

        // 企鹅停止判定
        let timeSinceLaunch = currentTime - launchTime
        if timeSinceLaunch > 10.0 && speed < physics.stopThreshold {
            // 超时强制停止（企鹅被卡住时触发）
            penguin.physicsBody = nil
            penguin.removeFromParent()
            activePenguin = nil
            flightState = .stopped
            onPenguinStopped()
        } else if speed < physics.stopThreshold && penguin.position.y < slingshotBase.position.y + 50 {
            penguin.physicsBody = nil
            penguin.removeFromParent()
            activePenguin = nil
            flightState = .stopped
            onPenguinStopped()
        }
    }

    // MARK: - 物理碰撞

    override func didSimulatePhysics() {
        checkPenguinCollisions()
    }

    private func checkPenguinCollisions() {
        guard let penguin = activePenguin,
              let pb = penguin.physicsBody else { return }

        // 炸弹道具效果：对所有冰块造成爆炸伤害（不return，继续反弹逻辑）
        var bombTriggeredThisFrame = false
        if ItemSystem.shared.hasBomb {
            bombTriggeredThisFrame = true
            for block in iceBlocks where !block.isBreaking {
                let destroyed = block.takeDamage(block.maxDurability)
                if destroyed {
                    roundComboCount += 1
                    addScoreForBlock(block)
                    let blockRef = block
                    block.playBreakAnimation { [weak self] in
                        self?.iceBlocks.removeAll { $0 === blockRef }
                        self?.checkLevelComplete()
                    }
                }
            }
            ItemSystem.shared.consumeBomb()
            // 炸弹触发后仍然应用反弹，让企鹅改变方向继续飞行
            let penguinSpeed = sqrt(pb.velocity.dx * pb.velocity.dx + pb.velocity.dy * pb.velocity.dy)
            if penguinSpeed > 1.0 {
                let angle = atan2(pb.velocity.dy, pb.velocity.dx)
                let newSpeed = max(penguinSpeed * physics.bounceDecay, 3.0)
                pb.velocity.dx = cos(angle) * newSpeed
                pb.velocity.dy = sin(angle) * newSpeed
            }
        }

        if !bombTriggeredThisFrame {
            let penguinSpeed = sqrt(pb.velocity.dx * pb.velocity.dx + pb.velocity.dy * pb.velocity.dy)

            for block in iceBlocks {
                guard !block.isBreaking else { continue }
                let distance = hypot(penguin.position.x - block.position.x,
                                     penguin.position.y - block.position.y)
                if distance < 42 {
                    let damage = max(1, Int(penguinSpeed / 3))
                    let destroyed = block.takeDamage(damage)

                    // 企鹅反弹
                    let angle = atan2(pb.velocity.dy, pb.velocity.dx)
                    let newSpeed = penguinSpeed * physics.bounceDecay
                    pb.velocity.dx = cos(angle) * newSpeed
                    pb.velocity.dy = sin(angle) * newSpeed

                    if destroyed {
                        roundComboCount += 1
                        addScoreForBlock(block)
                        AudioManager.shared.playIceBreakSound()
                        ParticleEffects.shared.playExplosion(at: block.position, in: self)
                        let blockRef = block
                        block.playBreakAnimation { [weak self] in
                            self?.iceBlocks.removeAll { $0 === blockRef }
                            self?.checkLevelComplete()
                        }

                        if block.blockType == .explosive {
                            triggerExplosion(at: block.position, collidedBlock: block)
                        }
                    }

                    if roundComboCount >= 2 {
                        showComboEffect(count: roundComboCount, at: block.position)
                        ParticleEffects.shared.playCombo(at: block.position, in: self)
                    }
                    break
                }
            }
        }
    }

    private func triggerExplosion(at position: CGPoint, collidedBlock: IceBlockNode? = nil) {
        let explosionNode = SKShapeNode(circleOfRadius: physics.explosionRadius)
        explosionNode.fillColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.4)
        explosionNode.strokeColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
        explosionNode.lineWidth = 3
        explosionNode.position = position
        explosionNode.zPosition = 30
        explosionNode.alpha = 0
        addChild(explosionNode)

        AudioManager.shared.playExplosionSound()

        let expand = SKAction.scale(to: 1.5, duration: 0.15)
        expand.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.removeFromParent()
        explosionNode.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.03),
            SKAction.group([expand, fadeOut]),
            remove
        ]))

        for block in iceBlocks where !block.isBreaking {
            if let collided = collidedBlock, block === collided { continue }
            let dist = hypot(block.position.x - position.x, block.position.y - position.y)
            if dist < physics.explosionRadius && dist > 0 {
                let damage = max(1, Int(ceil(Float(block.maxDurability) * Float(physics.explosionDamageRatio))))
                let destroyed = block.takeDamage(damage)
                if destroyed {
                    roundComboCount += 1
                    addScoreForBlock(block)
                    AudioManager.shared.playIceBreakSound()
                    ParticleEffects.shared.playExplosion(at: block.position, in: self)
                    let blockRef = block
                    block.playBreakAnimation { [weak self] in
                        self?.iceBlocks.removeAll { $0 === blockRef }
                        self?.checkLevelComplete()
                    }
                }
            }
        }
    }

    private func addScoreForBlock(_ block: IceBlockNode) {
        var baseScore: Int
        switch block.blockType {
        case .normal: baseScore = GameScore.normalIceBlock
        case .cracked: baseScore = GameScore.crackedIceBlock
        case .explosive: baseScore = GameScore.explosiveIceBlock
        }

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
        penguinCountLabel.text = "🐧 × \(penguinsRemaining)"
    }

    private func showScorePopup(amount: Int, at position: CGPoint) {
        let popup = SKLabelNode(text: "+\(amount)")
        popup.fontSize = 18
        popup.fontColor = .white
        popup.fontName = "BoldSystem"
        popup.position = CGPoint(x: position.x, y: position.y + 30)
        popup.zPosition = 50
        popup.alpha = 0
        addChild(popup)

        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        rise.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        popup.run(SKAction.sequence([
            SKAction.group([SKAction.fadeIn(withDuration: 0.1), rise]),
            fadeOut,
            remove
        ]))
    }

    private func showComboEffect(count: Int, at position: CGPoint) {
        let comboLabel = SKLabelNode(text: "Combo ×\(count)!")
        comboLabel.fontSize = 24
        comboLabel.fontName = "BoldSystem"
        comboLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 + 50)
        comboLabel.zPosition = 60
        comboLabel.alpha = 0
        addChild(comboLabel)

        if count >= 4 {
            comboLabel.fontColor = UIColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 1.0)
        } else if count >= 3 {
            comboLabel.fontColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        } else {
            comboLabel.fontColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        }

        comboLabel.setScale(0.5)
        let popIn = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()

        comboLabel.run(SKAction.sequence([
            SKAction.group([popIn, fadeIn]),
            SKAction.wait(forDuration: 0.5),
            fadeOut,
            remove
        ]))
    }

    // MARK: - 回合结束

    private func onPenguinStopped() {
        // 清理飞行轨迹粒子
        trailEmitter?.removeFromParent()
        trailEmitter = nil

        // 重置道具效果：将所有冰块恢复到初始位置
        if ItemSystem.shared.hasReset {
            resetIceBlocks()
            ItemSystem.shared.consumeReset()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkLevelComplete()
        }
    }

    /// 将所有冰块恢复到初始位置和状态
    private func resetIceBlocks() {
        for (index, block) in iceBlocks.enumerated() where index < iceBlockInitialPositions.count {
            let pos = iceBlockInitialPositions[index]
            block.position = pos
            block.durability = block.maxDurability
            block.alpha = 1.0
            block.isHidden = false
            block.isBreaking = false
        }
    }

    // MARK: - 关卡判定

    private func checkLevelComplete() {
        // 每次关卡结算时增加插屏广告计数器
        AdManager.shared.incrementInterstitialCounter()

        let activeBlocks = iceBlocks.filter { !$0.isBreaking && $0.parent != nil }
        if activeBlocks.isEmpty {
            showResult(success: true)
        } else if penguinsRemaining <= 0 {
            showResult(success: false)
        } else {
            reloadSlingshot()
        }
    }

    private func showResult(success: Bool) {
        // 播放结果音效
        if success {
            AudioManager.shared.playGameWinSound()
        } else {
            AudioManager.shared.playGameFailSound()
        }

        // 保存分数和解锁关卡
        let stars = calculateStars()
        if success {
            SaveManager.shared.updateScore(level: currentLevel, score: score, stars: stars)
            SaveManager.shared.unlockLevel(currentLevel + 1)
            // 通关奖励金币
            SaveManager.shared.addCoins(stars * 20)
        } else {
            SaveManager.shared.updateScore(level: currentLevel, score: score, stars: 0)
        }

        resultOverlay = SKNode()
        resultOverlay?.zPosition = 100
        resultOverlay?.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        addChild(resultOverlay!)

        let overlayBg = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
        overlayBg.fillColor = UIColor(white: 0, alpha: 0.5)
        overlayBg.strokeColor = .clear
        overlayBg.position = CGPoint(x: -frame.width / 2, y: -frame.height / 2)
        resultOverlay?.addChild(overlayBg)

        let titleLabel = SKLabelNode(text: success ? "🎉 通关！" : "💔 失败")
        titleLabel.fontSize = 48
        titleLabel.fontColor = success ? .green : .red
        titleLabel.fontName = "BoldSystem"
        titleLabel.position = CGPoint(x: 0, y: 80)
        titleLabel.alpha = 0
        resultOverlay?.addChild(titleLabel)

        let scoreText = "本关得分: \(score)"
        let scoreResultLabel = SKLabelNode(text: scoreText)
        scoreResultLabel.fontSize = 22
        scoreResultLabel.fontColor = .white
        scoreResultLabel.position = CGPoint(x: 0, y: 20)
        scoreResultLabel.alpha = 0
        resultOverlay?.addChild(scoreResultLabel)

        let starsLabel = SKLabelNode(text: String(repeating: "⭐", count: stars))
        starsLabel.fontSize = 36
        starsLabel.position = CGPoint(x: 0, y: -20)
        starsLabel.alpha = 0
        resultOverlay?.addChild(starsLabel)

        let btnLabel = success ? "下一关 →" : "重试"
        let actionBtn = SKShapeNode(rectOf: CGSize(width: 160, height: 48), cornerRadius: 10)
        actionBtn.fillColor = success ? UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0) : UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        actionBtn.strokeColor = .white
        actionBtn.lineWidth = 2
        actionBtn.position = CGPoint(x: 0, y: -90)
        actionBtn.name = success ? "nextButton" : "retryButton"
        actionBtn.alpha = 0
        resultOverlay?.addChild(actionBtn)

        let btnText = SKLabelNode(text: btnLabel)
        btnText.fontSize = 18
        btnText.fontColor = .white
        btnText.fontName = "BoldSystem"
        btnText.position = CGPoint(x: 0, y: -4)
        actionBtn.addChild(btnText)

        if success && currentLevel < Levels.totalLevels {
            let backBtn = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 8)
            backBtn.fillColor = UIColor(white: 0.4, alpha: 0.8)
            backBtn.strokeColor = .white
            backBtn.lineWidth = 1
            backBtn.position = CGPoint(x: 0, y: -150)
            backBtn.name = "resultBackButton"
            backBtn.alpha = 0
            resultOverlay?.addChild(backBtn)

            let backBtnText = SKLabelNode(text: "← 返回选关")
            backBtnText.fontSize = 14
            backBtnText.fontColor = .white
            backBtnText.position = CGPoint(x: 0, y: -3)
            backBtn.addChild(backBtnText)
        }

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        titleLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), fadeIn]))
        scoreResultLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.4), fadeIn]))
        starsLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.6), fadeIn]))
        // 通关时播放星星爆发特效
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                guard let self = self else { return }
                ParticleEffects.shared.playStarBurst(at: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2), in: self)
            }
        }
        actionBtn.run(SKAction.sequence([SKAction.wait(forDuration: 0.8), fadeIn]))
        if success && currentLevel < Levels.totalLevels {
            resultOverlay?.childNode(withName: "resultBackButton")?.run(SKAction.sequence([SKAction.wait(forDuration: 0.9), fadeIn]))
        }

        isUserInteractionEnabled = true

        // 检查是否需要展示插屏广告
        if let vc = view?.window?.rootViewController {
            AdManager.shared.showInterstitialIfDue(forLevel: currentLevel, from: vc)
        }
    }

    private func calculateStars() -> Int {
        if score >= levelConfig.threeStarScore { return 3 }
        if score >= levelConfig.twoStarScore { return 2 }
        if score >= levelConfig.oneStarScore { return 1 }
        return 0
    }

    private func goToNextLevel() {
        let nextLevel = currentLevel + 1
        guard nextLevel <= Levels.totalLevels else {
            dismiss(animated: true)
            return
        }
        let scene = GameScene(level: nextLevel)
        scene.scaleMode = .resizeFill
        scene.size = self.size
        view?.presentScene(scene, transition: .fade(withDuration: 0.3))
    }

    private func retryLevel() {
        let scene = GameScene(level: currentLevel)
        scene.scaleMode = .resizeFill
        scene.size = self.size
        view?.presentScene(scene, transition: .fade(withDuration: 0.3))
    }

    private func dismiss(animated: Bool) {
        view?.window?.rootViewController?.dismiss(animated: animated)
    }

    // MARK: - Pause / Resume
    @objc private func appDidBecomeActive() {
        isPaused = false
        physicsWorld.speed = 1.0
    }

    @objc private func appWillResignActive() {
        isPaused = true
        physicsWorld.speed = 0.0
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