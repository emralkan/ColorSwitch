import Foundation

enum MissionType: String, Codable {
    case playGames
    case collectStars
    case reachScore
    case collectJokers
}

struct Mission: Codable {
    let id: String
    let type: MissionType
    let targetAmount: Int
    var currentAmount: Int
    let reward: Int
    var isClaimed: Bool
    
    var isComplete: Bool {
        return currentAmount >= targetAmount
    }
    
    var title: String {
        switch type {
        case .playGames: return L10n.missionPlayGames(targetAmount)
        case .collectStars: return L10n.missionCollectStars(targetAmount)
        case .reachScore: return L10n.missionReachScore(targetAmount)
        case .collectJokers: return L10n.missionCollectJokers(targetAmount)
        }
    }
}

class MissionManager {
    static let shared = MissionManager()
    
    private let missionsKey = "DailyMissions"
    private let lastRefreshKey = "DailyMissionsLastRefresh"
    
    var currentMissions: [Mission] = []
    
    var onMissionsUpdated: (() -> Void)?
    
    private init() {
        loadMissions()
        checkDailyRefresh()
    }
    
    private func loadMissions() {
        if let data = UserDefaults.standard.data(forKey: missionsKey),
           let saved = try? JSONDecoder().decode([Mission].self, from: data) {
            currentMissions = saved
        } else {
            generateNewMissions()
        }
    }
    
    private func saveMissions() {
        if let data = try? JSONEncoder().encode(currentMissions) {
            UserDefaults.standard.set(data, forKey: missionsKey)
        }
        onMissionsUpdated?()
    }
    
    private func checkDailyRefresh() {
        let lastRefreshObj = UserDefaults.standard.object(forKey: lastRefreshKey) as? Date ?? Date.distantPast
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastRefreshObj) {
            generateNewMissions()
            UserDefaults.standard.set(Date(), forKey: lastRefreshKey)
        }
    }
    
    private func generateNewMissions() {
        let possibleTypes: [MissionType] = [.playGames, .collectStars, .reachScore, .collectJokers]
        let selected = possibleTypes.shuffled().prefix(3)
        
        var newMissions: [Mission] = []
        for type in selected {
            var target = 0
            var reward = 0
            
            switch type {
            case .playGames:
                target = [3, 5, 10].randomElement()!
                reward = target * 10
            case .collectStars:
                target = [20, 50, 100].randomElement()!
                reward = target / 2
            case .reachScore:
                target = [10, 20, 30].randomElement()!
                reward = target * 5
            case .collectJokers:
                target = [1, 3, 5].randomElement()!
                reward = target * 20
            }
            
            let mission = Mission(id: UUID().uuidString,
                                  type: type,
                                  targetAmount: target,
                                  currentAmount: 0,
                                  reward: reward,
                                  isClaimed: false)
            newMissions.append(mission)
        }
        
        currentMissions = newMissions
        saveMissions()
    }
    
    
    func reportPlayGame() {
        updateProgress(for: .playGames, amount: 1)
    }
    
    func reportStarCollected() {
        updateProgress(for: .collectStars, amount: 1)
    }
    
    func reportScoreTarget(score: Int) {
        for (index, mission) in currentMissions.enumerated() {
            if mission.type == .reachScore && !mission.isClaimed {
                if score > currentMissions[index].currentAmount {
                    currentMissions[index].currentAmount = score
                    if currentMissions[index].currentAmount >= mission.targetAmount {
                        currentMissions[index].currentAmount = mission.targetAmount
                    }
                    saveMissions()
                }
            }
        }
    }
    
    func reportJokerCollected() {
        updateProgress(for: .collectJokers, amount: 1)
    }
    
    private func updateProgress(for type: MissionType, amount: Int) {
        var modified = false
        for (index, mission) in currentMissions.enumerated() {
            if mission.type == type && !mission.isComplete {
                currentMissions[index].currentAmount += amount
                if currentMissions[index].currentAmount > currentMissions[index].targetAmount {
                    currentMissions[index].currentAmount = currentMissions[index].targetAmount
                }
                modified = true
            }
        }
        if modified {
            saveMissions()
        }
    }
    
    func claimReward(for missionID: String) -> Int {
        if let index = currentMissions.firstIndex(where: { $0.id == missionID }) {
            if currentMissions[index].isComplete && !currentMissions[index].isClaimed {
                currentMissions[index].isClaimed = true
                saveMissions()
                return currentMissions[index].reward
            }
        }
        return 0
    }
    
    var hasUnclaimedRewards: Bool {
        return currentMissions.contains { $0.isComplete && !$0.isClaimed }
    }
}
