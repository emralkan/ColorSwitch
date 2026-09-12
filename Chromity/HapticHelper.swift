import UIKit

enum HapticHelper {
    
    private static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: "HapticsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "HapticsEnabled")
    }

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    private static func impactGenerator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: return lightImpact
        case .medium: return mediumImpact
        case .heavy: return heavyImpact
        case .soft: return softImpact
        case .rigid: return rigidImpact
        @unknown default: return lightImpact
        }
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        let generator = impactGenerator(for: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
}
