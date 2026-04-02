import UIKit
import SnapKit

/// 关卡选择界面
class LevelSelectViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "选择关卡"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("← 返回", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 90)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(LevelCell.self, forCellWithReuseIdentifier: "LevelCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let totalLevels = 15

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 刷新关卡状态
        collectionView.reloadData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    private func startLevel(_ level: Int) {
        // 重置道具效果（跨关卡残留bug修复）
        ItemSystem.shared.resetForNewLevel()

        // 检查体力
        if StaminaSystem.shared.isEmpty {
            showStaminaEmptyAlert()
            return
        }

        // 检查关卡是否解锁
        guard SaveManager.shared.isLevelUnlocked(level) else {
            showLockedAlert(level: level)
            return
        }

        // 消耗体力
        _ = StaminaSystem.shared.consume()

        let gameVC = GameViewController(level: level)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }

    private func showStaminaEmptyAlert() {
        let alert = UIAlertController(
            title: "体力不足",
            message: "体力已耗尽，请等待恢复。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showLockedAlert(level: Int) {
        let alert = UIAlertController(
            title: "关卡未解锁",
            message: "需要先通关第 \(level - 1) 关才能解锁此关卡。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension LevelSelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalLevels
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
        let level = indexPath.item + 1
        let isUnlocked = SaveManager.shared.isLevelUnlocked(level)
        let stars = SaveManager.shared.stars(for: level)
        cell.configure(levelNumber: level, isUnlocked: isUnlocked, stars: stars)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LevelSelectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        startLevel(indexPath.item + 1)
    }
}

// MARK: - LevelCell

class LevelCell: UICollectionViewCell {

    private let numberLabel = UILabel()
    private let starLabel = UILabel()
    private let lockOverlay = UIView()
    private let lockIcon = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        layer.cornerRadius = 12
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor

        numberLabel.font = .systemFont(ofSize: 24, weight: .bold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center

        starLabel.font = .systemFont(ofSize: 12)
        starLabel.textColor = .yellow
        starLabel.textAlignment = .center

        lockOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        lockOverlay.layer.cornerRadius = 12
        lockOverlay.isHidden = true

        lockIcon.text = "🔒"
        lockIcon.font = .systemFont(ofSize: 24)
        lockIcon.textAlignment = .center

        contentView.addSubview(numberLabel)
        contentView.addSubview(starLabel)
        contentView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        numberLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }

        starLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(numberLabel.snp.bottom).offset(4)
        }

        lockOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lockIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func configure(levelNumber: Int, isUnlocked: Bool, stars: Int) {
        numberLabel.text = "\(levelNumber)"

        if isUnlocked {
            lockOverlay.isHidden = true
            numberLabel.isHidden = false
            starLabel.isHidden = false

            // 根据星级显示
            if stars > 0 {
                starLabel.text = String(repeating: "⭐", count: stars)
                starLabel.textColor = .yellow
            } else {
                starLabel.text = "未通关"
                starLabel.textColor = UIColor.white.withAlphaComponent(0.6)
                starLabel.font = .systemFont(ofSize: 10)
            }

            // 背景颜色：已通关用蓝色系，未通关用绿色系
            if stars > 0 {
                backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
            } else {
                backgroundColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
            }
        } else {
            lockOverlay.isHidden = false
            numberLabel.isHidden = true
            starLabel.isHidden = true
            backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        }
    }
}
