import UIKit
import SpriteKit

/// 游戏主界面（SpriteKit 场景）
class GameViewController: UIViewController {

    private let level: Int?
    private var scene: SealThrowScene!
    private var skView: SKView!
    private var isPauseOverlayVisible = false

    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("暂停", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.10, green: 0.20, blue: 0.30, alpha: 0.72)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        return button
    }()

    private lazy var pauseOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    private lazy var pausePanel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.94, green: 0.98, blue: 1.0, alpha: 0.98)
        view.layer.cornerRadius = 20
        return view
    }()

    private lazy var pauseTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 0.12, green: 0.28, blue: 0.44, alpha: 1.0)
        label.textAlignment = .center
        label.text = "已暂停"
        return label
    }()

    private lazy var pauseSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.25, green: 0.34, blue: 0.44, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var resumeButton = makePauseActionButton(
        title: "继续远投",
        backgroundColor: UIColor(red: 0.16, green: 0.46, blue: 0.78, alpha: 1.0),
        action: #selector(resumeTapped)
    )

    private lazy var restartButton = makePauseActionButton(
        title: "重新开始",
        backgroundColor: UIColor(red: 0.96, green: 0.65, blue: 0.18, alpha: 1.0),
        action: #selector(restartTapped)
    )

    private lazy var exitButton = makePauseActionButton(
        title: "返回菜单",
        backgroundColor: UIColor(red: 0.41, green: 0.50, blue: 0.58, alpha: 1.0),
        action: #selector(exitFromPauseTapped)
    )

    convenience init() {
        self.init(level: nil)
    }

    init(level: Int?) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 播放游戏背景音乐
        AudioManager.shared.playMusic(.game)

        // 创建 SpriteKit 场景
        scene = SealThrowScene()
        scene.onExit = { [weak self] in
            self?.dismiss(animated: true)
        }
        scene.scaleMode = .resizeFill
        scene.size = view.bounds.size

        // 将 SKView 添加到 VC
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.presentScene(scene)
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        view.addSubview(skView)
        self.skView = skView
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        setupPauseUI()

        // 监听系统通知：应用进入后台/前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupPauseUI() {
        view.addSubview(pauseButton)
        view.addSubview(pauseOverlayView)
        pauseOverlayView.addSubview(pausePanel)
        pausePanel.addSubview(pauseTitleLabel)
        pausePanel.addSubview(pauseSummaryLabel)
        pausePanel.addSubview(resumeButton)
        pausePanel.addSubview(restartButton)
        pausePanel.addSubview(exitButton)

        NSLayoutConstraint.activate([
            pauseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            pauseButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            pauseOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pauseOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pauseOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            pauseOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pausePanel.centerXAnchor.constraint(equalTo: pauseOverlayView.centerXAnchor),
            pausePanel.centerYAnchor.constraint(equalTo: pauseOverlayView.centerYAnchor),
            pausePanel.widthAnchor.constraint(equalToConstant: 312),

            pauseTitleLabel.topAnchor.constraint(equalTo: pausePanel.topAnchor, constant: 24),
            pauseTitleLabel.leadingAnchor.constraint(equalTo: pausePanel.leadingAnchor, constant: 20),
            pauseTitleLabel.trailingAnchor.constraint(equalTo: pausePanel.trailingAnchor, constant: -20),

            pauseSummaryLabel.topAnchor.constraint(equalTo: pauseTitleLabel.bottomAnchor, constant: 12),
            pauseSummaryLabel.leadingAnchor.constraint(equalTo: pausePanel.leadingAnchor, constant: 24),
            pauseSummaryLabel.trailingAnchor.constraint(equalTo: pausePanel.trailingAnchor, constant: -24),

            resumeButton.topAnchor.constraint(equalTo: pauseSummaryLabel.bottomAnchor, constant: 20),
            resumeButton.leadingAnchor.constraint(equalTo: pausePanel.leadingAnchor, constant: 24),
            resumeButton.trailingAnchor.constraint(equalTo: pausePanel.trailingAnchor, constant: -24),
            resumeButton.heightAnchor.constraint(equalToConstant: 48),

            restartButton.topAnchor.constraint(equalTo: resumeButton.bottomAnchor, constant: 12),
            restartButton.leadingAnchor.constraint(equalTo: resumeButton.leadingAnchor),
            restartButton.trailingAnchor.constraint(equalTo: resumeButton.trailingAnchor),
            restartButton.heightAnchor.constraint(equalTo: resumeButton.heightAnchor),

            exitButton.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 12),
            exitButton.leadingAnchor.constraint(equalTo: resumeButton.leadingAnchor),
            exitButton.trailingAnchor.constraint(equalTo: resumeButton.trailingAnchor),
            exitButton.heightAnchor.constraint(equalTo: resumeButton.heightAnchor),
            exitButton.bottomAnchor.constraint(equalTo: pausePanel.bottomAnchor, constant: -24)
        ])
    }

    private func makePauseActionButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func presentPauseOverlay() {
        let snapshot = scene.pauseSession()
        pauseSummaryLabel.text = """
        当前距离 \(snapshot.currentDistance)m
        会话 \(snapshot.sessionThrows) 投 · 完美 \(snapshot.sessionPerfectCount) 次 · 会话最佳 \(snapshot.sessionBestDistance)m
        \(snapshot.challengeTitle) \(snapshot.challengeBest)/\(snapshot.challengeTarget)m
        \(snapshot.nextGoalText)
        """
        isPauseOverlayVisible = true
        pauseOverlayView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.pauseOverlayView.alpha = 1
        }
    }

    private func dismissPauseOverlay(resumeScene: Bool) {
        isPauseOverlayVisible = false
        UIView.animate(withDuration: 0.2, animations: {
            self.pauseOverlayView.alpha = 0
        }) { _ in
            self.pauseOverlayView.isHidden = true
            if resumeScene {
                self.scene?.resumeSession()
            }
        }
    }

    @objc private func pauseTapped() {
        AudioManager.shared.playButtonTapSound()
        guard !isPauseOverlayVisible else { return }
        presentPauseOverlay()
    }

    @objc private func resumeTapped() {
        AudioManager.shared.playButtonTapSound()
        dismissPauseOverlay(resumeScene: true)
    }

    @objc private func restartTapped() {
        AudioManager.shared.playButtonTapSound()
        dismissPauseOverlay(resumeScene: false)
        scene?.restartSession()
    }

    @objc private func exitFromPauseTapped() {
        AudioManager.shared.playButtonTapSound()
        dismissPauseOverlay(resumeScene: false)
        dismiss(animated: true)
    }

    @objc private func appWillResignActive() {
        scene?.isPaused = true
    }

    @objc private func appDidBecomeActive() {
        scene?.isPaused = isPauseOverlayVisible
    }

    override var prefersStatusBarHidden: Bool { true }
}
