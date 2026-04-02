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
            <h1>隐私政策</h1>
            <p style="color:#888; font-size:13px;">更新日期：2025年1月1日</p>
        </div>

        <div class="card">
            <span class="tag">数据收集</span>
            <h2>我们收集什么</h2>
            <p>「打企鹅」App会收集以下信息以改进用户体验：</p>
            <ul>
                <li><strong>设备信息：</strong>设备型号、操作系统版本、屏幕分辨率，用于优化游戏适配性</li>
                <li><strong>游戏数据：</strong>最高分、关卡进度、设置偏好，存储在本地设备</li>
                <li><strong>广告标识符（IDFA）：</strong>用于展示个性化广告（可选），您可在系统设置中限制</li>
                <li><strong>崩溃日志：</strong>应用崩溃时的匿名错误报告，帮助我们修复问题</li>
            </ul>
            <p>我们<strong>不会</strong>收集您的姓名、邮箱、电话号码或任何个人身份信息。</p>
        </div>

        <div class="card">
            <span class="tag">第三方SDK</span>
            <h2>广告服务（Google AdMob）</h2>
            <p>本App使用 <strong>Google AdMob</strong> 作为广告服务提供商。AdMob可能会收集以下信息：</p>
            <ul>
                <li>设备标识符（GAID / IDFA）</li>
                <li>IP地址、浏览器类型</li>
                <li>应用使用行为、点击广告记录</li>
                <li>大致位置（基于IP）</li>
            </ul>
            <p>AdMob的隐私政策：<a href="https://policies.google.com/privacy">policies.google.com/privacy</a></p>
            <p>您可以随时在 iOS「设置 → 隐私 → 广告」中开启「限制广告跟踪」。</p>
        </div>

        <div class="card">
            <span class="tag">本地存储</span>
            <h2>本地数据</h2>
            <p>您的游戏进度、最高分和设置选项存储在<strong>本机本地</strong>，不会上传至我们的服务器。我们使用 iOS UserDefaults 存储偏好设置，使用本地文件存储游戏存档。</p>
        </div>

        <div class="card">
            <span class="tag">用户权利</span>
            <h2>您的权利</h2>
            <ul>
                <li>✅ 随时删除本App，卸载即清除所有本地数据</li>
                <li>✅ 在iOS设置中关闭「定位服务」（不影响App功能）</li>
                <li>✅ 开启「限制广告跟踪」减少个性化广告</li>
                <li>✅ 联系我们（app@hitpenguin.com）询问数据处理事宜</li>
            </ul>
        </div>

        <div class="card">
            <span class="tag">安全</span>
            <h2>数据安全</h2>
            <p>本App不收集任何敏感个人信息，数据传输使用HTTPS加密。我们定期审查数据收集行为，确保符合最小必要原则。</p>
        </div>

        <div class="card">
            <span class="tag">儿童隐私</span>
            <h2>儿童适用</h2>
            <p>本App面向全年龄用户。我们不会故意收集13岁以下儿童的个人信息。家长可通过iOS家长控制功能监管App使用。</p>
        </div>

        <div class="card">
            <span class="tag">变更</span>
            <h2>政策更新</h2>
            <p>本隐私政策可能随产品更新而修改。重大变更将在App内公告。如您继续使用App，即表示您接受更新后的政策。</p>
        </div>

        <div class="footer">
            © 2025 HitPenguin.com · 打企鹅开发团队<br>
            联系我们：app@hitpenguin.com
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
