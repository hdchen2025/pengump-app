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

    private lazy var staminaContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0).cgColor
        return view
    }()

    private lazy var staminaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()

    private lazy var coinsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
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

    private lazy var shopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🏪 商店", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.2, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(shopTapped), for: .touchUpInside)
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCallbacks()
        StaminaSystem.shared.startRecoveryTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        // 播放菜单背景音乐
        AudioManager.shared.playMusic(.menu)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(staminaContainer)
        staminaContainer.addSubview(staminaLabel)
        staminaContainer.addSubview(coinsLabel)

        view.addSubview(logoLabel)
        view.addSubview(startButton)
        view.addSubview(shopButton)
        view.addSubview(leaderboardButton)
        view.addSubview(settingsButton)

        staminaContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(60)
        }

        staminaLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }

        coinsLabel.snp.makeConstraints { make in
            make.top.equalTo(staminaLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }

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

        shopButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(startButton.snp.bottom).offset(16)
            make.width.equalTo(220)
            make.height.equalTo(48)
        }

        leaderboardButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(shopButton.snp.bottom).offset(12)
            make.width.equalTo(220)
            make.height.equalTo(48)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(leaderboardButton.snp.bottom).offset(20)
        }
    }

    private func setupCallbacks() {
        StaminaSystem.shared.onStaminaChanged = { [weak self] _, _ in
            self?.updateUI()
        }
    }

    // MARK: - UI更新

    private func updateUI() {
        // 体力显示
        let icons = StaminaSystem.shared.staminaIcons()
        if icons.count > 15 {
            // 简化显示：只显示前15个
            let filled = icons.prefix(15).filter { $0 == "❤️" }.count
            let empty = 15 - filled
            staminaLabel.text = String(repeating: "❤️", count: filled) + String(repeating: "🖤", count: empty)
        } else {
            staminaLabel.text = icons.joined()
        }

        // 金币显示
        coinsLabel.text = "💰 \(SaveManager.shared.coins) 金币"
    }

    // MARK: - Actions

    @objc private func startGameTapped() {
        // 检查体力
        if StaminaSystem.shared.isEmpty {
            showStaminaEmptyAlert()
            return
        }

        let levelSelectVC = LevelSelectViewController()
        levelSelectVC.modalPresentationStyle = .fullScreen
        present(levelSelectVC, animated: true)
    }

    @objc private func shopTapped() {
        showShopPanel()
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

    private func showStaminaEmptyAlert() {
        let alert = UIAlertController(
            title: "体力不足",
            message: "体力已耗尽，请等待恢复。\n恢复时间：\(StaminaSystem.shared.staminaRecoveryTime() ?? "—")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showShopPanel() {
        let shopView = ItemSystem.shared.createShopPanel(
            in: view,
            onPurchase: { [weak self] item in
                if ItemSystem.shared.purchase(item) {
                    self?.updateUI()
                    // 刷新商店金币显示
                    self?.refreshShopCoins()
                }
            },
            onClose: { [weak self] in
                self?.dismissShopPanel()
            }
        )
        shopView.alpha = 0
        view.addSubview(shopView)
        shopView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        UIView.animate(withDuration: 0.25) {
            shopView.alpha = 1
        }
    }

    private func dismissShopPanel() {
        if let shopView = view.viewWithTag(999) {
            UIView.animate(withDuration: 0.2, animations: {
                shopView.alpha = 0
            }) { _ in
                shopView.removeFromSuperview()
            }
        }
    }

    private func refreshShopCoins() {
        // 刷新商店金币文本（通过重新展示实现）
        dismissShopPanel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.showShopPanel()
        }
    }

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
