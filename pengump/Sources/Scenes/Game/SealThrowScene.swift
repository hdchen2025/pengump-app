import SpriteKit

final class SealThrowScene: SKScene {
    private let distanceMilestones = [100, 300, 800, 1500, 3000]

    var onExit: (() -> Void)?

    private struct CelebrationMessage {
        let text: String
        let color: SKColor
    }

    private enum Phase {
        case ready
        case swinging
        case flying
        case cooldown
    }

    private let environmentController = EnvironmentController()
    private let dailyChallenge = DailyChallenge.today()
    private var flightController = FlightController()
    private var metrics = RunMetrics()

    private let worldNode = SKNode()
    private let featureNode = SKNode()
    private let hudNode = SKNode()
    private let cameraNode = SKCameraNode()
    private let speedLinesNode = SKNode()

    private let launchBaseX: CGFloat = 170
    private var shoulderPoint: CGPoint = .zero

    private var phase: Phase = .ready
    private var lastUpdateTime: TimeInterval = 0
    private var holdDuration: TimeInterval = 0
    private var flightState: FlightBody?
    private var speedLineSprites: [SKSpriteNode] = []
    private var speedLinesPhase: CGFloat = 0
    private var slowMotionTimer: CGFloat = 0
    private var didCelebrateRecord = false
    private var nextMilestoneIndex = 0
    private var currentBiomeIndex = 0
    private var renderedFeatures: [String: SKNode] = [:]
    private var triggeredFeatureIDs: Set<String> = []

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
        layoutSpeedLines()
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
        let rawDt = max(1.0 / 120.0, min(1.0 / 30.0, currentTime - lastUpdateTime))
        lastUpdateTime = currentTime
        let dt = scaledDeltaTime(from: rawDt)

