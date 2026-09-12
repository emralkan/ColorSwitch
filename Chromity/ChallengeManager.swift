import Foundation

struct Challenge: Codable, Equatable {
    let level: Int
    let targetScore: Int
    let rewardCoins: Int
}

class ChallengeManager {
    static let shared = ChallengeManager()
    
    let totalLevels = 20
    private let unlockedLevelKey = "HighestUnlockedChallengeLevel"
    
    var highestUnlockedLevel: Int {
        get {
            let level = UserDefaults.standard.integer(forKey: unlockedLevelKey)
            return level == 0 ? 1 : level
        }
        set {
            UserDefaults.standard.set(newValue, forKey: unlockedLevelKey)
        }
    }
    
    var currentChallenge: Challenge?
    
    func getChallenge(for level: Int) -> Challenge {
        let target = 4 + (level * 2)
        let reward = level * 15
        return Challenge(level: level, targetScore: target, rewardCoins: reward)
    }
    
    func completeCurrentChallenge() {
        guard let challenge = currentChallenge else { return }
        
        let currentCoins = UserDefaults.standard.integer(forKey: "TotalCoins")
        let newCoins = currentCoins + challenge.rewardCoins
        UserDefaults.standard.set(newCoins, forKey: "TotalCoins")
        ICloudSyncManager.shared.pushValue(newCoins, forKey: "TotalCoins")
        
        if challenge.level == highestUnlockedLevel && highestUnlockedLevel < totalLevels {
            highestUnlockedLevel += 1
            ICloudSyncManager.shared.pushValue(highestUnlockedLevel, forKey: "HighestUnlockedChallengeLevel")
        }
        
    }
    
    func clearCurrentChallenge() {
        currentChallenge = nil
    }
}
