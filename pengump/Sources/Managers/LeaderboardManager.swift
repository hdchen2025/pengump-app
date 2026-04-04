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
        container.tag = 1000
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 16
        panel.tag = 1001

        let titleLabel = UILabel()
        titleLabel.text = "🏁 远投档案"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.15, green: 0.44, blue: 0.72, alpha: 1.0)

        let bestDistanceLabel = UILabel()
        bestDistanceLabel.font = .systemFont(ofSize: 28, weight: .bold)
        bestDistanceLabel.textAlignment = .center
        bestDistanceLabel.textColor = UIColor(red: 0.12, green: 0.33, blue: 0.62, alpha: 1.0)

        let statsLabel = UILabel()
        statsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statsLabel.numberOfLines = 4
        statsLabel.textAlignment = .center
        statsLabel.textColor = UIColor(red: 0.38, green: 0.45, blue: 0.52, alpha: 1.0)

        let recentTitleLabel = UILabel()
        recentTitleLabel.text = "最近战绩"
        recentTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        recentTitleLabel.textColor = UIColor(red: 0.21, green: 0.3, blue: 0.4, alpha: 1.0)

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tag = 1002
        let delegate = LeaderboardTableDelegate()
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: "LeaderboardCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 8
        tableView.isScrollEnabled = true

        let saveManager = SaveManager.shared
        bestDistanceLabel.text = saveManager.bestDistance > 0 ? "全局最佳 \(saveManager.bestDistance)m" : "还没有远投纪录"
        statsLabel.text = statsText(from: saveManager)
        delegate.bestDistance = saveManager.bestDistance
        delegate.records = saveManager.recentDistanceRecords(limit: 10)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
        objc_setAssociatedObject(closeButton, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(container, "closeAction", onClose, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(container, "leaderboardDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        container.addSubview(panel)
        panel.addSubview(titleLabel)
        panel.addSubview(bestDistanceLabel)
        panel.addSubview(statsLabel)
        panel.addSubview(recentTitleLabel)
        panel.addSubview(tableView)
        panel.addSubview(closeButton)

        panel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(340)
            make.height.equalTo(470)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
        }

        bestDistanceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }

        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(bestDistanceLabel.snp.bottom).offset(6)
            make.left.right.equalToSuperview().inset(20)
        }

        recentTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(statsLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(recentTitleLabel.snp.bottom).offset(10)
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

    private func statsText(from saveManager: SaveManager) -> String {
        let bestBiome = biomeTitle(for: saveManager.highestBiomeReached)
        let milestoneText: String
        if let next = DistanceMilestones.next(after: saveManager.bestDistance) {
            milestoneText = "下一里程碑 \(next)m"
        } else {
            milestoneText = "已冲破基础里程碑"
        }
        let challenge = saveManager.currentDailyChallenge()
        let challengeBest = saveManager.dailyChallengeBest(for: challenge)
        let challengeText = challengeBest > 0 ? "目标 \(challenge.targetDistance)m · 今日最佳 \(challengeBest)m" : "目标 \(challenge.targetDistance)m · 今日最佳待刷新"
        let unlockedText = "已解锁成就 \(saveManager.unlockedAchievementCount)/\(AchievementID.allCases.count)"
        return "累计 \(saveManager.totalThrows) 次 · 完美出手 \(saveManager.perfectReleaseCount) 次\n最远冲到 \(bestBiome) · \(milestoneText)\n今日挑战：\(challenge.title) · \(challengeText)\n\(unlockedText)"
    }

    private func biomeTitle(for highestBiome: Int) -> String {
        switch highestBiome {
        case 3:
            return "传说区"
        case 2:
            return "极光高空区"
        case 1:
            return "冰山裂谷区"
        default:
            return "雪地起跑区"
        }
    }
}

// MARK: - 排行榜Table数据源/代理

private class LeaderboardTableDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    var records: [DistanceRecord] = []
    var bestDistance: Int = 0

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(records.count, 1)  // 至少显示一行（空状态）
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardCell

        if indexPath.row < records.count {
            let record = records[indexPath.row]
            cell.configureDistance(
                index: indexPath.row + 1,
                record: record,
                isBest: bestDistance > 0 && record.distance >= bestDistance
            )
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
    private let subtitleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let badgeLabel = UILabel()
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

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = .darkGray

        distanceLabel.font = .systemFont(ofSize: 16, weight: .bold)
        distanceLabel.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)

        badgeLabel.font = .systemFont(ofSize: 14)

        dateLabel.font = .systemFont(ofSize: 11)
        dateLabel.textColor = .gray

        contentView.addSubview(rankLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(dateLabel)

        rankLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(rankLabel.snp.right).offset(8)
            make.top.equalToSuperview().offset(8)
        }

        badgeLabel.snp.makeConstraints { make in
            make.left.equalTo(rankLabel.snp.right).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        distanceLabel.snp.makeConstraints { make in
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

        subtitleLabel.text = "第 \(record.level) 关"
        distanceLabel.text = "\(record.score) 分"
        badgeLabel.text = String(repeating: "⭐", count: record.stars)

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        dateLabel.text = formatter.string(from: record.date)
    }

    func configureDistance(index: Int, record: DistanceRecord, isBest: Bool) {
        rankLabel.text = index == 1 ? "最新" : "\(index)"
        subtitleLabel.text = biomeTitle(for: record.highestBiome)
        distanceLabel.text = "\(record.distance)m"
        badgeLabel.text = badgeText(for: record, isBest: isBest)

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        dateLabel.text = formatter.string(from: record.date)
    }

    func configureEmpty() {
        rankLabel.text = "—"
        subtitleLabel.text = "暂无远投纪录"
        distanceLabel.text = ""
        badgeLabel.text = ""
        dateLabel.text = ""
    }

    private func biomeTitle(for highestBiome: Int) -> String {
        switch highestBiome {
        case 3:
            return "传说区"
        case 2:
            return "极光高空区"
        case 1:
            return "冰山裂谷区"
        default:
            return "雪地起跑区"
        }
    }

    private func badgeText(for record: DistanceRecord, isBest: Bool) -> String {
        var parts: [String] = []
        if isBest {
            parts.append("全局最佳")
        }
        parts.append(record.perfectRelease ? "完美出手" : "标准出手")
        return parts.joined(separator: " · ")
    }
}
