import UIKit

/// 关卡选择界面
final class LevelSelectViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "选择关卡"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = UIColor(red: 0.18, green: 0.31, blue: 0.46, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.38, green: 0.50, blue: 0.61, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("返回", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.22, green: 0.41, blue: 0.72, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 24, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.register(LevelCell.self, forCellWithReuseIdentifier: "LevelCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let totalLevels = Levels.totalLevels

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        refreshSummary()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.88, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(summaryLabel)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            summaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            collectionView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func refreshSummary() {
        let totalStars = (1...totalLevels).reduce(0) { $0 + SaveManager.shared.stars(for: $1) }
        let totalMedals = SaveManager.shared.completedChallengeCount
        let unlocked = min(SaveManager.shared.unlockedLevels, totalLevels)
        summaryLabel.text = "已解锁 \(unlocked)/\(totalLevels) 关  ·  已获得 \(totalStars) 颗星\n精英勋章 \(totalMedals)/\(totalLevels)"
    }

    @objc private func backTapped() {
        AudioManager.shared.playButtonTapSound()
        dismiss(animated: true)
    }

    private func startLevel(_ level: Int) {
        ItemSystem.shared.resetForNewLevel()

        guard SaveManager.shared.isLevelUnlocked(level) else {
            showLockedAlert(level: level)
            return
        }

        let gameVC = GameViewController(level: level)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
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

extension LevelSelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalLevels
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
        let level = indexPath.item + 1
        let isUnlocked = SaveManager.shared.isLevelUnlocked(level)
        let stars = SaveManager.shared.stars(for: level)
        let isCurrent = level == min(SaveManager.shared.unlockedLevels, totalLevels)
        cell.configure(
            levelNumber: level,
            isUnlocked: isUnlocked,
            stars: stars,
            isCurrent: isCurrent,
            badgeText: Levels.levelBadge(for: level),
            hasMedal: SaveManager.shared.isChallengeCompleted(level)
        )
        return cell
    }
}

extension LevelSelectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        startLevel(indexPath.item + 1)
    }
}

extension LevelSelectViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let horizontalPadding: CGFloat = 40
        let spacing: CGFloat = 28
        let availableWidth = collectionView.bounds.width - horizontalPadding - spacing
        let cellWidth = floor(availableWidth / 3)
        return CGSize(width: max(cellWidth, 80), height: 108)
    }
}

final class LevelCell: UICollectionViewCell {

    private let numberLabel = UILabel()
    private let starLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let medalLabel = UILabel()
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
        contentView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.shadowColor = UIColor(red: 0.12, green: 0.31, blue: 0.58, alpha: 1.0).cgColor
        contentView.layer.shadowOpacity = 0.12
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 6)

        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 28, weight: .bold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center

        starLabel.translatesAutoresizingMaskIntoConstraints = false
        starLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.numberOfLines = 2

        medalLabel.translatesAutoresizingMaskIntoConstraints = false
        medalLabel.font = .systemFont(ofSize: 10, weight: .bold)
        medalLabel.textAlignment = .center
        medalLabel.textColor = UIColor(red: 0.54, green: 0.31, blue: 0.02, alpha: 1.0)
        medalLabel.backgroundColor = UIColor(red: 1.0, green: 0.89, blue: 0.49, alpha: 0.96)
        medalLabel.layer.cornerRadius = 8
        medalLabel.layer.masksToBounds = true
        medalLabel.text = "精英"
        medalLabel.isHidden = true

        lockOverlay.translatesAutoresizingMaskIntoConstraints = false
        lockOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        lockOverlay.layer.cornerRadius = 16
        lockOverlay.isHidden = true

        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.text = "🔒"
        lockIcon.font = .systemFont(ofSize: 28)
        lockIcon.textAlignment = .center

        contentView.addSubview(numberLabel)
        contentView.addSubview(starLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(medalLabel)
        contentView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        NSLayoutConstraint.activate([
            medalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            medalLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            medalLabel.widthAnchor.constraint(equalToConstant: 34),
            medalLabel.heightAnchor.constraint(equalToConstant: 16),

            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -14),

            starLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 6),
            starLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            starLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: starLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            lockOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            lockIcon.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor)
        ])
    }

    func configure(levelNumber: Int, isUnlocked: Bool, stars: Int, isCurrent: Bool, badgeText: String, hasMedal: Bool) {
        numberLabel.text = "\(levelNumber)"
        subtitleLabel.text = isUnlocked
            ? (isCurrent ? "当前进度\n\(badgeText)" : badgeText)
            : ""

        if isUnlocked {
            lockOverlay.isHidden = true
            numberLabel.isHidden = false
            starLabel.isHidden = false
            subtitleLabel.isHidden = false
            medalLabel.isHidden = !hasMedal

            if stars > 0 {
                starLabel.text = String(repeating: "⭐", count: stars)
                starLabel.textColor = .yellow
                starLabel.font = .systemFont(ofSize: 14)
            } else {
                starLabel.text = "待挑战"
                starLabel.textColor = UIColor.white.withAlphaComponent(0.72)
                starLabel.font = .systemFont(ofSize: 12, weight: .medium)
            }

            if isCurrent {
                contentView.backgroundColor = UIColor(red: 0.15, green: 0.61, blue: 0.74, alpha: 1.0)
            } else if stars > 0 {
                contentView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
            } else {
                contentView.backgroundColor = UIColor(red: 0.28, green: 0.72, blue: 0.45, alpha: 1.0)
            }
        } else {
            lockOverlay.isHidden = false
            numberLabel.isHidden = true
            starLabel.isHidden = true
            subtitleLabel.isHidden = true
            medalLabel.isHidden = true
            contentView.backgroundColor = UIColor(white: 0.55, alpha: 1.0)
        }
    }
}
