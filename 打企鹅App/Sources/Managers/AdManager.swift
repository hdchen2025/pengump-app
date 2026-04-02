import Foundation
import UIKit

// MARK: - 广告类型

enum AdType {
    case rewardedVideo    // 激励视频广告（失败复活、双倍金币）
    case interstitial     // 插屏广告（每3关显示一次）
}

// MARK: - 激励视频奖励类型

enum RewardedAdReward {
    case extraPenguin        // 企鹅复活
    case doubleCoins         // 双倍金币
}

// MARK: - 广告回调协议

protocol AdManagerDelegate: AnyObject {
    func adManagerDidLoadRewardedAd()
    func adManagerDidFailToLoadRewardedAd(error: Error?)
    func adManagerDidRewardUser(reward: RewardedAdReward)
    func adManagerDidDismissRewardedAd()
    func adManagerDidLoadInterstitial()
    func adManagerDidFailToLoadInterstitial(error: Error?)
    func adManagerDidDismissInterstitial()
}

// MARK: - AdManager（广告管理框架）

class AdManager {
    static let shared = AdManager()

    // MARK: - Properties

    weak var delegate: AdManagerDelegate?

    // UserDefaults keys
    private enum Keys {
        static let interstitialCounter = "ad_interstitial_counter"
        static let adsRemoved = "ads_removed"
        static let rewardedAdReady = "rewarded_ad_ready"
    }

    /// 插屏广告每N关显示一次
    private let interstitialInterval: Int = 3

    /// 激励视频广告是否已加载
    private(set) var isRewardedAdLoaded: Bool = false

    /// 插屏广告是否已加载
    private(set) var isInterstitialLoaded: Bool = false

