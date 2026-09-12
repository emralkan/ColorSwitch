import SpriteKit
import UIKit
import GameplayKit

// MARK: - Oyun Katmanları

extension GameScene {
    
    
    func showTutorialOverlay() {
        let overlay = SKNode()
        overlay.name = "onboardingOverlay"
        overlay.zPosition = 500
        overlay.isUserInteractionEnabled = false
        
        let bg = SKShapeNode(rectOf: CGSize(width: size.width + 100, height: size.height + 100))
        bg.fillColor = SKColor.black.withAlphaComponent(0.85)
        bg.strokeColor = .clear
        overlay.addChild(bg)
        
        let pageContainer = SKNode()
        pageContainer.name = "pageContainer"
        overlay.addChild(pageContainer)
        
        let page1 = SKNode()
        page1.name = "page_0"
        
        let ringColors: [SKColor] = [.cyan, .magenta, .yellow, .orange]
        let logoRingRadius: CGFloat = 55
        for i in 0..<4 {
            let arc = SKShapeNode()
            let path = CGMutablePath()
            let startAngle = CGFloat(i) * (.pi / 2) - .pi / 4
            let endAngle = startAngle + (.pi / 2)
            path.addArc(center: .zero, radius: logoRingRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            arc.path = path
            arc.strokeColor = ringColors[i]
            arc.lineWidth = 8
            arc.glowWidth = 3
            arc.position = CGPoint(x: 0, y: 80)
            page1.addChild(arc)
            
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 4.0)
            arc.run(SKAction.repeatForever(spin))
        }
        
        let logoDot = SKShapeNode(circleOfRadius: 12)
        logoDot.fillColor = .cyan
        logoDot.strokeColor = .white
        logoDot.lineWidth = 2
        logoDot.glowWidth = 4
        logoDot.position = CGPoint(x: 0, y: 80)
        page1.addChild(logoDot)
        
        let colorCycle = SKAction.sequence([
            SKAction.run { logoDot.fillColor = .cyan },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { logoDot.fillColor = .magenta },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { logoDot.fillColor = .yellow },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { logoDot.fillColor = .orange },
            SKAction.wait(forDuration: 0.8)
        ])
        logoDot.run(SKAction.repeatForever(colorCycle))
        
        let welcomeTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        welcomeTitle.text = "CHROMITY"
        welcomeTitle.fontSize = 42
        welcomeTitle.fontColor = .white
        welcomeTitle.position = CGPoint(x: 0, y: -10)
        page1.addChild(welcomeTitle)
        
        let welcomeSub = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        welcomeSub.text = L10n.colorMatching
        welcomeSub.fontSize = 16
        welcomeSub.fontColor = SKColor(white: 0.6, alpha: 1.0)
        welcomeSub.position = CGPoint(x: 0, y: -40)
        page1.addChild(welcomeSub)
        
        let tagline = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tagline.text = L10n.matchJumpSurvive
        tagline.fontSize = 20
        tagline.fontColor = .cyan
        tagline.position = CGPoint(x: 0, y: -90)
        page1.addChild(tagline)
        
        let tagPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ])
        tagline.run(SKAction.repeatForever(tagPulse))
        
        pageContainer.addChild(page1)
        
        let page2 = SKNode()
        page2.name = "page_1"
        page2.position = CGPoint(x: size.width, y: 0)
        
        let howTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        howTitle.text = L10n.howToPlay
        howTitle.fontSize = 28
        howTitle.fontColor = .white
        howTitle.position = CGPoint(x: 0, y: 140)
        page2.addChild(howTitle)
        
        let step1Icon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        step1Icon.text = "👆"
        step1Icon.fontSize = 44
        step1Icon.position = CGPoint(x: -80, y: 65)
        page2.addChild(step1Icon)
        
        let tapAnim = SKAction.sequence([
            SKAction.scale(to: 0.8, duration: 0.3),
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.wait(forDuration: 0.5)
        ])
        step1Icon.run(SKAction.repeatForever(tapAnim))
        
        let step1Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        step1Label.text = L10n.tapToJump
        step1Label.fontSize = 20
        step1Label.fontColor = .cyan
        step1Label.horizontalAlignmentMode = .left
        step1Label.position = CGPoint(x: -40, y: 72)
        page2.addChild(step1Label)
        
        let step1Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        step1Desc.text = L10n.tapScreenToJump
        step1Desc.fontSize = 13
        step1Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        step1Desc.horizontalAlignmentMode = .left
        step1Desc.position = CGPoint(x: -40, y: 52)
        page2.addChild(step1Desc)
        
        let demoRingRadius: CGFloat = 32
        for i in 0..<4 {
            let arc = SKShapeNode()
            let path = CGMutablePath()
            let startAngle = CGFloat(i) * (.pi / 2)
            let endAngle = startAngle + (.pi / 2)
            path.addArc(center: .zero, radius: demoRingRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            arc.path = path
            arc.strokeColor = ringColors[i]
            arc.lineWidth = 6
            arc.position = CGPoint(x: -80, y: -15)
            page2.addChild(arc)
            
            arc.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3.0)))
        }
        
        let demoDot = SKShapeNode(circleOfRadius: 8)
        demoDot.fillColor = .cyan
        demoDot.strokeColor = .clear
        demoDot.position = CGPoint(x: -80, y: -15)
        page2.addChild(demoDot)
        
        let step2Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        step2Label.text = L10n.matchColors
        step2Label.fontSize = 20
        step2Label.fontColor = .yellow
        step2Label.horizontalAlignmentMode = .left
        step2Label.position = CGPoint(x: -40, y: -8)
        page2.addChild(step2Label)
        
        let step2Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        step2Desc.text = L10n.passThroughColor
        step2Desc.fontSize = 13
        step2Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        step2Desc.horizontalAlignmentMode = .left
        step2Desc.position = CGPoint(x: -40, y: -28)
        page2.addChild(step2Desc)
        
        let step3Icon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        step3Icon.text = "⭐"
        step3Icon.fontSize = 36
        step3Icon.position = CGPoint(x: -80, y: -85)
        page2.addChild(step3Icon)
        
        let starBounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.4),
            SKAction.moveBy(x: 0, y: -5, duration: 0.4)
        ])
        step3Icon.run(SKAction.repeatForever(starBounce))
        
        let step3Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        step3Label.text = L10n.collectStars
        step3Label.fontSize = 20
        step3Label.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        step3Label.horizontalAlignmentMode = .left
        step3Label.position = CGPoint(x: -40, y: -78)
        page2.addChild(step3Label)
        
        let step3Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        step3Desc.text = L10n.useCoinsDie
        step3Desc.fontSize = 13
        step3Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        step3Desc.horizontalAlignmentMode = .left
        step3Desc.position = CGPoint(x: -40, y: -98)
        page2.addChild(step3Desc)
        
        pageContainer.addChild(page2)
        
        let page3 = SKNode()
        page3.name = "page_2"
        page3.position = CGPoint(x: size.width * 2, y: 0)
        
        let tipsTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        tipsTitle.text = L10n.proTips
        tipsTitle.fontSize = 28
        tipsTitle.fontColor = .white
        tipsTitle.position = CGPoint(x: 0, y: 140)
        page3.addChild(tipsTitle)
        
        let tip1Icon = SKLabelNode(text: "⭐")
        tip1Icon.fontSize = 32
        tip1Icon.position = CGPoint(x: -80, y: 70)
        page3.addChild(tip1Icon)
        
        let tip1Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tip1Label.text = L10n.earnCoins
        tip1Label.fontSize = 18
        tip1Label.fontColor = .orange
        tip1Label.horizontalAlignmentMode = .left
        tip1Label.position = CGPoint(x: -40, y: 74)
        page3.addChild(tip1Label)
        
        let tip1Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tip1Desc.text = L10n.earnCoinsDesc
        tip1Desc.fontSize = 12
        tip1Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        tip1Desc.horizontalAlignmentMode = .left
        tip1Desc.position = CGPoint(x: -40, y: 55)
        page3.addChild(tip1Desc)
        
        let tip2Icon = SKLabelNode(text: "🛡️")
        tip2Icon.fontSize = 32
        tip2Icon.position = CGPoint(x: -80, y: 10)
        page3.addChild(tip2Icon)
        
        let tip2Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tip2Label.text = L10n.powerBar
        tip2Label.fontSize = 18
        tip2Label.fontColor = .green
        tip2Label.horizontalAlignmentMode = .left
        tip2Label.position = CGPoint(x: -40, y: 14)
        page3.addChild(tip2Label)
        
        let tip2Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tip2Desc.text = L10n.fillShieldDesc
        tip2Desc.fontSize = 12
        tip2Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        tip2Desc.horizontalAlignmentMode = .left
        tip2Desc.position = CGPoint(x: -40, y: -5)
        page3.addChild(tip2Desc)
        
        let tip3Icon = SKLabelNode(text: "🎨")
        tip3Icon.fontSize = 32
        tip3Icon.position = CGPoint(x: -80, y: -50)
        page3.addChild(tip3Icon)
        
        let tip3Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tip3Label.text = L10n.customize
        tip3Label.fontSize = 18
        tip3Label.fontColor = .magenta
        tip3Label.horizontalAlignmentMode = .left
        tip3Label.position = CGPoint(x: -40, y: -46)
        page3.addChild(tip3Label)
        
        let tip3Desc = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tip3Desc.text = L10n.unlockSkinsBg
        tip3Desc.fontSize = 12
        tip3Desc.fontColor = SKColor(white: 0.5, alpha: 1.0)
        tip3Desc.horizontalAlignmentMode = .left
        tip3Desc.position = CGPoint(x: -40, y: -65)
        page3.addChild(tip3Desc)
        
        let goBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 18)
        goBtn.fillColor = SKColor(red: 0.15, green: 0.65, blue: 0.35, alpha: 1.0)
        goBtn.strokeColor = .white
        goBtn.lineWidth = 2.0
        goBtn.position = CGPoint(x: 0, y: -130)
        goBtn.name = "onboardingDone"
        page3.addChild(goBtn)
        
        let goLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        goLabel.text = L10n.letsGo
        goLabel.fontSize = 20
        goLabel.fontColor = .white
        goLabel.verticalAlignmentMode = .center
        goLabel.position = .zero
        goBtn.addChild(goLabel)
        
        let goPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 0.95, duration: 0.6)
        ])
        goBtn.run(SKAction.repeatForever(goPulse))
        
        pageContainer.addChild(page3)
        
        let dotsNode = SKNode()
        dotsNode.name = "navDots"
        dotsNode.position = CGPoint(x: 0, y: -180)
        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: i == 0 ? 5 : 4)
            dot.fillColor = i == 0 ? .cyan : SKColor(white: 0.3, alpha: 1.0)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 1) * 20, y: 0)
            dot.name = "dot_\(i)"
            dotsNode.addChild(dot)
        }
        overlay.addChild(dotsNode)
        
        let tapHint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tapHint.text = L10n.tapToContinue
        tapHint.fontSize = 14
        tapHint.fontColor = SKColor(white: 0.4, alpha: 1.0)
        tapHint.position = CGPoint(x: 0, y: -210)
        tapHint.name = "tapHint"
        overlay.addChild(tapHint)
        
        let hintPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 0.8, duration: 0.8)
        ])
        tapHint.run(SKAction.repeatForever(hintPulse))
        
        overlay.userData = NSMutableDictionary()
        overlay.userData?["currentPage"] = 0
        
        page1.setScale(0.7)
        page1.alpha = 0
        page1.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.4),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
        
        cameraNode.addChild(overlay)
        tutorialOverlay = overlay
    }
    
    func advanceOnboarding() {
        guard let overlay = tutorialOverlay,
              let userData = overlay.userData,
              let currentPage = userData["currentPage"] as? Int,
              let pageContainer = overlay.childNode(withName: "pageContainer") else { return }
        
        if currentPage >= 2 { return }
        
        let nextPage = currentPage + 1
        
        let slideAmount = -size.width * CGFloat(nextPage)
        pageContainer.run(SKAction.moveTo(x: slideAmount, duration: 0.35))
        
        if let dotsNode = overlay.childNode(withName: "navDots") {
            for i in 0..<3 {
                if let dot = dotsNode.childNode(withName: "dot_\(i)") as? SKShapeNode {
                    dot.fillColor = i == nextPage ? .cyan : SKColor(white: 0.3, alpha: 1.0)
                    let radius: CGFloat = i == nextPage ? 5 : 4
                    dot.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2), transform: nil)
                }
            }
        }
        
        if nextPage == 2 {
            (overlay.childNode(withName: "tapHint") as? SKLabelNode)?.text = L10n.tapButtonStart
        }
        
        userData["currentPage"] = nextPage
    }
    
    func dismissTutorial() {
        UserDefaults.standard.set(true, forKey: "HasSeenTutorial")
        
        tutorialOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in
                self?.tutorialOverlay = nil
            }
        ]))
        
        HapticHelper.impact(.light)
    }
    
    
    func openSettings() {
        let scaleDown = SKAction.scale(to: 0.85, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.1)
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        settingsButton.run(SKAction.sequence([scaleDown, scaleUp, settle]))
        
        if settingsOverlay == nil {
            let overlay = SettingsOverlayNode()
            overlay.onClose = { [weak self] in
                self?.settingsOverlay?.removeFromParent()
                self?.settingsOverlay = nil
                self?.totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
                self?.stateMachine.enter(GSMenuState.self)
            }
            settingsOverlay = overlay
        }
        if let settingsOverlay, settingsOverlay.parent == nil {
            settingsOverlay.position = .zero
            cameraNode.addChild(settingsOverlay)
        }
    }
    
    func openShop() {
        let scaleDown = SKAction.scale(to: 0.85, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.1)
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        shopButton.run(SKAction.sequence([scaleDown, scaleUp, settle]))
        
        if shopOverlay == nil {
            let overlay = ShopOverlayNode()
            overlay.delegate = self
            shopOverlay = overlay
        }
        if let shopOverlay, shopOverlay.parent == nil {
            shopOverlay.position = .zero
            cameraNode.addChild(shopOverlay)
        }
    }
    
    func openLeaderboard() {
        AudioManager.shared.playSound(.jump)
        let scaleDown = SKAction.scale(to: 0.85, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.1)
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        leaderboardButton.run(SKAction.sequence([scaleDown, scaleUp, settle]))
        
        if let vc = self.view?.window?.rootViewController {
            GameCenterManager.shared.showLeaderboard(presentingViewController: vc)
        }
    }
    
    
    func pauseGame() {
        guard stateMachine.currentState is GSPlayingState else { return }
        stateMachine.enter(GSPausedState.self)
        self.isPaused = true
        
        if pauseOverlay == nil {
            let overlay = PauseOverlayNode()
            overlay.delegate = self
            pauseOverlay = overlay
        }
        
        if let pauseOverlay, pauseOverlay.parent == nil {
            pauseOverlay.position = .zero
            cameraNode.addChild(pauseOverlay)
        }
    }
    
    func resumeGame() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        self.isPaused = false
        if stateMachine.currentState is GSPausedState {
            stateMachine.enter(GSPlayingState.self)
        }
    }
    
    func jumpPlayer() {
        player.physicsBody?.velocity = CGVector.zero
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 9.0))
        HapticHelper.impact(.light)
        AudioManager.shared.playSound(.jump)
    }
}