        switch phase {
        case .ready:
            updateIdlePose(currentTime: currentTime)
            updateSpeedLines(forwardSpeed: 0, dt: CGFloat(rawDt))
        case .swinging:
            holdDuration += dt
            updateSwingPose()
            updateSpeedLines(forwardSpeed: 0, dt: CGFloat(rawDt))
        case .flying:
            updateFlight(dt: CGFloat(dt))
        case .cooldown:
            updateSpeedLines(forwardSpeed: 0, dt: CGFloat(rawDt))
            break
        }
    }

    private func setupScene() {
        backgroundColor = .black
        addChild(worldNode)

        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(cameraNode)
        speedLinesNode.zPosition = -18
        cameraNode.addChild(speedLinesNode)
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
        featureNode.zPosition = 4
        worldNode.addChild(featureNode)

        setupSeal()
        setupSpeedLines()
        setupHUD()
        layoutHUD()
        layoutSpeedLines()
        updateGroundPath(centerX: cameraNode.position.x)
        updateFeatureNodes(aroundX: cameraNode.position.x)
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
        hintLabel.text = "按住任意位置开始远投，松手出手，飞行中还能再点一次扑腾。"

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

    private func setupSpeedLines() {
        speedLinesNode.removeAllChildren()
        speedLineSprites = (0..<8).map { index in
            let line = SKSpriteNode(color: .white, size: CGSize(width: 88 + CGFloat(index % 3) * 24, height: 3))
            line.alpha = 0
            line.zRotation = -.pi * 0.12
            line.blendMode = .add
            speedLinesNode.addChild(line)
            return line
        }
    }

    private func layoutSpeedLines() {
        let left = -size.width * 0.5
        let right = size.width * 0.5
        let top = size.height * 0.5

        for (index, line) in speedLineSprites.enumerated() {
            let normalizedY = CGFloat(index) / CGFloat(max(1, speedLineSprites.count - 1))
            line.position = CGPoint(
                x: left + (right - left) * (0.18 + CGFloat(index % 4) * 0.18),
                y: top - 70 - normalizedY * max(140, size.height * 0.52)
            )
        }
    }

    private func resetForNextThrow(showHint: Bool) {
        removeAction(forKey: "autoRestart")
        phase = .ready
        holdDuration = 0
        flightState = nil
        slowMotionTimer = 0
        didCelebrateRecord = false
        nextMilestoneIndex = 0
        currentBiomeIndex = 0
        speedLinesPhase = 0
        triggeredFeatureIDs.removeAll()
        renderedFeatures.values.forEach { $0.removeFromParent() }
        renderedFeatures.removeAll()
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
        cameraNode.removeAllActions()
        cameraNode.setScale(1.0)
        cameraNode.position = CGPoint(x: size.width * 0.52, y: size.height * 0.52)
        messageLabel.removeAllActions()
        messageLabel.alpha = 0
        let profile = environmentController.profile(for: 0)
        updateHUD(for: profile, flapsRemaining: 1)
        updateEnvironment(for: profile)
        updateGroundPath(centerX: max(cameraNode.position.x, size.width * 0.5))
        updateArmPath(to: penguinNode.position)
        updateSpeedLines(forwardSpeed: 0, dt: 0)
        updateFeatureNodes(aroundX: cameraNode.position.x)
        if showHint {
            showFloatingMessage("今日挑战：\(dailyChallenge.title) · \(dailyChallenge.targetDistance)m", color: profile.accentColor, duration: 0.8)
        }
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

        let launch = ThrowMechanics.release(for: holdDuration, challenge: dailyChallenge)
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
            triggerLaunchCinematic()
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

        let previousPosition = state.position
        let groundHeight = environmentController.groundHeight(at: state.position.x)
        var result = flightController.step(
            body: &state,
            dt: dt,
            groundHeight: groundHeight,
            surface: environmentController.surface(at: metrics.currentDistance),
            challenge: dailyChallenge
        )

        if let triggeredFeature = triggerFeatureIfNeeded(on: &state, previousPosition: previousPosition) {
            metrics.registerInteraction()
            result.didStop = false
            showFloatingMessage(triggeredFeature.kind.label, color: featureAccentColor(for: triggeredFeature.kind), duration: 0.48)
            ParticleEffects.shared.playCombo(at: state.position, in: self)
            AudioManager.shared.playComboSound()
            pulseCamera(scale: 0.95)
        }
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
        let leadX = min(280, max(size.width * 0.18, abs(state.velocity.dx) * 0.16))
        let leadY = min(120, max(0, state.position.y - 180) * 0.10 + max(0, state.velocity.dy) * 0.04)
        updateCamera(
            targetX: max(size.width * 0.5, state.position.x + leadX),
            targetY: size.height * 0.52 + leadY
        )
        updateSpeedLines(forwardSpeed: max(0, state.velocity.dx), dt: dt)
        updateFeatureNodes(aroundX: state.position.x + size.width * 0.18)
        celebrateBiomeShiftIfNeeded(profile: profile)
        celebrateProgressIfNeeded(profile: profile)

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
        let roundedDistance = Int(metrics.currentDistance.rounded())
        let distanceText = "\(roundedDistance)m"
        let message = didBreakRecord ? "新纪录 \(distanceText)" : "本次 \(distanceText)"
        showFloatingMessage(message, color: didBreakRecord ? SKColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1.0) : .white, duration: 0.9)

        let outcome = SaveManager.shared.recordDistanceRun(
            distance: roundedDistance,
            perfectRelease: metrics.releaseLabel == ReleaseJudgement.perfect.rawValue,
            highestBiome: metrics.highestBiomeIndex,
            interactionCount: metrics.interactionCount,
            airTime: metrics.airTime,
            challenge: dailyChallenge
        )

        if didBreakRecord {
            ParticleEffects.shared.playStarBurst(at: penguinNode.position, in: self)
            AudioManager.shared.playGameWinSound()
        }

        var extraMessages: [CelebrationMessage] = []
        if outcome.didCompleteDailyChallenge {
            extraMessages.append(
                CelebrationMessage(
                    text: "挑战达成 \(outcome.challenge.targetDistance)m",
                    color: SKColor(red: 0.48, green: 0.94, blue: 0.86, alpha: 1.0)
                )
            )
        } else if outcome.didSetDailyChallengeRecord {
            extraMessages.append(
                CelebrationMessage(
                    text: "刷新今日最佳",
                    color: SKColor(red: 0.62, green: 0.9, blue: 1.0, alpha: 1.0)
                )
            )
        }

        for achievement in outcome.newlyUnlockedAchievements {
            extraMessages.append(
                CelebrationMessage(
                    text: "成就解锁：\(achievement.title)",
                    color: SKColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 1.0)
                )
            )
        }

        let extraDelay = scheduleCelebrationMessages(extraMessages)
        if !extraMessages.isEmpty {
            ParticleEffects.shared.playStarBurst(at: penguinNode.position, in: self)
        }

        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.0 + extraDelay),
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
        if metrics.interactionCount > 0 {
            flapLabel.text = "拍击 × \(flapsRemaining) · 连锁 \(metrics.interactionCount)"
        } else {
            flapLabel.text = "拍击 × \(flapsRemaining)"
        }
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

    private func updateSpeedLines(forwardSpeed: CGFloat, dt: CGFloat) {
        let intensity = min(1.0, max(0, (forwardSpeed - 480) / 820))
        speedLinesPhase += max(0, forwardSpeed) * max(0.002, dt * 0.028)

        for (index, line) in speedLineSprites.enumerated() {
            let baseX = -size.width * 0.5 + size.width * (0.18 + CGFloat(index % 4) * 0.18)
            let offset = (speedLinesPhase + CGFloat(index) * 38).truncatingRemainder(dividingBy: 180)
            line.position.x = baseX - offset
            line.alpha = intensity * (0.22 + CGFloat(index % 3) * 0.12)
            line.xScale = 0.72 + intensity * 0.95
        }
    }

    private func celebrateProgressIfNeeded(profile: EnvironmentProfile) {
        if metrics.didBeatBest && !didCelebrateRecord {
            didCelebrateRecord = true
            showFloatingMessage("破纪录了", color: SKColor(red: 1.0, green: 0.84, blue: 0.38, alpha: 1.0), duration: 0.55)
            AudioManager.shared.playGameWinSound()
            triggerRecordCinematic()
        }

        while nextMilestoneIndex < distanceMilestones.count && metrics.currentDistance >= CGFloat(distanceMilestones[nextMilestoneIndex]) {
            let milestone = distanceMilestones[nextMilestoneIndex]
            nextMilestoneIndex += 1
            ParticleEffects.shared.playStarBurst(at: penguinNode.position, in: self)
            AudioManager.shared.playComboSound()
            showFloatingMessage("冲破 \(milestone)m", color: profile.accentColor, duration: 0.55)
            pulseCamera(scale: 0.95)
        }
    }

    private func celebrateBiomeShiftIfNeeded(profile: EnvironmentProfile) {
        let biomeIndex = environmentController.biomeIndex(for: metrics.currentDistance)
        guard biomeIndex > currentBiomeIndex else { return }

        currentBiomeIndex = biomeIndex
        showFloatingMessage(profile.name, color: profile.accentColor, duration: 0.5)
        pulseCamera(scale: 0.96)
        AudioManager.shared.playComboSound()
    }

    private func triggerLaunchCinematic() {
        slowMotionTimer = max(slowMotionTimer, 0.12)
        pulseCamera(scale: 0.94)
    }

    private func triggerRecordCinematic() {
        slowMotionTimer = max(slowMotionTimer, 0.22)
        pulseCamera(scale: 0.92)
    }

    private func pulseCamera(scale: CGFloat) {
        cameraNode.removeAction(forKey: "cameraPulse")
        cameraNode.run(
            SKAction.sequence([
                SKAction.scale(to: scale, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.18)
            ]),
            withKey: "cameraPulse"
        )
    }

    private func scaledDeltaTime(from rawDt: TimeInterval) -> TimeInterval {
        guard slowMotionTimer > 0 else { return rawDt }
        slowMotionTimer = max(0, slowMotionTimer - CGFloat(rawDt))
        return rawDt * 0.42
    }

    private func updateFeatureNodes(aroundX centerX: CGFloat) {
        let features = environmentController.features(in: featureRange(aroundX: centerX), challenge: dailyChallenge)
        let visibleIDs = Set(features.map(\.id))

        let staleIDs = renderedFeatures.keys.filter { !visibleIDs.contains($0) || triggeredFeatureIDs.contains($0) }
        for id in staleIDs {
            renderedFeatures[id]?.removeFromParent()
            renderedFeatures.removeValue(forKey: id)
        }

        for feature in features where !triggeredFeatureIDs.contains(feature.id) && renderedFeatures[feature.id] == nil {
            let node = makeFeatureNode(for: feature)
            renderedFeatures[feature.id] = node
            featureNode.addChild(node)
        }
    }

    private func triggerFeatureIfNeeded(on body: inout FlightBody, previousPosition: CGPoint) -> EnvironmentFeature? {
        let lowerBound = min(previousPosition.x, body.position.x) - 40
        let upperBound = max(previousPosition.x, body.position.x) + 40
        let nearbyFeatures = environmentController.features(in: lowerBound...upperBound, challenge: dailyChallenge)

        for feature in nearbyFeatures where !triggeredFeatureIDs.contains(feature.id) {
            let anchor = featureAnchorPoint(for: feature)
            guard segmentDistance(from: previousPosition, to: body.position, point: anchor) < 44 else { continue }

            triggeredFeatureIDs.insert(feature.id)
            if let node = renderedFeatures.removeValue(forKey: feature.id) {
                node.run(
                    SKAction.sequence([
                        SKAction.scale(to: 1.16, duration: 0.06),
                        SKAction.fadeOut(withDuration: 0.16),
                        SKAction.removeFromParent()
                    ])
                )
            }

            switch feature.kind {
            case .fishBoost:
                flightController.applyFishBoost(on: &body)
            case .iceSpring:
                flightController.applyIceSpring(on: &body)
            }

            return feature
        }

        return nil
    }

    private func segmentDistance(from start: CGPoint, to end: CGPoint, point: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0.001 else {
            return hypot(point.x - start.x, point.y - start.y)
        }

        let projection = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        let clampedProjection = max(0, min(1, projection))
        let closest = CGPoint(x: start.x + dx * clampedProjection, y: start.y + dy * clampedProjection)
        return hypot(point.x - closest.x, point.y - closest.y)
    }

    private func makeFeatureNode(for feature: EnvironmentFeature) -> SKNode {
        let root = SKNode()
        root.position = featureAnchorPoint(for: feature)
        root.name = feature.id

        switch feature.kind {
        case .fishBoost:
            for index in 0..<3 {
                let fish = SKShapeNode(ellipseOf: CGSize(width: 18, height: 10))
                fish.fillColor = SKColor(red: 0.24, green: 0.72, blue: 0.96, alpha: 1.0)
                fish.strokeColor = SKColor(red: 0.08, green: 0.34, blue: 0.58, alpha: 1.0)
                fish.lineWidth = 1.5
                fish.position = CGPoint(x: CGFloat(index) * 14, y: sin(CGFloat(index)) * 4)
                root.addChild(fish)
            }
        case .iceSpring:
            let plate = SKShapeNode(rectOf: CGSize(width: 34, height: 10), cornerRadius: 4)
            plate.fillColor = SKColor(red: 0.48, green: 0.92, blue: 1.0, alpha: 1.0)
            plate.strokeColor = SKColor(red: 0.11, green: 0.48, blue: 0.63, alpha: 1.0)
            plate.lineWidth = 2
            root.addChild(plate)

            let spikePath = CGMutablePath()
            spikePath.move(to: CGPoint(x: -14, y: 0))
            spikePath.addLine(to: CGPoint(x: 0, y: 22))
            spikePath.addLine(to: CGPoint(x: 14, y: 0))
            spikePath.closeSubpath()

            let spike = SKShapeNode(path: spikePath)
            spike.fillColor = SKColor(red: 0.86, green: 0.98, blue: 1.0, alpha: 1.0)
            spike.strokeColor = SKColor(red: 0.22, green: 0.52, blue: 0.7, alpha: 1.0)
            spike.lineWidth = 2
            spike.position = CGPoint(x: 0, y: 8)
            root.addChild(spike)
        }

        return root
    }

    private func featureAnchorPoint(for feature: EnvironmentFeature) -> CGPoint {
        let groundY = environmentController.groundHeight(at: feature.worldX)
        switch feature.kind {
        case .fishBoost:
            return CGPoint(x: feature.worldX, y: groundY + 24)
        case .iceSpring:
            return CGPoint(x: feature.worldX, y: groundY + 8)
        }
    }

    private func featureAccentColor(for kind: EnvironmentFeatureKind) -> SKColor {
        switch kind {
        case .fishBoost:
            return SKColor(red: 0.38, green: 0.88, blue: 1.0, alpha: 1.0)
        case .iceSpring:
            return SKColor(red: 0.76, green: 0.96, blue: 1.0, alpha: 1.0)
        }
    }

    private func featureRange(aroundX centerX: CGFloat) -> ClosedRange<CGFloat> {
        let halfWidth = max(size.width, 420)
        return max(0, centerX - halfWidth)...(centerX + halfWidth)
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

    private func scheduleCelebrationMessages(_ messages: [CelebrationMessage]) -> TimeInterval {
        guard !messages.isEmpty else { return 0 }

        for (index, item) in messages.enumerated() {
            let delay = 0.52 + Double(index) * 0.64
            run(
                SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.run { [weak self] in
                        self?.showFloatingMessage(item.text, color: item.color, duration: 0.55)
                    }
                ])
            )
        }

        return 0.52 + Double(messages.count) * 0.64
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