    /// 是否已购买去广告
    var isAdsRemoved: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.adsRemoved) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.adsRemoved) }
    }

    /// 插屏广告计数器（用于控制每3关显示一次）
    private var interstitialCounter: Int {
        get { UserDefaults.standard.integer(forKey: Keys.interstitialCounter) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.interstitialCounter) }
    }

    // MARK: - 广告单元ID配置

    // 注意：以下为虚拟广告单元ID，仅用于测试
    // 正式上线前请替换为真实的AdMob广告单元ID
    private struct AdUnitIDs {
        // 激励视频广告单元ID
        // 格式：ca-app-pub-xxxxxxxxxx/xxxxxxxxxx
        // 测试ID：ca-app-pub-3940256099942544/1712485313
        static let rewardedVideo = "ca-app-pub-3940256099942544/1712485313"

        // 插屏广告单元ID
        // 测试ID：ca-app-pub-3940256099942544/1033173712
        static let interstitial = "ca-app-pub-3940256099942544/1033173712"
    }

    // MARK: - 当前待奖励类型

    private var pendingReward: RewardedAdReward?

    // MARK: - Init

    private init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        // 应用唤醒时尝试预加载广告
        preloadAds()
    }

    // MARK: - 预加载广告

    func preloadAds() {
        loadRewardedAd()
        loadInterstitialAd()
    }

    // MARK: - 激励视频广告

    /// 加载激励视频广告
    func loadRewardedAd() {
        // AdMob集成框架 - 实际使用需要引入 GoogleMobileAds SDK
        // 实现步骤：
        // 1. 在Podfile中添加: pod 'Google-Mobile-Ads-SDK'
        // 2. 在AppDelegate中初始化: GADMobileAds.sharedInstance().start(...)
        // 3. 使用 GADRewardedAd.loadWithAdUnitID(...) 加载广告

        // 以下为框架代码，实际接入时取消注释并配置真实SDK

        /*
        GADRewardedAd.load(
            withAdUnitID: AdUnitIDs.rewardedVideo,
            request: GADRequest(),
            completionHandler: { [weak self] ad, error in
                if let error = error {
                    self?.isRewardedAdLoaded = false
                    self?.delegate?.adManagerDidFailToLoadRewardedAd(error: error)
                    return
                }
                self?.isRewardedAdLoaded = true
                self?.rewardedAd = ad
                self?.delegate?.adManagerDidLoadRewardedAd()
            }
        )
        */

        // 模拟加载成功（用于框架测试）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isRewardedAdLoaded = true
            self?.delegate?.adManagerDidLoadRewardedAd()
        }
    }

    /// 显示激励视频广告
    /// - Parameters:
    ///   - reward: 奖励类型（.extraPenguin 或 .doubleCoins）
    ///   - from: 展示广告的视图控制器
    func showRewardedAd(reward: RewardedAdReward, from viewController: UIViewController) {
        guard !isAdsRemoved else {
            // 用户已购买去广告，直接给予奖励
            delegate?.adManagerDidRewardUser(reward: reward)
            return
        }

        guard isRewardedAdLoaded else {
            // 广告未加载，提示用户
            showAdNotAvailableAlert(from: viewController)
            return
        }

        pendingReward = reward

        // AdMob实现框架：
        /*
        guard let rewardedAd = self.rewardedAd else { return }
        rewardedAd.present(
            fromRootViewController: viewController,
            completionHandler: { [weak self] error in
                if let error = error {
                    self?.delegate?.adManagerDidFailToLoadRewardedAd(error: error)
                    return
                }
                // 广告播放完成，发放奖励
                self?.delegate?.adManagerDidRewardUser(reward: reward)
                self?.pendingReward = nil
                // 重新加载广告
                self?.loadRewardedAd()
            }
        )
        */

        // 模拟广告展示流程（用于框架测试）
        simulateRewardedAdPresentation(from: viewController, reward: reward)
    }

    private func simulateRewardedAdPresentation(from viewController: UIViewController, reward: RewardedAdReward) {
        // 创建模拟广告视图
        let adView = UIView()
        adView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        adView.frame = viewController.view.bounds
        adView.alpha = 0

        // 广告提示标签
        let titleLabel = UILabel()
        titleLabel.text = "🎬 观看广告"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.tag = 100

        // 奖励说明
        let rewardLabel = UILabel()
        rewardLabel.text = reward == .extraPenguin ? "观看后可获得 +1 企鹅（原地复活）" : "观看后可获得双倍金币奖励"
        rewardLabel.font = .systemFont(ofSize: 16)
        rewardLabel.textColor = .lightGray
        rewardLabel.textAlignment = .center
        rewardLabel.numberOfLines = 0
        rewardLabel.tag = 101

        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕ 关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 8
        closeButton.tag = 102

        // 模拟观看进度条
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.tag = 103

        // 添加到视图
        adView.addSubview(titleLabel)
        adView.addSubview(rewardLabel)
        adView.addSubview(closeButton)
        adView.addSubview(progressView)
        viewController.view.addSubview(adView)

        // 布局
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        rewardLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: adView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: adView.centerYAnchor, constant: -60),

            rewardLabel.centerXAnchor.constraint(equalTo: adView.centerXAnchor),
            rewardLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            rewardLabel.leftAnchor.constraint(equalTo: adView.leftAnchor, constant: 40),
            rewardLabel.rightAnchor.constraint(equalTo: adView.rightAnchor, constant: -40),

            closeButton.topAnchor.constraint(equalTo: adView.topAnchor, constant: 60),
            closeButton.rightAnchor.constraint(equalTo: adView.rightAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            progressView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -80),
            progressView.leftAnchor.constraint(equalTo: adView.leftAnchor, constant: 40),
            progressView.rightAnchor.constraint(equalTo: adView.rightAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])

        // 动画显示
        UIView.animate(withDuration: 0.3) {
            adView.alpha = 1.0
        }

        // 模拟广告播放进度
        var progress: Float = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            progress += 0.02
            progressView.setProgress(min(progress, 1.0), animated: true)

            if progress >= 1.0 {
                timer.invalidate()
                // 广告播放完成，发放奖励并关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.dismissSimulatedAd(adView: adView, from: viewController, reward: reward)
                }
            }
        }

        // 关闭按钮回调
        closeButton.addAction(UIAction { [weak self] _ in
            timer.invalidate()
            self?.dismissSimulatedAd(adView: adView, from: viewController, reward: nil)
        }, for: .touchUpInside)
    }

    private func dismissSimulatedAd(adView: UIView, from viewController: UIViewController, reward: RewardedAdReward?) {
        UIView.animate(withDuration: 0.3, animations: {
            adView.alpha = 0
        }) { _ in
            adView.removeFromSuperview()
        }

        if let reward = reward {
            // 发放奖励
            delegate?.adManagerDidRewardUser(reward: reward)
        }

        delegate?.adManagerDidDismissRewardedAd()

        // 重新加载广告
        loadRewardedAd()
    }

    // MARK: - 插屏广告

    /// 加载插屏广告
    func loadInterstitialAd() {
        // AdMob集成框架：
        /*
        interstitial = GADInterstitial(adUnitID: AdUnitIDs.interstitial)
        interstitial.load(GADRequest())
        interstitial.delegate = self
        */

        // 模拟加载成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isInterstitialLoaded = true
            self?.delegate?.adManagerDidLoadInterstitial()
        }
    }

    /// 检查并显示插屏广告（如需要）
    /// - Parameters:
    ///   - level: 当前关卡号
    ///   - from: 展示广告的视图控制器
    /// - Returns: 是否实际显示了广告
    @discardableResult
    func showInterstitialIfDue(forLevel level: Int, from viewController: UIViewController) -> Bool {
        // 去广告用户不显示
        guard !isAdsRemoved else { return false }

        // 检查是否应该显示（每N关一次）
        if level > 0 && level % interstitialInterval == 0 {
            if isInterstitialLoaded {
                presentInterstitial(from: viewController)
                // 重置计数器
                interstitialCounter = 0
                return true
            } else {
                // 广告未加载，悄悄重试
                loadInterstitialAd()
                return false
            }
        }
        return false
    }

    private func presentInterstitial(from viewController: UIViewController) {
        // AdMob实现框架：
        /*
        guard let interstitial = self.interstitial, interstitial.isReady else {
            loadInterstitialAd()
            return
        }
        interstitial.present(fromRootViewController: viewController)
        */

        // 模拟插屏广告
        presentSimulatedInterstitial(from: viewController)
    }

    private func presentSimulatedInterstitial(from viewController: UIViewController) {
        let adView = UIView()
        adView.backgroundColor = .white
        adView.frame = viewController.view.bounds
        adView.alpha = 0

        // 广告内容（模拟）
        let contentView = UIView()
        contentView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowRadius = 8
        contentView.tag = 200

        let adTitleLabel = UILabel()
        adTitleLabel.text = "📢 广告"
        adTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        adTitleLabel.textColor = .darkGray
        adTitleLabel.textAlignment = .center

        let adImageView = UIImageView()
        adImageView.backgroundColor = UIColor(red: 0.8, green: 0.85, blue: 0.9, alpha: 1.0)
        adImageView.layer.cornerRadius = 8
        adImageView.clipsToBounds = true
        adImageView.contentMode = .scaleAspectFill

        let adDescLabel = UILabel()
        adDescLabel.text = "这里可以展示精彩广告内容\n支持图片、视频等多种形式"
        adDescLabel.font = .systemFont(ofSize: 14)
        adDescLabel.textColor = .gray
        adDescLabel.textAlignment = .center
        adDescLabel.numberOfLines = 0

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕ 关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        closeButton.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
        closeButton.layer.cornerRadius = 20
        closeButton.tag = 201

        let skipLabel = UILabel()
        skipLabel.text = "广告 · 3 秒后可关闭"
        skipLabel.font = .systemFont(ofSize: 12)
        skipLabel.textColor = .lightGray
        skipLabel.textAlignment = .center
        skipLabel.tag = 202

        // 添加视图
        adView.addSubview(contentView)
        contentView.addSubview(adTitleLabel)
        contentView.addSubview(adImageView)
        contentView.addSubview(adDescLabel)
        adView.addSubview(closeButton)
        adView.addSubview(skipLabel)
        viewController.view.addSubview(adView)

        // 布局
        contentView.translatesAutoresizingMaskIntoConstraints = false
        adTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        adImageView.translatesAutoresizingMaskIntoConstraints = false
        adDescLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        skipLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: adView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: adView.widthAnchor, multiplier: 0.85),
            contentView.heightAnchor.constraint(equalToConstant: 300),

            adTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            adTitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            adImageView.topAnchor.constraint(equalTo: adTitleLabel.bottomAnchor, constant: 12),
            adImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            adImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            adImageView.heightAnchor.constraint(equalToConstant: 160),

            adDescLabel.topAnchor.constraint(equalTo: adImageView.bottomAnchor, constant: 12),
            adDescLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            adDescLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),

            closeButton.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 16),
            closeButton.centerXAnchor.constraint(equalTo: adView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 120),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            skipLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -40),
            skipLabel.centerXAnchor.constraint(equalTo: adView.centerXAnchor)
        ])

        closeButton.isEnabled = false

        // 动画显示
        adView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.3) {
            adView.alpha = 1.0
            adView.transform = .identity
        }

        // 3秒倒计时后可关闭
        var countdown = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                self?.closeButton.isEnabled = true
                self?.closeButton.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
                self?.skipLabel.text = "点击关闭广告"
            } else {
                self?.skipLabel.text = "广告 · \(countdown) 秒后可关闭"
            }
        }

        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismissSimulatedInterstitial(adView: adView, from: viewController)
        }, for: .touchUpInside)
    }

    private func dismissSimulatedInterstitial(adView: UIView, from viewController: UIViewController) {
        UIView.animate(withDuration: 0.3, animations: {
            adView.alpha = 0
            adView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            adView.removeFromSuperview()
        }

        delegate?.adManagerDidDismissInterstitial()

        // 重新加载插屏广告
        loadInterstitialAd()
    }

    // MARK: - 辅助方法

    private func showAdNotAvailableAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "广告加载中",
            message: "请稍后再试，或检查网络连接。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alert, animated: true)
    }

    /// 购买去广告
    func purchaseAdsRemoved() {
        isAdsRemoved = true
    }

    /// 重置插屏计数器（用于测试）
    func resetInterstitialCounter() {
        interstitialCounter = 0
    }

    /// 获取当前插屏计数器（用于调试）
    func getInterstitialCounter() -> Int {
        return interstitialCounter
    }
}

// MARK: - GADInterstitialDelegate 框架占位

/*
extension AdManager: GADInterstitialDelegate {
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        isInterstitialLoaded = true
        delegate?.adManagerDidLoadInterstitial()
    }

    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        isInterstitialLoaded = false
        delegate?.adManagerDidFailToLoadInterstitial(error: error)
    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        delegate?.adManagerDidDismissInterstitial()
        loadInterstitialAd()  // 重新加载下一个广告
    }
}
*/

// MARK: - GADRewardedAdDelegate 框架占位

/*
extension AdManager: GADRewardedAdDelegate {
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        isRewardedAdLoaded = false
        delegate?.adManagerDidFailToLoadRewardedAd(error: error)
    }

    func rewardedAd(_ rewardedAd: GADRewardedAd, didRewardUserWith reward: GADAdReward) {
        if let pending = pendingReward {
            delegate?.adManagerDidRewardUser(reward: pending)
            pendingReward = nil
        }
    }

    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        delegate?.adManagerDidDismissRewardedAd()
        loadRewardedAd()
    }
}
*/
