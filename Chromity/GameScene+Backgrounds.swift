import SpriteKit
import UIKit
import PhotosUI

// MARK: - Arka Planlar

extension GameScene {
    
    func createBackgroundStars() {
        let container = SKNode()
        container.name = "backgroundStarsContainer"
        container.zPosition = -10
        cameraNode.addChild(container)

        for _ in 0..<30 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.alpha = CGFloat.random(in: 0.1...0.5)
            let randomX = CGFloat.random(in: -size.width...size.width)
            let randomY = CGFloat.random(in: -size.height...size.height*2)
            star.position = CGPoint(x: randomX, y: randomY)
            star.zPosition = -10
            container.addChild(star)
            backgroundStars.append(star)

            let wait = SKAction.wait(forDuration: Double.random(in: 0.5...2.0))
            let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 1.0)
            let fadeIn = SKAction.fadeAlpha(to: star.alpha, duration: 1.0)
            star.run(SKAction.repeatForever(SKAction.sequence([wait, fadeOut, fadeIn])))
        }
    }
    
    func updateBackgroundStars(dy: CGFloat) {
        for star in backgroundStars {
            star.position.y -= (0.5 + dy * 0.1)
            
            if star.position.y < -size.height {
                star.position.y = size.height
                star.position.x = CGFloat.random(in: -size.width/2...size.width/2)
            } else if star.position.y > size.height {
                star.position.y = -size.height
                star.position.x = CGFloat.random(in: -size.width/2...size.width/2)
            }
        }
    }
    
    
    func triggerBackgroundPulse(color: SKColor) {
        let pulseNode = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        pulseNode.fillColor = color
        pulseNode.strokeColor = .clear
        pulseNode.alpha = 0.0
        pulseNode.zPosition = -19
        cameraNode.addChild(pulseNode)
        
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.05),
            SKAction.fadeAlpha(to: 0.0, duration: 0.4),
            SKAction.removeFromParent()
        ])
        pulseNode.run(pulseAction)
    }

    func setupNewBackgrounds() {
        let theme = BackgroundTheme.current
        let selectedBg = UserDefaults.standard.string(forKey: "SelectedBackground") ?? "earth_space"
        
        let groundSilhouette = SKShapeNode()
        let path = CGMutablePath()
        let width = size.width
        path.move(to: CGPoint(x: -width/2, y: -200))
        path.addLine(to: CGPoint(x: -width/2 + 50, y: -120))
        path.addLine(to: CGPoint(x: -width/2 + 120, y: -160))
        path.addLine(to: CGPoint(x: -width/2 + 200, y: -80))
        path.addLine(to: CGPoint(x: -width/2 + 280, y: -150))
        path.addLine(to: CGPoint(x: width/2 - 120, y: -100))
        path.addLine(to: CGPoint(x: width/2 - 40, y: -170))
        path.addLine(to: CGPoint(x: width/2, y: -130))
        path.addLine(to: CGPoint(x: width/2, y: -200))
        path.closeSubpath()
        
        groundSilhouette.path = path
        groundSilhouette.fillColor = SKColor(white: 0.05, alpha: 0.6)
        groundSilhouette.strokeColor = .clear
        groundLevelNode.addChild(groundSilhouette)
        
        let horizonGlow = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 500))
        horizonGlow.fillColor = .white
        horizonGlow.alpha = 0.15
        horizonGlow.glowWidth = 28
        horizonGlow.strokeColor = .clear
        horizonGlow.position = CGPoint(x: 0, y: -250)
        groundLevelNode.addChild(horizonGlow)
        
        groundLevelNode.position = CGPoint(x: frame.midX, y: 150)
        groundLevelNode.zPosition = -15
        groundLevelNode.isHidden = !theme.showGround
        addChild(groundLevelNode)
        
        addChild(cloudLayer)
        cloudLayer.zPosition = -12
        cloudLayer.isHidden = !theme.showClouds
        for _ in 0..<18 {
            let cloud = createCloud()
            let rx = CGFloat.random(in: -size.width...size.width)
            let ry = CGFloat.random(in: 400...6000)
            cloud.position = CGPoint(x: rx, y: ry)
            cloudLayer.addChild(cloud)
        }
        
        if selectedBg == "custom_photo" && GameViewController.hasCustomBackground {
            applyCustomPhotoBackground()
        }
    }
    
    func createCloud() -> SKNode {
        let cloud = SKShapeNode()
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -50, y: -25, width: 100, height: 50))
        path.addEllipse(in: CGRect(x: -20, y: 0, width: 80, height: 65))
        path.addEllipse(in: CGRect(x: -75, y: -15, width: 90, height: 55))
        cloud.path = path
        cloud.fillColor = .white
        cloud.strokeColor = .clear
        cloud.alpha = CGFloat.random(in: 0.2...0.5)
        cloud.setScale(CGFloat.random(in: 0.6...1.8))
        
        let driftDist = CGFloat.random(in: 50...150)
        let duration = Double.random(in: 10...20)
        let moveRight = SKAction.moveBy(x: driftDist, y: 0, duration: duration)
        let moveLeft = SKAction.moveBy(x: -driftDist, y: 0, duration: duration)
        cloud.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
        
        return cloud
    }
    
    func updateBackgroundTransition() {
        let selectedBg = UserDefaults.standard.string(forKey: "SelectedBackground") ?? "earth_space"
        if selectedBg == "custom_photo" {
            if let photoBg = childNode(withName: "customPhotoBg") {
                photoBg.position = cameraNode.position
            }
            return
        }
        
        let theme = BackgroundTheme.current
        let camY = cameraNode.position.y - (size.height / 2)
        
        let atmosThreshold: CGFloat = 3500
        let spaceThreshold: CGFloat = 9000
        let deepSpaceThreshold: CGFloat = 18000
        
        var targetColor: SKColor
        
        if camY < atmosThreshold {
            let t = max(0, min(1, camY / atmosThreshold))
            targetColor = SKColor.interpolate(from: theme.baseColor, to: theme.midColor, t: t)
        } else if camY < spaceThreshold {
            let t = max(0, min(1, (camY - atmosThreshold) / (spaceThreshold - atmosThreshold)))
            targetColor = SKColor.interpolate(from: theme.midColor, to: theme.highColor, t: t)
        } else {
            let t = max(0, min(1, (camY - spaceThreshold) / (deepSpaceThreshold - spaceThreshold)))
            targetColor = SKColor.interpolate(from: theme.highColor, to: theme.topColor, t: t)
        }
        
        backgroundColor = targetColor
        
        let heightStars = max(0, min(0.7, (camY - 2500) / 4000))
        let starsAlpha = max(theme.starBrightness, heightStars)
        cameraNode.childNode(withName: "backgroundStarsContainer")?.alpha = starsAlpha
        
        if theme.showGround {
            let groundFade = max(0, min(1, 1 - (camY / 2500)))
            groundLevelNode.alpha = groundFade
            groundLevelNode.position.y = 150 + (camY * 0.5)
        }
        if theme.showClouds {
            let cloudsFade = max(0, min(1, 1 - (camY - 4000) / 6000))
            cloudLayer.alpha = cloudsFade
            cloudLayer.position.y = camY * 0.3
        }
    }
    
    
    func openBackgroundPicker() {
        guard backgroundPickerOverlay == nil else { return }
        
        let overlay = SKNode()
        overlay.zPosition = 500
        
        let dimBg = SKShapeNode(rectOf: CGSize(width: size.width + 100, height: size.height + 100))
        dimBg.fillColor = SKColor.black.withAlphaComponent(0.7)
        dimBg.strokeColor = .clear
        dimBg.name = "BgPickerDim"
        overlay.addChild(dimBg)
        
        let panelW: CGFloat = 310
        let panelH: CGFloat = 540
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 28)
        panel.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.97)
        panel.strokeColor = SKColor(white: 0.2, alpha: 1.0)
        panel.lineWidth = 2.0
        panel.name = "BgPickerPanel"
        overlay.addChild(panel)
        
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = L10n.backgrounds
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: -10, y: panelH/2 - 40)
        panel.addChild(title)
        
        let sep = SKShapeNode(rectOf: CGSize(width: panelW - 50, height: 1.5), cornerRadius: 1)
        sep.fillColor = SKColor(white: 0.2, alpha: 1.0)
        sep.strokeColor = .clear
        sep.position = CGPoint(x: 0, y: panelH/2 - 58)
        panel.addChild(sep)
        
        let closeBtn = SKShapeNode(circleOfRadius: 16)
        closeBtn.fillColor = SKColor(white: 0.15, alpha: 1.0)
        closeBtn.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        closeBtn.lineWidth = 1.5
        closeBtn.position = CGPoint(x: panelW/2 - 25, y: panelH/2 - 25)
        closeBtn.name = "BgPickerClose"
        let closeLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLbl.text = "✕"
        closeLbl.fontSize = 14
        closeLbl.fontColor = .white
        closeLbl.verticalAlignmentMode = .center
        closeBtn.addChild(closeLbl)
        panel.addChild(closeBtn)
        
        let themes = BackgroundTheme.all
        let currentID = UserDefaults.standard.string(forKey: "SelectedBackground") ?? "earth_space"
        let cellW: CGFloat = 125
        let cellH: CGFloat = 100
        let spacing: CGFloat = 16
        let startX: CGFloat = -(cellW + spacing) / 2
        let startY: CGFloat = panelH/2 - 100
        
        for (index, theme) in themes.enumerated() {
            let col = index % 2
            let row = index / 2
            let x = startX + CGFloat(col) * (cellW + spacing)
            let y = startY - CGFloat(row) * (cellH + spacing)
            
            let cell = SKShapeNode(rectOf: CGSize(width: cellW, height: cellH), cornerRadius: 16)
            cell.name = "BgTheme_\(theme.id)"
            
            let stripeH = (cellH - 8) / 4
            let stripeW = cellW - 8
            let colors = [theme.baseColor, theme.midColor, theme.highColor, theme.topColor]
            for (i, color) in colors.enumerated() {
                let stripe = SKShapeNode(rectOf: CGSize(width: stripeW, height: stripeH))
                stripe.fillColor = color
                stripe.strokeColor = .clear
                let stripeY = (cellH/2 - 4) - stripeH/2 - (stripeH * CGFloat(i))
                stripe.position = CGPoint(x: 0, y: stripeY)
                stripe.zPosition = -1
                cell.addChild(stripe)
            }
            
            let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
            icon.text = theme.icon
            icon.fontSize = 30
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: 0, y: 10)
            icon.zPosition = 2
            cell.addChild(icon)
            
            let nameBg = SKShapeNode(rectOf: CGSize(width: stripeW, height: 22), cornerRadius: 4)
            nameBg.fillColor = SKColor.black.withAlphaComponent(0.5)
            nameBg.strokeColor = .clear
            nameBg.position = CGPoint(x: 0, y: -cellH/2 + 18)
            nameBg.zPosition = 1
            cell.addChild(nameBg)
            
            let nameLbl = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            nameLbl.text = theme.name
            nameLbl.fontSize = 11
            nameLbl.fontColor = .white
            nameLbl.verticalAlignmentMode = .center
            nameLbl.position = CGPoint(x: 0, y: -cellH/2 + 18)
            nameLbl.zPosition = 2
            cell.addChild(nameLbl)
            
            if theme.id == currentID {
                cell.fillColor = .clear
                cell.strokeColor = SKColor.systemGreen
                cell.lineWidth = 3.0
                cell.glowWidth = 3.0
                
                let check = SKLabelNode(fontNamed: "AvenirNext-Heavy")
                check.text = "✓"
                check.fontSize = 14
                check.fontColor = .systemGreen
                check.position = CGPoint(x: cellW/2 - 16, y: cellH/2 - 16)
                check.zPosition = 3
                cell.addChild(check)
            } else {
                cell.fillColor = .clear
                cell.strokeColor = SKColor(white: 0.25, alpha: 1.0)
                cell.lineWidth = 1.5
            }
            
            cell.position = CGPoint(x: x, y: y)
            panel.addChild(cell)
        }
        
        let customY = startY - CGFloat((themes.count + 1) / 2) * (cellH + spacing)
        let customCell = SKShapeNode(rectOf: CGSize(width: cellW * 2 + spacing, height: 55), cornerRadius: 16)
        customCell.name = "BgTheme_custom_photo"
        
        let isCustomActive = currentID == "custom_photo"
        
        if isCustomActive {
            customCell.fillColor = SKColor(red: 0.15, green: 0.3, blue: 0.15, alpha: 1.0)
            customCell.strokeColor = .systemGreen
            customCell.lineWidth = 2.5
            customCell.glowWidth = 2.0
        } else {
            customCell.fillColor = SKColor(white: 0.12, alpha: 1.0)
            customCell.strokeColor = SKColor(white: 0.25, alpha: 1.0)
            customCell.lineWidth = 1.5
        }
        
        let customIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        customIcon.text = "📷"
        customIcon.fontSize = 22
        customIcon.verticalAlignmentMode = .center
        customIcon.position = CGPoint(x: -60, y: 0)
        customCell.addChild(customIcon)
        
        let customLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        customLabel.text = isCustomActive ? "\(L10n.customPhoto)  ✓" : L10n.customPhoto
        customLabel.fontSize = 14
        customLabel.fontColor = .white
        customLabel.verticalAlignmentMode = .center
        customLabel.position = CGPoint(x: 10, y: 0)
        customCell.addChild(customLabel)
        
        let adBadge = SKLabelNode(fontNamed: "AvenirNext-Medium")
        adBadge.text = "🎬 AD"
        adBadge.fontSize = 10
        adBadge.fontColor = .cyan
        adBadge.verticalAlignmentMode = .center
        adBadge.position = CGPoint(x: 85, y: 0)
        customCell.addChild(adBadge)
        
        customCell.position = CGPoint(x: 0, y: customY)
        panel.addChild(customCell)
        
        panel.setScale(0.6)
        panel.alpha = 0
        panel.run(SKAction.fadeIn(withDuration: 0.2))
        panel.run(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
        
        cameraNode.addChild(overlay)
        backgroundPickerOverlay = overlay
    }
    
    func closeBackgroundPicker() {
        backgroundPickerOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in self?.backgroundPickerOverlay = nil }
        ]))
    }
    
    func applyTheme(_ themeID: String) {
        UserDefaults.standard.set(themeID, forKey: "SelectedBackground")
        ICloudSyncManager.shared.pushValue(themeID, forKey: "SelectedBackground")
        
        childNode(withName: "customPhotoBg")?.removeFromParent()
        
        let theme = BackgroundTheme.current
        
        backgroundColor = theme.baseColor
        groundLevelNode.isHidden = !theme.showGround
        cloudLayer.isHidden = !theme.showClouds
        cameraNode.childNode(withName: "backgroundStarsContainer")?.alpha = theme.starBrightness
        
        HapticHelper.impact(.medium)

        backgroundPickerOverlay?.removeFromParent()
        backgroundPickerOverlay = nil
        openBackgroundPicker()
    }
    
    
    func handleCustomPhotoTap() {
        guard let vc = self.scene?.view?.window?.rootViewController else { return }
        
        AdManager.shared.showRewardedAd(from: vc) { [weak self] reward in
            guard let self = self else { return }
            if reward > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.closeBackgroundPicker()
                    if let gameVC = vc as? GameViewController {
                        gameVC.presentPhotoPicker()
                    }
                }
            } else {
                HapticHelper.notification(.warning)
            }
        }
    }
    
    func applyCustomPhotoBackground() {
        guard let image = GameViewController.loadCustomBackgroundImage() else { return }
        
        childNode(withName: "customPhotoBg")?.removeFromParent()
        
        let texture = SKTexture(image: image)
        let bgSprite = SKSpriteNode(texture: texture)
        bgSprite.name = "customPhotoBg"
        bgSprite.size = size
        bgSprite.position = CGPoint(x: frame.midX, y: frame.midY)
        bgSprite.zPosition = -20
        bgSprite.alpha = 0.35
        addChild(bgSprite)
        
        backgroundColor = SKColor(white: 0.05, alpha: 1.0)
        groundLevelNode.isHidden = true
        cloudLayer.isHidden = true
        
        HapticHelper.impact(.medium)
    }
}
