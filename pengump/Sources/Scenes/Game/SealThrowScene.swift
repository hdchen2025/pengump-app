import SpriteKit

final class SealThrowScene: SKScene {
    var onExit: (() -> Void)?

    private enum Phase {
        case ready
        case swinging
        case flying
        case cooldown
    }

    private let environmentController = EnvironmentController()
    private var flightController = FlightController()
    private var metrics = RunMetrics()

    private let worldNode = SKNode()
    private let hudNode = SKNode()
    private let cameraNode = SKCameraNode()

    private let launchBaseX: CGFloat = 170
    private var shoulderPoint: CGPoint = .zero

    private var phase: Phase = .ready
    private var lastUpdateTime: TimeInterval = 0
    private var holdDuration: TimeInterval = 0
    private var flightState: FlightBody?

    private var skyNode: SKSpriteNode!
    private var horizonNode: SKSpriteNode!
    private var groundNode: SKShapeNode!
    private var sealNode = SKNode()
    private var armNode = SKShapeNode()
    private var penguinNode = SKNode()
    private var messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var hintLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var distanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var flapLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var biomeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var releaseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var penguinTrail: SKEmitterNode?

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        setupScene()
        resetForNextThrow(showHint: true)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        skyNode?.size = CGSize(width: size.width * 1.5, height: size.height * 1.5)
        horizonNode?.size = CGSize(width: size.width * 1.5, height: size.height * 0.45)
        updateGroundPath(centerX: cameraNode.position.x)
        layoutHUD()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let hudPoint = touch.location(in: hudNode)

        if hitFrame(for: backLabel).contains(hudPoint) {
            AudioManager.shared.playButtonTapSound()
            onExit?()
            return
        }

        switch phase {
        case .ready:
            beginSwing()
        case .flying:
            triggerFlap()
        case .swinging, .cooldown:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if phase == .swinging {
            releasePenguin()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if phase == .swinging {
            releasePenguin()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = max(1.0 / 120.0, min(1.0 / 30.0, currentTime - lastUpdateTime))
        lastUpdateTime = currentTime

        switch phase {
        case .ready:
            updateIdlePose(currentTime: currentTime)
        case .swinging:
            holdDuration += dt
            updateSwingPose()
        case .flying:
            updateFlight(dt: CGFloat(dt))
        case .cooldown:
            break
        }
    }

    private func setupScene() {
        backgroundColor = .black
        addChild(worldNode)

        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(cameraNode)
        cameraNode.addChild(hudNode)

        let appearance = environmentController.profile(for: 0)

        skyNode = SKSpriteNode(color: appearance.skyColor, size: CGSize(width: size.width * 1.5, height: size.height * 1.5))
        skyNode.zPosition = -20
        cameraNode.addChild(skyNode)

        horizonNode = SKSpriteNode(color: appearance.horizonColor, size: CGSize(width: size.width * 1.5, height: size.height * 0.45))
        horizonNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        horizonNode.position = CGPoint(x: 0, y: -size.height * 0.5)
        horizonNode.zPosition = -19
        cameraNode.addChild(horizonNode)

        groundNode = SKShapeNode()
        groundNode.zPosition = -5
        worldNode.addChild(groundNode)

        setupSeal()
        setupHUD()
        layoutHUD()
        updateGroundPath(centerX: cameraNode.position.x)
    }

    private func setupSeal() {
        let launchGround = environmentController.groundHeight(at: launchBaseX)
        shoulderPoint = CGPoint(x: launchBaseX, y: launchGround + 118)

        sealNode.removeAllChildren()
        sealNode.position = CGPoint(x: launchBaseX - 44, y: launchGround + 28)
        sealNode.zPosition = 12
        worldNode.addChild(sealNode)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 118, height: 28))
        shadow.fillColor = SKColor(white: 0.2, alpha: 0.15)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 38, y: -6)
        sealNode.addChild(shadow)

