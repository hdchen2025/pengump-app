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
        let gameVC = GameViewController(level: level)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension LevelSelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalLevels
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelCell", for: indexPath) as! LevelCell
        cell.configure(levelNumber: indexPath.item + 1)
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

        contentView.addSubview(numberLabel)
        contentView.addSubview(starLabel)

        numberLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }

        starLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(numberLabel.snp.bottom).offset(4)
        }
    }

    func configure(levelNumber: Int) {
        numberLabel.text = "\(levelNumber)"
        starLabel.text = "⭐⭐⭐"
    }
}
