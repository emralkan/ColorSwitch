import SpriteKit

protocol PauseOverlayDelegate: AnyObject {
    func pauseOverlayDidTapResume()
    func pauseOverlayDidTapQuit()
}

class PauseOverlayNode: SKNode {
    
    weak var delegate: PauseOverlayDelegate?
    
    private let background: SKShapeNode
    private let resumeButton: SKShapeNode
    private let quitButton: SKShapeNode
    private var confirmationDialog: SKShapeNode?
    
    override init() {
        let size = CGSize(width: 260, height: 320)
        background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.95)
        background.strokeColor = .white
        background.lineWidth = 2.0
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = L10n.paused
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        background.addChild(titleLabel)
        
        resumeButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        resumeButton.fillColor = .systemBlue
        resumeButton.strokeColor = .white
        resumeButton.position = CGPoint(x: 0, y: 20)
        
        let resumeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resumeLabel.text = L10n.resume
        resumeLabel.fontSize = 20
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeButton.addChild(resumeLabel)
        background.addChild(resumeButton)
        
        quitButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        quitButton.fillColor = .systemRed
        quitButton.strokeColor = .white
        quitButton.position = CGPoint(x: 0, y: -50)
        
        let quitLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        quitLabel.text = L10n.quit
        quitLabel.fontSize = 20
        quitLabel.fontColor = .white
        quitLabel.verticalAlignmentMode = .center
        quitButton.addChild(quitLabel)
        background.addChild(quitButton)
        
        super.init()
        
        addChild(background)
        
        self.isUserInteractionEnabled = true
        self.zPosition = 2000
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if let dialog = confirmationDialog {
            let dialogLoc = touch.location(in: dialog)
            let yesBtn = dialog.childNode(withName: "confirmQuitBtn") as? SKShapeNode
            let noBtn = dialog.childNode(withName: "cancelQuitBtn") as? SKShapeNode
            
            if yesBtn?.contains(dialogLoc) == true {
                delegate?.pauseOverlayDidTapQuit()
            } else if noBtn?.contains(dialogLoc) == true {
                hideQuitConfirmation()
            }
            return
        }
        
        if resumeButton.contains(location) {
            delegate?.pauseOverlayDidTapResume()
        } else if quitButton.contains(location) {
            showQuitConfirmation()
        }
    }
    
    private func showQuitConfirmation() {
        let dialog = SKShapeNode(rectOf: CGSize(width: 220, height: 140), cornerRadius: 15)
        dialog.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.98)
        dialog.strokeColor = SKColor(white: 0.4, alpha: 1.0)
        dialog.lineWidth = 2.0
        dialog.position = .zero
        dialog.zPosition = 100
        
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = L10n.areYouSure
        title.fontSize = 20
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 20)
        dialog.addChild(title)
        
        let yesBtn = SKShapeNode(rectOf: CGSize(width: 90, height: 40), cornerRadius: 10)
        yesBtn.fillColor = SKColor.systemRed
        yesBtn.strokeColor = .clear
        yesBtn.position = CGPoint(x: -50, y: -30)
        yesBtn.name = "confirmQuitBtn"
        let yesLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        yesLbl.text = L10n.yes
        yesLbl.fontSize = 16
        yesLbl.fontColor = .white
        yesLbl.verticalAlignmentMode = .center
        yesLbl.position = .zero
        yesBtn.addChild(yesLbl)
        dialog.addChild(yesBtn)
        
        let noBtn = SKShapeNode(rectOf: CGSize(width: 90, height: 40), cornerRadius: 10)
        noBtn.fillColor = SKColor.darkGray
        noBtn.strokeColor = .clear
        noBtn.position = CGPoint(x: 50, y: -30)
        noBtn.name = "cancelQuitBtn"
        let noLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        noLbl.text = L10n.no
        noLbl.fontSize = 16
        noLbl.fontColor = .white
        noLbl.verticalAlignmentMode = .center
        noLbl.position = .zero
        noBtn.addChild(noLbl)
        dialog.addChild(noBtn)
        
        background.addChild(dialog)
        confirmationDialog = dialog
        
        resumeButton.alpha = 0.3
        quitButton.alpha = 0.3
    }

    private func hideQuitConfirmation() {
        confirmationDialog?.removeFromParent()
        confirmationDialog = nil
        resumeButton.alpha = 1.0
        quitButton.alpha = 1.0
    }
}
