import Foundation
import UIKit

// MARK: - 广告类型（free edition compat shim）

enum AdType {
    case rewardedVideo
    case interstitial
}

// MARK: - 奖励类型（free edition compat shim）

enum RewardedAdReward {
    /// 免费版当前仅保留该奖励语义；历史 doubleCoins 已下线。
    case extraPenguin
}

// MARK: - 兼容回调协议（free edition compat shim）

protocol AdManagerDelegate: AnyObject {
    func adManagerDidLoadRewardedAd()
    func adManagerDidFailToLoadRewardedAd(error: Error?)
    func adManagerDidRewardUser(reward: RewardedAdReward)
    func adManagerDidDismissRewardedAd()
    func adManagerDidLoadInterstitial()
    func adManagerDidFailToLoadInterstitial(error: Error?)
    func adManagerDidDismissInterstitial()
}

// MARK: - AdManager（free edition compat shim）

class AdManager {
    static let shared = AdManager()

    weak var delegate: AdManagerDelegate?

    // UserDefaults keys（兼容字段保留）
    private enum Keys {
        static let adsRemoved = "ads_removed"
    }

    /// 兼容状态字段（free edition 固定不可用）
    private(set) var isRewardedAdLoaded: Bool = false

    /// 兼容状态字段（free edition 固定不可用）
    private(set) var isInterstitialLoaded: Bool = false

    /// 兼容字段（历史存档读取需要）
    var isAdsRemoved: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.adsRemoved) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.adsRemoved) }
    }

    private init() {}

    /// 兼容 no-op
    func incrementInterstitialCounter() {
        // no-op
    }

    // MARK: - 兼容 no-op 接口

    func preloadAds() {
        // no-op
    }

    func loadRewardedAd() {
        // no-op
    }

    /// free edition 下不展示广告，直接走奖励回调
    func showRewardedAd(reward: RewardedAdReward, from viewController: UIViewController) {
        delegate?.adManagerDidRewardUser(reward: reward)
        delegate?.adManagerDidDismissRewardedAd()
    }

    func loadInterstitialAd() {
        // no-op
    }

    @discardableResult
    func showInterstitialIfDue(forLevel level: Int, from viewController: UIViewController) -> Bool {
        false
    }

    // MARK: - 历史兼容接口

    /// 历史接口名保留（free edition 下仅写入兼容字段）
    func purchaseAdsRemoved() {
        isAdsRemoved = true
    }

    func resetInterstitialCounter() {
        // no-op
    }

    func getInterstitialCounter() -> Int {
        0
    }
}
