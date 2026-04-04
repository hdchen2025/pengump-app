import SpriteKit

// MARK: - 物理常量

struct GamePhysics {
    static let maxPullDistance: CGFloat = 138.0
    static let minPullDistance: CGFloat = 18.0
    static let launchSpeedMultiplier: CGFloat = 0.72
    static let minimumLaunchSpeed: CGFloat = 46.0
    static let maxLaunchSpeed: CGFloat = 112.0
    static let minimumSwingAngle: CGFloat = .pi / 10
    static let maximumSwingAngle: CGFloat = .pi * 0.46
    static let minimumSwingPowerToLaunch: CGFloat = 0.10
    static let gravity: CGFloat = 0.22
    static let airResistance: CGFloat = 0.992
    static let rubberBandElasticity: CGFloat = 0.4
    static let bounceDecay: CGFloat = 0.74
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
        physicsBody?.isDynamic = false
        physicsBody?.affectedByGravity = false
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
    private var groundedSince: TimeInterval?
    private var battlefieldSize: CGSize = .zero
    private var gameCamera: SKCameraNode!
    private let hudNode = SKNode()
    private var introPreviewRunning: Bool = false
    private var swingPivotNode: SKNode!
    private var batNode: SKShapeNode!
    private var aimAngle: CGFloat = GamePhysics.minimumSwingAngle
    private var aimPower: CGFloat = 0

    // MARK: - UI节点

    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var penguinCountLabel: SKLabelNode!
    private var powerMeterLabel: SKLabelNode!
    private var powerMeterFillNode: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var resultOverlay: SKNode?
    private var hasPresentedResult: Bool = false

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
        setupPauseNotifications()

