import SpriteKit

class SettingsOverlayNode: SKNode {
    
    private let background: SKShapeNode
    private let closeButton: SKShapeNode
    private let hapticButton: SKShapeNode
    private let hapticLabel: SKLabelNode
    
    private let soundButton: SKShapeNode
    private let soundLabel: SKLabelNode
    
    private let privacyButton: SKShapeNode
    private let contactButton: SKShapeNode
    private let removeAdsButton: SKShapeNode
    
    var onClose: (() -> Void)?
    
    var hapticsEnabled: Bool {
        get { 
            if UserDefaults.standard.object(forKey: "HapticsEnabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "HapticsEnabled") 
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "HapticsEnabled")
            ICloudSyncManager.shared.pushValue(newValue, forKey: "HapticsEnabled")
            updateHapticUI()
        }
    }
    
    override init() {
        let size = CGSize(width: 320, height: 500)
        background = SKShapeNode(rectOf: size, cornerRadius: 24)
        background.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.98)
        background.strokeColor = SKColor(white: 0.25, alpha: 1.0)
        background.lineWidth = 2.0
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = L10n.settings
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        
        let separator = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 2), cornerRadius: 1)
        separator.fillColor = SKColor(white: 0.2, alpha: 1.0)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: size.height/2 - 80)
        
        closeButton = SKShapeNode(circleOfRadius: 18)
        closeButton.fillColor = SKColor(white: 0.2, alpha: 1.0)
        closeButton.strokeColor = .clear
        closeButton.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        
        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.text = "✕"
        closeLabel.fontSize = 18
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = CGPoint(x: 0, y: 1)
        closeButton.addChild(closeLabel)
        
        hapticButton = SKShapeNode(rectOf: CGSize(width: 240, height: 60), cornerRadius: 16)
        hapticButton.position = CGPoint(x: 0, y: 55)
        
        hapticLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hapticLabel.fontSize = 18
        hapticLabel.verticalAlignmentMode = .center
        hapticLabel.position = .zero
        hapticButton.addChild(hapticLabel)
        
        soundButton = SKShapeNode(rectOf: CGSize(width: 240, height: 60), cornerRadius: 16)
        soundButton.position = CGPoint(x: 0, y: -20)
        
        soundLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        soundLabel.fontSize = 18
        soundLabel.verticalAlignmentMode = .center
        soundLabel.position = .zero
        soundButton.addChild(soundLabel)
        
        removeAdsButton = SKShapeNode(rectOf: CGSize(width: 240, height: 45), cornerRadius: 12)
        let hasRemovedAds = UserDefaults.standard.bool(forKey: "HasRemovedAds")
        removeAdsButton.fillColor = hasRemovedAds ? SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.8) : SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.8)
        removeAdsButton.strokeColor = .white
        removeAdsButton.lineWidth = 1.5
        removeAdsButton.position = CGPoint(x: 0, y: -90)
        
        let removeAdsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        removeAdsLabel.text = hasRemovedAds ? L10n.adsRemoved : L10n.removeAds
        removeAdsLabel.name = "removeAdsLabel"
        removeAdsLabel.fontSize = 15
        removeAdsLabel.fontColor = .white
        removeAdsLabel.verticalAlignmentMode = .center
        removeAdsLabel.position = .zero
        removeAdsButton.addChild(removeAdsLabel)
        
        if !hasRemovedAds {
            StoreManager.shared.fetchRemoveAdsPrice { price in
                DispatchQueue.main.async {
                    if let priceText = price {
                        removeAdsLabel.text = "\(L10n.removeAds) (\(priceText))"
                    }
                }
            }
        }
        
        privacyButton = SKShapeNode(rectOf: CGSize(width: 240, height: 45), cornerRadius: 12)
        privacyButton.fillColor = SKColor(white: 0.12, alpha: 1.0)
        privacyButton.strokeColor = SKColor(white: 0.25, alpha: 1.0)
        privacyButton.lineWidth = 1.0
        privacyButton.position = CGPoint(x: 0, y: -145)
        
        let privacyLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        privacyLabel.text = L10n.privacyPolicy
        privacyLabel.fontSize = 15
        privacyLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        privacyLabel.verticalAlignmentMode = .center
        privacyLabel.position = .zero
        privacyButton.addChild(privacyLabel)
        
        contactButton = SKShapeNode(rectOf: CGSize(width: 240, height: 45), cornerRadius: 12)
        contactButton.fillColor = SKColor(white: 0.12, alpha: 1.0)
        contactButton.strokeColor = SKColor(white: 0.25, alpha: 1.0)
        contactButton.lineWidth = 1.0
        contactButton.position = CGPoint(x: 0, y: -195)
        
        let contactLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        contactLabel.text = L10n.contactUs
        contactLabel.fontSize = 15
        contactLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        contactLabel.verticalAlignmentMode = .center
        contactLabel.position = .zero
        contactButton.addChild(contactLabel)
        
        let restoreButton = SKShapeNode(rectOf: CGSize(width: 240, height: 35), cornerRadius: 10)
        restoreButton.fillColor = .clear
        restoreButton.strokeColor = .clear
        restoreButton.position = CGPoint(x: 0, y: -230)
        restoreButton.name = "restoreButton"
        
        let restoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        restoreLabel.text = L10n.restorePurchases
        restoreLabel.fontSize = 13
        restoreLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        restoreLabel.verticalAlignmentMode = .center
        restoreLabel.position = .zero
        restoreButton.addChild(restoreLabel)
        
        super.init()
        
        addChild(background)
        background.addChild(closeButton)
        background.addChild(titleLabel)
        background.addChild(separator)
        background.addChild(hapticButton)
        background.addChild(soundButton)
        background.addChild(removeAdsButton)
        background.addChild(privacyButton)
        background.addChild(contactButton)
        background.addChild(restoreButton)
        
        self.isUserInteractionEnabled = true
        self.zPosition = 1000

        updateHapticUI()

        fitToScreen(panelHeight: size.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateHapticUI() {
        if hapticsEnabled {
            hapticButton.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.15)
            hapticButton.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.8)
            hapticButton.lineWidth = 2.0
            hapticLabel.text = L10n.hapticsOn
            hapticLabel.fontColor = SKColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
        } else {
            hapticButton.fillColor = SKColor(white: 0.15, alpha: 1.0)
            hapticButton.strokeColor = SKColor(white: 0.3, alpha: 1.0)
            hapticButton.lineWidth = 2.0
            hapticLabel.text = L10n.hapticsOff
            hapticLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        }
        
        let soundOn = AudioManager.shared.isSoundEnabled
        if soundOn {
            soundButton.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.15)
            soundButton.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.8)
            soundButton.lineWidth = 2.0
            soundLabel.text = L10n.soundOn
            soundLabel.fontColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        } else {
            soundButton.fillColor = SKColor(white: 0.15, alpha: 1.0)
            soundButton.strokeColor = SKColor(white: 0.3, alpha: 1.0)
            soundButton.lineWidth = 2.0
            soundLabel.text = L10n.soundOff
            soundLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if closeButton.contains(location) {
            onClose?()
        } else if hapticButton.contains(location) {
            hapticsEnabled.toggle()
        } else if soundButton.contains(location) {
            AudioManager.shared.isSoundEnabled.toggle()
            updateHapticUI()
        } else if removeAdsButton.contains(location) {
            let hasRemovedAds = UserDefaults.standard.bool(forKey: "HasRemovedAds")
            if hasRemovedAds { return }
            
            let originalText = (removeAdsButton.childNode(withName: "removeAdsLabel") as? SKLabelNode)?.text
            (removeAdsButton.childNode(withName: "removeAdsLabel") as? SKLabelNode)?.text = "..."
            
            StoreManager.shared.purchaseRemoveAds { [weak self] success, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if success {
                        let currentCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
                        let newCoins = currentCoins + 2000
                        UserDefaults.standard.set(newCoins, forKey: "TotalCoins")
                        ICloudSyncManager.shared.pushValue(newCoins, forKey: "TotalCoins")
                        
                        if let label = self.removeAdsButton.childNode(withName: "removeAdsLabel") as? SKLabelNode {
                            label.text = L10n.vipBonusCoins
                        }
                        self.removeAdsButton.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.8)
                        self.removeAdsButton.run(SKAction.sequence([
                            SKAction.scale(to: 0.9, duration: 0.1),
                            SKAction.scale(to: 1.0, duration: 0.1)
                        ]))
                        
                        AdManager.shared.hideBanner()
                        
                        if let vc = self.scene?.view?.window?.rootViewController {
                            let alert = UIAlertController(
                                title: L10n.vipWelcomeTitle,
                                message: L10n.vipWelcomeMsg,
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: L10n.awesome, style: .default, handler: nil))
                            vc.present(alert, animated: true)
                        }
                        
                    } else {
                        (self.removeAdsButton.childNode(withName: "removeAdsLabel") as? SKLabelNode)?.text = originalText
                        print("Purchase failed: \(error ?? "Unknown")")
                    }
                }
            }
        } else if privacyButton.contains(location) {
            if let url = URL(string: "https://emrealkan.com.tr/chromity") {
                UIApplication.shared.open(url)
            }
        } else if contactButton.contains(location) {
            if let url = URL(string: "mailto:chromitygame@gmail.com?subject=Chromity%20Feedback") {
                UIApplication.shared.open(url)
            }
        } else if let restoreBtn = background.childNode(withName: "restoreButton"), restoreBtn.contains(location) {
            StoreManager.shared.restorePurchases { [weak self] success, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if success {
                        if let label = self.removeAdsButton.childNode(withName: "removeAdsLabel") as? SKLabelNode {
                            label.text = L10n.adsRemoved
                        }
                        self.removeAdsButton.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.8)
                    }
                }
            }
        }
    }
}
