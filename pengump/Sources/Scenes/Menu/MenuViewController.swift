import UIKit

/// 主菜单界面
final class MenuViewController: UIViewController {

    private let gradientLayer = CAGradientLayer()

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "打企鹅"
        label.font = .systemFont(ofSize: 44, weight: .heavy)
        label.textColor = UIColor(red: 0.12, green: 0.34, blue: 0.63, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "投送王牌企鹅，推进三章战役，冲击三星和精英勋章。"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor(red: 0.30, green: 0.43, blue: 0.56, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var progressCard: UIView = {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        card.layer.shadowColor = UIColor(red: 0.26, green: 0.47, blue: 0.66, alpha: 1.0).cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 18
        card.layer.shadowOffset = CGSize(width: 0, height: 12)
        return card
    }()

    private lazy var progressTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "当前进度"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.20, green: 0.31, blue: 0.45, alpha: 1.0)
        return label
    }()

    private lazy var progressValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = UIColor(red: 0.11, green: 0.42, blue: 0.76, alpha: 1.0)
        return label
    }()

    private lazy var progressDetailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.36, green: 0.48, blue: 0.59, alpha: 1.0)
        label.numberOfLines = 0
        return label
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("开始冒险", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        button.backgroundColor = UIColor(red: 0.18, green: 0.50, blue: 0.89, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor(red: 0.18, green: 0.50, blue: 0.89, alpha: 1.0).cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)
        return button
    }()

    private lazy var leaderboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("排行榜", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.96, green: 0.79, blue: 0.22, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(leaderboardTapped), for: .touchUpInside)
        return button
    }()

    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("设置", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.setTitleColor(UIColor(red: 0.22, green: 0.34, blue: 0.48, alpha: 1.0), for: .normal)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        button.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateProgressSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AudioManager.shared.playMusic(.menu)
        updateProgressSummary()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupUI() {
        gradientLayer.colors = [
            UIColor(red: 0.80, green: 0.91, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.94, green: 0.98, blue: 1.0, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)

        view.addSubview(logoLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(progressCard)
        view.addSubview(startButton)
        view.addSubview(leaderboardButton)
        view.addSubview(settingsButton)

        progressCard.addSubview(progressTitleLabel)
        progressCard.addSubview(progressValueLabel)
        progressCard.addSubview(progressDetailLabel)

        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            logoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            progressCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            progressCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            progressTitleLabel.topAnchor.constraint(equalTo: progressCard.topAnchor, constant: 20),
            progressTitleLabel.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 20),
            progressTitleLabel.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -20),

            progressValueLabel.topAnchor.constraint(equalTo: progressTitleLabel.bottomAnchor, constant: 10),
            progressValueLabel.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 20),
            progressValueLabel.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -20),

            progressDetailLabel.topAnchor.constraint(equalTo: progressValueLabel.bottomAnchor, constant: 8),
            progressDetailLabel.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 20),
            progressDetailLabel.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -20),
            progressDetailLabel.bottomAnchor.constraint(equalTo: progressCard.bottomAnchor, constant: -20),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 60),
            startButton.topAnchor.constraint(greaterThanOrEqualTo: progressCard.bottomAnchor, constant: 24),
            startButton.bottomAnchor.constraint(equalTo: leaderboardButton.topAnchor, constant: -16),

            leaderboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            leaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            leaderboardButton.heightAnchor.constraint(equalToConstant: 52),
            leaderboardButton.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -12),

            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            settingsButton.heightAnchor.constraint(equalToConstant: 52),
            settingsButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func updateProgressSummary() {
        let totalStars = (1...Levels.totalLevels).reduce(0) { $0 + SaveManager.shared.stars(for: $1) }
        let bestScore = SaveManager.shared.topScores(limit: 1).first?.score ?? 0
        let medals = SaveManager.shared.completedChallengeCount
        let unlocked = SaveManager.shared.unlockedLevels
        let spotlightLevel = min(max(unlocked, 1), Levels.totalLevels)
        let presentation = Levels.presentation(for: spotlightLevel)
        let nextBattlePrefix = presentation.isBossLevel ? "下一战 BOSS" : "下一战"

        progressValueLabel.text = "已解锁 \(min(unlocked, Levels.totalLevels))/\(Levels.totalLevels) 关"
        progressDetailLabel.text = """
        星 \(totalStars) / \(Levels.totalLevels * 3) · 勋章 \(medals) / \(Levels.totalLevels) · 最高分 \(bestScore)
        当前战区 \(presentation.chapterTitle) · \(nextBattlePrefix) \(presentation.operationTitle)
        """
    }

    @objc private func startGameTapped() {
        AudioManager.shared.playButtonTapSound()
        let levelSelectVC = LevelSelectViewController()
        levelSelectVC.modalPresentationStyle = .fullScreen
        present(levelSelectVC, animated: true)
    }

    @objc private func leaderboardTapped() {
        AudioManager.shared.playButtonTapSound()
        showLeaderboardPanel()
    }

    @objc private func settingsTapped() {
        AudioManager.shared.playButtonTapSound()
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .fullScreen
        present(settingsVC, animated: true)
    }

    private func showLeaderboardPanel() {
        let panel = LeaderboardManager.shared.createLeaderboardPanel { [weak self] in
            self?.dismissLeaderboardPanel()
        }
        panel.alpha = 0
        panel.tag = 9090
        view.addSubview(panel)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.topAnchor),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        UIView.animate(withDuration: 0.25) {
            panel.alpha = 1
        }
    }

    private func dismissLeaderboardPanel() {
        guard let panel = view.viewWithTag(9090) else { return }
        UIView.animate(withDuration: 0.2, animations: {
            panel.alpha = 0
        }) { _ in
            panel.removeFromSuperview()
        }
    }
}