        let body = SKShapeNode(ellipseOf: CGSize(width: 124, height: 86))
        body.fillColor = SKColor(red: 0.48, green: 0.54, blue: 0.62, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.22, green: 0.26, blue: 0.32, alpha: 1.0)
        body.lineWidth = 3
        body.position = CGPoint(x: 28, y: 42)
        sealNode.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 72, height: 50))
        belly.fillColor = SKColor(red: 0.86, green: 0.9, blue: 0.94, alpha: 1.0)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 18, y: 8)
        body.addChild(belly)

        let head = SKShapeNode(circleOfRadius: 34)
        head.fillColor = body.fillColor
        head.strokeColor = body.strokeColor
        head.lineWidth = 3
        head.position = CGPoint(x: 80, y: 70)
        sealNode.addChild(head)

        let nose = SKShapeNode(circleOfRadius: 8)
        nose.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0)
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 18, y: -4)
        head.addChild(nose)

        for offset in [-8.0, 8.0] {
            let eye = SKShapeNode(circleOfRadius: 4)
            eye.fillColor = .white
            eye.strokeColor = .clear
            eye.position = CGPoint(x: 2, y: CGFloat(offset))
            head.addChild(eye)

            let pupil = SKShapeNode(circleOfRadius: 2)
            pupil.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0)
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: 1, y: 0)
            eye.addChild(pupil)
        }

        for x in [0.0, 54.0] {
            let flipper = SKShapeNode(ellipseOf: CGSize(width: 32, height: 16))
            flipper.fillColor = SKColor(red: 0.34, green: 0.39, blue: 0.45, alpha: 1.0)
            flipper.strokeColor = .clear
            flipper.position = CGPoint(x: x, y: 0)
            sealNode.addChild(flipper)
        }

        armNode.strokeColor = SKColor(red: 0.22, green: 0.26, blue: 0.32, alpha: 1.0)
        armNode.lineWidth = 18
        armNode.lineCap = .round
        armNode.zPosition = 14
        worldNode.addChild(armNode)

        penguinNode = createPenguinNode()
        penguinNode.zPosition = 15
        worldNode.addChild(penguinNode)
    }

    private func setupHUD() {
        for label in [messageLabel, hintLabel, distanceLabel, bestLabel, flapLabel, biomeLabel, releaseLabel, backLabel] {
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            hudNode.addChild(label)
        }

        messageLabel.fontSize = 30
        messageLabel.alpha = 0

        hintLabel.fontSize = 16
        hintLabel.fontColor = SKColor(red: 0.23, green: 0.31, blue: 0.40, alpha: 0.8)
        hintLabel.text = "按住开始抡臂，松手出手，飞行中还能再点一次扑腾。"

        distanceLabel.fontSize = 28
        distanceLabel.fontColor = .white

        bestLabel.fontSize = 18
        bestLabel.fontColor = SKColor(red: 0.96, green: 0.91, blue: 0.72, alpha: 1.0)

        flapLabel.fontSize = 18
        flapLabel.fontColor = SKColor(red: 0.88, green: 0.96, blue: 1.0, alpha: 1.0)

        biomeLabel.fontSize = 18
        biomeLabel.fontColor = SKColor(red: 0.93, green: 0.98, blue: 1.0, alpha: 1.0)
        biomeLabel.horizontalAlignmentMode = .right

        releaseLabel.fontSize = 18
        releaseLabel.fontColor = SKColor(red: 1.0, green: 0.82, blue: 0.34, alpha: 1.0)
        releaseLabel.horizontalAlignmentMode = .right

        backLabel.fontSize = 16
        backLabel.text = "返回"
        backLabel.fontColor = .white
        backLabel.fontColor = SKColor(red: 0.20, green: 0.28, blue: 0.36, alpha: 1.0)
    }

    private func layoutHUD() {
        let left = -size.width * 0.5 + 20
        let right = size.width * 0.5 - 20
        let top = size.height * 0.5 - 24
        let bottom = -size.height * 0.5 + 24

        distanceLabel.position = CGPoint(x: left, y: top - 8)
        bestLabel.position = CGPoint(x: left, y: top - 40)
        flapLabel.position = CGPoint(x: left, y: top - 68)
        hintLabel.position = CGPoint(x: left, y: bottom + 26)
        messageLabel.position = CGPoint(x: 0, y: top - 38)
        messageLabel.horizontalAlignmentMode = .center
        biomeLabel.position = CGPoint(x: right, y: top - 16)
        releaseLabel.position = CGPoint(x: right, y: top - 46)
        backLabel.position = CGPoint(x: left, y: top - 96)
    }

    private func resetForNextThrow(showHint: Bool) {
        removeAction(forKey: "autoRestart")
        phase = .ready
        holdDuration = 0
        flightState = nil
        penguinTrail?.removeFromParent()
        penguinTrail = nil

        let groundY = environmentController.groundHeight(at: launchBaseX)
        shoulderPoint = CGPoint(x: launchBaseX, y: groundY + 118)
        sealNode.position = CGPoint(x: launchBaseX - 44, y: groundY + 28)
        penguinNode.position = orbitPosition(for: ThrowMechanics.restAngle)
        penguinNode.zRotation = ThrowMechanics.restAngle + .pi / 2
        metrics.beginRun(bestDistance: CGFloat(SaveManager.shared.bestDistance))
        metrics.releaseLabel = ReleaseJudgement.nice.rawValue
        releaseLabel.text = "准备出手"
        releaseLabel.fontColor = SKColor(cgColor: ReleaseJudgement.nice.accentColor)
        hintLabel.alpha = showHint ? 1.0 : 0.55
        cameraNode.position = CGPoint(x: size.width * 0.52, y: size.height * 0.52)
        messageLabel.removeAllActions()
        messageLabel.alpha = 0
        let profile = environmentController.profile(for: 0)
        updateHUD(for: profile, flapsRemaining: 1)
        updateEnvironment(for: profile)
        updateGroundPath(centerX: max(cameraNode.position.x, size.width * 0.5))
        updateArmPath(to: penguinNode.position)
    }

    private func beginSwing() {
        phase = .swinging
        holdDuration = 0
        releaseLabel.text = "松手出手"
        releaseLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.84, alpha: 1.0)
        hintLabel.alpha = 0.2
        AudioManager.shared.playButtonTapSound()
    }

    private func triggerFlap() {
        guard phase == .flying, var state = flightState else { return }
        guard flightController.useFlap(on: &state) else { return }
        flightState = state
        flapLabel.text = "拍击 × \(state.flapsRemaining)"
        showFloatingMessage("扑腾续命", color: SKColor(red: 0.78, green: 0.96, blue: 1.0, alpha: 1.0))
        ParticleEffects.shared.playCombo(at: penguinNode.position, in: self)
        AudioManager.shared.playComboSound()
    }

    private func releasePenguin() {
        guard phase == .swinging else { return }

        let launch = ThrowMechanics.release(for: holdDuration)
        metrics.beginRun(bestDistance: CGFloat(SaveManager.shared.bestDistance))
        metrics.releaseLabel = launch.judgement.rawValue
        releaseLabel.text = launch.judgement.rawValue
        releaseLabel.fontColor = SKColor(cgColor: launch.judgement.accentColor)

        phase = .flying
        flightState = FlightBody(position: penguinNode.position, velocity: launch.velocity)
        penguinTrail = ParticleEffects.shared.attachTrail(to: penguinNode)
        if let penguinTrail {
            penguinNode.addChild(penguinTrail)
        }

        AudioManager.shared.playLaunchSound()
        if launch.judgement == .perfect {
            ParticleEffects.shared.playStarBurst(at: penguinNode.position, in: self)
            showFloatingMessage("完美出手", color: SKColor(cgColor: launch.judgement.accentColor))
        } else {
            showFloatingMessage(launch.judgement.rawValue, color: SKColor(cgColor: launch.judgement.accentColor))
        }
    }

    private func updateIdlePose(currentTime: TimeInterval) {
        let idleAngle = ThrowMechanics.restAngle + sin(CGFloat(currentTime) * 1.8) * 0.08
        penguinNode.position = orbitPosition(for: idleAngle)
        penguinNode.zRotation = idleAngle + .pi / 2
        updateArmPath(to: penguinNode.position)
        updateCamera(targetX: size.width * 0.52, targetY: size.height * 0.52)
    }

    private func updateSwingPose() {
        let orbitAngle = ThrowMechanics.orbitAngle(after: holdDuration)
        let speed = ThrowMechanics.angularSpeed(for: holdDuration)
        penguinNode.position = orbitPosition(for: orbitAngle)
        penguinNode.zRotation = orbitAngle + .pi / 2
        updateArmPath(to: penguinNode.position)

        let previewJudgement = ThrowMechanics.releaseJudgement(
            for: max(0.05, orbitAngle + .pi / 2),
            speed: ThrowMechanics.linearSpeed(for: holdDuration),
            holdDuration: holdDuration
        )
        releaseLabel.text = "\(previewJudgement.rawValue)  \(Int(speed.rounded()))"
        releaseLabel.fontColor = SKColor(cgColor: previewJudgement.accentColor)
    }

    private func updateFlight(dt: CGFloat) {
        guard var state = flightState else { return }

        let groundHeight = environmentController.groundHeight(at: state.position.x)
        let result = flightController.step(
            body: &state,
            dt: dt,
            groundHeight: groundHeight,
            surface: environmentController.surface(at: metrics.currentDistance)
        )
        flightState = state

        penguinNode.position = state.position
        if abs(state.velocity.dx) > 20 || abs(state.velocity.dy) > 20 {
            penguinNode.zRotation = atan2(state.velocity.dy, state.velocity.dx)
        }
        updateArmPath(to: orbitPosition(for: ThrowMechanics.restAngle))

        metrics.airTime = state.airTime
        metrics.updateDistance(currentX: state.position.x, launchX: launchBaseX)
        let profile = environmentController.profile(for: metrics.currentDistance)
        metrics.registerBiome(
            name: profile.name,
            index: environmentController.biomeIndex(for: metrics.currentDistance)
        )
        updateEnvironment(for: profile)
        updateHUD(for: profile, flapsRemaining: state.flapsRemaining)
        updateGroundPath(centerX: state.position.x + size.width * 0.18)
        updateCamera(targetX: max(size.width * 0.5, state.position.x + size.width * 0.18), targetY: size.height * 0.52 + min(90, max(0, state.position.y - 180) * 0.10))

        if result.didBounce {
            AudioManager.shared.playIceHitSound()
            ParticleEffects.shared.playCombo(at: penguinNode.position, in: self)
        }

        if result.didStop {
            finishRun()
        }
    }

    private func finishRun() {
        guard phase == .flying else { return }

        phase = .cooldown
        let didBreakRecord = metrics.didBeatBest
        let distanceText = "\(Int(metrics.currentDistance.rounded()))m"
        let message = didBreakRecord ? "新纪录 \(distanceText)" : "本次 \(distanceText)"
        showFloatingMessage(message, color: didBreakRecord ? SKColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1.0) : .white, duration: 0.9)

        SaveManager.shared.recordDistanceRun(
            distance: Int(metrics.currentDistance.rounded()),
            perfectRelease: metrics.releaseLabel == ReleaseJudgement.perfect.rawValue,
            highestBiome: metrics.highestBiomeIndex
        )

        if didBreakRecord {
            ParticleEffects.shared.playStarBurst(at: penguinNode.position, in: self)
            AudioManager.shared.playGameWinSound()
        }

        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    self?.resetForNextThrow(showHint: false)
                }
            ]),
            withKey: "autoRestart"
        )
    }

    private func updateHUD(for profile: EnvironmentProfile, flapsRemaining: Int) {
        distanceLabel.text = "本次 \(Int(metrics.currentDistance.rounded()))m"
        bestLabel.text = "最佳 \(Int(metrics.bestDistance.rounded()))m"
        flapLabel.text = "拍击 × \(flapsRemaining)"
        biomeLabel.text = profile.name
    }

    private func updateEnvironment(for profile: EnvironmentProfile) {
        backgroundColor = profile.skyColor
        skyNode.color = profile.skyColor
        horizonNode.color = profile.horizonColor
        groundNode.fillColor = profile.groundColor
        groundNode.strokeColor = profile.accentColor
        distanceLabel.fontColor = profile.accentColor
    }

    private func updateCamera(targetX: CGFloat, targetY: CGFloat) {
        let target = CGPoint(x: targetX, y: max(size.height * 0.5, targetY))
        cameraNode.position.x += (target.x - cameraNode.position.x) * 0.12
        cameraNode.position.y += (target.y - cameraNode.position.y) * 0.12
    }

    private func updateGroundPath(centerX: CGFloat) {
        let halfWidth = max(size.width, 420)
        let startX = max(0, centerX - halfWidth)
        let endX = centerX + halfWidth
        let step: CGFloat = 32

        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: 0))

        var x = startX
        while x <= endX {
            path.addLine(to: CGPoint(x: x, y: environmentController.groundHeight(at: x)))
            x += step
        }

        path.addLine(to: CGPoint(x: endX, y: 0))
        path.closeSubpath()
        groundNode.path = path
        groundNode.lineWidth = 6
    }

    private func updateArmPath(to target: CGPoint) {
        let path = CGMutablePath()
        path.move(to: shoulderPoint)
        path.addLine(to: target)
        armNode.path = path
    }

    private func orbitPosition(for angle: CGFloat) -> CGPoint {
        CGPoint(
            x: shoulderPoint.x + cos(angle) * ThrowMechanics.orbitRadius,
            y: shoulderPoint.y + sin(angle) * ThrowMechanics.orbitRadius
        )
    }

    private func showFloatingMessage(_ text: String, color: SKColor, duration: TimeInterval = 0.65) {
        messageLabel.removeAllActions()
        messageLabel.text = text
        messageLabel.fontColor = color
        messageLabel.alpha = 1.0
        messageLabel.setScale(0.88)
        messageLabel.position = CGPoint(x: 0, y: size.height * 0.5 - 62)
        messageLabel.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.12),
                    SKAction.moveBy(x: 0, y: 8, duration: 0.12)
                ]),
                SKAction.wait(forDuration: duration),
                SKAction.fadeOut(withDuration: 0.25)
            ])
        )
    }

    private func createPenguinNode() -> SKNode {
        let root = SKNode()

        let body = SKShapeNode(ellipseOf: CGSize(width: 34, height: 44))
        body.fillColor = SKColor(red: 0.25, green: 0.79, blue: 0.76, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.11, green: 0.37, blue: 0.39, alpha: 1.0)
        body.lineWidth = 2.5
        root.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 20, height: 26))
        belly.fillColor = .white
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -4)
        root.addChild(belly)

        let goggles = SKShapeNode(rectOf: CGSize(width: 26, height: 12), cornerRadius: 6)
        goggles.fillColor = SKColor(red: 0.98, green: 0.77, blue: 0.26, alpha: 1.0)
        goggles.strokeColor = SKColor(red: 0.69, green: 0.44, blue: 0.10, alpha: 1.0)
        goggles.lineWidth = 2
        goggles.position = CGPoint(x: 0, y: 8)
        root.addChild(goggles)

        let strap = SKShapeNode(rectOf: CGSize(width: 34, height: 4), cornerRadius: 2)
        strap.fillColor = SKColor(red: 0.28, green: 0.32, blue: 0.36, alpha: 1.0)
        strap.strokeColor = .clear
        strap.position = CGPoint(x: 0, y: 8)
        root.addChild(strap)

        let beak = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
        beak.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.39, alpha: 1.0)
        beak.strokeColor = .clear
        beak.position = CGPoint(x: 0, y: 0)
        root.addChild(beak)

        return root
    }

    private func hitFrame(for node: SKNode, expandBy: CGFloat = 12) -> CGRect {
        node.calculateAccumulatedFrame().insetBy(dx: -expandBy, dy: -expandBy)
    }
}
