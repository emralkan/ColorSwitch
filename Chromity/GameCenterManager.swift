import Foundation
import GameKit
import UIKit

class GameCenterManager: NSObject, GKLocalPlayerListener {
    static let shared = GameCenterManager()

    var isConfigured = false
    var isAuthenticated = false

    let alltimeLeaderboardID = "chromity_alltime_highscore"

    private let pendingScoreKey = "PendingGCScore"
    private var isFlushingPending = false

    private override init() {
        super.init()
    }

    func authenticateUser(presentingViewController: UIViewController) {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            if let vc = viewController {
                presentingViewController.present(vc, animated: true)
            } else if localPlayer.isAuthenticated {
                #if DEBUG
                print("Game Center: Successfully authenticated user!")
                print("Game Center: Player Nickname: \(localPlayer.displayName)")
                #endif
                self.isAuthenticated = true
                self.isConfigured = true
                localPlayer.register(self)
                self.flushPendingScore()
            } else {
                #if DEBUG
                print("Game Center: User is not authenticated. \(error?.localizedDescription ?? "")")
                #endif
                self.isAuthenticated = false
            }
        }
    }

    func submitScore(_ score: Int, completion: ((Bool) -> Void)? = nil) {
        guard isAuthenticated else {
            #if DEBUG
            print("Game Center: Not authenticated. Cannot submit score.")
            #endif
            savePendingScore(score)
            completion?(false)
            return
        }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [alltimeLeaderboardID]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("Game Center: Error submitting score: \(error.localizedDescription)")
                    #endif
                    self?.savePendingScore(score)
                    completion?(false)
                } else {
                    #if DEBUG
                    print("Game Center: Successfully submitted score: \(score)")
                    #endif
                    self?.clearPendingScoreIfNotGreater(than: score)
                    completion?(true)
                }
            }
        }
    }


    private func savePendingScore(_ score: Int) {
        let defaults = UserDefaults.standard
        let existing = defaults.integer(forKey: pendingScoreKey)
        if score > existing {
            defaults.set(score, forKey: pendingScoreKey)
        }
    }

    private func clearPendingScoreIfNotGreater(than score: Int) {
        let defaults = UserDefaults.standard
        let pending = defaults.integer(forKey: pendingScoreKey)
        if pending <= score {
            defaults.removeObject(forKey: pendingScoreKey)
        } else {
            flushPendingScore()
        }
    }

    private func flushPendingScore() {
        let defaults = UserDefaults.standard
        let pending = defaults.integer(forKey: pendingScoreKey)
        guard pending > 0, isAuthenticated, !isFlushingPending else { return }
        isFlushingPending = true

        GKLeaderboard.submitScore(pending, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [alltimeLeaderboardID]) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFlushingPending = false
                if let error = error {
                    #if DEBUG
                    print("Game Center: Error flushing pending score: \(error.localizedDescription)")
                    #endif
                } else {
                    #if DEBUG
                    print("Game Center: Successfully flushed pending score: \(pending)")
                    #endif
                    let current = UserDefaults.standard.integer(forKey: self.pendingScoreKey)
                    if current <= pending {
                        UserDefaults.standard.removeObject(forKey: self.pendingScoreKey)
                    } else {
                        self.flushPendingScore()
                    }
                }
            }
        }
    }

    func showLeaderboard(presentingViewController: UIViewController) {
        guard isAuthenticated else {
            #if DEBUG
            print("Game Center: Not authenticated -> Mocking UI presentation instead")
            #endif
            return
        }

        let gcVC = GKGameCenterViewController(leaderboardID: alltimeLeaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = presentingViewController as? GKGameCenterControllerDelegate
        presentingViewController.present(gcVC, animated: true)
    }
}
