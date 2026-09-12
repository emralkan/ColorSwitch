import SpriteKit

protocol MissionOverlayDelegate: AnyObject {
    func missionOverlayDidClose()
}

class MissionOverlayNode: SKNode {
    
    weak var delegate: MissionOverlayDelegate?
    
    private let background: SKShapeNode
    private let closeButton: SKShapeNode
    private let itemsContainer = SKNode()
    private var missionNodes: [SKShapeNode] = []
    
    override init() {
        let size = CGSize(width: 320, height: 480)
        background = SKShapeNode(rectOf: size, cornerRadius: 28)
        background.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.98)
        background.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        background.lineWidth = 2.0
        
        closeButton = SKShapeNode(circleOfRadius: 18)
        closeButton.fillColor = SKColor(white: 0.25, alpha: 1.0)
        closeButton.strokeColor = .clear
        closeButton.position = CGPoint(x: size.width/2 - 25, y: size.height/2 - 25)
        closeButton.zPosition = 55
        
        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.text = "✕"
        closeLabel.fontSize = 18
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = CGPoint(x: 0, y: 1)
        closeButton.addChild(closeLabel)
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = L10n.dailyMissions
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: -10, y: size.height/2 - 50)
        titleLabel.zPosition = 55
        
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitleLabel.text = L10n.missionSubtitle
        subtitleLabel.fontSize = 14
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: 0, y: size.height/2 - 75)
        subtitleLabel.zPosition = 55
        
        super.init()
        
        addChild(background)
        background.addChild(closeButton)
        background.addChild(titleLabel)
        background.addChild(subtitleLabel)
        
        itemsContainer.zPosition = 10
        background.addChild(itemsContainer)
        
        setupMissionsList()
        
        MissionManager.shared.onMissionsUpdated = { [weak self] in
            self?.refreshUI()
        }
        
        self.isUserInteractionEnabled = true
        self.zPosition = 1000

        fitToScreen(panelHeight: size.height)
    }

    private func setupMissionsList() {
        let missions = MissionManager.shared.currentMissions
        itemsContainer.removeAllChildren()
        missionNodes.removeAll()
        
        let startY: CGFloat = 80
        let spacingY: CGFloat = 110
        
        for (index, mission) in missions.enumerated() {
            let yPos = startY - CGFloat(index) * spacingY
            
            let itemBg = SKShapeNode(rectOf: CGSize(width: 300, height: 95), cornerRadius: 16)
            itemBg.position = CGPoint(x: 0, y: yPos)
            itemBg.fillColor = SKColor(white: 0.18, alpha: 1.0)
            itemBg.strokeColor = .clear
            itemBg.name = mission.id
            
            let iconLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            iconLabel.fontSize = 28
            iconLabel.position = CGPoint(x: -115, y: -10)
            switch mission.type {
            case .playGames: iconLabel.text = "🎮"
            case .collectStars: iconLabel.text = "⭐"
            case .reachScore: iconLabel.text = "🏆"
            case .collectJokers: iconLabel.text = "🌈"
            }
            itemBg.addChild(iconLabel)
            
            let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
            title.text = mission.title
            title.fontSize = 15
            title.fontColor = .white
            title.position = CGPoint(x: -80, y: 15)
            title.horizontalAlignmentMode = .left
            itemBg.addChild(title)
            
            let barWidth: CGFloat = 120
            let barBase = SKShapeNode(rectOf: CGSize(width: barWidth, height: 10), cornerRadius: 5)
            barBase.fillColor = SKColor(white: 0.1, alpha: 1.0)
            barBase.strokeColor = .clear
            barBase.position = CGPoint(x: (-80 + barWidth/2), y: -6)
            itemBg.addChild(barBase)
            
            let fillParent = SKNode()
            fillParent.position = CGPoint(x: -80, y: -6)
            fillParent.name = "fillParent"
            
            let barFill = SKShapeNode(rectOf: CGSize(width: 0.1, height: 10), cornerRadius: 5)
            barFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
            barFill.strokeColor = .clear
            barFill.name = "fill"
            barFill.position = CGPoint(x: 0, y: 0)
            fillParent.addChild(barFill)
            itemBg.addChild(fillParent)
            
            let progressText = SKLabelNode(fontNamed: "AvenirNext-Medium")
            progressText.name = "progressText"
            progressText.text = "\(mission.currentAmount)/\(mission.targetAmount)"
            progressText.fontSize = 12
            progressText.fontColor = SKColor(white: 0.7, alpha: 1.0)
            progressText.position = CGPoint(x: -80 + barWidth/2, y: -24)
            progressText.horizontalAlignmentMode = .center
            itemBg.addChild(progressText)
            
            let claimBtn = SKShapeNode(rectOf: CGSize(width: 80, height: 35), cornerRadius: 12)
            claimBtn.name = "claimBtn"
            claimBtn.position = CGPoint(x: 95, y: -6)
            
            let btnLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            btnLabel.name = "btnLabel"
            btnLabel.fontSize = 13
            btnLabel.verticalAlignmentMode = .center
            btnLabel.position = .zero
            claimBtn.addChild(btnLabel)
            
            itemBg.addChild(claimBtn)
            
            itemsContainer.addChild(itemBg)
            missionNodes.append(itemBg)
        }
        
        refreshUI()
    }
    
    private func refreshUI() {
        let missions = MissionManager.shared.currentMissions
        
        for (index, itemBg) in missionNodes.enumerated() {
            guard index < missions.count else { continue }
            let mission = missions[index]
            
            let progressParent = itemBg.childNode(withName: "fillParent")
            let progressFill = progressParent?.childNode(withName: "fill") as? SKShapeNode
            let progressText = itemBg.childNode(withName: "progressText") as? SKLabelNode
            let claimBtn = itemBg.childNode(withName: "claimBtn") as? SKShapeNode
            let claimLbl = claimBtn?.childNode(withName: "btnLabel") as? SKLabelNode
            
            progressText?.text = "\(mission.currentAmount)/\(mission.targetAmount)"
            
            let fillRatio = min(CGFloat(mission.currentAmount) / CGFloat(mission.targetAmount), 1.0)
            let barWidth: CGFloat = 120
            let fillW = max(fillRatio * barWidth, 0.1)
            
            progressFill?.path = CGPath(roundedRect: CGRect(x: 0, y: -5, width: fillW, height: 10), cornerWidth: 5, cornerHeight: 5, transform: nil)
            
            if mission.isClaimed {
                claimBtn?.fillColor = SKColor(white: 0.3, alpha: 1.0)
                claimBtn?.strokeColor = .clear
                claimLbl?.text = L10n.claimed
                claimLbl?.fontColor = SKColor(white: 0.6, alpha: 1.0)
            } else if mission.isComplete {
                claimBtn?.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
                claimBtn?.strokeColor = .white
                claimLbl?.text = L10n.getReward(mission.reward)
                claimLbl?.fontColor = .black
                
                if claimBtn?.action(forKey: "pulse") == nil {
                    let pulse = SKAction.sequence([
                        SKAction.scale(to: 1.1, duration: 0.3),
                        SKAction.scale(to: 1.0, duration: 0.3)
                    ])
                    claimBtn?.run(SKAction.repeatForever(pulse), withKey: "pulse")
                }
            } else {
                claimBtn?.fillColor = SKColor(white: 0.2, alpha: 1.0)
                claimBtn?.strokeColor = SKColor(white: 0.4, alpha: 1.0)
                claimLbl?.text = "⭐ \(mission.reward)"
                claimLbl?.fontColor = SKColor(white: 0.6, alpha: 1.0)
                claimBtn?.removeAction(forKey: "pulse")
                claimBtn?.setScale(1.0)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if closeButton.contains(location) {
            delegate?.missionOverlayDidClose()
            return
        }
        
        let containerLoc = touch.location(in: itemsContainer)
        let missions = MissionManager.shared.currentMissions
        
        for (index, itemBg) in missionNodes.enumerated() {
            if itemBg.contains(containerLoc) {
                guard index < missions.count else { continue }
                let mission = missions[index]
                
                if mission.isComplete && !mission.isClaimed {
                    let reward = MissionManager.shared.claimReward(for: mission.id)
                    if reward > 0 {
                        
                        let currentCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
                        let newCoins = currentCoins + reward
                        UserDefaults.standard.set(newCoins, forKey: "TotalCoins")
                        ICloudSyncManager.shared.pushValue(newCoins, forKey: "TotalCoins")
                        
                        let particle = SKShapeNode(circleOfRadius: 10)
                        particle.fillColor = .yellow
                        particle.position = itemBg.position
                        particle.position.x += 100
                        itemsContainer.addChild(particle)
                        
                        let throwStar = SKAction.sequence([
                            SKAction.moveBy(x: 0, y: 150, duration: 0.3),
                            SKAction.fadeOut(withDuration: 0.2),
                            SKAction.removeFromParent()
                        ])
                        particle.run(throwStar)
                        
                        if let delegateScene = delegate as? GameScene {
                            delegateScene.totalCoins = newCoins
                            HapticHelper.notification(.success)
                        }
                    }
                }
            }
        }
    }
}
