
import UIKit
import SpriteKit
import GameplayKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        StoreManager.shared.configure()

        UpdateChecker.shared.checkForUpdate()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard let window = window,
              let skView = window.rootViewController?.view as? SKView,
              let scene = skView.scene as? GameScene else { return }
        
        if scene.stateMachine.currentState is GSPlayingState {
            scene.pauseGame()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UpdateChecker.shared.checkForUpdate()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard !hasStartedAds else { return }
        hasStartedAds = true
        AdManager.shared.startConsentFlow()
    }

    private var hasStartedAds = false
}
