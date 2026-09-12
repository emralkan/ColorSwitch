import SpriteKit
import UIKit
import GameplayKit

extension GameScene {
    
    func updatePlayerShape() {
        let shapeID = UserDefaults.standard.string(forKey: "EquippedSkin") ?? "circle"

        clearPlayerDecorations()
        player.removeAction(forKey: "ghostSway")
        player.alpha = 1.0
        player.zRotation = 0
        player.path = SkinPathFactory.path(for: shapeID, radius: 15)
        applySkinDecorations(shapeID)
        
        let physicsRadius: CGFloat = 15.0
        player.physicsBody = SKPhysicsBody(circleOfRadius: physicsRadius)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.colorSwitch | PhysicsCategory.scorePoint | PhysicsCategory.bonusStar | PhysicsCategory.lava | PhysicsCategory.powerUp
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        player.physicsBody?.isDynamic = (stateMachine.currentState is GSPlayingState)
    }
    
    func clearPlayerDecorations() {
        for child in player.children where child.name == "skinDecoration" {
            child.removeFromParent()
        }
    }
    
    func applySkinDecorations(_ shapeID: String) {
        if shapeID == "royal" {
            let crown = SKShapeNode(path: makeCrownPath(width: 26, height: 12))
            crown.name = "skinDecoration"
            crown.fillColor = .systemYellow
            crown.strokeColor = .white
            crown.lineWidth = 1.2
            crown.position = CGPoint(x: 0, y: 17)
            player.addChild(crown)
        } else if shapeID == "blaze" {
            let flame = SKShapeNode(path: makeFlamePath(width: 14, height: 24))
            flame.name = "skinDecoration"
            flame.fillColor = .systemOrange
            flame.strokeColor = .systemRed
            flame.lineWidth = 1.0
            flame.position = CGPoint(x: 0, y: 2)
            player.addChild(flame)
        } else if shapeID == "prism" {
            let ring = SKShapeNode(circleOfRadius: 20)
            ring.name = "skinDecoration"
            ring.strokeColor = .white
            ring.lineWidth = 3
            ring.glowWidth = 4
            ring.fillColor = .clear
            player.addChild(ring)
        } else if shapeID == "feather" {
            let ring = SKShapeNode(circleOfRadius: 19)
            ring.name = "skinDecoration"
            ring.strokeColor = SKColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8)
            ring.lineWidth = 1.5
            ring.fillColor = .clear
            player.addChild(ring)
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "🪶"
            label.name = "skinDecoration"
            label.fontSize = 10
            label.position = CGPoint(x: 0, y: 18)
            player.addChild(label)
        } else if shapeID == "bolt" {
            let ring = SKShapeNode(circleOfRadius: 19)
            ring.name = "skinDecoration"
            ring.strokeColor = SKColor.systemYellow.withAlphaComponent(0.8)
            ring.lineWidth = 1.5
            ring.fillColor = .clear
            player.addChild(ring)
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "⚡"
            label.name = "skinDecoration"
            label.fontSize = 10
            label.position = CGPoint(x: 0, y: 18)
            player.addChild(label)
        } else if shapeID == "ghost" {
            player.alpha = 0.7
            let sway = SKAction.sequence([
                SKAction.rotate(toAngle: 0.15, duration: 0.8),
                SKAction.rotate(toAngle: -0.15, duration: 0.8)
            ])
            player.run(SKAction.repeatForever(sway), withKey: "ghostSway")
            
            let leftEye = SKShapeNode(circleOfRadius: 3)
            leftEye.name = "skinDecoration"
            leftEye.fillColor = .black
            leftEye.strokeColor = .clear
            leftEye.position = CGPoint(x: -5, y: 5)
            player.addChild(leftEye)
            
            let rightEye = SKShapeNode(circleOfRadius: 3)
            rightEye.name = "skinDecoration"
            rightEye.fillColor = .black
            rightEye.strokeColor = .clear
            rightEye.position = CGPoint(x: 5, y: 5)
            player.addChild(rightEye)
        } else if shapeID == "ring" {
            let innerGlow = SKShapeNode(circleOfRadius: 10)
            innerGlow.name = "skinDecoration"
            innerGlow.fillColor = .clear
            innerGlow.strokeColor = .white
            innerGlow.lineWidth = 1
            innerGlow.glowWidth = 3
            player.addChild(innerGlow)
        } else if shapeID == "crescent" {
            let glow = SKShapeNode(circleOfRadius: 18)
            glow.name = "skinDecoration"
            glow.fillColor = .clear
            glow.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 0.4)
            glow.lineWidth = 1
            glow.glowWidth = 5
            player.addChild(glow)
        }
    }
    
    func makeCrownPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: -height / 2))
        path.addLine(to: CGPoint(x: -width / 3, y: height / 4))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.addLine(to: CGPoint(x: width / 3, y: height / 4))
        path.addLine(to: CGPoint(x: width / 2, y: -height / 2))
        path.closeSubpath()
        return path
    }
    
    func makeFlamePath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addCurve(to: CGPoint(x: width / 2, y: -height / 4),
                      controlPoint1: CGPoint(x: width / 3, y: height / 4),
                      controlPoint2: CGPoint(x: width / 2, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: -height / 2),
                      controlPoint1: CGPoint(x: width / 3, y: -height / 2),
                      controlPoint2: CGPoint(x: width / 6, y: -height / 2))
        path.addCurve(to: CGPoint(x: -width / 2, y: -height / 4),
                      controlPoint1: CGPoint(x: -width / 6, y: -height / 3),
                      controlPoint2: CGPoint(x: -width / 3, y: -height / 2))
        path.addCurve(to: CGPoint(x: 0, y: height / 2),
                      controlPoint1: CGPoint(x: -width / 2, y: 0),
                      controlPoint2: CGPoint(x: -width / 3, y: height / 4))
        path.close()
        return path.cgPath
    }
    
    func spawnPlayer() {
        player.removeFromParent()
        player.removeAllActions()
        player.position = CGPoint(x: frame.midX, y: frame.minY + 120)
        player.setScale(1.0)
        player.alpha = 1.0
        
        let colorIndex = Int.random(in: 0..<4)
        currentColorIndex = colorIndex
        player.fillColor = PlayColors.colors[colorIndex]
        player.strokeColor = SKColor(white: 0.0, alpha: 0.35)
        player.lineWidth = 1.5
        
        updatePlayerShape()
        player.physicsBody?.isDynamic = false
        
        if player.childNode(withName: "trail") == nil {
            let trail = SKEmitterNode()
            trail.name = "trail"
            trail.particleTexture = particleTexture
            trail.particleBirthRate = 60
            trail.particleLifetime = 0.4
            trail.particlePositionRange = CGVector(dx: 10, dy: 10)
            trail.particleSpeed = 20
            trail.particleSpeedRange = 10
            trail.particleAlpha = 0.8
            trail.particleAlphaRange = 0.2
            trail.particleAlphaSpeed = -2.0
            trail.particleScale = 0.8
            trail.particleScaleRange = 0.2
            trail.particleScaleSpeed = -1.5
            trail.emissionAngle = .pi * 1.5
            trail.emissionAngleRange = .pi / 4
            trail.particleColorSequence = nil
            trail.particleColorBlendFactor = 1.0
            trail.targetNode = self
            player.addChild(trail)
        }
        
        if let trail = player.childNode(withName: "trail") as? SKEmitterNode {
            let shapeID = UserDefaults.standard.string(forKey: "EquippedSkin") ?? "circle"
            applyLegendaryTrail(trail: trail, shapeID: shapeID, defaultColor: player.fillColor)
        }
        
        addChild(player)
    }
    
    func applyLegendaryTrail(trail: SKEmitterNode, shapeID: String, defaultColor: SKColor) {
        trail.particleBirthRate = 60
        trail.particleLifetime = 0.4
        trail.particleScale = 0.8
        trail.particleScaleSpeed = -1.5
        trail.particleColorSequence = nil
        trail.particleBlendMode = .add
        trail.particleAlpha = 0.8
        
        if shapeID == "blaze" {
            trail.particleBirthRate = 120
            trail.particleLifetime = 0.6
            trail.particleScale = 1.2
            trail.particleColor = .systemOrange
        } else if shapeID == "ghost" {
            trail.particleBirthRate = 30
            trail.particleLifetime = 0.8
            trail.particleScale = 1.0
            trail.particleColor = SKColor(white: 0.8, alpha: 0.5)
            trail.particleBlendMode = .alpha
        } else if shapeID == "prism" {
            trail.particleBirthRate = 80
            trail.particleLifetime = 0.5
            trail.particleColor = .white
        } else if shapeID == "royal" {
            trail.particleBirthRate = 50
            trail.particleLifetime = 0.5
            trail.particleColor = .systemYellow
            trail.particleScale = 1.0
        } else {
            trail.particleColor = defaultColor
        }
    }
}
