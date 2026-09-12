import SpriteKit

enum SkinPathFactory {
    
    static func path(for skinID: String, radius: CGFloat) -> CGPath {
        switch skinID {
        case "square":
            return CGPath(rect: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
            
        case "triangle":
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: -radius, y: -radius))
            path.addLine(to: CGPoint(x: radius, y: -radius))
            path.closeSubpath()
            return path
            
        case "star", "royal":
            return starPath(radius: radius)
            
        case "diamond", "blaze":
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))
            path.addLine(to: CGPoint(x: -radius, y: 0))
            path.closeSubpath()
            return path
            
        case "prism":
            return pentagonPath(radius: radius)
            
        case "hexagon":
            return polygonPath(sides: 6, radius: radius)
            
        case "crescent":
            return crescentPath(radius: radius)
            
        case "ring":
            return ringPath(radius: radius)
            
        case "ghost":
            return ghostPath(radius: radius)
            
        case "mini":
            return CGPath(ellipseIn: CGRect(x: -radius / 2, y: -radius / 2, width: radius, height: radius), transform: nil)
            
        default:
            return CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        }
    }
    
    static func createIcon(for skinID: String, radius: CGFloat) -> SKShapeNode {
        let icon = SKShapeNode()
        icon.path = path(for: skinID, radius: radius)
        icon.fillColor = .white
        icon.strokeColor = .clear
        return icon
    }
    
    
    private static func starPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let pointsOnStar = 5
        var angle: CGFloat = -.pi / 2
        let angleIncrement = CGFloat.pi * 2 / CGFloat(pointsOnStar)
        let innerRadius = radius * 0.4
        var firstPoint = true
        for _ in 0..<pointsOnStar {
            let outerPoint = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if firstPoint { path.move(to: outerPoint); firstPoint = false }
            else { path.addLine(to: outerPoint) }
            angle += angleIncrement / 2
            let innerPoint = CGPoint(x: cos(angle) * innerRadius, y: sin(angle) * innerRadius)
            path.addLine(to: innerPoint)
            angle += angleIncrement / 2
        }
        path.closeSubpath()
        return path
    }
    
    private static func pentagonPath(radius: CGFloat) -> CGPath {
        return polygonPath(sides: 5, radius: radius)
    }
    
    private static func polygonPath(sides: Int, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleOffset: CGFloat = -.pi / 2
        for i in 0..<sides {
            let angle = angleOffset + CGFloat(i) * (2 * .pi / CGFloat(sides))
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
    
    private static func crescentPath(radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        path.addArc(withCenter: .zero, radius: radius, startAngle: .pi * 0.3, endAngle: .pi * 1.7, clockwise: true)
        path.addArc(withCenter: CGPoint(x: radius * 0.35, y: 0), radius: radius * 0.8, startAngle: .pi * 1.7, endAngle: .pi * 0.3, clockwise: false)
        path.close()
        return path.cgPath
    }
    
    private static func ringPath(radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        path.addArc(withCenter: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        path.addArc(withCenter: .zero, radius: radius * 0.55, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        return path.cgPath
    }
    
    private static func ghostPath(radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: 0, y: radius * 0.1), radius: radius * 0.85, startAngle: 0, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: -radius * 0.85, y: -radius * 0.7))
        path.addCurve(to: CGPoint(x: -radius * 0.3, y: -radius * 0.4),
                      controlPoint1: CGPoint(x: -radius * 0.85, y: -radius * 0.3),
                      controlPoint2: CGPoint(x: -radius * 0.55, y: -radius * 0.3))
        path.addCurve(to: CGPoint(x: 0, y: -radius * 0.7),
                      controlPoint1: CGPoint(x: -radius * 0.1, y: -radius * 0.5),
                      controlPoint2: CGPoint(x: 0, y: -radius * 0.7))
        path.addCurve(to: CGPoint(x: radius * 0.3, y: -radius * 0.4),
                      controlPoint1: CGPoint(x: 0, y: -radius * 0.7),
                      controlPoint2: CGPoint(x: radius * 0.1, y: -radius * 0.5))
        path.addCurve(to: CGPoint(x: radius * 0.85, y: -radius * 0.7),
                      controlPoint1: CGPoint(x: radius * 0.55, y: -radius * 0.3),
                      controlPoint2: CGPoint(x: radius * 0.85, y: -radius * 0.3))
        path.addLine(to: CGPoint(x: radius * 0.85, y: radius * 0.1))
        path.close()
        return path.cgPath
    }
}
