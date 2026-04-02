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

    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⚙️ 设置", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(logoLabel)
        view.addSubview(startButton)
        view.addSubview(settingsButton)

        logoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
        }

        startButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoLabel.snp.bottom).offset(48)
            make.width.equalTo(220)
            make.height.equalTo(56)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(startButton.snp.bottom).offset(20)
        }
    }

    // MARK: - Actions

    @objc private func startGameTapped() {
        let levelSelectVC = LevelSelectViewController()
        levelSelectVC.modalPresentationStyle = .fullScreen
        present(levelSelectVC, animated: true)
    }

    @objc private func settingsTapped() {
        // TODO: 设置页面
    }
}
