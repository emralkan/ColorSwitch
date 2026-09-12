import SpriteKit

protocol ShopOverlayDelegate: AnyObject {
    func shopOverlayDidClose()
    func shopOverlayDidEquipSkin(_ skinName: String)
}

class ShopOverlayNode: SKNode {

    private func normalizeSkinID(_ id: String) -> String {
        switch id {
        case "boss_crown": return "royal"
        case "boss_flame": return "blaze"
        case "boss_chromatic": return "prism"
        default: return id
        }
    }
    
    weak var delegate: ShopOverlayDelegate?
    
    private let background: SKShapeNode
    private let closeButton: SKShapeNode
    private let coinsLabel: SKLabelNode
    
    private let rewardedAdButton: SKShapeNode
    

    private let headerCover: SKShapeNode
    private let footerCover: SKShapeNode
    
    private let itemsContainer = SKNode()
    private var initialTouch: CGPoint?
    private var initialContainerY: CGFloat = 0
    private var isDragging = false
    
    private var confirmationDialog: SKShapeNode?
    private var pendingSkinToBuy: SkinData?
    private var pendingSkinAction: ActionType = .none
    
    enum ActionType {
        case none
        case buy
        case equip
        case locked
    }
    
    struct SkinData {
        let id: String
        let name: String
        let price: Int
    }
    
    let skins: [SkinData] = [
        SkinData(id: "circle", name: "Circle", price: 0),
        SkinData(id: "square", name: "Square", price: 50),
        SkinData(id: "triangle", name: "Triangle", price: 100),
        SkinData(id: "star", name: "Star", price: 150),
        SkinData(id: "diamond", name: "Diamond", price: 200),
        SkinData(id: "hexagon", name: "Hexagon", price: 250),
        SkinData(id: "mini", name: "Mini", price: 300),
        SkinData(id: "crescent", name: "Crescent", price: 400),
        SkinData(id: "royal", name: "Royal", price: 800),
        SkinData(id: "ring", name: "Ring", price: 1000),
        SkinData(id: "blaze", name: "Blaze", price: 1500),
        SkinData(id: "prism", name: "Prism", price: 2500),
        SkinData(id: "ghost", name: "Ghost", price: 5000)
    ]
    
    private var itemNodes: [SKShapeNode] = []

    static let panelSize = CGSize(width: 340, height: 720)
    static let headerArea: CGFloat = 110.0
    static let footerArea: CGFloat = 100.0