        setupBattlefieldMetrics()
        setupPhysicsWorld()
        setupSlingshot()
        setupCamera()
        setupPenguinQueue()
        setupTrajectoryLine()
        setupUI()
        setupIceBlocks()
        setupGround()
        reloadSlingshot()
        runIntroFlyoverIfNeeded()
    }

    // MARK: - 场景搭建

    private func setupBattlefieldMetrics() {
        battlefieldSize = CGSize(
            width: max(size.width * 2.0, 900),
            height: max(size.height * 1.45, 1100)
        )
    }

    private func setupCamera() {
        let cameraNode = SKCameraNode()
        gameCamera = cameraNode
        gameCamera.position = homeCameraFocus()
        addChild(cameraNode)
        camera = cameraNode

        hudNode.position = .zero
        gameCamera.addChild(hudNode)
    }

    private func clampCameraPosition(_ position: CGPoint) -> CGPoint {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let minX = halfWidth
        let maxX = max(minX, battlefieldSize.width - halfWidth)
        let minY = halfHeight
        let maxY = max(minY, battlefieldSize.height - halfHeight)

        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }

    private func homeCameraFocus() -> CGPoint {
        let slingshotX = slingshotBase?.position.x ?? size.width * 0.18
        let slingshotY = slingshotBase?.position.y ?? size.height * 0.22
        return clampCameraPosition(
            CGPoint(
                x: slingshotX + size.width * 0.32,
                y: slingshotY + size.height * 0.28
            )
        )
    }

    private func previewCameraFocus() -> CGPoint {
        guard let firstBlock = iceBlocks.first else { return homeCameraFocus() }

        var bounds = firstBlock.calculateAccumulatedFrame()
        for block in iceBlocks.dropFirst() {
            bounds = bounds.union(block.calculateAccumulatedFrame())
        }

        return clampCameraPosition(
            CGPoint(
                x: bounds.midX,
                y: bounds.midY + size.height * 0.06
            )
        )
    }

    private func followCameraFocus() -> CGPoint {
        guard let penguin = activePenguin else { return homeCameraFocus() }

        let velocity = penguin.physicsBody?.velocity ?? .zero
        let leadX = max(size.width * 0.14, min(size.width * 0.24, abs(velocity.dx) * 4.0))
        let leadY = max(size.height * 0.08, min(size.height * 0.18, max(0, velocity.dy) * 4.0))

        return clampCameraPosition(
            CGPoint(
                x: penguin.position.x + leadX,
                y: max(homeCameraFocus().y, penguin.position.y + leadY)
            )
        )
    }

    private func updateCameraPosition() {
        guard let gameCamera else { return }
        guard !introPreviewRunning else { return }

        let target = (activePenguin != nil && flightState == .flying) ? followCameraFocus() : homeCameraFocus()
        gameCamera.position.x += (target.x - gameCamera.position.x) * 0.14
        gameCamera.position.y += (target.y - gameCamera.position.y) * 0.14
    }

    private func runIntroFlyoverIfNeeded() {
        guard let gameCamera else { return }

        let home = homeCameraFocus()
        let preview = previewCameraFocus()
        guard abs(preview.x - home.x) > size.width * 0.22 || abs(preview.y - home.y) > size.height * 0.16 else {
            gameCamera.position = home
            return
        }

        let moveOut = SKAction.move(to: preview, duration: 0.85)
        moveOut.timingMode = .easeInEaseOut

        let moveBack = SKAction.move(to: home, duration: 0.8)
        moveBack.timingMode = .easeInEaseOut

        introPreviewRunning = true
        isUserInteractionEnabled = false
        gameCamera.position = home
        gameCamera.run(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.2),
                moveOut,
                SKAction.wait(forDuration: 0.35),
                moveBack
            ])
        ) { [weak self] in
            self?.introPreviewRunning = false
            self?.isUserInteractionEnabled = true
        }
    }

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -physics.gravity * 60)
        physicsWorld.speed = 1.0
    }

    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: battlefieldSize.width, height: 40))
        ground.fillColor = UIColor(red: 0.85, green: 0.92, blue: 0.95, alpha: 1.0)
        ground.strokeColor = UIColor(red: 0.7, green: 0.85, blue: 0.9, alpha: 1.0)
        ground.lineWidth = 2
        ground.position = CGPoint(x: battlefieldSize.width / 2, y: 20)
        ground.name = "ground"
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: battlefieldSize.width, height: 40))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0b1000
        addChild(ground)
    }

    private func setupSlingshot() {
        let baseX = frame.width * 0.16
        let baseY = frame.height * 0.17

        slingshotBase = SKNode()
        slingshotBase.position = CGPoint(x: baseX, y: baseY)
        addChild(slingshotBase)

        let platform = SKShapeNode(rectOf: CGSize(width: 150, height: 18), cornerRadius: 9)
        platform.fillColor = UIColor(red: 0.81, green: 0.71, blue: 0.56, alpha: 1.0)
        platform.strokeColor = UIColor(red: 0.54, green: 0.42, blue: 0.25, alpha: 1.0)
        platform.lineWidth = 2
        platform.position = CGPoint(x: 34, y: 10)
        slingshotBase.addChild(platform)

        let body = SKShapeNode(ellipseOf: CGSize(width: 34, height: 58))
        body.fillColor = UIColor(red: 0.96, green: 0.42, blue: 0.36, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.65, green: 0.18, blue: 0.14, alpha: 1.0)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 44)
        slingshotBase.addChild(body)

        let head = SKShapeNode(circleOfRadius: 15)
        head.fillColor = UIColor(red: 1.0, green: 0.89, blue: 0.73, alpha: 1.0)
        head.strokeColor = UIColor(red: 0.72, green: 0.58, blue: 0.42, alpha: 1.0)
        head.lineWidth = 2
        head.position = CGPoint(x: 0, y: 84)
        slingshotBase.addChild(head)

        let visor = SKShapeNode(rectOf: CGSize(width: 18, height: 6), cornerRadius: 3)
        visor.fillColor = UIColor(red: 0.16, green: 0.2, blue: 0.28, alpha: 1.0)
        visor.strokeColor = .clear
        visor.position = CGPoint(x: 6, y: 1)
        head.addChild(visor)

        let tee = SKShapeNode(rectOf: CGSize(width: 14, height: 26), cornerRadius: 4)
        tee.fillColor = UIColor(red: 0.38, green: 0.46, blue: 0.54, alpha: 1.0)
        tee.strokeColor = UIColor(red: 0.22, green: 0.28, blue: 0.34, alpha: 1.0)
        tee.lineWidth = 2
        tee.position = CGPoint(x: 66, y: 25)
        slingshotBase.addChild(tee)

        let teeTop = SKShapeNode(rectOf: CGSize(width: 26, height: 8), cornerRadius: 4)
        teeTop.fillColor = UIColor(red: 0.63, green: 0.74, blue: 0.82, alpha: 1.0)
        teeTop.strokeColor = .clear
        teeTop.position = CGPoint(x: 0, y: 9)
        tee.addChild(teeTop)

        swingPivotNode = SKNode()
        swingPivotNode.position = CGPoint(x: baseX + 12, y: baseY + 60)
        addChild(swingPivotNode)

        batNode = SKShapeNode(rectOf: CGSize(width: 64, height: 10), cornerRadius: 5)
        batNode.fillColor = UIColor(red: 0.45, green: 0.27, blue: 0.13, alpha: 1.0)
        batNode.strokeColor = UIColor(red: 0.25, green: 0.14, blue: 0.06, alpha: 1.0)
        batNode.lineWidth = 2
        batNode.position = CGPoint(x: 34, y: 0)
        swingPivotNode.addChild(batNode)

        let grip = SKShapeNode(rectOf: CGSize(width: 16, height: 12), cornerRadius: 4)
        grip.fillColor = UIColor(red: 0.19, green: 0.12, blue: 0.08, alpha: 1.0)
        grip.strokeColor = .clear
        grip.position = CGPoint(x: -22, y: 0)
        batNode.addChild(grip)

        let maceHead = SKShapeNode(circleOfRadius: 13)
        maceHead.fillColor = UIColor(red: 0.34, green: 0.39, blue: 0.47, alpha: 1.0)
        maceHead.strokeColor = UIColor(red: 0.2, green: 0.24, blue: 0.3, alpha: 1.0)
        maceHead.lineWidth = 2
        maceHead.position = CGPoint(x: 28, y: 0)
        batNode.addChild(maceHead)

        for index in 0..<6 {
            let spikePath = CGMutablePath()
            spikePath.move(to: CGPoint(x: 0, y: 0))
            spikePath.addLine(to: CGPoint(x: 10, y: 2))
            spikePath.addLine(to: CGPoint(x: 0, y: 4))
            spikePath.closeSubpath()

            let spike = SKShapeNode(path: spikePath)
            spike.fillColor = UIColor(red: 0.72, green: 0.77, blue: 0.84, alpha: 1.0)
            spike.strokeColor = UIColor(red: 0.26, green: 0.31, blue: 0.37, alpha: 1.0)
            spike.lineWidth = 1.2
            let rotation = CGFloat(index) * (.pi / 3)
            spike.zRotation = rotation
            spike.position = CGPoint(
                x: cos(rotation) * 11,
                y: sin(rotation) * 11
            )
            maceHead.addChild(spike)
        }

        leftBandNode = SKShapeNode()
        leftBandNode.strokeColor = UIColor(red: 0.98, green: 0.62, blue: 0.25, alpha: 0.7)
        leftBandNode.lineWidth = 4
        leftBandNode.lineCap = .round
        leftBandNode.zPosition = 7
        addChild(leftBandNode)

        rightBandNode = SKShapeNode()
        rightBandNode.strokeColor = UIColor(red: 0.98, green: 0.82, blue: 0.38, alpha: 0.55)
        rightBandNode.lineWidth = 2
        rightBandNode.lineCap = .round
        rightBandNode.zPosition = 6
        addChild(rightBandNode)

        slingshotAnchorLeft = swingPivotNode.position
        slingshotAnchorRight = penguinReadyPosition()
        aimAngle = .pi / 4.6
        aimPower = 0.42
        updateSwingAimingVisuals(showTrajectory: true)
    }

    private func penguinReadyPosition() -> CGPoint {
        CGPoint(x: slingshotBase.position.x + 66, y: slingshotBase.position.y + 38)
    }

    private func aimOrigin() -> CGPoint {
        penguinNode?.position ?? penguinReadyPosition()
    }

    private func strikeOrigin() -> CGPoint {
        swingPivotNode?.position ?? CGPoint(x: slingshotBase.position.x + 12, y: slingshotBase.position.y + 60)
    }

    private func updateSwingAimingVisuals(showTrajectory: Bool) {
        let launchOrigin = aimOrigin()
        let swingOrigin = strikeOrigin()
        let guideLength = 56 + aimPower * 120
        let primaryTip = CGPoint(
            x: launchOrigin.x + cos(aimAngle) * guideLength,
            y: launchOrigin.y + sin(aimAngle) * guideLength
        )
        let secondaryTip = CGPoint(
            x: launchOrigin.x + cos(aimAngle + 0.08) * (guideLength * 0.88),
            y: launchOrigin.y + sin(aimAngle + 0.08) * (guideLength * 0.88)
        )

        let primaryPath = CGMutablePath()
        primaryPath.move(to: launchOrigin)
        primaryPath.addLine(to: primaryTip)
        leftBandNode.path = primaryPath
        leftBandNode.alpha = showTrajectory ? 1.0 : 0.32

        let secondaryPath = CGMutablePath()
        secondaryPath.move(to: swingOrigin)
        secondaryPath.addLine(to: launchOrigin)
        secondaryPath.addLine(to: secondaryTip)
        rightBandNode.path = secondaryPath
        rightBandNode.alpha = showTrajectory ? 0.82 : 0.22

        let cockedBackAngle = aimAngle - (0.68 + aimPower * 0.34)
        swingPivotNode.zRotation = cockedBackAngle
        if trajectoryLine != nil {
            trajectoryLine.isHidden = !showTrajectory
        }
        updatePowerMeter()
    }

    private func setupPenguinQueue() {
        for i in 0..<max(penguinsRemaining - 1, 0) {
            let penguin = createPenguinNode()
            penguin.position = reservePenguinPosition(at: i)
            penguin.alpha = 0.6
            penguin.setScale(0.85)
            hudNode.addChild(penguin)
            penguinQueue.append(penguin)
        }
    }

    private func reservePenguinPosition(at index: Int) -> CGPoint {
        let leftEdge = -size.width / 2
        let bottomEdge = -size.height / 2
        let spacing: CGFloat = 42
        return CGPoint(
            x: leftEdge + 34 + CGFloat(index) * spacing,
            y: bottomEdge + 70
        )
    }

    private func createPenguinNode() -> SKSpriteNode {
        let penguin = SKSpriteNode(color: .clear, size: CGSize(width: 36, height: 42))
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
        guard penguinNode == nil, activePenguin == nil, penguinsRemaining > 0 else { return }

        penguinNode = createPenguinNode()
        let launchPos = penguinReadyPosition()
        penguinNode.position = launchPos
        penguinNode.zPosition = 20
        addChild(penguinNode)
        aimAngle = .pi / 4.6
        aimPower = 0.42
        updateSwingAimingVisuals(showTrajectory: true)
        drawTrajectory()
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
        let leftEdge = -size.width / 2
        let rightEdge = size.width / 2
        let topEdge = size.height / 2

        let backBtn = SKShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 6)
        backBtn.fillColor = UIColor(white: 0.3, alpha: 0.8)
        backBtn.strokeColor = UIColor(white: 0.5, alpha: 0.8)
        backBtn.lineWidth = 1
        backBtn.position = CGPoint(x: leftEdge + 50, y: topEdge - 28)
        backBtn.name = "backButton"
        hudNode.addChild(backBtn)

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
        scoreLabel.position = CGPoint(x: 0, y: topEdge - 40)
        hudNode.addChild(scoreLabel)

        levelLabel = SKLabelNode(text: "第 \(currentLevel) 关")
        levelLabel.fontSize = 18
        levelLabel.fontColor = UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        levelLabel.name = "levelLabel"
        levelLabel.position = CGPoint(x: 0, y: topEdge - 68)
        hudNode.addChild(levelLabel)

        penguinCountLabel = SKLabelNode(text: "🐧 × \(penguinsRemaining)")
        penguinCountLabel.fontSize = 20
        penguinCountLabel.name = "countLabel"
        penguinCountLabel.position = CGPoint(x: rightEdge - 55, y: topEdge - 40)
        hudNode.addChild(penguinCountLabel)

        powerMeterLabel = SKLabelNode(text: "力度 42%")
        powerMeterLabel.fontSize = 14
        powerMeterLabel.fontColor = UIColor(red: 0.84, green: 0.42, blue: 0.16, alpha: 1.0)
        powerMeterLabel.fontName = "BoldSystem"
        powerMeterLabel.position = CGPoint(x: rightEdge - 90, y: topEdge - 68)
        hudNode.addChild(powerMeterLabel)

        let powerMeterBg = SKShapeNode(rectOf: CGSize(width: 128, height: 16), cornerRadius: 8)
        powerMeterBg.fillColor = UIColor(white: 1.0, alpha: 0.18)
        powerMeterBg.strokeColor = UIColor(red: 0.74, green: 0.58, blue: 0.28, alpha: 0.85)
        powerMeterBg.lineWidth = 1.5
        powerMeterBg.position = CGPoint(x: rightEdge - 90, y: topEdge - 88)
        hudNode.addChild(powerMeterBg)

        powerMeterFillNode = SKSpriteNode(
            color: UIColor(red: 0.98, green: 0.62, blue: 0.25, alpha: 1.0),
            size: CGSize(width: 120, height: 10)
        )
        powerMeterFillNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        powerMeterFillNode.position = CGPoint(x: powerMeterBg.position.x - 60, y: powerMeterBg.position.y)
        hudNode.addChild(powerMeterFillNode)

        let targetLabel = SKLabelNode(text: "目标: \(levelConfig.targetScore)")
        targetLabel.fontSize = 14
        targetLabel.fontColor = UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)
        targetLabel.name = "targetLabel"
        targetLabel.position = CGPoint(x: 0, y: topEdge - 92)
        hudNode.addChild(targetLabel)

        if let hint = levelConfig.hint {
            hintLabel = SKLabelNode(text: hint)
            hintLabel.fontSize = 16
            hintLabel.fontColor = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.8)
            hintLabel.name = "hintLabel"
            hintLabel.position = CGPoint(x: 0, y: size.height * 0.10)
            hintLabel.alpha = 0
            hudNode.addChild(hintLabel)

            hintLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.2),
                SKAction.fadeIn(withDuration: 0.5),
                SKAction.wait(forDuration: 3.0),
                SKAction.fadeOut(withDuration: 1.0)
            ]))
        }

        updatePowerMeter()
    }

    private func setupIceBlocks() {
        iceBlocks.removeAll()
        for config in levelConfig.iceBlocks {
            let blockSize: CGFloat = 48
            let block = IceBlockNode(type: config.type, size: CGSize(width: blockSize, height: blockSize))
            let pos = CGPoint(
                x: min(battlefieldSize.width - 60, battlefieldSize.width * config.x),
                y: min(battlefieldSize.height - 80, size.height * 0.18 + battlefieldSize.height * config.y)
            )
            block.position = pos
            block.zPosition = 8
            addChild(block)
            iceBlocks.append(block)
        }
    }

    private func hitFrame(for node: SKNode, expandBy: CGFloat = 0) -> CGRect {
        node.calculateAccumulatedFrame().insetBy(dx: -expandBy, dy: -expandBy)
    }

    private func updatePowerMeter() {
        guard powerMeterFillNode != nil, powerMeterLabel != nil else { return }

        let clampedPower = max(0, min(aimPower, 1))
        powerMeterFillNode.xScale = max(0.04, clampedPower)
        powerMeterFillNode.alpha = clampedPower > 0.01 ? 1.0 : 0.32
        powerMeterLabel.text = "力度 \(Int((clampedPower * 100).rounded()))%"
    }

    private func isNodeInteractable(_ node: SKNode?, minimumAlpha: CGFloat = 0.95) -> Bool {
        guard let node else { return false }
        return node.parent != nil && !node.isHidden && node.alpha >= minimumAlpha
    }

    private func canStartAiming(at location: CGPoint) -> Bool {
        guard let penguin = penguinNode else { return false }

        let strikePos = strikeOrigin()
        let strikeHitZone = CGRect(
            x: strikePos.x - 56,
            y: strikePos.y - 56,
            width: 112,
            height: 112
        )
        let launchPos = aimOrigin()
        let launchHitZone = CGRect(
            x: launchPos.x - 64,
            y: launchPos.y - 64,
            width: 128,
            height: 128
        )

        return hitFrame(for: penguin, expandBy: 28).contains(location)
            || strikeHitZone.contains(location)
            || launchHitZone.contains(location)
    }

    private func clearGroundedState() {
        groundedSince = nil
    }

    private func finishActivePenguin() {
        guard let penguin = activePenguin else { return }

        penguin.physicsBody = nil
        penguin.removeFromParent()
        activePenguin = nil
        flightState = .stopped
        clearGroundedState()
        onPenguinStopped()
    }

    // MARK: - 触摸控制

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hudLocation = touch.location(in: hudNode)

        // 结果页面触摸处理
        if let overlay = resultOverlay {
            let overlayLocation = touch.location(in: overlay)
            if let nextBtn = overlay.childNode(withName: "nextButton"),
               isNodeInteractable(nextBtn),
               hitFrame(for: nextBtn, expandBy: 10).contains(overlayLocation) {
                goToNextLevel()
                return
            }
            if let retryBtn = overlay.childNode(withName: "retryButton"),
               isNodeInteractable(retryBtn),
               hitFrame(for: retryBtn, expandBy: 10).contains(overlayLocation) {
                retryLevel()
                return
            }
            if let backBtn = overlay.childNode(withName: "resultBackButton"),
               isNodeInteractable(backBtn),
               hitFrame(for: backBtn, expandBy: 10).contains(overlayLocation) {
                dismiss(animated: true)
                return
            }
            return
        }

        // 返回按钮
        if let backBtn = hudNode.childNode(withName: "backButton"),
           hitFrame(for: backBtn, expandBy: 10).contains(hudLocation) {
            dismiss(animated: true)
            return
        }

        // 开始瞄准
        if flightState == .ready,
           canStartAiming(at: location) {
            flightState = .aiming
            updateSwingAim(at: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard flightState == .aiming, let touch = touches.first else { return }

        let location = touch.location(in: self)
        updateSwingAim(at: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard flightState == .aiming else { return }

        if let touch = touches.first {
            updateSwingAim(at: touch.location(in: self))
        }

        if aimPower < physics.minimumSwingPowerToLaunch {
            aimPower = 0.42
            aimAngle = .pi / 4.6
            updateSwingAimingVisuals(showTrajectory: true)
            drawTrajectory()
            flightState = .ready
            return
        }

        launchPenguin()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - 发射逻辑

    private func updateSwingAim(at location: CGPoint) {
        let origin = aimOrigin()
        let forward = max(location.x - origin.x, 0)
        let lift = max(location.y - origin.y, 0)
        let dx = max(forward, 12)
        let rawAngle = atan2(lift, dx)
        aimAngle = min(max(rawAngle, physics.minimumSwingAngle), physics.maximumSwingAngle)

        let distance = min(hypot(forward, lift), physics.maxPullDistance)
        let normalizedDistance = max(0, distance - physics.minPullDistance)
        let powerDenominator = max(1, physics.maxPullDistance - physics.minPullDistance)
        aimPower = min(1, normalizedDistance / powerDenominator)

        updateSwingAimingVisuals(showTrajectory: aimPower >= physics.minimumSwingPowerToLaunch)
        if aimPower >= physics.minimumSwingPowerToLaunch {
            drawTrajectory()
        }
    }

    private func launchParameters() -> (speed: CGFloat, angle: CGFloat) {
        let curvedPower = CGFloat(pow(Double(max(aimPower, 0)), Double(physics.launchSpeedMultiplier)))
        let speedRange = physics.maxLaunchSpeed - physics.minimumLaunchSpeed
        let speed = physics.minimumLaunchSpeed + speedRange * curvedPower
        return (speed, aimAngle)
    }

    private func drawTrajectory() {
        guard let penguin = penguinNode else { return }

        let launch = launchParameters()
        let previewOffset: CGFloat = 18
        var vx = cos(launch.angle) * launch.speed
        var vy = sin(launch.angle) * launch.speed

        var x = penguin.position.x + cos(launch.angle) * previewOffset
        var y = penguin.position.y + sin(launch.angle) * previewOffset

        let path = CGMutablePath()
        var firstPoint = true

        let timeStep: CGFloat = 0.12
        for _ in 0..<30 {
            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            vx *= physics.airResistance
            vy = vy * physics.airResistance - physics.gravity
            x += vx * timeStep
            y += vy * timeStep
            if y < 0 { break }
        }

        trajectoryLine.path = path
    }

    private func launchPenguin() {
        guard let penguin = penguinNode else { return }

        let launch = launchParameters()
        let vx = cos(launch.angle) * launch.speed
        let vy = sin(launch.angle) * launch.speed
        let launchOffset: CGFloat = 18
        penguin.position = CGPoint(
            x: penguin.position.x + cos(launch.angle) * launchOffset,
            y: penguin.position.y + sin(launch.angle) * launchOffset
        )

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
        clearGroundedState()

        // 附加飞行轨迹粒子
        trailEmitter = ParticleEffects.shared.attachTrail(to: penguin)
        penguin.addChild(trailEmitter!)

        // 挥棒出手动画
        animateBandsRelease()

        // 播放发射音效
        AudioManager.shared.playLaunchSound()

        // 更新队列
        penguinsRemaining -= 1
        updatePenguinCountDisplay()
        if !penguinQueue.isEmpty {
            penguinQueue.removeFirst()
            for (i, p) in penguinQueue.enumerated() {
                let move = SKAction.move(to: reservePenguinPosition(at: i), duration: 0.3)
                move.timingMode = .easeOut
                p.run(move)
            }
        }
    }

    private func animateBandsRelease() {
        leftBandNode.removeAllActions()
        rightBandNode.removeAllActions()
        leftBandNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.08))
        rightBandNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.08))

        let contactAngle = aimAngle + 0.12 + aimPower * 0.1
        let followThroughAngle = min(contactAngle + 0.2, physics.maximumSwingAngle + 0.3)
        let restAngle = physics.minimumSwingAngle - 0.28
        swingPivotNode.removeAllActions()
        swingPivotNode.run(
            SKAction.sequence([
                SKAction.rotate(toAngle: contactAngle, duration: 0.08, shortestUnitArc: true),
                SKAction.rotate(toAngle: followThroughAngle, duration: 0.08, shortestUnitArc: true),
                SKAction.rotate(toAngle: restAngle, duration: 0.18, shortestUnitArc: true)
            ])
        )
    }

    // MARK: - 每帧更新

    override func update(_ currentTime: TimeInterval) {
        defer { updateCameraPosition() }

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
        if penguin.position.x > battlefieldSize.width - 20 {
            penguin.position.x = battlefieldSize.width - 20
            pb.velocity.dx = -abs(pb.velocity.dx) * physics.bounceDecay
        }
        if penguin.position.y > battlefieldSize.height - 20 {
            penguin.position.y = battlefieldSize.height - 20
            pb.velocity.dy = -abs(pb.velocity.dy) * physics.bounceDecay
        }

        let penguinGroundThreshold: CGFloat = 58
        if penguin.position.y <= penguinGroundThreshold {
            if groundedSince == nil {
                groundedSince = currentTime
            } else if let groundedSince, currentTime - groundedSince >= 2.0 {
                finishActivePenguin()
                return
            }
        } else {
            clearGroundedState()
        }

        // 企鹅停止判定
        let timeSinceLaunch = currentTime - launchTime
        if timeSinceLaunch > 10.0 && speed < physics.stopThreshold {
            // 超时强制停止（企鹅被卡住时触发）
            finishActivePenguin()
        } else if speed < physics.stopThreshold && penguin.position.y < slingshotBase.position.y + 50 {
            finishActivePenguin()
        }
    }

    // MARK: - 物理碰撞

    override func didSimulatePhysics() {
        checkPenguinCollisions()
    }

    private func checkPenguinCollisions() {
        guard let penguin = activePenguin,
              let pb = penguin.physicsBody else { return }

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
        comboLabel.position = CGPoint(x: 0, y: size.height * 0.12)
        comboLabel.zPosition = 60
        comboLabel.alpha = 0
        hudNode.addChild(comboLabel)

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkLevelComplete()
        }
    }

    // MARK: - 关卡判定

    private func checkLevelComplete() {
        guard !hasPresentedResult else { return }

        let activeBlocks = iceBlocks.filter { !$0.isBreaking && $0.parent != nil }
        if activeBlocks.isEmpty {
            showResult(success: true)
        } else if activePenguin != nil || flightState == .flying {
            return
        } else if penguinsRemaining <= 0 {
            showResult(success: false)
        } else {
            reloadSlingshot()
        }
    }

    private func showResult(success: Bool) {
        guard !hasPresentedResult else { return }
        hasPresentedResult = true

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
        } else {
            SaveManager.shared.updateScore(level: currentLevel, score: score, stars: 0)
        }

        resultOverlay = SKNode()
        resultOverlay?.zPosition = 100
        resultOverlay?.position = .zero
        hudNode.addChild(resultOverlay!)

        let overlayBg = SKShapeNode(rectOf: size)
        overlayBg.fillColor = UIColor(white: 0, alpha: 0.5)
        overlayBg.strokeColor = .clear
        overlayBg.position = .zero
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

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        titleLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), fadeIn]))
        scoreResultLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.4), fadeIn]))
        starsLabel.run(SKAction.sequence([SKAction.wait(forDuration: 0.6), fadeIn]))
        // 通关时播放星星爆发特效
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                guard let self = self else { return }
                ParticleEffects.shared.playStarBurst(at: self.gameCamera?.position ?? CGPoint(x: self.size.width / 2, y: self.size.height / 2), in: self)
            }
        }
        actionBtn.run(SKAction.sequence([SKAction.wait(forDuration: 0.8), fadeIn]))
        resultOverlay?.childNode(withName: "resultBackButton")?.run(SKAction.sequence([SKAction.wait(forDuration: 0.9), fadeIn]))

        isUserInteractionEnabled = true
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
