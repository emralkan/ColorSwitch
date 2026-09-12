import SpriteKit

protocol ChallengeOverlayDelegate: AnyObject {
    func challengeOverlayDidClose()
    func challengeOverlayDidSelect(level: Int)
}

class ChallengeOverlayNode: SKNode {
    
    weak var delegate: ChallengeOverlayDelegate?
    
    private let background: SKShapeNode
    private let closeButton: SKShapeNode
    private let gridContainer = SKNode()
    
    override init() {
        let size = CGSize(width: 340, height: 500)
        background = SKShapeNode(rectOf: size, cornerRadius: 28)
        background.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.98)
        background.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        background.lineWidth = 2.0
        
        closeButton = SKShapeNode(circleOfRadius: 18)
        closeButton.fillColor = SKColor(white: 0.25, alpha: 1.0)
        closeButton.strokeColor = .clear
        closeButton.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton.zPosition = 55
        
        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.text = "✕"
        closeLabel.fontSize = 18
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = CGPoint(x: 0, y: 1)
        closeButton.addChild(closeLabel)
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = L10n.challenges
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        titleLabel.zPosition = 55
        
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitleLabel.text = L10n.challengeSubtitle
        subtitleLabel.fontSize = 13
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: 0, y: size.height/2 - 85)
        subtitleLabel.zPosition = 55
        
        super.init()
        
        addChild(background)
        background.addChild(closeButton)
        background.addChild(titleLabel)
        background.addChild(subtitleLabel)
        
        gridContainer.zPosition = 10
        gridContainer.position = CGPoint(x: 0, y: -20)
        background.addChild(gridContainer)
        
        setupGrid()

        self.isUserInteractionEnabled = true
        self.zPosition = 1000

        fitToScreen(panelHeight: size.height)
    }
    
    private func setupGrid() {
        let cols = 4
        let cellWidth: CGFloat = 60
        let cellHeight: CGFloat = 60
        let spacing: CGFloat = 15
        
        let totalWidth = CGFloat(cols) * cellWidth + CGFloat(cols - 1) * spacing
        let startX = -totalWidth / 2 + cellWidth / 2
        let startY: CGFloat = 120
        
        let highest = ChallengeManager.shared.highestUnlockedLevel
        let total = ChallengeManager.shared.totalLevels
        
        for i in 0..<total {
            let level = i + 1
            let row = i / cols
            let col = i % cols
            
            let x = startX + CGFloat(col) * (cellWidth + spacing)
            let y = startY - CGFloat(row) * (cellHeight + spacing)
            
            let cell = SKShapeNode(rectOf: CGSize(width: cellWidth, height: cellHeight), cornerRadius: 12)
            cell.position = CGPoint(x: x, y: y)
            cell.name = "level_\(level)"
            
            let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
            lbl.text = "\(level)"
            lbl.fontSize = 24
            lbl.verticalAlignmentMode = .center
            lbl.position = CGPoint(x: 0, y: 1)
            lbl.name = "levelLabel"
            cell.addChild(lbl)
            
            if level < highest {
                cell.fillColor = SKColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 1.0)
                cell.strokeColor = .clear
                lbl.fontColor = .white
                
                let check = SKLabelNode(fontNamed: "AvenirNext-Bold")
                check.text = "✓"
                check.fontSize = 14
                check.fontColor = .yellow
                check.position = CGPoint(x: 18, y: -20)
                cell.addChild(check)
                
            } else if level == highest {
                cell.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1.0)
                cell.strokeColor = .white
                cell.lineWidth = 2.0
                lbl.fontColor = .black
                
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.05, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                cell.run(SKAction.repeatForever(pulse))
                
            } else {
                cell.fillColor = SKColor(white: 0.2, alpha: 1.0)
                cell.strokeColor = SKColor(white: 0.3, alpha: 1.0)
                lbl.fontColor = SKColor(white: 0.4, alpha: 1.0)
                
                let lock = SKLabelNode(fontNamed: "AvenirNext-Bold")
                lock.text = "🔒"
                lock.fontSize = 12
                lock.position = CGPoint(x: 0, y: -18)
                cell.addChild(lock)
            }
            
            gridContainer.addChild(cell)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if closeButton.contains(location) {
            delegate?.challengeOverlayDidClose()
            return
        }
        
        let containerLoc = touch.location(in: gridContainer)
        let tappedNodes = gridContainer.nodes(at: containerLoc)
        
        for node in tappedNodes {
            if let name = node.name, name.hasPrefix("level_") {
                let levelStr = name.replacingOccurrences(of: "level_", with: "")
                if let level = Int(levelStr) {
                    let highest = ChallengeManager.shared.highestUnlockedLevel
                    if level <= highest {
                        delegate?.challengeOverlayDidSelect(level: level)
                    } else {
                        let shake = SKAction.sequence([
                            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
                        ])
                        node.run(shake)
                    }
                }
                break
            }
        }
    }
}
