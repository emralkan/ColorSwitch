
import Foundation
import RevenueCat

// MARK: - Satın Almalar

class StoreManager {
    static let shared = StoreManager()
    
    private init() {}
    
    func configure() {
        Purchases.configure(withAPIKey: "appl_UQlSGYiEEbMmUSjCPQkidfMRSgo")
    }
    
    func purchaseRemoveAds(completion: @escaping (Bool, String?) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let package = offerings?.current?.lifetime else {
                completion(false, "Package not found.")
                return
            }
            
            Purchases.shared.purchase(package: package) { transaction, purchaserInfo, error, userCancelled in
                if let error = error {
                    completion(false, userCancelled ? nil : error.localizedDescription)
                    return
                }
                
                let proActive = purchaserInfo?.entitlements["Chromity Pro"]?.isActive == true
                let anyActive = purchaserInfo?.entitlements.active.isEmpty == false
                if proActive || anyActive {
                    UserDefaults.standard.set(true, forKey: "HasRemovedAds")
                    ICloudSyncManager.shared.pushValue(true, forKey: "HasRemovedAds")
                    DispatchQueue.main.async {
                        AdManager.shared.hideBanner()
                    }
                    completion(true, nil)
                } else {
                    completion(false, "Entitlement verification failed.")
                }
            }
        }
    }
    
    func restorePurchases(completion: @escaping (Bool, String?) -> Void) {
        Purchases.shared.restorePurchases { purchaserInfo, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            let proActive = purchaserInfo?.entitlements["Chromity Pro"]?.isActive == true
            let anyActive = purchaserInfo?.entitlements.active.isEmpty == false
            if proActive || anyActive {
                UserDefaults.standard.set(true, forKey: "HasRemovedAds")
                ICloudSyncManager.shared.pushValue(true, forKey: "HasRemovedAds")
                DispatchQueue.main.async {
                    AdManager.shared.hideBanner()
                }
                completion(true, nil)
            } else {
                completion(false, "No active subscription to restore.")
            }
        }
    }
    
    func fetchRemoveAdsPrice(completion: @escaping (String?) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let package = offerings?.current?.lifetime {
                completion(package.localizedPriceString)
            } else {
                completion(nil)
            }
        }
    }

}
