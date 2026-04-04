import UIKit
import SnapKit

/// 主菜单界面
class MenuViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🦭 海豹甩企鹅"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = UIColor(red: 0.14, green: 0.32, blue: 0.58, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.31, green: 0.39, blue: 0.49, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始首投", for: .normal)
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

        startButton.setTitle(totalThrows > 0 ? "再来一投" : "开始首投", for: .normal)

        if let latestRun {
            statusLabel.text = """
            全局最佳 \(bestDistance)m
            最近一投 \(latestRun.distance)m · \(releaseSummary(for: latestRun))
            累计远投 \(totalThrows) 次
            """
            return
        }

        statusLabel.text = """
        直接挑战最远距离
        短局结算后立刻开下一投
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
}
