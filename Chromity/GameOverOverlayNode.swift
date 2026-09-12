import SpriteKit
import UIKit

protocol GameOverOverlayDelegate: AnyObject {
    func gameOverOverlayDidTapRestart()
    func gameOverOverlayDidTapMenu()
    func gameOverOverlayDidTapContinue()
    func gameOverOverlayDidTapDoubleCoins()
}

class GameOverOverlayNode: SKNode {
    
    weak var delegate: GameOverOverlayDelegate?
    
    private let background: SKShapeNode
    private let restartButton: SKShapeNode
    private let menuButton: SKShapeNode
    private let shareButton: SKShapeNode
    private var continueButton: SKShapeNode?
    private var continueAdButton: SKShapeNode?
    private var doubleCoinsButton: SKShapeNode?
    private var coinsDisplayLabel: SKLabelNode?
    private var isClaimingDouble = false
    private var isClaimingContinue = false
    private let canContinue: Bool
    private let scoreValue: Int
    private let runCoins: Int

    static func continueCost(for continueCount: Int) -> Int {
        let exp = min(max(continueCount, 0), 25)
        return 200 * (1 << exp)
    }
    private let currentContinueCost: Int

    init(score: Int, highScore: Int, continueCount: Int = 0, coinsThisRun: Int = 0) {
        self.canContinue = true
        self.scoreValue = score
        self.runCoins = coinsThisRun
        self.currentContinueCost = GameOverOverlayNode.continueCost(for: continueCount)
        
        let coins = UserDefaults.standard.integer(forKey: "TotalCoins")
        let canAfford = coins >= currentContinueCost
        
        let size = CGSize(width: 300, height: canContinue ? 580 : 420)
        background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.95)
        background.strokeColor = .red
        background.lineWidth = 2.0
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.fontSize = 32
        titleLabel.fontColor = .red
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        titleLabel.text = L10n.gameOver
        
