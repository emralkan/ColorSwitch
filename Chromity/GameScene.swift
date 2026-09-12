
import SpriteKit
import UIKit
import GameplayKit

enum PlayColors {
    static let colors = [
        SKColor.cyan,
        SKColor.yellow,
        SKColor.magenta,
        SKColor.orange
    ]
}

enum SwitchState {
    case bottom, top
}

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let obstacle: UInt32 = 0b10
    static let colorSwitch: UInt32 = 0b100
    static let scorePoint: UInt32 = 0b1000
    static let bonusStar: UInt32 = 0b10000
    static let lava: UInt32 = 0b100000
    static let powerUp: UInt32 = 0b1000000
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    enum ObstaclePattern {
        case circle
        case square
        case splitCircle
        case reverseCircle
    }

    lazy var stateMachine = GameStateMachine(scene: self)
    var currentColorIndex: Int?
    
    
    let pauseButton = SKShapeNode(circleOfRadius: 22)
    var pauseOverlay: PauseOverlayNode?
    
    var powerCharge: CGFloat = 0.0
    var lastPowerCharge: CGFloat = -1.0
    var isJokerModeActive = false
    var isSlowMoActive = false
    var jokerTimerNode: SKShapeNode?
    var continueCount = 0
    var hasShownOnboardingThisSession = false
    var waitingForFirstTap = false
    let powerRing = SKShapeNode()
    
    let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    let tapToPlayLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    let settingsButton = SKShapeNode(circleOfRadius: 25)
    let shopButton = SKShapeNode(circleOfRadius: 25)
    let missionsButton = SKShapeNode(circleOfRadius: 25)
    let challengesButton = SKShapeNode(circleOfRadius: 25)
    let leaderboardButton = SKShapeNode(circleOfRadius: 25)
    let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    let coinsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var totalCoins = 0 {
        didSet {
            let txt = "⭐ \(totalCoins)"
            coinsLabel.text = txt
            (coinsLabel.childNode(withName: "shadow") as? SKLabelNode)?.text = ""
            UserDefaults.standard.set(totalCoins, forKey: "TotalCoins")
            ICloudSyncManager.shared.pushValue(totalCoins, forKey: "TotalCoins")
        }
    }
    var menuDecorations = SKNode()
    
    var settingsOverlay: SettingsOverlayNode?
    var missionsOverlay: MissionOverlayNode?
    var shopOverlay: ShopOverlayNode?
    var challengesOverlay: ChallengeOverlayNode?
    var levelCompleteOverlay: LevelCompleteOverlayNode?
    var gameOverOverlay: GameOverOverlayNode?
    var tutorialOverlay: SKNode?
    var backgroundPickerOverlay: SKNode?
    let backgroundButton = SKShapeNode(circleOfRadius: 25)
    let dailyBonusButton = SKShapeNode(circleOfRadius: 16)
    var isClaimingDailyBonus = false
    var coinsThisRun = 0
    
    var score = 0 {
        didSet {
            let txt = "\(score)"
            scoreLabel.text = txt
            (scoreLabel.childNode(withName: "shadow") as? SKLabelNode)?.text = txt
            
            MissionManager.shared.reportScoreTarget(score: score)
        }
    }
    var highScore: Int = 0
    
    let player = SKShapeNode(circleOfRadius: 15)
    
    var obstacles: [SKNode] = []
    var obstaclePool: [String: [SKNode]] = [:]
    var highestObstacleY: CGFloat = 0.0
    var highestObstacleRadius: CGFloat = 0.0
    var cameraNode = SKCameraNode()
    var lastCameraY: CGFloat = 0.0
    
    var backgroundStars: [SKShapeNode] = []
    let groundLevelNode = SKNode()
    let cloudLayer = SKNode()
    
    lazy var particleTexture: SKTexture = {
        let size = CGSize(width: 10, height: 10)
        let image = UIGraphicsImageRenderer(size: size).image { rendererContext in
            rendererContext.cgContext.setFillColor(UIColor.white.cgColor)
            rendererContext.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }()

    // MARK: - Sahne Yaşam Döngüsü

    override func didMove(to view: SKView) {
        setupPhysics()
        loadHighScore()
        layoutScene()
        setupNewBackgrounds()
        createBackgroundStars()
        stateMachine.enter(GSMenuState.self)
    }

    
    func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "HighScore")
        totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
    }
    
    func saveHighScore() {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "HighScore")
            ICloudSyncManager.shared.pushValue(highScore, forKey: "HighScore")
        }
    }

    func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.8)
        physicsWorld.contactDelegate = self
    }
    

    // MARK: - Arayüz Kurulumu

    func layoutScene() {
        backgroundColor = BackgroundTheme.current.baseColor
        
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        camera = cameraNode
        addChild(cameraNode)
        
        scoreLabel.text = "0"
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - 100)
        scoreLabel.zPosition = 100
        scoreLabel.alpha = 0
        
        let scoreShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreShadow.name = "shadow"
        scoreShadow.fontSize = 60
        scoreShadow.fontColor = SKColor.black.withAlphaComponent(0.6)
        scoreShadow.position = CGPoint(x: 3, y: -3)
        scoreShadow.zPosition = -1
        scoreLabel.addChild(scoreShadow)
        
        cameraNode.addChild(scoreLabel)
        
        titleLabel.text = ""
        titleLabel.position = CGPoint(x: 0, y: 130)
        titleLabel.zPosition = 100
        
        let letters = Array("CHROMITY")
        let letterColors: [SKColor] = [.cyan, .magenta, .yellow, .orange, .cyan, .magenta, .yellow, .orange]
        let totalWidth: CGFloat = 260
        let letterSpacing = totalWidth / CGFloat(letters.count)
        let startX = -totalWidth / 2 + letterSpacing / 2
        
        for (i, char) in letters.enumerated() {
            let letter = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            letter.text = String(char)
            letter.fontSize = 48
            letter.fontColor = letterColors[i]
            letter.position = CGPoint(x: startX + CGFloat(i) * letterSpacing, y: 0)
            letter.verticalAlignmentMode = .center
            letter.horizontalAlignmentMode = .center
            letter.zPosition = 1
            titleLabel.addChild(letter)
            
            let delay = Double(i) * 0.15
            let glowPulse = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.run { letter.fontColor = .white },
                    SKAction.wait(forDuration: 0.12),
                    SKAction.run { letter.fontColor = letterColors[i] },
                    SKAction.wait(forDuration: 1.5)
                ]))
            ])
            letter.run(glowPulse)
        }
        
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text = "CHROMITY"
        shadow.fontSize = 48
        shadow.fontColor = SKColor(white: 0.15, alpha: 0.6)
        shadow.position = CGPoint(x: 3, y: -3)
        shadow.zPosition = -1
        titleLabel.addChild(shadow)
        
        let decorationNode = SKNode()
        decorationNode.position = CGPoint(x: 0, y: 15)
        decorationNode.zPosition = -2
        
        let innerRing = SKShapeNode(circleOfRadius: 180)
        innerRing.strokeColor = .white
        innerRing.lineWidth = 1.5
        innerRing.alpha = 0.2
        decorationNode.addChild(innerRing)
        
        let outerRing = SKShapeNode(circleOfRadius: 220)
        outerRing.strokeColor = .white
        outerRing.lineWidth = 1.0
        outerRing.alpha = 0.1
        decorationNode.addChild(outerRing)
        
        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: 6)
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.alpha = 0.4
            
            let angle = CGFloat(i) * (.pi * 2 / 3)
            dot.position = CGPoint(x: cos(angle) * 180, y: sin(angle) * 180)
            innerRing.addChild(dot)
        }
        
        innerRing.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 20)))
        outerRing.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi * 2, duration: 30)))
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        decorationNode.run(SKAction.repeatForever(pulse))
        
        titleLabel.addChild(decorationNode)
        
        cameraNode.addChild(titleLabel)
        
        highScoreLabel.text = L10n.highScore(highScore)
        highScoreLabel.fontSize = 24
        highScoreLabel.fontColor = .lightGray
        highScoreLabel.position = CGPoint(x: 0, y: 20)
        highScoreLabel.zPosition = 100
        
        let hsShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hsShadow.name = "shadow"
        hsShadow.text = highScoreLabel.text
        hsShadow.fontSize = 24
        hsShadow.fontColor = SKColor.black.withAlphaComponent(0.7)
        hsShadow.position = CGPoint(x: 2, y: -2)
        hsShadow.zPosition = -1
        highScoreLabel.addChild(hsShadow)
        
        cameraNode.addChild(highScoreLabel)
        
        tapToPlayLabel.text = L10n.tapToPlay
        tapToPlayLabel.fontSize = 24
        tapToPlayLabel.fontColor = .white
        tapToPlayLabel.position = CGPoint(x: 0, y: -100)
        tapToPlayLabel.zPosition = 100
        
        let tapShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapShadow.name = "shadow"
        tapShadow.text = L10n.tapToPlay
        tapShadow.fontSize = 24
        tapShadow.fontColor = SKColor.black.withAlphaComponent(0.7)
        tapShadow.position = CGPoint(x: 2, y: -2)
        tapShadow.zPosition = -1
        tapToPlayLabel.addChild(tapShadow)
        
        let glowNode = SKShapeNode(rectOf: CGSize(width: 320, height: 60), cornerRadius: 30)
        glowNode.fillColor = SKColor.black.withAlphaComponent(0.4)
        glowNode.strokeColor = SKColor.cyan
        glowNode.lineWidth = 2.0
        glowNode.glowWidth = 6.0
        glowNode.position = CGPoint(x: 0, y: 10)
        glowNode.zPosition = -2
        tapToPlayLabel.addChild(glowNode)
        
        cameraNode.addChild(tapToPlayLabel)
        
        shopButton.fillColor = SKColor.systemOrange
        shopButton.strokeColor = .white
        
        let shopIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shopIcon.text = "🛒"
        shopIcon.fontSize = 25
        shopIcon.verticalAlignmentMode = .center
        shopIcon.position = .zero
        shopButton.addChild(shopIcon)
        shopButton.name = "ShopButton"
        shopButton.position = CGPoint(x: 0, y: -220)
        cameraNode.addChild(shopButton)
        
        leaderboardButton.fillColor = SKColor.systemYellow
        leaderboardButton.strokeColor = .white
        
        let leaderIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        leaderIcon.text = "🏆"
        leaderIcon.fontSize = 25
        leaderIcon.verticalAlignmentMode = .center
        leaderIcon.position = .zero
        leaderboardButton.addChild(leaderIcon)
        leaderboardButton.name = "LeaderboardButton"
        leaderboardButton.position = CGPoint(x: -110, y: -220)
        cameraNode.addChild(leaderboardButton)
        
        backgroundButton.fillColor = SKColor.systemPurple
        backgroundButton.strokeColor = .white
        
        let bgIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bgIcon.text = "🎨"
        bgIcon.fontSize = 25
        bgIcon.verticalAlignmentMode = .center
        bgIcon.position = .zero
        backgroundButton.addChild(bgIcon)
        backgroundButton.name = "BackgroundButton"
        backgroundButton.position = CGPoint(x: -55, y: -220)
        cameraNode.addChild(backgroundButton)
        
        missionsButton.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        missionsButton.strokeColor = .white
        missionsButton.lineWidth = 1.0
        
        let missionsIcon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        missionsIcon.text = "📜"
        missionsIcon.fontSize = 25
        missionsIcon.verticalAlignmentMode = .center
        missionsIcon.position = CGPoint(x: 0, y: -2)
        missionsButton.addChild(missionsIcon)
        missionsButton.name = "MissionsButton"
        missionsButton.position = CGPoint(x: 55, y: -220)
        cameraNode.addChild(missionsButton)
        
        challengesButton.fillColor = SKColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1.0)
        challengesButton.strokeColor = .white
        challengesButton.lineWidth = 1.0
        
        let challengesIcon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        challengesIcon.text = "🔥"
        challengesIcon.fontSize = 25
        challengesIcon.verticalAlignmentMode = .center
        challengesIcon.position = CGPoint(x: 0, y: -2)
        challengesButton.addChild(challengesIcon)
        challengesButton.name = "ChallengesButton"
        challengesButton.position = CGPoint(x: 110, y: -220)
        cameraNode.addChild(challengesButton)
        
        settingsButton.fillColor = SKColor.darkGray
        settingsButton.strokeColor = .lightGray
        settingsButton.lineWidth = 1.5
        
        let settingsIcon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        settingsIcon.text = "⚙"
        settingsIcon.fontSize = 25
        settingsIcon.fontColor = .white
        settingsIcon.position = CGPoint(x: 0, y: -9)
        settingsButton.addChild(settingsIcon)
        
        settingsButton.position = CGPoint(x: (size.width / 2) - 50, y: (size.height / 2) - 80)
        settingsButton.zPosition = 100
        settingsButton.name = "SettingsButton"
        cameraNode.addChild(settingsButton)
        
        coinsLabel.text = "⭐ \(totalCoins)"
        coinsLabel.fontSize = 28
        coinsLabel.fontColor = .yellow
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: (-size.width / 2) + 30, y: (size.height / 2) - 90)
        coinsLabel.zPosition = 100
        
        let coinsShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinsShadow.name = "shadow"
        coinsShadow.text = ""
        coinsShadow.fontSize = 28
        coinsShadow.fontColor = SKColor.black.withAlphaComponent(0.7)
        coinsShadow.horizontalAlignmentMode = .left
        coinsShadow.position = CGPoint(x: 2, y: -2)
        coinsShadow.zPosition = -1
        coinsLabel.addChild(coinsShadow)
        
        cameraNode.addChild(coinsLabel)

        dailyBonusButton.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        dailyBonusButton.strokeColor = .white
        dailyBonusButton.lineWidth = 1.5
        dailyBonusButton.position = CGPoint(x: (-size.width / 2) + 150, y: (size.height / 2) - 80)
        dailyBonusButton.zPosition = 100
        dailyBonusButton.name = "DailyBonusButton"

        let giftIcon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        giftIcon.text = "🎁"
        giftIcon.fontSize = 18
        giftIcon.verticalAlignmentMode = .center
        giftIcon.horizontalAlignmentMode = .center
        giftIcon.position = CGPoint(x: 0, y: 0)
        dailyBonusButton.addChild(giftIcon)

        let dailyBadge = SKShapeNode(circleOfRadius: 6)
        dailyBadge.fillColor = .systemRed
        dailyBadge.strokeColor = .white
        dailyBadge.lineWidth = 1.0
        dailyBadge.position = CGPoint(x: 12, y: 12)
        dailyBadge.name = "dailyBadge"
        dailyBonusButton.addChild(dailyBadge)

        cameraNode.addChild(dailyBonusButton)

        pauseButton.fillColor = SKColor.darkGray.withAlphaComponent(0.7)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 1.5
        pauseButton.position = CGPoint(x: (size.width / 2) - 50, y: (size.height / 2) - 50)
        pauseButton.zPosition = 100
        pauseButton.name = "PauseButton"
        pauseButton.isHidden = true
        
        let pauseIcon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pauseIcon.text = "⏸"
        pauseIcon.fontSize = 20
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.position = .zero
        pauseButton.addChild(pauseIcon)
        cameraNode.addChild(pauseButton)
        
        powerRing.strokeColor = .cyan
        powerRing.lineWidth = 3.0
        powerRing.fillColor = .clear
        powerRing.zPosition = 5
        powerRing.isHidden = true
        player.addChild(powerRing)
        
        let trail = SKEmitterNode()
        trail.particleTexture = particleTexture
        trail.particleBirthRate = 0
        trail.particleLifetime = 0.5
        trail.particlePositionRange = CGVector(dx: 12, dy: 12)
        trail.particleSpeed = 15
        trail.particleSpeedRange = 10
        trail.emissionAngleRange = .pi * 2
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -1.6
        trail.particleScale = 0.8
        trail.particleScaleSpeed = -1.6
        trail.particleColorBlendFactor = 1.0
        trail.particleBlendMode = .add
        trail.name = "trail"
        trail.targetNode = self
        trail.position = .zero
        trail.zPosition = -1
        player.addChild(trail)
    }
    
    func updatePowerBar() {
        if powerCharge == lastPowerCharge { return }
        lastPowerCharge = powerCharge
        
        if powerCharge <= 0.001 {
            powerRing.isHidden = true
            powerRing.removeAction(forKey: "powerBlink")
            return
        }
        
        powerRing.isHidden = false
        
        let radius: CGFloat = 22.0
        let endAngle = CGFloat.pi * 2 * powerCharge
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: .pi / 2, endAngle: (.pi / 2) - endAngle, clockwise: true)
        powerRing.path = path
        
        if powerCharge >= 1.0 {
            powerRing.strokeColor = .systemYellow
            powerRing.lineWidth = 4.0
            powerRing.glowWidth = 6
            if powerRing.action(forKey: "powerBlink") == nil {
                let blink = SKAction.sequence([
                    SKAction.run { self.powerRing.alpha = 0.3 },
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { self.powerRing.alpha = 1.0 },
                    SKAction.wait(forDuration: 0.3)
                ])
                powerRing.run(SKAction.repeatForever(blink), withKey: "powerBlink")
            }
        } else {
            powerRing.removeAction(forKey: "powerBlink")
            powerRing.alpha = 1.0
            powerRing.glowWidth = 2
            powerRing.lineWidth = 3.0
            if powerCharge >= 0.5 {
                powerRing.strokeColor = .orange
            } else {
                powerRing.strokeColor = .cyan
            }
        }
    }



    // MARK: - Oyun Akışı

    func showMenu() {
        cameraNode.removeAllActions()
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        
        spawnPlayer()
        player.alpha = 0
        player.physicsBody?.isDynamic = false
        if let trail = player.childNode(withName: "trail") as? SKEmitterNode {
            trail.particleBirthRate = 0
        }
        
        clearObstacles()
        spawnInitialObstacles()
        for obs in obstacles { obs.alpha = 0 }
        
        score = 0
        continueCount = 0
        totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")

        let hsTxt = L10n.highScore(highScore)
        highScoreLabel.text = hsTxt
        (highScoreLabel.childNode(withName: "shadow") as? SKLabelNode)?.text = hsTxt
        
        titleLabel.isHidden = false
        titleLabel.alpha = 1
        highScoreLabel.isHidden = false
        highScoreLabel.alpha = 1
        tapToPlayLabel.isHidden = false
        tapToPlayLabel.alpha = 1
        shopButton.isHidden = false
        shopButton.alpha = 1
        missionsButton.isHidden = false
        missionsButton.alpha = 1
        challengesButton.isHidden = false
        challengesButton.alpha = 1
        settingsButton.isHidden = false
        settingsButton.alpha = 1
        coinsLabel.isHidden = false
        coinsLabel.alpha = 1
        leaderboardButton.isHidden = false
        leaderboardButton.alpha = 1
        backgroundButton.isHidden = false
        backgroundButton.alpha = 1
        dailyBonusButton.isHidden = false
        dailyBonusButton.alpha = 1
        updateDailyBonusBadge()
        scoreLabel.alpha = 0
        pauseButton.isHidden = true
        powerRing.isHidden = true
        
        titleLabel.setScale(0.8)
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.8)
        scaleUp.timingMode = .easeOut
        
        titleLabel.run(SKAction.group([
            scaleUp,
            SKAction.fadeIn(withDuration: 0.8)
        ]))
        
        tapToPlayLabel.removeAllActions()
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        tapToPlayLabel.run(SKAction.repeatForever(pulse))
        
        if !UserDefaults.standard.bool(forKey: "HasSeenTutorial") && !hasShownOnboardingThisSession {
            hasShownOnboardingThisSession = true
            showTutorialOverlay()
        }
    }
    
    func startGame() {
        cameraNode.removeAllActions()
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        score = 0
        coinsThisRun = 0
        
        clearObstacles()
        spawnInitialObstacles()
        for obs in obstacles { obs.alpha = 0 }
        
        powerCharge = 0
        isJokerModeActive = false
        isSlowMoActive = false
        player.removeAction(forKey: "jokerBlink")
        removeAction(forKey: "deactivateJoker")
        player.childNode(withName: "jokerShield")?.isHidden = true
        
        MissionManager.shared.reportPlayGame()
        
        if let challenge = ChallengeManager.shared.currentChallenge {
            let targetLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            targetLabel.text = L10n.goal(challenge.targetScore)
            targetLabel.fontSize = 40
            targetLabel.fontColor = .white
            targetLabel.position = CGPoint(x: 0, y: 150)
            targetLabel.zPosition = 50
            cameraNode.addChild(targetLabel)
            
            targetLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 50, duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        updatePowerBar()
        UserDefaults.standard.set(false, forKey: "HasSeen_square")
        UserDefaults.standard.set(false, forKey: "HasSeen_splitCircle")
        UserDefaults.standard.set(false, forKey: "HasSeen_reverseCircle")
        
        titleLabel.removeAllActions()
        tapToPlayLabel.removeAllActions()
        
        if let trail = player.childNode(withName: "trail") as? SKEmitterNode {
            trail.particleBirthRate = 80
            if let idx = currentColorIndex {
                trail.particleColor = PlayColors.colors[idx]
            }
        }
        
        titleLabel.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { [weak self] in self?.titleLabel.isHidden = true }
        ]))
        tapToPlayLabel.isHidden = true
        highScoreLabel.isHidden = true
        shopButton.isHidden = true
        settingsButton.isHidden = true
        coinsLabel.isHidden = true
        missionsButton.isHidden = true
        challengesButton.isHidden = true
        leaderboardButton.isHidden = true
        backgroundButton.isHidden = true
        dailyBonusButton.isHidden = true
        
        scoreLabel.alpha = 1
        pauseButton.isHidden = false
        
        for obs in obstacles { obs.run(SKAction.fadeIn(withDuration: 0.5)) }
        
        setupPhysics()
        powerRing.isHidden = true
        
        player.position = CGPoint(x: frame.midX, y: frame.minY + 120)
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false
        let equippedSkinID = UserDefaults.standard.string(forKey: "EquippedSkin") ?? "circle"
        player.alpha = (equippedSkinID == "ghost") ? 0.7 : 1.0
        waitingForFirstTap = true
        
        let hover = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.6),
            SKAction.moveBy(x: 0, y: -8, duration: 0.6)
        ])
        player.run(SKAction.repeatForever(hover), withKey: "hoverWait")
        
        let hint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hint.text = L10n.tapToJump
        hint.fontSize = 22
        hint.fontColor = .white
        hint.position = CGPoint(x: 0, y: (-size.height / 2) + 180)
        hint.zPosition = 100
        hint.name = "firstTapHint"
        cameraNode.addChild(hint)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        hint.run(SKAction.repeatForever(pulse))
    }
    
    func gameOver() {
        if let challenge = ChallengeManager.shared.currentChallenge {
            if score >= challenge.targetScore {
                die(win: true)
                return
            }
        }
        
        die(win: false)
    }
    
    func die(win: Bool = false) {
        
        AudioManager.shared.playSound(win ? .coin : .die)
        if win {
            HapticHelper.notification(.success)
        } else {
            HapticHelper.notification(.error)
        }
        
        cameraShake(intensity: win ? 15.0 : 30.0, duration: 0.4)
        
        switch stateMachine.currentState {
        case is GSPlayingState:
            stateMachine.enter(GSGameOverState.self)
            
            if win {
                player.physicsBody?.velocity = .zero
                player.physicsBody?.isDynamic = false
                pauseButton.isHidden = true

                powerRing.isHidden = true
                powerRing.removeAction(forKey: "powerBlink")
                isJokerModeActive = false
                player.removeAction(forKey: "jokerBlink")
                player.glowWidth = 0
                
                if isSlowMoActive {
                    isSlowMoActive = false
                    removeAction(forKey: "slowMoTimer")
                    for node in obstacles {
                        if node.name?.hasPrefix("Pattern_") == true {
                            node.speed = 1.0
                        }
                    }
                    for child in cameraNode.children {
                        if child is SKShapeNode && child.zPosition == -10 {
                            child.removeFromParent()
                        }
                    }
                }
                
                for _ in 0..<30 {
                    let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
                    spark.fillColor = [.yellow, .green, .cyan, .orange].randomElement()!
                    spark.position = player.position
                    spark.zPosition = 60
                    let dx = CGFloat.random(in: -200...200)
                    let dy = CGFloat.random(in: -200...200)
                    addChild(spark)
                    spark.run(SKAction.sequence([
                        SKAction.moveBy(x: dx, y: dy, duration: 0.8),
                        SKAction.fadeOut(withDuration: 0.4),
                        SKAction.removeFromParent()
                    ]))
                }
                
                player.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.5, duration: 0.3),
                        SKAction.run { self.player.glowWidth = 10 }
                    ]),
                    SKAction.group([
                        SKAction.scale(to: 0.0, duration: 0.5),
                        SKAction.fadeOut(withDuration: 0.5)
                    ])
                ]))
                
                ChallengeManager.shared.completeCurrentChallenge()
                totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
                let nextAction = SKAction.run { [weak self] in
                    self?.showLevelCompleteOverlay()
                }
                run(SKAction.sequence([SKAction.wait(forDuration: 1.0), nextAction]))
            } else {
                GameCenterManager.shared.submitScore(score)
                saveHighScore()
                
                player.physicsBody?.velocity = .zero
                player.physicsBody?.isDynamic = false
                
                pauseButton.isHidden = true

                powerRing.isHidden = true
                powerRing.removeAction(forKey: "powerBlink")
                isJokerModeActive = false
                player.removeAction(forKey: "jokerBlink")
                player.glowWidth = 0
                
                if isSlowMoActive {
                    isSlowMoActive = false
                    removeAction(forKey: "slowMoTimer")
                    for node in obstacles {
                        if node.name?.hasPrefix("Pattern_") == true {
                            node.speed = 1.0
                        }
                    }
                    for child in cameraNode.children {
                        if child is SKShapeNode && child.zPosition == -10 {
                            child.removeFromParent()
                        }
                    }
                }
                
                let deathColor = player.fillColor
                let explosion = SKEmitterNode()
                explosion.particleTexture = particleTexture
                explosion.particleBirthRate = 2000
                explosion.numParticlesToEmit = 120
                explosion.particleLifetime = 1.0
                explosion.particlePositionRange = CGVector(dx: 20, dy: 20)
                explosion.particleSpeed = 280
                explosion.particleSpeedRange = 150
                explosion.emissionAngleRange = .pi * 2
                explosion.particleAlpha = 1.0
                explosion.particleAlphaSpeed = -1.0
                explosion.particleScale = 1.5
                explosion.particleScaleSpeed = -1.0
                explosion.particleColor = deathColor
                explosion.particleColorBlendFactor = 1.0
                explosion.particleBlendMode = .add
                explosion.position = player.position
                explosion.zPosition = 100
                addChild(explosion)
                
                explosion.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.removeFromParent()
                ]))
                
                player.run(SKAction.sequence([
                    SKAction.scale(to: 2.0, duration: 0.1),
                    SKAction.fadeOut(withDuration: 0.1)
                ]))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.showGameOver()
                }
            }
        default:
            break
        }
    }
    
    func showGameOver() {
        if gameOverOverlay == nil {
            let overlay = GameOverOverlayNode(score: score, highScore: highScore, continueCount: continueCount, coinsThisRun: coinsThisRun)
            overlay.delegate = self
            overlay.position = .zero
            gameOverOverlay = overlay
            cameraNode.addChild(overlay)
        }
    }
    
    func showSettingsOverlay() {
        if settingsOverlay != nil { return }
        let overlay = SettingsOverlayNode()
        overlay.onClose = { [weak self] in
            self?.settingsOverlay?.removeFromParent()
            self?.settingsOverlay = nil
        }
        overlay.position = .zero
        cameraNode.addChild(overlay)
        settingsOverlay = overlay
        
        HapticHelper.impact(.medium)
    }
    
    func showShopOverlay() {
        if shopOverlay != nil { return }
        let overlay = ShopOverlayNode()
        overlay.delegate = self
        overlay.position = .zero
        cameraNode.addChild(overlay)
        shopOverlay = overlay

        HapticHelper.impact(.medium)
    }

    func claimDailyBonus() {
        guard !isClaimingDailyBonus else { return }
        guard DailyBonus.isAvailable else {
            HapticHelper.notification(.warning)
            showFloatingMenuMessage(L10n.dailyBonusClaimed)
            return
        }

        dailyBonusButton.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.06)
        ]))

        let grant: () -> Void = { [weak self] in
            guard let self = self else { return }
            DailyBonus.markClaimed()
            self.totalCoins += DailyBonus.amount
            self.updateDailyBonusBadge()
            HapticHelper.notification(.success)
            self.showFloatingMenuMessage("🎁 +\(DailyBonus.amount) ⭐")
        }

        if UserDefaults.standard.bool(forKey: "HasRemovedAds") {
            grant()
            return
        }

        guard let vc = self.view?.window?.rootViewController else { return }
        isClaimingDailyBonus = true
        AdManager.shared.showRewardedAd(from: vc) { [weak self] reward in
            guard let self = self else { return }
            self.isClaimingDailyBonus = false
            if reward > 0 {
                grant()
            } else {
                HapticHelper.notification(.warning)
            }
        }
    }

    private func showFloatingMenuMessage(_ text: String) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 22
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 60)
        label.zPosition = 250
        cameraNode.addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 60, duration: 1.0),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.6),
                    SKAction.fadeOut(withDuration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func updateDailyBonusBadge() {
        let badge = dailyBonusButton.childNode(withName: "dailyBadge")
        badge?.isHidden = !DailyBonus.isAvailable
        dailyBonusButton.position.x = coinsLabel.frame.maxX + 24
    }
    
    func showMissionsOverlay() {
        if missionsOverlay != nil { return }
        let overlay = MissionOverlayNode()
        overlay.delegate = self
        overlay.position = .zero
        cameraNode.addChild(overlay)
        missionsOverlay = overlay
        
        HapticHelper.impact(.medium)
    }
    
    func showChallengesOverlay() {
        if challengesOverlay != nil { return }
        let overlay = ChallengeOverlayNode()
        overlay.delegate = self
        overlay.position = .zero
        cameraNode.addChild(overlay)
        challengesOverlay = overlay
        
        HapticHelper.impact(.medium)
    }
    
    func showLevelCompleteOverlay() {
        if levelCompleteOverlay != nil { return }
        if let challenge = ChallengeManager.shared.currentChallenge {
            let overlay = LevelCompleteOverlayNode(challenge: challenge)
            overlay.delegate = self
            overlay.position = .zero
            cameraNode.addChild(overlay)
            levelCompleteOverlay = overlay
            
            HapticHelper.notification(.success)
        }
    }
    
    func resetGameLayout() {
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        player.position = CGPoint(x: frame.midX, y: frame.minY + 120)
        player.setScale(1.0)

        powerCharge = 0
        isJokerModeActive = false
        player.removeAction(forKey: "jokerBlink")
        player.glowWidth = 0
        updatePowerBar()
    }
    
    func clearObstacles() {
        for node in obstacles {
            node.removeFromParent()
            if let name = node.name, name.hasPrefix("Pattern_") {
                node.removeAllActions()
                node.zRotation = 0
                obstaclePool[name, default: []].append(node)
            }
        }
        obstacles.removeAll()
    }

    
    func cameraShake(intensity: CGFloat, duration: TimeInterval) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: intensity*0.8...intensity*1.2), y: CGFloat.random(in: -intensity/3...intensity/3), duration: duration/6),
            SKAction.moveBy(x: CGFloat.random(in: -intensity*1.2 ... -intensity*0.8), y: CGFloat.random(in: -intensity/3...intensity/3), duration: duration/6),
            SKAction.moveBy(x: CGFloat.random(in: intensity*0.5...intensity), y: CGFloat.random(in: -intensity/3...intensity/3), duration: duration/6),
            SKAction.moveBy(x: CGFloat.random(in: -intensity ... -intensity*0.5), y: CGFloat.random(in: -intensity/3...intensity/3), duration: duration/6),
            SKAction.moveBy(x: CGFloat.random(in: intensity*0.2...intensity*0.5), y: CGFloat.random(in: -intensity/4...intensity/4), duration: duration/6),
            SKAction.moveTo(x: frame.midX, duration: duration/6)
        ])
        cameraNode.run(shake)
    }

    func cameraZoom(scale: CGFloat, duration: TimeInterval) {
        let zoom = SKAction.sequence([
            SKAction.scale(to: scale, duration: duration / 2),
            SKAction.scale(to: 1.0, duration: duration / 2)
        ])
        zoom.timingMode = .easeInEaseOut
        cameraNode.run(zoom)
    }

    var obstacleSpawnCount = 0

    
    // MARK: - Kullanıcı Etkileşimi

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        
        if settingsOverlay?.parent != nil ||
           shopOverlay?.parent != nil ||
           missionsOverlay?.parent != nil ||
           challengesOverlay?.parent != nil ||
           gameOverOverlay?.parent != nil ||
           levelCompleteOverlay?.parent != nil {
            return
        }
        
        if tutorialOverlay != nil && stateMachine.currentState is GSMenuState {
            for node in tappedNodes {
                if node.name == "onboardingDone" || node.parent?.name == "onboardingDone" {
                    dismissTutorial()
                    return
                }
            }
            advanceOnboarding()
            return
        }
        
        if stateMachine.currentState is GSPausedState {
            return
        }
        
        if backgroundPickerOverlay != nil {
            for node in tappedNodes {
                var current: SKNode? = node
                while let n = current {
                    if let name = n.name {
                        if name == "BgPickerClose" || name == "BgPickerDim" {
                            closeBackgroundPicker()
                            return
                        }
                        if name.hasPrefix("BgTheme_") {
                            let themeID = String(name.dropFirst(8))
                            if themeID == "custom_photo" {
                                handleCustomPhotoTap()
                            } else {
                                applyTheme(themeID)
                            }
                            return
                        }
                    }
                    current = n.parent
                }
            }
            return
        }
        
        if stateMachine.currentState is GSMenuState {
            func isNodeTapped(name: String) -> Bool {
                for node in tappedNodes {
                    var currentNode: SKNode? = node
                    while let cNode = currentNode {
                        if cNode.name == name { return true }
                        currentNode = cNode.parent
                    }
                }
                return false
            }
            
            if isNodeTapped(name: "SettingsButton") {
                openSettings()
                return
            }
            if isNodeTapped(name: "ShopButton") {
                openShop()
                return
            }
            if isNodeTapped(name: "MissionsButton") {
                showMissionsOverlay()
                return
            }
            if isNodeTapped(name: "ChallengesButton") {
                showChallengesOverlay()
                return
            }
            if isNodeTapped(name: "LeaderboardButton") {
                openLeaderboard()
                return
            }
            if isNodeTapped(name: "BackgroundButton") {
                openBackgroundPicker()
                return
            }
            if isNodeTapped(name: "DailyBonusButton") {
                claimDailyBonus()
                return
            }
            
            if tutorialOverlay != nil {
                let tappedDone = tappedNodes.contains { $0.name == "onboardingDone" || $0.parent?.name == "onboardingDone" }
                if tappedDone {
                    dismissTutorial()
                } else {
                    advanceOnboarding()
                }
                return
            }
            
            stateMachine.enter(GSPlayingState.self)
            
        } else if stateMachine.currentState is GSPlayingState {
            func isNodeTappedPlaying(name: String) -> Bool {
                for node in tappedNodes {
                    var currentNode: SKNode? = node
                    while let cNode = currentNode {
                        if cNode.name == name { return true }
                        currentNode = cNode.parent
                    }
                }
                return false
            }
            if isNodeTappedPlaying(name: "PauseButton") {
                pauseGame()
                return
            }
            if self.view?.isPaused == true || stateMachine.currentState is GSPausedState { return }
            
            if waitingForFirstTap {
                waitingForFirstTap = false
                player.removeAction(forKey: "hoverWait")
                player.physicsBody?.isDynamic = true
                
                cameraNode.childNode(withName: "firstTapHint")?.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.removeFromParent()
                ]))
            }
            
            jumpPlayer()
        } else if stateMachine.currentState is GSGameOverState {
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    // MARK: - Kare Güncellemesi

    override func update(_ currentTime: TimeInterval) {
        updateBackgroundTransition()
        
        let dy = cameraNode.position.y - lastCameraY
        lastCameraY = cameraNode.position.y
        
        updateBackgroundStars(dy: dy)
        
        guard stateMachine.currentState is GSPlayingState else { return }
        if waitingForFirstTap { return }
        
        updatePowerBar()
        
        if let challenge = ChallengeManager.shared.currentChallenge {
            if score >= challenge.targetScore {
                gameOver()
                return
            }
        }

        if player.position.y > cameraNode.position.y {
            cameraNode.position.y = player.position.y
        }
        
        if player.position.y < cameraNode.position.y - (size.height / 2) {
            gameOver()
        }
        
        if highestObstacleY < player.position.y + size.height * 1.5 {
            spawnNextObstacle()
        }
        
        for (index, node) in obstacles.enumerated().reversed() {
            if node.position.y < cameraNode.position.y - size.height {
                node.removeFromParent()
                if let name = node.name, name.hasPrefix("Pattern_") {
                    node.removeAllActions()
                    node.zRotation = 0
                    obstaclePool[name, default: []].append(node)
                }
                obstacles.remove(at: index)
            }
        }
    }
    
    // MARK: - Çarpışmalar

    func didBegin(_ contact: SKPhysicsContact) {
        guard stateMachine.currentState is GSPlayingState else { return }
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == PhysicsCategory.player | PhysicsCategory.powerUp {
            let powerUpNode = (contact.bodyA.categoryBitMask == PhysicsCategory.powerUp) ? contact.bodyA.node : contact.bodyB.node
            
            if powerUpNode?.parent != nil {
                let pName = powerUpNode?.name
                powerUpNode?.removeFromParent()
                
                if pName == "slowMoPowerUp" {
                    activateSlowMoMode()
                } else {
                    activateJokerMode()
                    MissionManager.shared.reportJokerCollected()
                }
                
                AudioManager.shared.playSound(.coin)
                HapticHelper.impact(.medium)
                cameraZoom(scale: 0.94, duration: 0.2)
                triggerBackgroundPulse(color: .white)
                
                let colors: [SKColor] = [.cyan, .magenta, .yellow, .orange]
                for _ in 0..<10 {
                    let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
                    spark.fillColor = colors.randomElement()!
                    spark.strokeColor = .clear
                    spark.position = player.position
                    spark.zPosition = 50
                    addChild(spark)
                    let dx = CGFloat.random(in: -100...100)
                    let dy = CGFloat.random(in: -60...120)
                    spark.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.moveBy(x: dx, y: dy, duration: 0.5),
                            SKAction.fadeOut(withDuration: 0.5),
                            SKAction.scale(to: 0.1, duration: 0.5)
                        ]),
                        SKAction.removeFromParent()
                    ]))
                }
            }
        } else if contactMask == PhysicsCategory.player | PhysicsCategory.bonusStar {
            let starNode = (contact.bodyA.categoryBitMask == PhysicsCategory.bonusStar) ? contact.bodyA.node : contact.bodyB.node
            
            if starNode?.parent != nil {
                starNode?.removeFromParent()
                totalCoins += 1
                coinsThisRun += 1

                MissionManager.shared.reportStarCollected()
                
                AudioManager.shared.playSound(.coin)
                HapticHelper.impact(.light)
                
                let plusOne = SKLabelNode(fontNamed: "AvenirNext-Bold")
                plusOne.text = "+1"
                plusOne.fontSize = 30
                plusOne.fontColor = .yellow
                plusOne.position = starNode?.position ?? player.position
                plusOne.zPosition = 100
                addChild(plusOne)
                
                let floatAction = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: 0, y: 50, duration: 0.6),
                        SKAction.fadeOut(withDuration: 0.6)
                    ]),
                    SKAction.removeFromParent()
                ])
                plusOne.run(floatAction)
            }
            
        } else if contactMask == PhysicsCategory.player | PhysicsCategory.scorePoint {
            let starNode = (contact.bodyA.categoryBitMask == PhysicsCategory.scorePoint) ? contact.bodyA.node : contact.bodyB.node
            
            if starNode?.parent != nil && starNode?.physicsBody != nil {
                starNode?.physicsBody = nil
                score += 1
                totalCoins += 1
                coinsThisRun += 1
                
                powerCharge = min(1.0, powerCharge + 0.07)
                updatePowerBar()
                
                AudioManager.shared.playSound(.coin)
                
                let plusOne = SKLabelNode(fontNamed: "AvenirNext-Bold")
                plusOne.text = "+1"
                plusOne.fontSize = 30
                plusOne.fontColor = .yellow
                plusOne.position = starNode?.position ?? player.position
                plusOne.zPosition = 100
                addChild(plusOne)
                
                let floatAction = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: 0, y: 50, duration: 0.6),
                        SKAction.fadeOut(withDuration: 0.6)
                    ]),
                    SKAction.removeFromParent()
                ])
                plusOne.run(floatAction)
                
                starNode?.run(SKAction.sequence([
                    SKAction.scale(to: 0, duration: 0.1),
                    SKAction.removeFromParent()
                ]))
                
                HapticHelper.impact(.medium)
                triggerBackgroundPulse(color: player.fillColor)
            }
            
        } else if contactMask == PhysicsCategory.player | PhysicsCategory.colorSwitch {
            let changerNode = (contact.bodyA.categoryBitMask == PhysicsCategory.colorSwitch) ? contact.bodyA.node : contact.bodyB.node
            
            if changerNode?.parent != nil {
                var newColorIndex = Int.random(in: 0..<4)
                while newColorIndex == currentColorIndex {
                    newColorIndex = Int.random(in: 0..<4)
                }
                currentColorIndex = newColorIndex
                let newColor = PlayColors.colors[newColorIndex]
                
                player.run(SKAction.customAction(withDuration: 0.15) { node, elapsed in
                    (node as? SKShapeNode)?.fillColor = newColor
                })
                
                if let trail = player.childNode(withName: "trail") as? SKEmitterNode {
                    trail.particleColor = newColor
                }
                
                HapticHelper.impact(.light)
                AudioManager.shared.playSound(.switchColor)
                cameraZoom(scale: 0.97, duration: 0.15)
                cameraShake(intensity: 4, duration: 0.15)
                
                changerNode?.run(SKAction.sequence([
                    SKAction.scale(to: 1.5, duration: 0.1),
                    SKAction.fadeOut(withDuration: 0.1),
                    SKAction.removeFromParent()
                ]))
            }
            
        } else if contactMask == PhysicsCategory.player | PhysicsCategory.obstacle {
            if isJokerModeActive { return }
            
            let obstacleNode = (contact.bodyA.categoryBitMask == PhysicsCategory.obstacle) ? contact.bodyA.node : contact.bodyB.node
            
            var isWrongColor = false
            
            if let obstacleName = obstacleNode?.name, obstacleName.hasPrefix("obstacle_"),
               let colorIndexStr = obstacleName.split(separator: "_").last,
               let colorIndex = Int(colorIndexStr) {
                isWrongColor = (colorIndex != currentColorIndex)
            } else if let objColor = (obstacleNode as? SKShapeNode)?.fillColor ?? (obstacleNode as? SKSpriteNode)?.color {
                isWrongColor = (objColor != player.fillColor)
            }
            
            if isWrongColor {
                if powerCharge >= 1.0 {
                    HapticHelper.impact(.heavy)
                    AudioManager.shared.playSound(.coin)
                    cameraShake(intensity: 15, duration: 0.2)
                    triggerBackgroundPulse(color: .red)
                    
                    powerCharge = 0
                    lastPowerCharge = -1
                    updatePowerBar()
                    
                    player.run(SKAction.sequence([
                        SKAction.run { self.player.glowWidth = 8 },
                        SKAction.wait(forDuration: 0.3),
                        SKAction.run { self.player.glowWidth = 0 }
                    ]))
                    
                    if let segment = obstacleNode {
                        let shatterColor = (segment as? SKShapeNode)?.fillColor ?? .white
                        let worldPos = segment.convert(CGPoint.zero, to: self)
                        
                        for _ in 0..<6 {
                            let shard = SKShapeNode(rectOf: CGSize(width: 8, height: 4))
                            shard.fillColor = shatterColor
                            shard.strokeColor = .clear
                            shard.position = worldPos
                            shard.zPosition = 50
                            addChild(shard)
                            
                            let dx = CGFloat.random(in: -120...120)
                            let dy = CGFloat.random(in: -60...100)
                            shard.run(SKAction.sequence([
                                SKAction.group([
                                    SKAction.moveBy(x: dx, y: dy, duration: 0.5),
                                    SKAction.fadeOut(withDuration: 0.5),
                                    SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
                                ]),
                                SKAction.removeFromParent()
                            ]))
                        }
                        
                        segment.removeFromParent()
                    }
                } else {
                    powerCharge = 0
                    updatePowerBar()
                    AudioManager.shared.playSound(.die)
                    gameOver()
                }
            }
        }
    }
    // MARK: - Güçlendirmeler

    func activateJokerMode() {
        isJokerModeActive = true
        
        player.removeAction(forKey: "jokerBlink")
        
        if player.childNode(withName: "jokerShield") == nil {
            let shield = SKShapeNode(circleOfRadius: 22)
            shield.name = "jokerShield"
            shield.strokeColor = .white
            shield.lineWidth = 3.0
            shield.glowWidth = 5.0
            shield.fillColor = .clear
            shield.zPosition = -1
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.3),
                SKAction.scale(to: 0.9, duration: 0.3)
            ])
            shield.run(SKAction.repeatForever(pulse))
            player.addChild(shield)
        }
        player.childNode(withName: "jokerShield")?.isHidden = false
        
        let rainbowPulse = SKAction.sequence([
            SKAction.run { self.player.fillColor = .cyan },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { self.player.fillColor = .magenta },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { self.player.fillColor = .yellow },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { self.player.fillColor = .orange },
            SKAction.wait(forDuration: 0.1)
        ])
        player.run(SKAction.repeatForever(rainbowPulse), withKey: "jokerBlink")
        
        player.glowWidth = 4.0
        
        let jokerDuration: TimeInterval = 6.0
        jokerTimerNode?.removeFromParent()
        
        let barContainer = SKShapeNode()
        barContainer.zPosition = 110
        barContainer.position = CGPoint(x: 0, y: (size.height / 2) - 130)
        cameraNode.addChild(barContainer)
        jokerTimerNode = barContainer
        
        let barWidth: CGFloat = 200
        let barHeight: CGFloat = 20
        let bgBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 10)
        bgBar.fillColor = SKColor(white: 0.15, alpha: 0.9)
        bgBar.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        bgBar.lineWidth = 1.5
        barContainer.addChild(bgBar)
        
        let fillBar = SKShapeNode(rectOf: CGSize(width: barWidth - 4, height: barHeight - 4), cornerRadius: 8)
        fillBar.fillColor = .cyan
        fillBar.strokeColor = .clear
        fillBar.glowWidth = 3.0
        fillBar.name = "jokerFill"
        barContainer.addChild(fillBar)
        
        let jokerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        jokerLabel.text = L10n.jokerMode
        jokerLabel.fontSize = 14
        jokerLabel.fontColor = .white
        jokerLabel.position = CGPoint(x: 0, y: 18)
        barContainer.addChild(jokerLabel)
        
        let barRainbow = SKAction.sequence([
            SKAction.run { fillBar.fillColor = .cyan },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { fillBar.fillColor = .magenta },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { fillBar.fillColor = .yellow },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { fillBar.fillColor = .orange },
            SKAction.wait(forDuration: 0.15)
        ])
        fillBar.run(SKAction.repeatForever(barRainbow))
        
        let shrinkFill = SKAction.customAction(withDuration: jokerDuration) { node, elapsed in
            let t = 1.0 - (elapsed / CGFloat(jokerDuration))
            let currentWidth = max(2, (barWidth - 4) * t)
            let rect = CGRect(x: -currentWidth/2, y: -(barHeight - 4)/2, width: currentWidth, height: barHeight - 4)
            (node as? SKShapeNode)?.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        }
        fillBar.run(shrinkFill)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        barContainer.run(SKAction.repeatForever(pulse))
        
        barContainer.setScale(0.5)
        barContainer.alpha = 0
        barContainer.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
        
        removeAction(forKey: "deactivateJoker")
        run(SKAction.sequence([
            SKAction.wait(forDuration: jokerDuration),
            SKAction.run { self.deactivateJokerMode() }
        ]), withKey: "deactivateJoker")
    }

    func deactivateJokerMode() {
        guard stateMachine.currentState is GSPlayingState else {
            isJokerModeActive = false
            player.removeAction(forKey: "jokerBlink")
            player.childNode(withName: "jokerShield")?.isHidden = true
            jokerTimerNode?.removeFromParent()
            jokerTimerNode = nil
            return
        }

        isJokerModeActive = false
        player.removeAction(forKey: "jokerBlink")
        player.childNode(withName: "jokerShield")?.isHidden = true
        
        if let idx = currentColorIndex {
            player.fillColor = PlayColors.colors[idx]
        }
        
        jokerTimerNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        jokerTimerNode = nil

        let baseAlpha: CGFloat = (UserDefaults.standard.string(forKey: "EquippedSkin") == "ghost") ? 0.7 : 1.0
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: baseAlpha, duration: 0.1)
        ])
        player.run(SKAction.repeat(blink, count: 3))
    }

    func activateSlowMoMode() {
        if isSlowMoActive { return }
        isSlowMoActive = true
        
        let vignette = SKShapeNode(rectOf: size)
        vignette.fillColor = SKColor.cyan.withAlphaComponent(0.15)
        vignette.strokeColor = .clear
        vignette.zPosition = -10
        cameraNode.addChild(vignette)
        
        vignette.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.15, duration: 0.5)
        ])))
        
        for node in obstacles {
            if node.name?.hasPrefix("Pattern_") == true {
                node.speed = 0.4
            }
        }
        
        triggerBackgroundPulse(color: .cyan)
        
        let wait = SKAction.wait(forDuration: 6.0)
        let finish = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isSlowMoActive = false
            for node in self.obstacles {
                if node.name?.hasPrefix("Pattern_") == true {
                    node.speed = 1.0
                }
            }
            vignette.removeFromParent()
        }
        
        self.run(SKAction.sequence([wait, finish]), withKey: "slowMoTimer")
    }
}

