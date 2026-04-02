import SpriteKit

/// 游戏主场景 - 弹弓发射企鹅
class GameScene: SKScene {

    // MARK: - 游戏配置（与方案文档一致）

    private let GRAVITY: CGFloat = 0.25
    private let AIR_RESISTANCE: CGFloat = 0.99
    private let MAX_PULL_DISTANCE: CGFloat = 120
    private let MIN_PULL_DISTANCE: CGFloat = 20
    private let LAUNCH_SPEED_MULTIPLIER: CGFloat = 0.15
    private let MAX_INITIAL_SPEED: CGFloat = 18

    // MARK: - 游戏状态

    private var currentLevel: Int = 1
    private var penguinsRemaining: Int = 3
    private var score: Int = 0
    private var isAiming: Bool = false
    private var aimStartPoint: CGPoint = .zero

    // MARK: - 节点引用

    private var slingshotNode: SKSpriteNode!
    private var penguinNode: SKSpriteNode!
    private var trajectoryLine: SKShapeNode!
    private var penguinQueue: [SKSpriteNode] = []
    private var activePenguin: SKSpriteNode?

    // MARK: - 初始化

    init(level: Int) {
        self.currentLevel = level
        super.init(size: .zero)
        self.backgroundColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 0.3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupSlingshot()
        setupPenguinQueue()
        setupTrajectoryLine()
        setupUI()
        setupIceBlocks()
    }

    // MARK: - 场景搭建

    private func setupSlingshot() {
        // 弹弓底座（简化版，用矩形代替）
        let slingshotY = frame.height * 0.25
        slingshotNode = SKSpriteNode(color: UIColor.brown, size: CGSize(width: 20, height: 80))
        slingshotNode.position = CGPoint(x: frame.width * 0.2, y: slingshotY)
        addChild(slingshotNode)

        // 弹弓皮筋（用两条线段表示）
        drawSlingshotBands()
    }

    private func drawSlingshotBands() {
        // 左皮筋
        let leftBand = SKShapeNode(rectOf: CGSize(width: 4, height: 40))
        leftBand.strokeColor = UIColor(red: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)
        leftBand.position = CGPoint(x: slingshotNode.position.x - 10,
                                    y: slingshotNode.position.y + 30)
        addChild(leftBand)

        // 右皮筋
        let rightBand = SKShapeNode(rectOf: CGSize(width: 4, height: 40))
        rightBand.strokeColor = UIColor(red: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)
        rightBand.position = CGPoint(x: slingshotNode.position.x + 10,
                                     y: slingshotNode.position.y + 30)
        addChild(rightBand)
    }

    private func setupPenguinQueue() {
        // 放置待发射企鹅队列（屏幕底部左侧）
        let queueY = frame.height * 0.12
        for i in 0..<penguinsRemaining {
            let penguin = createPenguinNode()
            penguin.position = CGPoint(x: frame.width * 0.08 + CGFloat(i) * 50,
                                       y: queueY)
            penguin.alpha = 0.5
            addChild(penguin)
            penguinQueue.append(penguin)
        }
        // 第一只企鹅上弹弓
        reloadSlingshot()
    }

    private func createPenguinNode() -> SKSpriteNode {
        // 企鹅精灵（用简单图形组合）
        let penguin = SKSpriteNode(color: UIColor.black, size: CGSize(width: 32, height: 32))
        penguin.name = "penguin"

        // 身体（白色椭圆）
        let body = SKShapeNode(circleOfRadius: 12)
        body.fillColor = .white
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: -2)
        penguin.addChild(body)

