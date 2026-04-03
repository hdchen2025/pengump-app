import Foundation
import UIKit
import ObjectiveC

// MARK: - 排行榜管理器

final class LeaderboardManager: NSObject {
    static let shared = LeaderboardManager()

    private enum AssociatedKeys {
        static var closeAction: UInt8 = 0
        static var tableController: UInt8 = 0
    }

    private override init() {}

    // MARK: - 排行榜UI

    /// 创建排行榜面板
    func createLeaderboardPanel(onClose: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let panel = UIView()
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 20
        panel.tag = 1001

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "积分排行榜"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.93, green: 0.71, blue: 0.05, alpha: 1.0)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "记录每一关打出的最佳成绩"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tag = 1002
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 10
        tableView.isScrollEnabled = true
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: "LeaderboardCell")

        let tableController = LeaderboardTableController(scores: SaveManager.shared.topScores(limit: 10))
        tableView.delegate = tableController
        tableView.dataSource = tableController
        objc_setAssociatedObject(tableView, &AssociatedKeys.tableController, tableController, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
        closeButton.layer.cornerRadius = 10
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        objc_setAssociatedObject(closeButton, &AssociatedKeys.closeAction, onClose, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(container, &AssociatedKeys.closeAction, onClose, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        container.addGestureRecognizer(tapGesture)

        container.addSubview(panel)
        panel.addSubview(titleLabel)
        panel.addSubview(subtitleLabel)
        panel.addSubview(tableView)
        panel.addSubview(closeButton)

        let preferredWidth = panel.widthAnchor.constraint(equalToConstant: 340)
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            panel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            panel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            panel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -32),
            preferredWidth,
            panel.heightAnchor.constraint(equalToConstant: 430),

            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -16),

            closeButton.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -16),
            closeButton.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 110),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        return container
    }

    @objc private func closeTapped(_ sender: UIButton) {
        if let action = objc_getAssociatedObject(sender, &AssociatedKeys.closeAction) as? () -> Void {
            action()
        }
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        if let panel = gesture.view?.viewWithTag(1001),
           !panel.frame.contains(location),
           let container = gesture.view,
           let closeAction = objc_getAssociatedObject(container, &AssociatedKeys.closeAction) as? () -> Void {
            closeAction()
        }
    }
}

// MARK: - 排行榜Table数据源/代理

private final class LeaderboardTableController: NSObject, UITableViewDataSource, UITableViewDelegate {

    let scores: [ScoreRecord]

    init(scores: [ScoreRecord]) {
        self.scores = scores
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(scores.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardCell

        if indexPath.row < scores.count {
            let record = scores[indexPath.row]
            cell.configure(rank: indexPath.row + 1, record: record)
        } else {
            cell.configureEmpty()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }
}

// MARK: - 排行榜单元格

final class LeaderboardCell: UITableViewCell {

    private let rankLabel = UILabel()
    private let levelLabel = UILabel()
    private let scoreLabel = UILabel()
    private let starsLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.font = .systemFont(ofSize: 18, weight: .bold)
        rankLabel.textAlignment = .center

        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.font = .systemFont(ofSize: 14, weight: .medium)
        levelLabel.textColor = .darkGray

        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        scoreLabel.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)

        starsLabel.translatesAutoresizingMaskIntoConstraints = false
        starsLabel.font = .systemFont(ofSize: 14)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 11)
        dateLabel.textColor = .gray

        contentView.addSubview(rankLabel)
        contentView.addSubview(levelLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(starsLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 36),

            levelLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            levelLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),

            starsLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            starsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9),

            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scoreLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),

            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9)
        ])
    }

    func configure(rank: Int, record: ScoreRecord) {
        switch rank {
        case 1: rankLabel.text = "🥇"
        case 2: rankLabel.text = "🥈"
        case 3: rankLabel.text = "🥉"
        default: rankLabel.text = "\(rank)"
        }

        levelLabel.text = "第 \(record.level) 关"
        scoreLabel.text = "\(record.score) 分"
        starsLabel.text = record.stars > 0 ? String(repeating: "⭐", count: record.stars) : "未通关"

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        dateLabel.text = formatter.string(from: record.date)
    }

    func configureEmpty() {
        rankLabel.text = "—"
        levelLabel.text = "暂无记录"
        scoreLabel.text = ""
        starsLabel.text = ""
        dateLabel.text = ""
    }
}