// MARK: - Katman Temsilcileri

extension GameScene: ShopOverlayDelegate {
    func shopOverlayDidClose() {
        shopOverlay?.removeFromParent()
        shopOverlay = nil
        
        totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
        stateMachine.enter(GSMenuState.self)
    }
    
    func shopOverlayDidEquipSkin(_ skinName: String) {
        updatePlayerShape()
    }
}

extension GameScene: MissionOverlayDelegate {
    func missionOverlayDidClose() {
        missionsOverlay?.removeFromParent()
        missionsOverlay = nil
        
        stateMachine.enter(GSMenuState.self)
    }
}

extension GameScene: ChallengeOverlayDelegate {
    func challengeOverlayDidClose() {
        challengesOverlay?.removeFromParent()
        challengesOverlay = nil
        ChallengeManager.shared.clearCurrentChallenge()
        stateMachine.enter(GSMenuState.self)
    }
    
    func challengeOverlayDidSelect(level: Int) {
        challengesOverlay?.removeFromParent()
        challengesOverlay = nil
        
        let challenge = ChallengeManager.shared.getChallenge(for: level)
        ChallengeManager.shared.currentChallenge = challenge
        
        stateMachine.enter(GSPlayingState.self)
    }
}

extension GameScene: LevelCompleteDelegate {
    func levelCompleteDidTapNext() {
        guard let current = ChallengeManager.shared.currentChallenge else { return }
        levelCompleteOverlay?.removeFromParent()
        levelCompleteOverlay = nil
        
        let nextLevel = current.level + 1
        if nextLevel <= ChallengeManager.shared.totalLevels {
            ChallengeManager.shared.currentChallenge = ChallengeManager.shared.getChallenge(for: nextLevel)
            
            continueCount = 0
            clearObstacles()
            resetGameLayout()
            spawnPlayer()
            spawnInitialObstacles()
            
            stateMachine.enter(GSPlayingState.self)
        } else {
            ChallengeManager.shared.clearCurrentChallenge()
            stateMachine.enter(GSMenuState.self)
        }
    }
    
