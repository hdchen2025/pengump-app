import UIKit
import SnapKit

/// 主菜单界面
class MenuViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🐧 企鹅飞多远"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = UIColor(red: 0.14, green: 0.32, blue: 0.58, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.31, green: 0.39, blue: 0.49, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始远投", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.16, green: 0.46, blue: 0.78, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)
        return button
    }()

    private lazy var leaderboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🏁 纪录", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.95, green: 0.63, blue: 0.15, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(leaderboardTapped), for: .touchUpInside)
        return button
    }()

    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⚙️ 设置", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AudioManager.shared.playMusic(.menu)
        refreshStatus()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(logoLabel)
        view.addSubview(statusLabel)
        view.addSubview(startButton)
        view.addSubview(leaderboardButton)
        view.addSubview(settingsButton)

        logoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-120)
        }

        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoLabel.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(36)
        }

        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(28)
            make.width.equalTo(220)
            make.height.equalTo(56)
        }

        leaderboardButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(startButton.snp.bottom).offset(16)
            make.width.equalTo(220)
            make.height.equalTo(48)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(leaderboardButton.snp.bottom).offset(20)
        }
    }

    // MARK: - Actions

    @objc private func startGameTapped() {
        AudioManager.shared.playButtonTapSound()
        let gameVC = GameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
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

    // MARK: - 弹窗

    private func showLeaderboardPanel() {
        guard view.viewWithTag(1000) == nil else { return }
        let panel = LeaderboardManager.shared.createLeaderboardPanel { [weak self] in
            self?.dismissLeaderboardPanel()
        }
        panel.alpha = 0
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        UIView.animate(withDuration: 0.25) {
            panel.alpha = 1
        }
    }

    private func dismissLeaderboardPanel() {
        if let panel = view.viewWithTag(1000) {
            UIView.animate(withDuration: 0.2, animations: {
                panel.alpha = 0
            }) { _ in
                panel.removeFromSuperview()
            }
        }
    }

    private func refreshStatus() {
        let saveManager = SaveManager.shared
        let bestDistance = saveManager.bestDistance
        let totalThrows = saveManager.totalThrows
        let latestRun = saveManager.latestDistanceRecord
        let challenge = saveManager.currentDailyChallenge()
        let challengeText = dailyChallengeSummary(challenge: challenge, saveManager: saveManager)
        let activityText = dailyChallengeActivitySummary(saveManager: saveManager)
        let achievementText = achievementSummary(saveManager: saveManager)
        let titleText = distanceTitleSummary(saveManager: saveManager)

        startButton.setTitle(totalThrows > 0 ? "再来远投" : "开始远投", for: .normal)

        if let latestRun {
            statusLabel.text = """
            全局最佳 \(bestDistance)m
            最近一投 \(latestRun.distance)m · \(releaseSummary(for: latestRun))
            \(activityText)
            今日挑战：\(challenge.title)
            \(challengeText)
            \(achievementText)
            \(titleText)
            """
            return
        }

        statusLabel.text = """
        目标先冲过 \(DistanceMilestones.all.first ?? 100)m
        \(activityText)
        今日挑战：\(challenge.title)
        \(challengeText)
        \(achievementText)
        自动结算后立刻下一投
        \(titleText)
        """
    }

    private func releaseSummary(for record: DistanceRecord) -> String {
        if record.perfectRelease {
            return "完美出手"
        }
        return biomeTitle(for: record.highestBiome)
    }

    private func biomeTitle(for highestBiome: Int) -> String {
        switch highestBiome {
        case 3:
            return "冲进传说区"
        case 2:
            return "冲到极光区"
        case 1:
            return "冲到裂谷区"
        default:
            return "雪地起跑"
        }
    }

    private func dailyChallengeSummary(challenge: DailyChallenge, saveManager: SaveManager) -> String {
        let todayBest = saveManager.dailyChallengeBest(for: challenge)
        if todayBest > 0 {
            return "目标 \(challenge.targetDistance)m · 今日最佳 \(todayBest)m"
        }
        return "目标 \(challenge.targetDistance)m · 今日最佳待刷新"
    }

    private func dailyChallengeActivitySummary(saveManager: SaveManager) -> String {
        let activity = saveManager.dailyChallengeActivitySummary()
        return "近7日 \(activity.playedDays)/7 天 · 连续 \(activity.streakText) 天"
    }

    private func achievementSummary(saveManager: SaveManager) -> String {
        if let progress = saveManager.nextAchievementProgressSummary() {
            return "下一成就：\(progress.title) \(progress.progressText)"
        }
        return "成就已全部解锁"
    }

    private func distanceTitleSummary(saveManager: SaveManager) -> String {
        let progress = saveManager.distanceTitleProgress()
        if let nextTitle = progress.nextTitle {
            return "称号 \(progress.currentTitle.title) · 距 \(nextTitle.title) 还差 \(progress.remainingDistance)m"
        }
        return "称号 \(progress.currentTitle.title) · 已达最高段位"
    }
}
