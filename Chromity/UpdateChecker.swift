
import UIKit

final class UpdateChecker {
    
    static let shared = UpdateChecker()
    private init() {}
    
    private let lastCheckKey = "UpdateChecker_LastCheckDate"
    private let checkInterval: TimeInterval = 24 * 60 * 60
    
    func checkForUpdate(from viewController: UIViewController? = nil) {
        let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
        if lastCheck > 0 && Date().timeIntervalSince1970 - lastCheck < checkInterval {
            return
        }
        
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleID)"
        guard let url = URL(string: urlString) else { return }

        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, error == nil, let data = data else { return }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let storeInfo = results.first,
                      let storeVersion = storeInfo["version"] as? String,
                      let trackId = storeInfo["trackId"] as? Int,
                      let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                else { return }
                
                if self.isVersion(storeVersion, newerThan: currentVersion) {
                    DispatchQueue.main.async {
                        self.showUpdateAlert(storeVersion: storeVersion, appId: trackId, on: viewController)
                    }
                }
            } catch {
            }
        }
        task.resume()
    }
    
    private func isVersion(_ storeVersion: String, newerThan currentVersion: String) -> Bool {
        let store = storeVersion.split(separator: ".").compactMap { Int($0) }
        let current = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(store.count, current.count)
        for i in 0..<maxCount {
            let s = i < store.count ? store[i] : 0
            let c = i < current.count ? current[i] : 0
            if s > c { return true }
            if s < c { return false }
        }
        return false
    }
    
    private func showUpdateAlert(storeVersion: String, appId: Int, on viewController: UIViewController?) {
        let vc = viewController ?? (UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene)?.windows.first?.rootViewController
        guard let presenter = vc else { return }
        
        let alert = UIAlertController(
            title: L10n.updateAvailableTitle,
            message: L10n.updateAvailableMsg(storeVersion),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: L10n.updateNow, style: .default) { _ in
            if let url = URL(string: "https://apps.apple.com/app/id\(appId)") {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: L10n.later, style: .cancel))
        
        presenter.present(alert, animated: true)
    }
}