        let isNewBest = score >= highScore && score > 0
        
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: isNewBest ? size.height/2 - 140 : size.height/2 - 120)
        scoreLabel.text = L10n.score(score)
        
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = .lightGray
        highScoreLabel.position = CGPoint(x: 0, y: isNewBest ? size.height/2 - 180 : size.height/2 - 160)
        highScoreLabel.text = L10n.best(highScore)
        
        restartButton = SKShapeNode(rectOf: CGSize(width: 220, height: 55), cornerRadius: 15)
        restartButton.fillColor = SKColor.systemBlue
        restartButton.strokeColor = .white
        restartButton.lineWidth = 2.0
        
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.text = L10n.playAgain
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartLabel.position = .zero
        restartButton.addChild(restartLabel)
        
        shareButton = SKShapeNode(rectOf: CGSize(width: 220, height: 45), cornerRadius: 12)
        shareButton.fillColor = SKColor(white: 0.12, alpha: 1.0)
        shareButton.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        shareButton.lineWidth = 1.5
        
        let shareLabelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shareLabelNode.text = L10n.shareScore
        shareLabelNode.fontSize = 16
        shareLabelNode.fontColor = SKColor(white: 0.7, alpha: 1.0)
        shareLabelNode.verticalAlignmentMode = .center
        shareLabelNode.position = .zero
        shareButton.addChild(shareLabelNode)
        
        menuButton = SKShapeNode(rectOf: CGSize(width: 220, height: 45), cornerRadius: 12)
        menuButton.fillColor = SKColor(white: 0.12, alpha: 1.0)
        menuButton.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        menuButton.lineWidth = 1.5
        
        let menuLabelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuLabelNode.text = L10n.mainMenu
        menuLabelNode.fontSize = 16
        menuLabelNode.fontColor = SKColor(white: 0.7, alpha: 1.0)
        menuLabelNode.verticalAlignmentMode = .center
        menuLabelNode.position = .zero
        menuButton.addChild(menuLabelNode)
        
        super.init()
        
        addChild(background)
        background.addChild(titleLabel)
        background.addChild(scoreLabel)
        background.addChild(highScoreLabel)
        
        if canContinue {
            let coinsDisplay = SKLabelNode(fontNamed: "AvenirNext-Bold")
            coinsDisplay.fontSize = 18
            coinsDisplay.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            coinsDisplay.position = CGPoint(x: 0, y: isNewBest ? size.height/2 - 210 : size.height/2 - 190)
            coinsDisplay.text = "⭐ \(coins)"
            background.addChild(coinsDisplay)
            coinsDisplayLabel = coinsDisplay

            if runCoins > 0 {
                let dblBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 38), cornerRadius: 12)
                dblBtn.position = CGPoint(x: 0, y: 40)
                dblBtn.fillColor = SKColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 0.22)
                dblBtn.strokeColor = SKColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 0.9)
                dblBtn.lineWidth = 1.5

                let dblLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                dblLabel.text = L10n.doubleCoins(runCoins)
                dblLabel.fontSize = 14
                dblLabel.fontColor = SKColor(red: 1.0, green: 0.88, blue: 0.4, alpha: 1.0)
                dblLabel.verticalAlignmentMode = .center
                dblLabel.position = .zero
                dblBtn.addChild(dblLabel)
                doubleCoinsButton = dblBtn
                background.addChild(dblBtn)
            }

            let coinBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 55), cornerRadius: 15)
            coinBtn.position = CGPoint(x: 0, y: -20)
            
            if canAfford {
                coinBtn.fillColor = SKColor(red: 0.15, green: 0.65, blue: 0.35, alpha: 1.0)
                coinBtn.strokeColor = .white
                coinBtn.lineWidth = 2.0
            } else {
                coinBtn.fillColor = SKColor(white: 0.15, alpha: 1.0)
                coinBtn.strokeColor = SKColor(white: 0.3, alpha: 1.0)
                coinBtn.lineWidth = 1.5
            }
            
            let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            coinLabel.text = L10n.continueCost(currentContinueCost)
            coinLabel.fontSize = 16
            coinLabel.fontColor = canAfford ? .white : SKColor(white: 0.4, alpha: 1.0)
            coinLabel.verticalAlignmentMode = .center
            coinLabel.position = CGPoint(x: 0, y: 1)
            coinBtn.addChild(coinLabel)
            continueButton = coinBtn
            background.addChild(coinBtn)
            
            let adBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 42), cornerRadius: 12)
            adBtn.position = CGPoint(x: 0, y: -75)
            adBtn.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.8, alpha: 0.3)
            adBtn.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
            adBtn.lineWidth = 1.5
            
            let adLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            let hasRemovedAds = UserDefaults.standard.bool(forKey: "HasRemovedAds")
            adLabel.text = hasRemovedAds ? L10n.reviveVip : L10n.watchAdContinue
            adLabel.fontSize = 13
            adLabel.fontColor = .cyan
            adLabel.verticalAlignmentMode = .center
            adLabel.position = .zero
            adBtn.addChild(adLabel)
            continueAdButton = adBtn
            background.addChild(adBtn)
            
            restartButton.position = CGPoint(x: 0, y: -140)
            menuButton.position = CGPoint(x: 0, y: -200)
            shareButton.position = CGPoint(x: 0, y: -255)
        } else {
            restartButton.position = CGPoint(x: 0, y: isNewBest ? -100 : -60)
            menuButton.position = CGPoint(x: 0, y: isNewBest ? -155 : -115)
            shareButton.position = CGPoint(x: 0, y: isNewBest ? -210 : -170)
        }
        
        background.addChild(restartButton)
        background.addChild(menuButton)
        background.addChild(shareButton)
        
        if isNewBest {
            let newBest = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            newBest.text = L10n.newBest
            newBest.fontSize = 26
            newBest.fontColor = SKColor.yellow
            newBest.position = CGPoint(x: 0, y: size.height/2 - 100)
            newBest.setScale(0.1)
            background.addChild(newBest)
            
            newBest.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 0.95, duration: 0.5)
            ])
            newBest.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.repeatForever(pulse)
            ]))
            
            for _ in 0..<20 {
                let confetti = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
                confetti.fillColor = [SKColor.red, .green, .yellow, .cyan, .orange, .magenta].randomElement()!
                confetti.strokeColor = .clear
                confetti.position = CGPoint(x: CGFloat.random(in: -140...140), y: size.height/2)
                confetti.zPosition = 10
                background.addChild(confetti)
                
                let fall = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: -size.height - 50, duration: Double.random(in: 1.5...3.0))
                let spin = SKAction.rotate(byAngle: .pi * CGFloat.random(in: 2...6), duration: Double.random(in: 1.5...3.0))
                confetti.run(SKAction.group([fall, spin, SKAction.fadeOut(withDuration: 3.0)]))
            }
        }
        
        self.isUserInteractionEnabled = true
        self.zPosition = 1000

        fitToScreen(panelHeight: size.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if restartButton.contains(location) {
            restartButton.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            delegate?.gameOverOverlayDidTapRestart()
            
        } else if let btn = continueButton, btn.contains(location) {
            let coins = UserDefaults.standard.integer(forKey: "TotalCoins")
            guard coins >= currentContinueCost else { return }
            
            btn.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            
            let newCoins = coins - currentContinueCost
            UserDefaults.standard.set(newCoins, forKey: "TotalCoins")
            ICloudSyncManager.shared.pushValue(newCoins, forKey: "TotalCoins")
            
            HapticHelper.notification(.success)
            delegate?.gameOverOverlayDidTapContinue()
            
        } else if let btn = continueAdButton, btn.contains(location) {
            guard !isClaimingContinue else { return }
            btn.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            let hasRemovedAds = UserDefaults.standard.bool(forKey: "HasRemovedAds")
            if hasRemovedAds {
                HapticHelper.notification(.success)
                self.delegate?.gameOverOverlayDidTapContinue()
                return
            }

            guard let vc = self.scene?.view?.window?.rootViewController else { return }

            isClaimingContinue = true
            AdManager.shared.showRewardedAd(from: vc) { [weak self] reward in
                guard let self = self else { return }
                self.isClaimingContinue = false
                if reward > 0 {
                    HapticHelper.notification(.success)
                    self.delegate?.gameOverOverlayDidTapContinue()
                } else {
                    self.showToast(L10n.adNotAvailable)
                    HapticHelper.notification(.warning)
                }
            }
        } else if let btn = doubleCoinsButton, btn.contains(location) {
            guard runCoins > 0, !isClaimingDouble else { return }
            btn.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))

            let grant: () -> Void = { [weak self] in
                guard let self = self else { return }
                self.delegate?.gameOverOverlayDidTapDoubleCoins()
                let c = UserDefaults.standard.integer(forKey: "TotalCoins")
                self.coinsDisplayLabel?.text = "⭐ \(c)"
                self.doubleCoinsButton?.removeFromParent()
                self.doubleCoinsButton = nil
                HapticHelper.notification(.success)
            }

            if UserDefaults.standard.bool(forKey: "HasRemovedAds") {
                grant()
                return
            }

            guard let vc = self.scene?.view?.window?.rootViewController else { return }
            isClaimingDouble = true
            AdManager.shared.showRewardedAd(from: vc) { [weak self] reward in
                guard let self = self else { return }
                self.isClaimingDouble = false
                if reward > 0 {
                    grant()
                } else {
                    self.showToast(L10n.adNotAvailable)
                    HapticHelper.notification(.warning)
                }
            }

        } else if menuButton.contains(location) {
            menuButton.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            delegate?.gameOverOverlayDidTapMenu()
            
        } else if shareButton.contains(location) {
            shareButton.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            shareScore()
        }
    }
    
    private func shareScore() {
        guard let vc = self.scene?.view?.window?.rootViewController else { return }
        
        let shareText = L10n.shareText("\(scoreValue)")
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = vc.view
            popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        vc.present(activityVC, animated: true)
    }
    
    private func showToast(_ message: String) {
        let toast = SKShapeNode(rectOf: CGSize(width: 260, height: 50), cornerRadius: 12)
        toast.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.9)
        toast.strokeColor = .clear
        toast.position = CGPoint(x: 0, y: 150)
        toast.zPosition = 300
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = message
        label.fontSize = 12
        label.fontColor = .white
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 240
        label.verticalAlignmentMode = .center
        label.position = .zero
        toast.addChild(label)
        
        toast.alpha = 0
        background.addChild(toast)
        
        toast.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
}