    func levelCompleteDidTapMenu() {
        levelCompleteOverlay?.removeFromParent()
        levelCompleteOverlay = nil
        ChallengeManager.shared.clearCurrentChallenge()
        stateMachine.enter(GSMenuState.self)
    }
}

extension GameScene: GameOverOverlayDelegate {
    func gameOverOverlayDidTapRestart() {
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        continueCount = 0
        clearObstacles()
        resetGameLayout()
        spawnPlayer()
        spawnInitialObstacles()
        stateMachine.enter(GSPlayingState.self)
    }
    
    func gameOverOverlayDidTapMenu() {
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        ChallengeManager.shared.clearCurrentChallenge()
        stateMachine.enter(GSMenuState.self)
    }

    func gameOverOverlayDidTapDoubleCoins() {
        guard coinsThisRun > 0 else { return }
        totalCoins += coinsThisRun
        coinsThisRun = 0
    }
    
    func gameOverOverlayDidTapContinue() {
        totalCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
        coinsThisRun = 0
        continueCount += 1
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        setupPhysics()
        
        player.removeAllActions()
        
        player.alpha = 1
        player.setScale(1.0)
        
        updatePlayerShape()
        player.physicsBody?.isDynamic = false
        player.physicsBody?.velocity = .zero
        
        player.position = CGPoint(x: frame.midX, y: cameraNode.position.y)
        
        if let idx = currentColorIndex {
            player.fillColor = PlayColors.colors[idx]
            if let trail = player.childNode(withName: "trail") as? SKEmitterNode {
                trail.particleColor = player.fillColor
            }
        }
        
        jokerTimerNode?.removeFromParent()
        jokerTimerNode = nil
        removeAction(forKey: "deactivateJoker")
        
        activateJokerMode()
        
        pauseButton.isHidden = false
        scoreLabel.alpha = 1
        
        stateMachine.enter(GSPlayingState.self)
        
        waitingForFirstTap = true
        
        let hover = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.6),
            SKAction.moveBy(x: 0, y: -8, duration: 0.6)
        ])
        player.run(SKAction.repeatForever(hover), withKey: "hoverWait")
        
        cameraNode.childNode(withName: "firstTapHint")?.removeFromParent()
        let hint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hint.text = L10n.tapToJump
        hint.fontSize = 22
        hint.fontColor = .white
        hint.position = CGPoint(x: 0, y: (-size.height / 2) + 180)
        hint.zPosition = 100
        hint.name = "firstTapHint"
        cameraNode.addChild(hint)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        hint.run(SKAction.repeatForever(pulse))
    }
}

extension GameScene: PauseOverlayDelegate {
    func pauseOverlayDidTapResume() {
        resumeGame()
    }
    
    func pauseOverlayDidTapQuit() {
        self.isPaused = false
        
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        
        clearObstacles()
        resetGameLayout()
        
        if isSlowMoActive {
            isSlowMoActive = false
            removeAction(forKey: "slowMoTimer")
            for child in cameraNode.children {
                if child is SKShapeNode && child.zPosition == -10 {
                    child.removeFromParent()
                }
            }
        }
        
        stateMachine.enter(GSMenuState.self)
    }
}

extension SKColor {
    static func interpolate(from color1: SKColor, to color2: SKColor, t: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return SKColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}