        // 眼睛（两个黑点）
        let leftEye = SKShapeNode(circleOfRadius: 2)
        leftEye.fillColor = .black
        leftEye.position = CGPoint(x: -4, y: 4)
        penguin.addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 2)
        rightEye.fillColor = .black
        rightEye.position = CGPoint(x: 4, y: 4)
        penguin.addChild(rightEye)

        // 喙（橙色三角形用椭圆代替）
        let beak = SKShapeNode(circleOfRadius: 3)
        beak.fillColor = UIColor.orange
        beak.strokeColor = .clear
        beak.position = CGPoint(x: 0, y: 0)
        penguin.addChild(beak)

        return penguin
    }

    private func reloadSlingshot() {
        guard penguinNode == nil || !penguinNode.hasActions() else { return }

        penguinNode = createPenguinNode()
        let launchPos = CGPoint(x: slingshotNode.position.x,
                                y: slingshotNode.position.y + 40)
        penguinNode.position = launchPos
        addChild(penguinNode)
    }

    private func setupTrajectoryLine() {
        trajectoryLine = SKShapeNode()
        trajectoryLine.strokeColor = UIColor.gray.withAlphaComponent(0.5)
        trajectoryLine.lineWidth = 2
        trajectoryLine.isHidden = true
        addChild(trajectoryLine)
    }

    private func setupUI() {
        // 返回按钮
        let backBtn = SKSpriteNode(color: UIColor.darkGray, size: CGSize(width: 80, height: 36))
        backBtn.position = CGPoint(x: 50, y: frame.height - 40)
        backBtn.name = "backButton"
        addChild(backBtn)

        let backLabel = SKLabelNode(text: "← 返回")
        backLabel.fontSize = 14
        backLabel.fontColor = .white
        backLabel.name = "backLabel"
        backBtn.addChild(backLabel)

        // 分数标签
        let scoreLabel = SKLabelNode(text: "分数: 0")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .darkGray
        scoreLabel.name = "scoreLabel"
        scoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 50)
        addChild(scoreLabel)

        // 关卡标签
        let levelLabel = SKLabelNode(text: "第 \(currentLevel) 关")
        levelLabel.fontSize = 18
        levelLabel.fontColor = .darkGray
        levelLabel.position = CGPoint(x: frame.width / 2, y: frame.height - 80)
        addChild(levelLabel)

        // 企鹅剩余数量
        updatePenguinCount()
    }

    private func updatePenguinCount() {
        let countLabel = SKLabelNode(text: "🐧 × \(penguinsRemaining)")
        countLabel.fontSize = 18
        countLabel.name = "countLabel"
        countLabel.position = CGPoint(x: frame.width - 80, y: frame.height - 50)
        // 移除旧标签
        (self.childNode(withName: "countLabel") as? SKLabelNode)?.removeFromParent()
        addChild(countLabel)
    }

    private func setupIceBlocks() {
        // 冰块（简化版：屏幕右侧排列）
        let blockSize: CGFloat = 50
        let startX = frame.width * 0.7
        let startY = frame.height * 0.7

        let iceBlock = SKSpriteNode(color: UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8),
                                     size: CGSize(width: blockSize, height: blockSize))
        iceBlock.position = CGPoint(x: startX, y: startY)
        iceBlock.name = "iceBlock"
        iceBlock.physicsBody = SKPhysicsBody(rectangleOf: blockSize)
        iceBlock.physicsBody?.isDynamic = true
        iceBlock.physicsBody?.mass = 1.0
        iceBlock.physicsBody?.friction = 0.5
        addChild(iceBlock)

        // 再加两个冰块，形成简单关卡
        let iceBlock2 = SKSpriteNode(color: UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8),
                                      size: CGSize(width: blockSize, height: blockSize))
        iceBlock2.position = CGPoint(x: startX + 60, y: startY)
        iceBlock2.name = "iceBlock"
        iceBlock2.physicsBody = SKPhysicsBody(rectangleOf: blockSize)
        iceBlock2.physicsBody?.isDynamic = true
        addChild(iceBlock2)
    }

    // MARK: - 触摸控制

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // 返回按钮
        if let backBtn = childNode(withName: "backButton"),
           backBtn.frame.contains(location) {
            dismiss(animated: true)
            return
        }

        // 开始瞄准
        if let penguin = penguinNode,
           penguin.frame.insetBy(dx: -20, dy: -20).contains(location) {
            isAiming = true
            aimStartPoint = location
            trajectoryLine.isHidden = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAiming, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // 限制拉动距离
        let dx = location.x - slingshotNode.position.x
        let dy = location.y - (slingshotNode.position.y + 40)
        var distance = sqrt(dx * dx + dy * dy)
        distance = min(distance, MAX_PULL_DISTANCE)

        let angle = atan2(dy, dx)
        let clampedX = slingshotNode.position.x + cos(angle) * distance
        let clampedY = slingshotNode.position.y + 40 + sin(angle) * distance

        penguinNode?.position = CGPoint(x: clampedX, y: clampedY)

        // 绘制轨迹
        drawTrajectory()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAiming else { return }
        isAiming = false
        trajectoryLine.isHidden = true

        launchPenguin()
    }

    // MARK: - 发射逻辑

    private func drawTrajectory() {
        let path = CGMutablePath()
        var x = penguinNode?.position.x ?? 0
        var y = penguinNode?.position.y ?? 0
        var vx = (slingshotNode.position.x - x) * LAUNCH_SPEED_MULTIPLIER
        var vy = (slingshotNode.position.y + 40 - y) * LAUNCH_SPEED_MULTIPLIER

        path.move(to: CGPoint(x: x, y: y))

        for _ in 0..<30 {
            vx *= AIR_RESISTANCE
            vy = vy * AIR_RESISTANCE - GRAVITY
            x += vx
            y += vy
            if y < 0 { break }
            path.addLine(to: CGPoint(x: x, y: y))
        }

        trajectoryLine.path = path
    }

    private func launchPenguin() {
        guard let penguin = penguinNode else { return }

        let launchPos = CGPoint(x: slingshotNode.position.x,
                                y: slingshotNode.position.y + 40)
        let dx = launchPos.x - penguin.position.x
        let dy = launchPos.y - penguin.position.y

        // 限制速度
        var speed = sqrt(dx * dx + dy * dy) * LAUNCH_SPEED_MULTIPLIER
        speed = min(speed, MAX_INITIAL_SPEED)

        let angle = atan2(dy, dx)
        let vx = cos(angle) * speed
        let vy = sin(angle) * speed

        penguin.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        penguin.physicsBody?.isDynamic = true
        penguin.physicsBody?.mass = 1.0
        penguin.physicsBody?.applyImpulse(CGVector(dx: vx, dy: vy))

        // 发射后企鹅飞完检查
        activePenguin = penguin
        penguinNode = nil

        // 更新队列显示
        if !penguinQueue.isEmpty {
            penguinQueue.removeFirst()
            for (i, p) in penguinQueue.enumerated() {
                p.position.x = frame.width * 0.08 + CGFloat(i) * 50
            }
            reloadSlingshot()
        } else {
            // 所有企鹅用完，等待游戏结束判定
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.checkLevelComplete()
            }
        }
    }

    // MARK: - 碰撞检测

    override func didEvaluateActions() {
        // 每帧检查活跃企鹅是否停止
        guard let penguin = activePenguin,
              let pb = penguin.physicsBody else { return }

        if pb.velocity.speed < 0.5 && penguin.position.y < slingshotNode.position.y {
            // 企鹅停止，移除
            penguin.removeFromParent()
            activePenguin = nil
            penguinsRemaining -= 1
            updatePenguinCount()
        }
    }

    // MARK: - 关卡判定

    private func checkLevelComplete() {
        // 检查是否还有冰块
        let iceBlocks = children.filter { $0.name == "iceBlock" }
        if iceBlocks.isEmpty {
            showResult(success: true)
        } else {
            showResult(success: false)
        }
    }

    private func showResult(success: Bool) {
        let label = SKLabelNode(text: success ? "🎉 通关！" : "💔 再试一次")
        label.fontSize = 48
        label.fontColor = success ? .green : .red
        label.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        addChild(label)

        let subLabel = SKLabelNode(text: "点击任意位置继续")
        subLabel.fontSize = 18
        subLabel.fontColor = .darkGray
        subLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 50)
        addChild(subLabel)

        isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, continued: Bool) {
        guard let label = childNode(withName: "//scoreLabel") else { return }
        if label.parent != nil {
            // 游戏结束，点击返回关卡选择
            if let vc = view?.window?.rootViewController {
                vc.dismiss(animated: true)
            }
        }
    }

    private func dismiss(animated: Bool) {
        view?.window?.rootViewController?.dismiss(animated: animated)
    }
}
