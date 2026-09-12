import SpriteKit
import UIKit

// MARK: - Engeller

extension GameScene {
    
    func spawnInitialObstacles() {
        obstacleSpawnCount = 0
        highestObstacleY = frame.midY + 100
        highestObstacleRadius = 110.0

        for _ in 0..<3 {
            spawnNextObstacle()
        }
    }

    func spawnNextObstacle() {
        obstacleSpawnCount += 1

        let isBreathingRoom = (score > 0 && score % 15 == 0)
        
        let nextPattern: ObstaclePattern
        if isBreathingRoom {
            nextPattern = .circle
        } else {
            nextPattern = selectNextObstaclePattern()
        }
        
        let nextRadius = radius(for: nextPattern)
        
        let clearance: CGFloat
        if isBreathingRoom {
            clearance = 200.0
        } else {
            let t = CGFloat(min(score, 200)) / 200.0
            clearance = 190.0 - (40.0 * t)
        }

        let posY: CGFloat
        if obstacleSpawnCount == 1 {
            posY = frame.midY + 100
        } else {
            posY = highestObstacleY + highestObstacleRadius + clearance + nextRadius
            let changerY = highestObstacleY + highestObstacleRadius + (clearance / 2.0)
            spawnColorChanger(atY: changerY)
        }

        spawnObstacle(nextPattern, atY: posY, isBreathingRoom: isBreathingRoom)
        
        if Int.random(in: 1...100) <= 8 {
            spawnJokerPowerUp(posY: posY)
        } else {
            spawnCoinAtSafePath(posY: posY, pattern: nextPattern)
        }

        highestObstacleY = posY
        highestObstacleRadius = nextRadius
    }

    func selectNextObstaclePattern() -> ObstaclePattern {
        if obstacleSpawnCount == 1 {
            return .circle
        }

        switch score {
        case ..<5:
            return .circle
        case 5..<15:
            return [.circle, .splitCircle].randomElement()!
        case 15..<30:
            return [.circle, .splitCircle, .square].randomElement()!
        default:
            return [.circle, .splitCircle, .square, .reverseCircle].randomElement()!
        }
    }

    func radius(for pattern: ObstaclePattern) -> CGFloat {
        switch pattern {
        case .circle, .reverseCircle:
            return 110.0
        case .square:
            return 155.0
        case .splitCircle:
            return 120.0
        }
    }

