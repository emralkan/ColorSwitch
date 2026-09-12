import SpriteKit

struct BackgroundTheme {
    let id: String
    let name: String
    let icon: String
    let baseColor: SKColor
    let midColor: SKColor
    let highColor: SKColor
    let topColor: SKColor
    let showClouds: Bool
    let showGround: Bool
    let starBrightness: CGFloat
    
    static let all: [BackgroundTheme] = [
        BackgroundTheme(
            id: "earth_space",
            name: "Earth → Space",
            icon: "🌍",
            baseColor: SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 1.0),
            midColor: SKColor(red: 0.1, green: 0.2, blue: 0.45, alpha: 1.0),
            highColor: SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0),
            topColor: SKColor(red: 0.01, green: 0.01, blue: 0.03, alpha: 1.0),
            showClouds: true,
            showGround: true,
            starBrightness: 0.0
        ),
        BackgroundTheme(
            id: "sunset",
            name: "Sunset",
            icon: "🌅",
            baseColor: SKColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0),
            midColor: SKColor(red: 0.75, green: 0.20, blue: 0.35, alpha: 1.0),
            highColor: SKColor(red: 0.30, green: 0.08, blue: 0.25, alpha: 1.0),
            topColor: SKColor(red: 0.05, green: 0.02, blue: 0.10, alpha: 1.0),
            showClouds: true,
            showGround: true,
            starBrightness: 0.0
        ),
        BackgroundTheme(
            id: "ocean",
            name: "Deep Ocean",
            icon: "🌊",
            baseColor: SKColor(red: 0.05, green: 0.35, blue: 0.55, alpha: 1.0),
            midColor: SKColor(red: 0.02, green: 0.18, blue: 0.38, alpha: 1.0),
            highColor: SKColor(red: 0.01, green: 0.08, blue: 0.22, alpha: 1.0),
            topColor: SKColor(red: 0.0, green: 0.02, blue: 0.08, alpha: 1.0),
            showClouds: false,
            showGround: false,
            starBrightness: 0.3
        ),
        BackgroundTheme(
            id: "neon",
            name: "Neon Night",
            icon: "🌃",
            baseColor: SKColor(red: 0.08, green: 0.02, blue: 0.18, alpha: 1.0),
            midColor: SKColor(red: 0.12, green: 0.0, blue: 0.25, alpha: 1.0),
            highColor: SKColor(red: 0.05, green: 0.0, blue: 0.15, alpha: 1.0),
            topColor: SKColor(red: 0.02, green: 0.0, blue: 0.08, alpha: 1.0),
            showClouds: false,
            showGround: true,
            starBrightness: 0.6
        ),
        BackgroundTheme(
            id: "arctic",
            name: "Arctic",
            icon: "❄️",
            baseColor: SKColor(red: 0.75, green: 0.88, blue: 0.95, alpha: 1.0),
            midColor: SKColor(red: 0.55, green: 0.72, blue: 0.85, alpha: 1.0),
            highColor: SKColor(red: 0.30, green: 0.45, blue: 0.65, alpha: 1.0),
            topColor: SKColor(red: 0.10, green: 0.15, blue: 0.30, alpha: 1.0),
            showClouds: true,
            showGround: false,
            starBrightness: 0.0
        ),
        BackgroundTheme(
            id: "volcanic",
            name: "Volcanic",
            icon: "🌋",
            baseColor: SKColor(red: 0.35, green: 0.05, blue: 0.02, alpha: 1.0),
            midColor: SKColor(red: 0.55, green: 0.12, blue: 0.0, alpha: 1.0),
            highColor: SKColor(red: 0.25, green: 0.05, blue: 0.0, alpha: 1.0),
            topColor: SKColor(red: 0.08, green: 0.02, blue: 0.0, alpha: 1.0),
            showClouds: false,
            showGround: true,
            starBrightness: 0.4
        )
    ]
    
    static var current: BackgroundTheme {
        let id = UserDefaults.standard.string(forKey: "SelectedBackground") ?? "earth_space"
        return all.first { $0.id == id } ?? all[0]
    }
}
