import UIKit
import SpriteKit

/// 游戏主界面（SpriteKit 场景）
class GameViewController: UIViewController {

    private let level: Int
    private var scene: GameScene!

    init(level: Int) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建 SpriteKit 场景
        scene = GameScene(level: level)
        scene.scaleMode = .resizeFill
        scene.size = view.bounds.size

        // 将 SKView 添加到 VC
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.presentScene(scene)
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        view.addSubview(skView)
        view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
    }

    override var prefersStatusBarHidden: Bool { true }
}