    func isFirstEncounter(for pattern: ObstaclePattern) -> Bool {
        let key = "HasSeen_\(pattern)"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            return true
        }
        return false
    }
    
    func firstEncounterDuration(base: Double, pattern: ObstaclePattern) -> Double {
        let duration = adjustedRotationDuration(base: base)
        return isFirstEncounter(for: pattern) ? duration * 1.2 : duration
    }

    func spawnObstacle(_ pattern: ObstaclePattern, atY posY: CGFloat, isBreathingRoom: Bool = false) {
        switch pattern {
        case .circle:
            if isBreathingRoom {
                spawnCircleObstacle(atY: posY, rotationDuration: 8.0)
            } else {
                spawnCircleObstacle(atY: posY)
            }
        case .square:
            spawnSquareObstacle(atY: posY, rotationDuration: firstEncounterDuration(base: 5.5, pattern: .square))
        case .splitCircle:
            spawnSplitCircleObstacle(atY: posY, rotationDuration: firstEncounterDuration(base: 5.0, pattern: .splitCircle))
        case .reverseCircle:
            spawnReverseCircleObstacle(atY: posY, rotationDuration: firstEncounterDuration(base: 4.5, pattern: .reverseCircle))
        }
        
        if isSlowMoActive {
            obstacles.last?.speed = 0.4
        }
    }

    func adjustedRotationDuration(base: Double) -> Double {
        let speedModifier = max(0.5, 1.0 - (log10(max(1.0, Double(score))) * 0.25))
        return max(3.0, base * speedModifier)
    }
    
    
    func spawnJokerPowerUp(posY: CGFloat) {
        let size = CGSize(width: 24, height: 24)
        let powerUpNode = SKShapeNode(rectOf: size, cornerRadius: 5)
        powerUpNode.fillColor = .white
        powerUpNode.strokeColor = .clear
        powerUpNode.position = CGPoint(x: frame.midX, y: posY)
        powerUpNode.physicsBody = SKPhysicsBody(rectangleOf: size)
        powerUpNode.physicsBody?.isDynamic = false
        powerUpNode.physicsBody?.categoryBitMask = PhysicsCategory.powerUp
        powerUpNode.name = "powerUp"
        
        let rainbowPulse = SKAction.sequence([
            SKAction.run { [weak powerUpNode] in powerUpNode?.fillColor = .cyan },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak powerUpNode] in powerUpNode?.fillColor = .magenta },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak powerUpNode] in powerUpNode?.fillColor = .yellow },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak powerUpNode] in powerUpNode?.fillColor = .orange },
            SKAction.wait(forDuration: 0.1)
        ])
        powerUpNode.run(SKAction.repeatForever(rainbowPulse))
        
        let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 0.5)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        floatDown.timingMode = .easeInEaseOut
        let seq = SKAction.sequence([floatUp, floatDown])
        let rotate = SKAction.rotate(byAngle: .pi, duration: 1.0)
        powerUpNode.run(SKAction.repeatForever(SKAction.group([seq, rotate])))
        
        powerUpNode.glowWidth = 4.0
        
        addChild(powerUpNode)
        obstacles.append(powerUpNode)
    }
    
    func spawnSlowMoPowerUp(posY: CGFloat) {
        let size = CGSize(width: 26, height: 26)
        let node = SKShapeNode(rectOf: size, cornerRadius: 13)
        node.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
        node.strokeColor = .white
        node.lineWidth = 2.0
        node.position = CGPoint(x: frame.midX, y: posY)
        node.physicsBody = SKPhysicsBody(circleOfRadius: 13)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.powerUp
        node.name = "slowMoPowerUp"
        
        let hand = SKShapeNode(rectOf: CGSize(width: 2, height: 10))
        hand.fillColor = .white
        hand.position = CGPoint(x: 0, y: 3)
        node.addChild(hand)
        
        let rot = SKAction.rotate(byAngle: -.pi * 2, duration: 2.0)
        hand.run(SKAction.repeatForever(rot))
        
        let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 0.8)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 0.8)
        floatDown.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
        
        node.glowWidth = 4.0
        
        addChild(node)
        obstacles.append(node)
    }
    
    func spawnCoinAtSafePath(posY: CGFloat, pattern: ObstaclePattern) {
        let coinRadius: CGFloat = 12.0
        let coin = SKShapeNode(circleOfRadius: coinRadius)
        coin.fillColor = .systemYellow
        coin.strokeColor = .orange
        coin.lineWidth = 2.0
        
        coin.position = CGPoint(x: frame.midX, y: posY)
        
        coin.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = PhysicsCategory.scorePoint
        coin.name = "star"
        
        let innerCoin = SKShapeNode(circleOfRadius: coinRadius - 4)
        innerCoin.fillColor = .clear
        innerCoin.strokeColor = .orange
        innerCoin.lineWidth = 1.0
        coin.addChild(innerCoin)
        
        let floatUp = SKAction.moveBy(x: 0, y: 3, duration: 0.5)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -3, duration: 0.5)
        floatDown.timingMode = .easeInEaseOut
        coin.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
        
        addChild(coin)
        obstacles.append(coin)
    }
    
    private static let colorChangerArcPath: CGPath =
        UIBezierPath(arcCenter: .zero, radius: 15, startAngle: 0, endAngle: .pi/2, clockwise: true).cgPath

    func spawnColorChanger(atY posY: CGFloat) {
        let changerNode = SKNode()
        changerNode.position = CGPoint(x: frame.midX, y: posY)
        changerNode.name = "ColorChanger"

        let path = GameScene.colorChangerArcPath
        let s1 = SKShapeNode(path: path); s1.fillColor = PlayColors.colors[0]; s1.strokeColor = SKColor(white: 0.0, alpha: 0.3); s1.lineWidth = 1.5
        let s2 = SKShapeNode(path: path); s2.fillColor = PlayColors.colors[1]; s2.strokeColor = SKColor(white: 0.0, alpha: 0.3); s2.lineWidth = 1.5; s2.zRotation = .pi/2
        let s3 = SKShapeNode(path: path); s3.fillColor = PlayColors.colors[2]; s3.strokeColor = SKColor(white: 0.0, alpha: 0.3); s3.lineWidth = 1.5; s3.zRotation = .pi
        let s4 = SKShapeNode(path: path); s4.fillColor = PlayColors.colors[3]; s4.strokeColor = SKColor(white: 0.0, alpha: 0.3); s4.lineWidth = 1.5; s4.zRotation = -.pi/2
        
        changerNode.addChild(s1)
        changerNode.addChild(s2)
        changerNode.addChild(s3)
        changerNode.addChild(s4)
        
        changerNode.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        changerNode.physicsBody?.isDynamic = false
        changerNode.physicsBody?.categoryBitMask = PhysicsCategory.colorSwitch
        
        changerNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.5)))
        addChild(changerNode)
        obstacles.append(changerNode)
    }


    func spawnCircleObstacle(atY posY: CGFloat, rotationDuration: Double? = nil) {
        let container: SKNode
        if let pooledNode = obstaclePool["Pattern_circle"]?.popLast() {
            container = pooledNode
            container.position = CGPoint(x: frame.midX, y: posY)
            container.zRotation = 0
            container.alpha = 1.0
            container.speed = 1.0
            if container.parent == nil { addChild(container) }
        } else {
            container = SKNode()
            container.name = "Pattern_circle"
            container.position = CGPoint(x: frame.midX, y: posY)
            let thickness: CGFloat = 20.0
            let radius: CGFloat = 110.0
            
            for i in 0..<4 {
                let startAngle = CGFloat(i) * .pi / 2
                let endAngle = startAngle + .pi / 2
                let path = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.addArc(withCenter: .zero, radius: radius - thickness, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                path.close()
                
                let segment = SKShapeNode(path: path.cgPath)
                segment.fillColor = PlayColors.colors[i]
                segment.strokeColor = SKColor(white: 0.0, alpha: 0.3)
                segment.lineWidth = 1.5
                segment.name = "obstacle_\(i)"
                segment.physicsBody = SKPhysicsBody(polygonFrom: path.cgPath)
                segment.physicsBody?.isDynamic = false
                segment.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
                container.addChild(segment)
            }
            addChild(container)
        }
        
        obstacles.append(container)
        
        let duration: Double = rotationDuration ?? adjustedRotationDuration(base: 4.5)
        let direction: CGFloat = (Int.random(in: 0...1) == 0) ? 1.0 : -1.0
        let rotAction = SKAction.rotate(byAngle: direction * (380.0 * .pi / 180.0), duration: duration)
        container.run(SKAction.repeatForever(rotAction))
    }
    
    func spawnSquareObstacle(atY posY: CGFloat, rotationDuration: Double? = nil) {
        let container: SKNode
        if let pooledNode = obstaclePool["Pattern_square"]?.popLast() {
            container = pooledNode
            container.position = CGPoint(x: frame.midX, y: posY)
            container.zRotation = 0
            container.alpha = 1.0
            container.speed = 1.0
            if container.parent == nil { addChild(container) }
        } else {
            container = SKNode()
            container.name = "Pattern_square"
            container.position = CGPoint(x: frame.midX, y: posY)
            let length: CGFloat = 200.0
            let thickness: CGFloat = 20.0
            
            let offsets: [CGPoint] = [
                CGPoint(x: 0, y: length / 2), CGPoint(x: length / 2, y: 0),
                CGPoint(x: 0, y: -length / 2), CGPoint(x: -length / 2, y: 0)
            ]
            
            for i in 0..<4 {
                let segment = SKSpriteNode(color: PlayColors.colors[i], size: CGSize(width: length + thickness, height: thickness))
                segment.position = offsets[i]
                if i % 2 != 0 { segment.zRotation = .pi / 2 }
                
                segment.physicsBody = SKPhysicsBody(rectangleOf: segment.size)
                segment.physicsBody?.isDynamic = false
                segment.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
                segment.name = "obstacle_\(i)"
                container.addChild(segment)
            }
            addChild(container)
        }
        
        obstacles.append(container)
        
        let duration: Double = rotationDuration ?? adjustedRotationDuration(base: 5.5)
        let direction: CGFloat = (Int.random(in: 0...1) == 0) ? 1.0 : -1.0
        let rotAction = SKAction.rotate(byAngle: direction * (380.0 * .pi / 180.0), duration: duration)
        container.run(SKAction.repeatForever(rotAction))
    }
    
    func spawnSplitCircleObstacle(atY posY: CGFloat, rotationDuration: Double? = nil) {
        let container: SKNode
        if let pooledNode = obstaclePool["Pattern_splitCircle"]?.popLast() {
            container = pooledNode
            container.position = CGPoint(x: frame.midX, y: posY)
            container.zRotation = 0
            container.alpha = 1.0
            container.speed = 1.0
            if container.parent == nil { addChild(container) }
        } else {
            container = SKNode()
            container.name = "Pattern_splitCircle"
            container.position = CGPoint(x: frame.midX, y: posY)
            
            let radius: CGFloat = 120.0
            let thickness: CGFloat = 20.0
            let degrees120 = CGFloat(120.0) * .pi / 180.0
            
            let path1 = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: degrees120, clockwise: true)
            path1.addArc(withCenter: .zero, radius: radius - thickness, startAngle: degrees120, endAngle: 0, clockwise: false)
            path1.close()
            
            let segment1 = SKShapeNode(path: path1.cgPath)
            segment1.fillColor = PlayColors.colors[0]
            segment1.strokeColor = SKColor(white: 0.0, alpha: 0.3)
            segment1.lineWidth = 1.5
            segment1.name = "obstacle_0"
            segment1.physicsBody = SKPhysicsBody(polygonFrom: path1.cgPath)
            segment1.physicsBody?.isDynamic = false
            segment1.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            segment1.zRotation = (.pi / 2.0) - (degrees120 / 2.0)
            container.addChild(segment1)
            
            let path2 = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: degrees120, clockwise: true)
            path2.addArc(withCenter: .zero, radius: radius - thickness, startAngle: degrees120, endAngle: 0, clockwise: false)
            path2.close()
            
            let segment2 = SKShapeNode(path: path2.cgPath)
            segment2.fillColor = PlayColors.colors[2]
            segment2.strokeColor = SKColor(white: 0.0, alpha: 0.3)
            segment2.lineWidth = 1.5
            segment2.name = "obstacle_2"
            segment2.physicsBody = SKPhysicsBody(polygonFrom: path2.cgPath)
            segment2.physicsBody?.isDynamic = false
            segment2.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
            segment2.zRotation = (3.0 * .pi / 2.0) - (degrees120 / 2.0)
            container.addChild(segment2)
            
            addChild(container)
        }
        
        obstacles.append(container)
        
        let duration: Double = rotationDuration ?? adjustedRotationDuration(base: 5.0)
        let direction: CGFloat = (Int.random(in: 0...1) == 0) ? 1.0 : -1.0
        let rotAction = SKAction.rotate(byAngle: direction * (380.0 * .pi / 180.0), duration: duration)
        container.run(SKAction.repeatForever(rotAction))
    }
    
    
    
    
    
    func spawnReverseCircleObstacle(atY posY: CGFloat, rotationDuration: Double = 4.5) {
        let container: SKNode
        if let pooledNode = obstaclePool["Pattern_reverseCircle"]?.popLast() {
            container = pooledNode
            container.position = CGPoint(x: frame.midX, y: posY)
            container.zRotation = 0
            container.alpha = 1.0
            container.speed = 1.0
            if container.parent == nil { addChild(container) }
        } else {
            container = SKNode()
            container.name = "Pattern_reverseCircle"
            container.position = CGPoint(x: frame.midX, y: posY)
            let thickness: CGFloat = 20.0
            let radius: CGFloat = 110.0
            
            for i in 0..<4 {
                let startAngle = CGFloat(i) * .pi / 2
                let endAngle = startAngle + .pi / 2
                let path = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.addArc(withCenter: .zero, radius: radius - thickness, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                path.close()
                
                let segment = SKShapeNode(path: path.cgPath)
                segment.fillColor = PlayColors.colors[i]
                segment.strokeColor = SKColor(white: 0.0, alpha: 0.3)
                segment.lineWidth = 1.5
                segment.name = "obstacle_\(i)"
                segment.physicsBody = SKPhysicsBody(polygonFrom: path.cgPath)
                segment.physicsBody?.isDynamic = false
                segment.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
                container.addChild(segment)
            }
            addChild(container)
        }
        
        obstacles.append(container)
        
        var currentDirection: CGFloat = (Int.random(in: 0...1) == 0) ? 1.0 : -1.0
        
        let twoTurns = 2.0 * 360.0 * .pi / 180.0
        let twoTurnDuration = rotationDuration * 2.0
        
        let reverseSequence = SKAction.sequence([
            SKAction.run {
                let rotAction = SKAction.rotate(byAngle: currentDirection * CGFloat(twoTurns), duration: twoTurnDuration)
                container.run(rotAction, withKey: "currentSpin")
            },
            SKAction.wait(forDuration: twoTurnDuration),
            SKAction.run {
                currentDirection *= -1
                let flash = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.1),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ])
                container.run(flash)
            }
        ])
        
        container.run(SKAction.repeatForever(reverseSequence), withKey: "reverser")
    }
}
