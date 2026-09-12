import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import UserMessagingPlatform

extension Notification.Name {
    static let adsReady = Notification.Name("AdsReady")
}

// MARK: - Reklam Yönetimi

class AdManager: NSObject, FullScreenContentDelegate {
    static let shared = AdManager()

    var isConfigured: Bool { return true }

    private(set) var isSDKInitialized = false
    
    var isRewardedAdReady: Bool { return canRequestAds && rewardedAd != nil }
    
    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    private let interstitialAdUnitID = "ca-app-pub-7795937092215431/3483950677"
    private let rewardedAdUnitID = "ca-app-pub-7795937092215431/9526614847"
    private let bannerAdUnitID = "ca-app-pub-7795937092215431/9224364536"
    #endif
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private(set) var bannerView: BannerView?
    
    private var gamesSinceLastInterstitial = 0
    private let interstitialFrequency = 3
    
    private var interstitialDismissCompletion: (() -> Void)?
    private var rewardedDismissCompletion: ((Int) -> Void)?
    private var pendingRewardAmount: Int = 0
    private var sdkStarted = false
    
    private override init() {
        super.init()
    }
    

    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    // MARK: - İzin ve SDK Kurulumu

    func startConsentFlow() {
        let parameters = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
            guard let self else { return }
            ConsentForm.loadAndPresentIfRequired(from: self.rootViewController) { [weak self] _ in
                self?.startAdsIfAllowed()
            }
            self.startAdsIfAllowed()
        }
    }

    private func startAdsIfAllowed() {
        guard canRequestAds, !sdkStarted else { return }
        sdkStarted = true
        initializeSDK()
    }

    private func initializeSDK() {
        MobileAds.shared.start { [weak self] status in
            #if DEBUG
            print("✅ AdManager: Google Mobile Ads SDK initialized")
            for (adapter, info) in status.adapterStatusesByClassName {
                print("   Adapter: \(adapter) — \(info.state == .ready ? "Ready" : "Not Ready")")
            }
            #endif

            self?.loadInterstitial()
            self?.loadRewarded()

            self?.isSDKInitialized = true
            NotificationCenter.default.post(name: .adsReady, object: nil)
        }
    }

    private func requestTrackingIfNeeded(completion: @escaping () -> Void) {
        guard #available(iOS 14, *),
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            completion()
            return
        }
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async(execute: completion)
        }
    }

    private var rootViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return activeScene?.keyWindow?.rootViewController
    }
    
    
    // MARK: - Banner Reklam

    func setupBanner(in viewController: UIViewController) {
        guard canRequestAds else { return }
        if UserDefaults.standard.bool(forKey: "HasRemovedAds") { return }
        
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = bannerAdUnitID
        banner.rootViewController = viewController
        banner.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
        ])
        
        banner.load(Request())
        bannerView = banner
        
        #if DEBUG
        print("✅ AdManager: Banner ad setup complete")
        #endif
    }
    
    func hideBanner() {
        bannerView?.removeFromSuperview()
        bannerView = nil
    }
    
    
    // MARK: - Geçiş Reklamı

    private func loadInterstitial() {
        guard canRequestAds else { return }
        InterstitialAd.load(with: interstitialAdUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                #if DEBUG
                print("⚠️ AdManager: Interstitial load failed — \(error.localizedDescription)")
                #endif
                return
            }
            self?.interstitialAd = ad
            #if DEBUG
            print("✅ AdManager: Interstitial loaded")
            #endif
        }
    }
    
    func showInterstitialIfEligible(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        guard canRequestAds else {
            completion?()
            return
        }
        if UserDefaults.standard.bool(forKey: "HasRemovedAds") {
            completion?()
            return
        }
        
        gamesSinceLastInterstitial += 1
        guard gamesSinceLastInterstitial >= interstitialFrequency else {
            completion?()
            return
        }
        
        guard let ad = interstitialAd else {
            #if DEBUG
            print("⚠️ AdManager: Interstitial not ready, loading...")
            #endif
            loadInterstitial()
            completion?()
            return
        }
        
        rewardedDismissCompletion = nil
        interstitialDismissCompletion = completion
        ad.fullScreenContentDelegate = self
        ad.present(from: viewController)
        interstitialAd = nil
        gamesSinceLastInterstitial = 0
        
        loadInterstitial()
    }
    
    
    // MARK: - Tam Ekran Reklam Temsilcisi

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.interstitialDismissCompletion?()
            self.interstitialDismissCompletion = nil
            if let rewardCompletion = self.rewardedDismissCompletion {
                rewardCompletion(self.pendingRewardAmount)
                self.rewardedDismissCompletion = nil
                self.pendingRewardAmount = 0
            }
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        #if DEBUG
        print("⚠️ AdManager: Ad failed to present — \(error.localizedDescription)")
        #endif
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.interstitialDismissCompletion?()
            self.interstitialDismissCompletion = nil
            if let rewardCompletion = self.rewardedDismissCompletion {
                rewardCompletion(0)
                self.rewardedDismissCompletion = nil
                self.pendingRewardAmount = 0
                self.rewardedAd = nil
                self.loadRewarded()
            }
        }
    }
    
    
    // MARK: - Ödüllü Reklam

    private func loadRewarded() {
        guard canRequestAds else { return }
        RewardedAd.load(with: rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                #if DEBUG
                print("⚠️ AdManager: Rewarded load failed — \(error.localizedDescription)")
                #endif
                return
            }
            self?.rewardedAd = ad
            #if DEBUG
            print("✅ AdManager: Rewarded ad loaded")
            #endif
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Int) -> Void) {
        guard canRequestAds else {
            completion(0)
            return
        }

        requestTrackingIfNeeded { [weak self, weak viewController] in
            guard let self, let viewController else {
                completion(0)
                return
            }
            self.presentRewardedAd(from: viewController, completion: completion)
        }
    }

    private func presentRewardedAd(from viewController: UIViewController, completion: @escaping (Int) -> Void) {
        guard let ad = rewardedAd else {
            #if DEBUG
            print("⚠️ AdManager: Rewarded ad not ready, no reward granted")
            #endif
            loadRewarded()
            completion(0)
            return
        }

        pendingRewardAmount = 0
        interstitialDismissCompletion = nil
        rewardedDismissCompletion = completion
        ad.fullScreenContentDelegate = self

        ad.present(from: viewController) { [weak self] in
            let reward = ad.adReward.amount.intValue
            #if DEBUG
            print("✅ AdManager: Rewarded ad completed — reward: \(reward)")
            #endif
            self?.pendingRewardAmount = max(reward, 50)

            self?.rewardedAd = nil
            self?.loadRewarded()
        }
    }
}
