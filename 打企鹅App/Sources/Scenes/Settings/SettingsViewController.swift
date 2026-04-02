import UIKit
import SnapKit

// MARK: - 设置项类型

enum SettingsSection: Int, CaseIterable {
    case audio
    case language
    case about

    var title: String {
        let english = UserDefaults.standard.string(forKey: "game_language") == "English"
        switch self {
        case .audio: return english ? "Audio" : "声音设置"
        case .language: return english ? "Language" : "语言"
        case .about: return english ? "About" : "关于"
        }
    }
}

// MARK: - 设置ViewController

class SettingsViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        table.register(SliderTableViewCell.self, forCellReuseIdentifier: "SliderCell")
        table.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        return table
    }()

    private lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
        view.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = "⚙️ 设置"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }

        return view
    }()

    // MARK: - Data

    private enum SettingsItem {
        case musicSwitch
        case musicVolume
        case sfxSwitch
        case sfxVolume
        case language(String)
        case about(String)
        case version(String)
        case privacy
        case rateApp
        case removeAds
    }

    private var sections: [(SettingsSection, [SettingsItem])] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupData()
        tableView.reloadData()
    }

    // MARK: - Setup

    private var isEnglish: Bool {
        UserDefaults.standard.string(forKey: "game_language") == "English"
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(tableView)
        tableView.tableHeaderView = headerView

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 导航栏返回按钮
        let backButton = UIButton(type: .system)
        backButton.setTitle("← 返回", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16)
        backButton.setTitleColor(UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0), for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.frame = CGRect(x: 16, y: 50, width: 80, height: 32)
        view.addSubview(backButton)
    }

    private func setupData() {
        let audioManager = AudioManager.shared

        let currentLang = UserDefaults.standard.string(forKey: "game_language") ?? "简体中文"

        sections = [
            (.audio, [
                .musicSwitch,
                .musicVolume,
                .sfxSwitch,
                .sfxVolume
            ]),
            (.language, [
                .language(currentLang)
            ]),
            (.about, [
                .version("v1.0.0"),
                .about("打企鹅 - 像素弹弓休闲游戏"),
                .rateApp,
                .removeAds,
                .privacy
            ])
        ]
    }

    // MARK: - Actions

    @objc private func backTapped() {
        AudioManager.shared.playButtonTapSound()
        dismiss(animated: true)
    }

    private func showLanguagePicker() {
        let alertTitle = isEnglish ? "Select Language" : "选择语言"
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)

        let languages = ["简体中文", "English"]
        for lang in languages {
            let action = UIAlertAction(title: lang, style: .default) { [weak self] _ in
                UserDefaults.standard.set(lang, forKey: "game_language")
                self?.setupData()
                self?.tableView.reloadData()
                self?.showRestartAlert()
            }
            if lang == (UserDefaults.standard.string(forKey: "game_language") ?? "简体中文") {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: isEnglish ? "Cancel" : "取消", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alert, animated: true)
    }

    private func showRestartAlert() {
        let alert = UIAlertController(
            title: isEnglish ? "Language Changed" : "语言已更改",
            message: isEnglish ? "Some changes will take effect after restarting the app." : "部分语言更改将在重启应用后生效。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: isEnglish ? "OK" : "确定", style: .default))
        present(alert, animated: true)
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.hitpenguin.com/privacy") {
            UIApplication.shared.open(url)
        }
    }

    private func openRatePage() {
        // 打开App Store评分页
        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    private func showRemoveAdsPurchase() {
        let alert = UIAlertController(
            title: isEnglish ? "Remove Ads" : "移除广告",
            message: isEnglish ? "One-time purchase, remove all ads permanently.\n\nPrice: ¥25" : "一次性购买，永久移除所有广告。\n\n价格：¥25",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: isEnglish ? "Purchase" : "购买", style: .default) { [weak self] _ in
            // TODO: 接入IAP购买
            self?.showComingSoonAlert()
        })

        alert.addAction(UIAlertAction(title: isEnglish ? "Cancel" : "取消", style: .cancel))

        present(alert, animated: true)
    }

    private func showComingSoonAlert() {
        let alert = UIAlertController(
            title: isEnglish ? "Coming Soon" : "即将上线",
            message: isEnglish ? "In-app purchases are being prepared. Stay tuned!" : "内购功能正在准备中，敬请期待！",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: isEnglish ? "OK" : "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].1[indexPath.row]
        let audioManager = AudioManager.shared

        switch item {
        case .musicSwitch:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            let title = isEnglish ? "🎵 Background Music" : "🎵 背景音乐"
            cell.configure(title: title, isOn: audioManager.isMusicEnabled) { isOn in
                audioManager.isMusicEnabled = isOn
                if isOn {
                    audioManager.playMusic(.menu)
                } else {
                    audioManager.stopMusic()
                }
            }
            return cell

        case .musicVolume:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as! SliderTableViewCell
            let title = isEnglish ? "Music Volume" : "音乐音量"
            cell.configure(title: title, value: audioManager.musicVolume, icon: "🎵") { value in
                audioManager.musicVolume = value
            }
            return cell

        case .sfxSwitch:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            let title = isEnglish ? "🔊 Sound Effects" : "🔊 音效"
            cell.configure(title: title, isOn: audioManager.isSFXEnabled) { isOn in
                audioManager.isSFXEnabled = isOn
            }
            return cell

        case .sfxVolume:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as! SliderTableViewCell
            let title = isEnglish ? "SFX Volume" : "音效音量"
            cell.configure(title: title, value: audioManager.sfxVolume, icon: "🔊") { value in
                audioManager.sfxVolume = value
            }
            return cell

        case .language(let currentLang):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = isEnglish ? "Language" : "语言"
            config.secondaryText = currentLang
            config.secondaryTextProperties.color = .gray
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell

        case .version(let version):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = isEnglish ? "Version" : "版本"
            config.secondaryText = version
            config.secondaryTextProperties.color = .gray
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell

        case .about(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = text
            config.textProperties.font = .systemFont(ofSize: 14)
            config.textProperties.alignment = .center
            config.textProperties.color = .darkGray
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell

        case .rateApp:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = isEnglish ? "⭐️ Rate Us" : "⭐️ 给我们评分"
            config.textProperties.color = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell

        case .removeAds:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if AdManager.shared.isAdsRemoved {
                var config = cell.defaultContentConfiguration()
                config.text = isEnglish ? "🚫 Ads Removed" : "🚫 已移除广告"
                config.textProperties.color = .gray
                cell.contentConfiguration = config
                cell.selectionStyle = .none
            } else {
                var config = cell.defaultContentConfiguration()
                config.text = isEnglish ? "🚫 Remove Ads" : "🚫 移除广告"
                config.secondaryText = isEnglish ? "¥25 · Permanent" : "¥25 · 永久有效"
                config.secondaryTextProperties.color = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
                config.textProperties.color = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
            }
            return cell

        case .privacy:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = isEnglish ? "📜 Privacy Policy" : "📜 隐私政策"
            config.textProperties.color = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section].1[indexPath.row]

        switch item {
        case .language:
            showLanguagePicker()
        case .rateApp:
            openRatePage()
        case .removeAds:
            if !AdManager.shared.isAdsRemoved {
                showRemoveAdsPurchase()
            }
        case .privacy:
            openPrivacyPolicy()
        default:
            break
        }
    }

    func tableView(_ titleForHeaderInSection section: Int) -> String? {
        return sections[section].0.title
    }
}

// MARK: - Switch Cell

class SwitchTableViewCell: UITableViewCell {

    private lazy var switchControl: UISwitch = {
        let s = UISwitch()
        s.onTintColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        s.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return s
    }()

    private var onSwitchChanged: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = switchControl
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isOn: Bool, onChanged: @escaping (Bool) -> Void) {
        var config = defaultContentConfiguration()
        config.text = title
        contentConfiguration = config

        switchControl.isOn = isOn
        onSwitchChanged = onChanged
    }

    @objc private func switchChanged() {
        onSwitchChanged?(switchControl.isOn)
    }
}

// MARK: - Slider Cell

class SliderTableViewCell: UITableViewCell {

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .darkGray
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()

    private lazy var slider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0
        s.maximumValue = 1
        s.minimumTrackTintColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        s.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return s
    }()

    private var onSliderChanged: ((Float) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(iconLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(slider)

        iconLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconLabel.snp.right).offset(8)
            make.centerY.equalTo(iconLabel)
        }

        valueLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(iconLabel)
            make.width.equalTo(50)
        }

        slider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(title: String, value: Float, icon: String, onChanged: @escaping (Float) -> Void) {
        iconLabel.text = icon
        titleLabel.text = title
        slider.value = value
        valueLabel.text = "\(Int(value * 100))%"
        onSliderChanged = onChanged
    }

    @objc private func sliderChanged() {
        let value = slider.value
        valueLabel.text = "\(Int(value * 100))%"
        onSliderChanged?(value)
    }
}
