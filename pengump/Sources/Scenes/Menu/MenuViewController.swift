import UIKit
import SnapKit

/// 主菜单界面
class MenuViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🐧 打企鹅"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始游戏", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)
        return button
    }()

    private lazy var leaderboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🏆 排行榜", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
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
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(logoLabel)
        view.addSubview(startButton)
        view.addSubview(leaderboardButton)
        view.addSubview(settingsButton)

        logoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-120)
        }

        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoLabel.snp.bottom).offset(40)
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
        let levelSelectVC = LevelSelectViewController()
        levelSelectVC.modalPresentationStyle = .fullScreen
        present(levelSelectVC, animated: true)
    }

    @objc private func leaderboardTapped() {
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
        if let panel = view.subviews.first(where: { $0.tag == 1001 || ($0.backgroundColor == UIColor.black.withAlphaComponent(0.5) && $0.subviews.contains(where: { $0.tag == 1001 })) }) {
            UIView.animate(withDuration: 0.2, animations: {
                panel.alpha = 0
            }) { _ in
                panel.removeFromSuperview()
            }
        }
    }
}
