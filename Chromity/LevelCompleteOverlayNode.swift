import SpriteKit

protocol LevelCompleteDelegate: AnyObject {
    func levelCompleteDidTapNext()
    func levelCompleteDidTapMenu()
}

class LevelCompleteOverlayNode: SKNode {
    
    weak var delegate: LevelCompleteDelegate?
    
    private let background: SKShapeNode
    private let nextBtn: SKShapeNode
    private let menuBtn: SKShapeNode
    
    init(challenge: Challenge) {
        let size = CGSize(width: 300, height: 350)
        background = SKShapeNode(rectOf: size, cornerRadius: 28)
        background.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 0.95)
        background.strokeColor = SKColor(white: 0.8, alpha: 1.0)
        background.lineWidth = 3.0
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = L10n.level(challenge.level)
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 100)
        
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subtitleLabel.text = L10n.complete
        subtitleLabel.fontSize = 32
        subtitleLabel.fontColor = .yellow
        subtitleLabel.position = CGPoint(x: 0, y: 60)
        
        let rewardLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        rewardLabel.text = L10n.reward(challenge.rewardCoins)
        rewardLabel.fontSize = 20
        rewardLabel.fontColor = .white
        rewardLabel.position = CGPoint(x: 0, y: 0)
        
        nextBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
        nextBtn.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        nextBtn.strokeColor = .white
        nextBtn.lineWidth = 2.0
        nextBtn.position = CGPoint(x: 0, y: -60)
        nextBtn.name = "nextBtn"
        
        let nextLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nextLabel.text = L10n.nextLevel
        nextLabel.fontSize = 20
        nextLabel.fontColor = .black
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = .zero
        nextLabel.name = "nextBtnLabel"
        nextBtn.addChild(nextLabel)
        
        if challenge.level >= ChallengeManager.shared.totalLevels {
            nextBtn.isHidden = true
        }
        
        menuBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
        menuBtn.fillColor = SKColor(white: 0.2, alpha: 1.0)
        menuBtn.strokeColor = SKColor(white: 0.6, alpha: 1.0)
        menuBtn.lineWidth = 2.0
        menuBtn.position = CGPoint(x: 0, y: -130)
        menuBtn.name = "menuBtn"
        
        let menuLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuLabel.text = L10n.mainMenu
        menuLabel.fontSize = 20
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuLabel.position = .zero
        menuLabel.name = "menuBtnLabel"
        menuBtn.addChild(menuLabel)
        
        super.init()
        
        addChild(background)
        background.addChild(titleLabel)
        background.addChild(subtitleLabel)
        background.addChild(rewardLabel)
        background.addChild(nextBtn)
        background.addChild(menuBtn)
        
        self.isUserInteractionEnabled = true
        self.zPosition = 2000
        
        self.setScale(0.5)
        self.alpha = 0
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.5)
        scaleAction.timingMode = .easeOut
        
        let show = SKAction.group([
            scaleAction,
            SKAction.fadeIn(withDuration: 0.3)
        ])
        self.run(show)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if nextBtn.contains(location) && !nextBtn.isHidden {
            self.run(SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.2),
                SKAction.removeFromParent()
            ])) {
                self.delegate?.levelCompleteDidTapNext()
            }
        } else if menuBtn.contains(location) {
            self.run(SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.2),
                SKAction.removeFromParent()
            ])) {
                self.delegate?.levelCompleteDidTapMenu()
            }
        }
    }
}
