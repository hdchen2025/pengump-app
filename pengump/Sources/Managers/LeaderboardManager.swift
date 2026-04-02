import Foundation
import UIKit
import SnapKit

// MARK: - 排行榜管理器

class LeaderboardManager {
    static let shared = LeaderboardManager()

    private init() {}

    // MARK: - 排行榜UI

    /// 创建排行榜面板
    func createLeaderboardPanel(onClose: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.tag = 1001

        let titleLabel = UILabel()
        titleLabel.text = "🏆 积分排行榜"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.9, green: 0.7, blue: 0.0, alpha: 1.0)

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tag = 1002
        tableView.delegate = LeaderboardTableDelegate()
        tableView.dataSource = LeaderboardTableDelegate()
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: "LeaderboardCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 8
        tableView.isScrollEnabled = true

        // 注入数据
        let topScores = SaveManager.shared.topScores(limit: 10)
        if let delegate = tableView.delegate as? LeaderboardTableDelegate {
            delegate.scores = topScores
        }
        if let source = tableView.dataSource as? LeaderboardTableDelegate {
            source.scores = topScores
        }

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(nil, action: #selector(closeTapped(_:)), for: .touchUpInside)
        objc_setAssociatedObject(closeButton, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(container, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        container.addSubview(panel)
        panel.addSubview(titleLabel)
        panel.addSubview(tableView)
        panel.addSubview(closeButton)

        panel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(340)
            make.height.equalTo(420)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(closeButton.snp.top).offset(-16)
        }

        closeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(36)
        }

        return container
    }

    @objc private func closeTapped(_ sender: UIButton) {
        if let action = objc_getAssociatedObject(sender, "closeAction") as? () -> Void {
            action()
        }
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        if let panel = gesture.view?.viewWithTag(1001), !panel.frame.contains(location) {
            if let closeAction = objc_getAssociatedObject(gesture.view!, "closeAction") as? () -> Void {
                closeAction()
            }
        }
    }
}

// MARK: - 排行榜Table数据源/代理

private class LeaderboardTableDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    var scores: [ScoreRecord] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(scores.count, 1)  // 至少显示一行（空状态）
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
        return 52
    }
}

// MARK: - 排行榜单元格

class LeaderboardCell: UITableViewCell {

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

        rankLabel.font = .systemFont(ofSize: 18, weight: .bold)
        rankLabel.textAlignment = .center
        rankLabel.frame = CGRect(x: 0, y: 0, width: 40, height: 52)

        levelLabel.font = .systemFont(ofSize: 14, weight: .medium)
        levelLabel.textColor = .darkGray

        scoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        scoreLabel.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)

        starsLabel.font = .systemFont(ofSize: 14)

        dateLabel.font = .systemFont(ofSize: 11)
        dateLabel.textColor = .gray

        contentView.addSubview(rankLabel)
        contentView.addSubview(levelLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(starsLabel)
        contentView.addSubview(dateLabel)

        rankLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }

        levelLabel.snp.makeConstraints { make in
            make.left.equalTo(rankLabel.snp.right).offset(8)
            make.top.equalToSuperview().offset(8)
        }

        starsLabel.snp.makeConstraints { make in
            make.left.equalTo(rankLabel.snp.right).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        scoreLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
        }

        dateLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
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
        starsLabel.text = String(repeating: "⭐", count: record.stars)

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
