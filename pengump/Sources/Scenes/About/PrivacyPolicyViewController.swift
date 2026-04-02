import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        return wv
    }()

    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("← 返回", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "📜 隐私政策"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Privacy Policy HTML

    private lazy var privacyHTML: String = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                font-size: 15px;
                line-height: 1.7;
                color: #333;
                background: #f5f7fa;
                padding: 20px 16px 60px;
            }
            h1 { font-size: 22px; color: #1a1a2e; margin-bottom: 6px; }
            h2 { font-size: 17px; color: #16213e; margin-top: 24px; margin-bottom: 8px; font-weight: 600; }
            p  { margin-bottom: 12px; }
            .card {
                background: #fff;
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 12px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            }
            .tag {
                display: inline-block;
                background: #e8f0fe;
                color: #1a73e8;
                font-size: 12px;
                font-weight: 600;
                padding: 2px 8px;
                border-radius: 4px;
                margin-bottom: 8px;
            }
            .subtitle {
                color: #666;
                font-size: 13px;
                margin-bottom: 8px;
            }
            ul { padding-left: 20px; margin-bottom: 12px; }
            li { margin-bottom: 6px; }
            .footer {
                text-align: center;
                color: #999;
                font-size: 13px;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #eee;
            }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>隐私政策 / Privacy Policy</h1>
            <p style="color:#888; font-size:13px;">更新日期 Updated: 2026-04-02</p>
            <p class="subtitle">本页面提供中文与英文版本，两者含义一致。<br>This page provides both Chinese and English text with the same meaning.</p>
        </div>

        <div class="card">
            <span class="tag">数据范围 / Data Scope</span>
            <h2>我们收集什么 / What We Collect</h2>
            <p>「打企鹅」免费版的核心数据保存在本机，不需要账号注册。<br>The free edition stores core gameplay data on your device and does not require account registration.</p>
            <ul>
                <li><strong>本地游戏数据 / Local game data:</strong> 最高分、关卡进度、设置偏好，仅保存在设备本地。<br>Best scores, level progress, and settings are stored locally on your device.</li>
                <li><strong>设备与运行信息 / Device and runtime info:</strong> 设备型号、系统版本、应用版本，用于兼容性排查。<br>Device model, OS version, and app version may be used for compatibility troubleshooting.</li>
                <li><strong>可选稳定性统计 / Optional stability metrics:</strong> 如启用基础崩溃或性能统计，仅用于定位故障与性能问题。<br>If basic crash/performance metrics are enabled, they are used only for diagnosing failures and performance issues.</li>
            </ul>
            <p>我们不会收集您的姓名、手机号、邮箱、通讯录或其他身份资料。<br>We do not collect your name, phone number, email, contacts, or other identity data.</p>
        </div>

        <div class="card">
            <span class="tag">使用目的 / Purpose</span>
            <h2>数据如何使用 / How Data Is Used</h2>
            <ul>
                <li>用于保存游戏进度与设置。<br>Used to save game progress and settings.</li>
                <li>用于提升兼容性、稳定性与性能表现。<br>Used to improve compatibility, stability, and performance.</li>
                <li>仅用于产品运行维护，不用于用户画像。<br>Used only for product operation and maintenance, not for user profiling.</li>
            </ul>
        </div>

        <div class="card">
            <span class="tag">本地存储 / Local Storage</span>
            <h2>本地数据保存 / On-Device Storage</h2>
            <p>我们使用 iOS UserDefaults 与本地文件保存游戏状态。<br>We use iOS UserDefaults and local files to store game state.</p>
            <p>默认情况下，游戏数据不会上传到我们的服务器。<br>By default, game data is not uploaded to our servers.</p>
        </div>

        <div class="card">
            <span class="tag">第三方服务 / Third-Party Services</span>
            <h2>基础技术服务 / Basic Technical Services</h2>
            <p>为提升稳定性，应用可能接入基础崩溃与性能统计服务。<br>To improve stability, the app may use basic crash and performance analytics services.</p>
            <p>此类服务仅处理必要的技术诊断信息。<br>Such services process only necessary technical diagnostic information.</p>
            <p>如未启用相关服务，则不会上传对应统计数据。<br>If such services are not enabled, related analytics data will not be uploaded.</p>
        </div>

        <div class="card">
            <span class="tag">用户控制 / Your Controls</span>
            <h2>您的选择权 / Your Choices</h2>
            <ul>
                <li>✅ 您可随时卸载 App 以移除本地数据。<br>You can uninstall the app at any time to remove local data.</li>
                <li>✅ 您可在系统设置中管理网络与隐私权限。<br>You can manage network and privacy permissions in system settings.</li>
                <li>✅ 您可通过邮箱联系我们咨询数据处理问题。<br>You can contact us by email for data-processing questions.</li>
            </ul>
        </div>

        <div class="card">
            <span class="tag">安全与儿童 / Security & Children</span>
            <h2>数据安全与儿童隐私 / Data Security & Children</h2>
            <p>我们采用合理措施保护数据安全，并持续改进产品稳定性。<br>We apply reasonable safeguards to protect data and continuously improve product stability.</p>
            <p>本应用面向全年龄用户，不会故意收集儿童身份信息。<br>This app is suitable for all ages and does not intentionally collect children’s identity information.</p>
        </div>

        <div class="card">
            <span class="tag">政策更新 / Updates</span>
            <h2>隐私政策变更 / Policy Changes</h2>
            <p>本政策可能随产品更新而调整，更新后将以应用内信息为准。<br>This policy may be updated with product changes; in-app information after update shall prevail.</p>
        </div>

        <div class="footer">
            © 2026 HitPenguin.com · 打企鹅开发团队<br>
            联系我们 / Contact: app@hitpenguin.com
        </div>
    </body>
    </html>
    """

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadHTML()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)

        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(webView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 70),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            webView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadHTML() {
        webView.loadHTMLString(privacyHTML, baseURL: nil)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        AudioManager.shared.playButtonTapSound()
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