    static let gridStartY: CGFloat = 120.0
    static let gridItemHeight: CGFloat = 95.0
    static let gridSpacingY: CGFloat = 12.0
    static let gridCols = 3

private var unlockedSkins: [String] {
    get {
        let saved = UserDefaults.standard.stringArray(forKey: "UnlockedSkins") ?? ["circle"]
        let normalized = Array(Set(saved.map(normalizeSkinID))).sorted()
        if normalized != saved {
            UserDefaults.standard.set(normalized, forKey: "UnlockedSkins")
            ICloudSyncManager.shared.pushValue(normalized, forKey: "UnlockedSkins")
        }
        return normalized.isEmpty ? ["circle"] : normalized
    }
    set {
        let normalized = Array(Set(newValue.map(normalizeSkinID))).sorted()
        UserDefaults.standard.set(normalized, forKey: "UnlockedSkins")
        ICloudSyncManager.shared.pushValue(normalized, forKey: "UnlockedSkins")
    }
}

private var equippedSkin: String {
    get {
        let saved = UserDefaults.standard.string(forKey: "EquippedSkin") ?? "circle"
        let normalized = normalizeSkinID(saved)
        if normalized != saved {
            UserDefaults.standard.set(normalized, forKey: "EquippedSkin")
            ICloudSyncManager.shared.pushValue(normalized, forKey: "EquippedSkin")
        }
        return normalized
    }
    set {
        let normalized = normalizeSkinID(newValue)
        UserDefaults.standard.set(normalized, forKey: "EquippedSkin")
        ICloudSyncManager.shared.pushValue(normalized, forKey: "EquippedSkin")
    }
}
    
private var totalCoins: Int {

        get { UserDefaults.standard.integer(forKey: "TotalCoins") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "TotalCoins")
            ICloudSyncManager.shared.pushValue(newValue, forKey: "TotalCoins")
            coinsLabel.text = "⭐ \(newValue)"
            updateUI()
        }
    }
    
    override init() {
        let size = ShopOverlayNode.panelSize
        background = SKShapeNode(rectOf: size, cornerRadius: 28)
        background.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.98)
        background.strokeColor = SKColor(white: 0.25, alpha: 1.0)
        background.lineWidth = 2.0
        
        headerCover = SKShapeNode(path: CGPath(roundedRect: CGRect(x: -size.width/2, y: size.height/2 - 180, width: size.width, height: 180), cornerWidth: 28, cornerHeight: 28, transform: nil))
        headerCover.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.98)
        headerCover.strokeColor = .clear
        headerCover.zPosition = 50
        
        let headerFlat = SKShapeNode(rectOf: CGSize(width: size.width, height: 20))
        headerFlat.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.98)
        headerFlat.strokeColor = .clear
        headerFlat.position = CGPoint(x: 0, y: size.height/2 - 170)
        headerFlat.zPosition = 50
        
        footerCover = SKShapeNode(path: CGPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: 100), cornerWidth: 28, cornerHeight: 28, transform: nil))
        footerCover.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.98)
        footerCover.strokeColor = .clear
        footerCover.zPosition = 50
        
        closeButton = SKShapeNode(circleOfRadius: 18)
        closeButton.fillColor = SKColor(white: 0.2, alpha: 1.0)
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
        titleLabel.text = L10n.store
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        titleLabel.zPosition = 55
        
        coinsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinsLabel.fontSize = 24
        coinsLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        coinsLabel.position = CGPoint(x: 0, y: size.height/2 - 95)
        coinsLabel.zPosition = 55
        
        let separator = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 2), cornerRadius: 1)
        separator.fillColor = SKColor(white: 0.2, alpha: 1.0)
        separator.strokeColor = .clear
        separator.position = CGPoint(x: 0, y: size.height/2 - 110)
        separator.zPosition = 55
        
        rewardedAdButton = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 18)
        rewardedAdButton.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.2)
        rewardedAdButton.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
        rewardedAdButton.lineWidth = 2.0
        rewardedAdButton.position = CGPoint(x: 0, y: -size.height/2 + 60)
        rewardedAdButton.zPosition = 60
        
        let rewardLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        rewardLabel.text = L10n.freeStars
        rewardLabel.fontSize = 18
        rewardLabel.fontColor = .cyan
        rewardLabel.verticalAlignmentMode = .center
        rewardLabel.position = .zero
        rewardedAdButton.addChild(rewardLabel)
        
        super.init()
        
        coinsLabel.text = "⭐ \(totalCoins)"
        
        addChild(background)
        background.addChild(headerCover)
        background.addChild(headerFlat)
        background.addChild(footerCover)
        
        background.addChild(closeButton)
        background.addChild(titleLabel)
        background.addChild(coinsLabel)
        background.addChild(separator)
        
        itemsContainer.zPosition = 10
        background.addChild(itemsContainer)
        
        background.addChild(rewardedAdButton)
        
        let rewardBgCover = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: 100))
        rewardBgCover.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 1.0)
        rewardBgCover.strokeColor = .clear
        rewardBgCover.position = CGPoint(x: 0, y: -size.height/2 + 50)
        rewardBgCover.zPosition = 50
        background.addChild(rewardBgCover)

        setupGrid()

        self.isUserInteractionEnabled = true
        self.zPosition = 1000

        fitToScreen(panelHeight: size.height)
    }
    
    private func setupGrid() {
        itemsContainer.removeAllChildren()
        itemNodes.removeAll()
        itemsContainer.position = .zero
        
        let filteredSkins = skins
        
        let cols = ShopOverlayNode.gridCols
        let itemWidth: CGFloat = 90
        let itemHeight: CGFloat = ShopOverlayNode.gridItemHeight
        let spacingX: CGFloat = 15
        let spacingY: CGFloat = ShopOverlayNode.gridSpacingY

        let startX = -(itemWidth + spacingX)
        let startY: CGFloat = ShopOverlayNode.gridStartY
        
        for (index, skin) in filteredSkins.enumerated() {
            let row = index / cols
            let col = index % cols
            
            let xPos = startX + CGFloat(col) * (itemWidth + spacingX)
            let yPos = startY - CGFloat(row) * (itemHeight + spacingY)
            
            let itemBg = SKShapeNode(rectOf: CGSize(width: itemWidth, height: itemHeight), cornerRadius: 16)
            itemBg.position = CGPoint(x: xPos, y: yPos)
            itemBg.name = skin.id
            itemBg.lineWidth = 2.0
            
            let icon = SkinPathFactory.createIcon(for: skin.id, radius: 18)
            icon.position = CGPoint(x: 0, y: 15)
            itemBg.addChild(icon)
            
            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            nameLabel.text = skin.name
            nameLabel.fontSize = 14
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: 0, y: -20)
            itemBg.addChild(nameLabel)
            
            let statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            statusLabel.fontSize = 12
            statusLabel.position = CGPoint(x: 0, y: -40)
            statusLabel.name = "statusLabel"
            itemBg.addChild(statusLabel)
            
            itemsContainer.addChild(itemBg)
            itemNodes.append(itemBg)
        }
        
        updateUI()
        clipItemsIfNeeded()
    }
    

    
    
    private func updateUI() {
        let filteredSkins = skins
        
        for (index, itemBg) in itemNodes.enumerated() {
            guard index < filteredSkins.count else { break }
            let skin = filteredSkins[index]
            guard let statusLabel = itemBg.childNode(withName: "statusLabel") as? SKLabelNode,
                  let nameLabel = itemBg.children.first(where: { $0 is SKLabelNode && $0.name != "statusLabel" && $0.name != "descLabel" && $0.name != "tabLabel" }) as? SKLabelNode else { continue }
            
            let isEquipped = equippedSkin == skin.id
            
            if isEquipped {
                itemBg.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.2)
                itemBg.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
                statusLabel.text = L10n.equipped
                statusLabel.fontColor = SKColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
                nameLabel.fontColor = .white
            } else if unlockedSkins.contains(skin.id) {
                itemBg.fillColor = SKColor(white: 0.15, alpha: 1.0)
                itemBg.strokeColor = SKColor(white: 0.4, alpha: 1.0)
                statusLabel.text = L10n.owned
                statusLabel.fontColor = .white
                nameLabel.fontColor = .white
            } else {
                itemBg.fillColor = SKColor(white: 0.12, alpha: 1.0)
                itemBg.strokeColor = SKColor(white: 0.2, alpha: 1.0)
                statusLabel.text = "⭐ \(skin.price)"
                statusLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
                nameLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if confirmationDialog != nil { return }
        
        initialTouch = location
        initialContainerY = itemsContainer.position.y
        isDragging = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = initialTouch, confirmationDialog == nil else { return }
        let location = touch.location(in: background)
        let dy = location.y - start.y
        
        if abs(dy) > 10 {
            isDragging = true
        }
        
        if isDragging {
            var newY = initialContainerY + dy

            let maxScroll = maxScrollOffset()
            if newY < 0 { newY = 0 }
            if newY > maxScroll { newY = maxScroll }

            itemsContainer.position.y = newY
            clipItemsIfNeeded()
        }
    }
    
    private func maxScrollOffset() -> CGFloat {
        let rows = Int(ceil(Double(skins.count) / Double(ShopOverlayNode.gridCols)))
        guard rows > 0 else { return 0 }
        let rowHeight = ShopOverlayNode.gridItemHeight + ShopOverlayNode.gridSpacingY
        let lastRowCenterY = ShopOverlayNode.gridStartY - CGFloat(rows - 1) * rowHeight
        let contentBottom = lastRowCenterY - ShopOverlayNode.gridItemHeight / 2
        let bottomCutoff = -ShopOverlayNode.panelSize.height / 2 + ShopOverlayNode.footerArea
        let maxScroll = bottomCutoff - contentBottom
        return max(0, maxScroll)
    }

    private func clipItemsIfNeeded() {
        let containerY = itemsContainer.position.y
        let topCutoff = ShopOverlayNode.panelSize.height / 2 - ShopOverlayNode.headerArea
        let bottomCutoff = -ShopOverlayNode.panelSize.height / 2 + ShopOverlayNode.footerArea

        for item in itemNodes {
            let absoluteY = item.position.y + containerY
            if absoluteY > topCutoff || absoluteY < bottomCutoff {
                item.isHidden = true
            } else {
                item.isHidden = false
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: background)
        
        if let dialog = confirmationDialog {
            let dialogLoc = touch.location(in: dialog)
            let actionBtn = dialog.childNode(withName: "actionBtn") as? SKShapeNode
            let closeBtn = dialog.childNode(withName: "closeBtn") as? SKShapeNode
            
            if actionBtn?.contains(dialogLoc) == true {
                processPopupAction()
            } else if closeBtn?.contains(dialogLoc) == true {
                closeConfirmation()
            }
            return
        }
        
        if !isDragging {
            if closeButton.contains(location) {
                delegate?.shopOverlayDidClose()
                return
            }
            
            if rewardedAdButton.contains(location) {
                if let vc = self.scene?.view?.window?.rootViewController {
                    rewardedAdButton.run(SKAction.sequence([
                        SKAction.scale(to: 0.9, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ]))
                    
                    AdManager.shared.showRewardedAd(from: vc) { [weak self] reward in
                        guard let self = self else { return }
                        if reward > 0 {
                            self.totalCoins += reward
                            HapticHelper.notification(.success)
                        } else {
                            self.showToast(L10n.adNotAvailable)
                            HapticHelper.notification(.warning)
                        }
                    }
                }
                return
            }
            
            let containerLoc = touch.location(in: itemsContainer)
            let filteredSkins = skins
            for (index, itemBg) in itemNodes.enumerated() {
                if !itemBg.isHidden && itemBg.contains(containerLoc) {
                    guard index < filteredSkins.count else { break }
                    let skin = filteredSkins[index]
                    
                    let isEquipped = equippedSkin == skin.id
                    
                    if isEquipped {
                    } else if unlockedSkins.contains(skin.id) {
                        equipSkinInstantly(skin: skin)
                        itemBg.run(SKAction.sequence([
                            SKAction.scale(to: 0.90, duration: 0.05),
                            SKAction.scale(to: 1.0, duration: 0.05)
                        ]))
                    } else {
                        showConfirmationWindow(for: skin)
                    }
                    break
                }
            }
        }
        
        isDragging = false
        initialTouch = nil
    }
    
    private func equipSkinInstantly(skin: SkinData) {
        equippedSkin = skin.id
        updateUI()
        delegate?.shopOverlayDidEquipSkin(skin.id)
        
        HapticHelper.impact(.medium)
    }
    
    private func showConfirmationWindow(for skin: SkinData) {
        pendingSkinToBuy = skin
        pendingSkinAction = .buy
        
        let dialog = SKShapeNode(rectOf: CGSize(width: 280, height: 280), cornerRadius: 24)
        dialog.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.98)
        dialog.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)
        dialog.lineWidth = 2.0
        dialog.position = .zero
        dialog.zPosition = 200
        
        let icon = SkinPathFactory.createIcon(for: skin.id, radius: 35)
        icon.position = CGPoint(x: 0, y: 45)
        dialog.addChild(icon)
        
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = skin.name.uppercased()
        title.fontSize = 24
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: -20)
        dialog.addChild(title)
        
        let desc = SKLabelNode(fontNamed: "AvenirNext-Bold")
        desc.fontSize = 20
        desc.position = CGPoint(x: 0, y: -55)
        desc.text = "⭐ \(skin.price)"
        desc.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        dialog.addChild(desc)
        
        let canAfford = totalCoins >= skin.price
        
        let actionBtn = SKShapeNode(rectOf: CGSize(width: 130, height: 45), cornerRadius: 12)
        actionBtn.position = CGPoint(x: 65, y: -100)
        actionBtn.name = "actionBtn"
        actionBtn.fillColor = canAfford ? SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0) : SKColor(white: 0.3, alpha: 1.0)
        actionBtn.strokeColor = .white
        dialog.addChild(actionBtn)
        
        let actionLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        actionLbl.text = canAfford ? L10n.buy : L10n.needCoins
        actionLbl.fontSize = 14
        actionLbl.fontColor = canAfford ? .white : SKColor(white: 0.6, alpha: 1.0)
        actionLbl.verticalAlignmentMode = .center
        actionLbl.position = .zero
        actionBtn.addChild(actionLbl)
        
        let closeBtn = SKShapeNode(rectOf: CGSize(width: 110, height: 45), cornerRadius: 12)
        closeBtn.fillColor = SKColor(white: 0.25, alpha: 1.0)
        closeBtn.strokeColor = .clear
        closeBtn.position = CGPoint(x: -65, y: -100)
        closeBtn.name = "closeBtn"
        let closeLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLbl.text = L10n.close
        closeLbl.fontSize = 16
        closeLbl.fontColor = .white
        closeLbl.verticalAlignmentMode = .center
        closeLbl.position = .zero
        closeBtn.addChild(closeLbl)
        dialog.addChild(closeBtn)
        
        dialog.setScale(0.1)
        dialog.run(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        background.addChild(dialog)
        confirmationDialog = dialog
        
        itemsContainer.run(SKAction.fadeAlpha(to: 0.2, duration: 0.2))
        
        HapticHelper.impact(.light)
    }
    
    private func closeConfirmation() {
        if let dialog = confirmationDialog {
            dialog.run(SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.15),
                SKAction.removeFromParent()
            ]))
        }
        confirmationDialog = nil
        pendingSkinToBuy = nil
        pendingSkinAction = .none
        itemsContainer.run(SKAction.fadeAlpha(to: 1.0, duration: 0.2))
    }
    
    private func processPopupAction() {
        guard let skin = pendingSkinToBuy else { return }
        
        if totalCoins >= skin.price {
            totalCoins -= skin.price
            
            var unlocked = self.unlockedSkins
            unlocked.append(skin.id)
            self.unlockedSkins = unlocked
            
            self.equippedSkin = skin.id
            self.updateUI()
            self.delegate?.shopOverlayDidEquipSkin(skin.id)
            
            HapticHelper.notification(.success)
            self.closeConfirmation()
            
            if let parentNode = self.itemsContainer.parent {
                let emitter = SKEmitterNode()
                emitter.particleTexture = nil
                emitter.particleBirthRate = 50
                emitter.numParticlesToEmit = 30
                emitter.particleLifetime = 1.0
                emitter.particlePositionRange = CGVector(dx: 150, dy: 150)
                emitter.particleSpeed = 200
                emitter.particleSpeedRange = 50
                emitter.particleAlpha = 1.0
                emitter.particleAlphaSpeed = -1.0
                emitter.particleScale = 0.2
                emitter.particleScaleRange = 0.1
                emitter.particleColor = .yellow
                emitter.particleColorBlendFactor = 1.0
                emitter.position = CGPoint(x: 0, y: 0)
                emitter.zPosition = 300
                parentNode.addChild(emitter)
                
                emitter.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.removeFromParent()
                ]))
            }
            
        } else {
            showToast(L10n.notEnoughStars)
            HapticHelper.notification(.error)
        }
    }
    
    private func showToast(_ message: String) {
        let toast = SKShapeNode(rectOf: CGSize(width: 260, height: 60), cornerRadius: 14)
        toast.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.9)
        toast.strokeColor = .clear
        toast.position = CGPoint(x: 0, y: 200)
        toast.zPosition = 300
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = message
        label.fontSize = 13
        label.fontColor = .white
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 240
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        toast.addChild(label)
        
        toast.alpha = 0
        toast.setScale(0.8)
        background.addChild(toast)
        
        toast.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.2)
            ]),
            SKAction.wait(forDuration: 2.5),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.8, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}

extension SKNode {
    func fitToScreen(panelHeight: CGFloat, margin: CGFloat = 100) {
        let screenHeight = UIScreen.main.bounds.size.height
        let available = screenHeight - margin
        guard panelHeight > available, available > 0 else { return }
        let ratio = available / panelHeight
        setScale(min(ratio, 1.0))
    }
}
