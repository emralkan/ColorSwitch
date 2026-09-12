import Foundation

/// İlerlemeyi veri kaybını önleyen birleştirme kurallarıyla iCloud'a eşitler.
final class ICloudSyncManager {
    static let shared = ICloudSyncManager()

    private let store = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private let syncedKeys = [
        "HighScore",
        "TotalCoins",
        "UnlockedSkins",
        "EquippedSkin",
        "SoundEnabled",
        "HapticsEnabled",
        "SelectedBackground",
        "HighestUnlockedChallengeLevel",
        "HasRemovedAds"
    ]

    private var started = false

    private init() {}

    func startSync() {
        guard !started else { return }
        started = true

        migrateLegacySkinIDs()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )

        store.synchronize()
        pullFromCloud()
        pushToCloud()
    }

    func pushValue(_ value: Any?, forKey key: String) {
        guard syncedKeys.contains(key) else { return }

        if let array = value as? [String] {
            store.set(array, forKey: key)
        } else if let string = value as? String {
            store.set(string, forKey: key)
        } else if let intValue = value as? Int {
            store.set(intValue, forKey: key)
        } else if let boolValue = value as? Bool {
            store.set(boolValue, forKey: key)
        }

        if settingsKeys.contains(key) {
            let tsKey = "\(key)__ts"
            let ts = Date().timeIntervalSince1970
            store.set(ts, forKey: tsKey)
            defaults.set(ts, forKey: tsKey)
        }

        store.synchronize()
    }

    @objc private func handleExternalChange(_ notification: Notification) {
        pullFromCloud()
    }

    private let maxMergeKeys: Set<String> = ["HighScore", "TotalCoins", "HighestUnlockedChallengeLevel"]
    private let boolOrMergeKeys: Set<String> = ["HasRemovedAds"]
    private let settingsKeys: Set<String> = ["EquippedSkin", "SelectedBackground", "SoundEnabled", "HapticsEnabled"]

    private func pullFromCloud() {
        for key in syncedKeys {
            guard let value = store.object(forKey: key) else { continue }

            if key == "UnlockedSkins", let array = value as? [String] {
                let localSkins = Set(defaults.stringArray(forKey: key) ?? ["circle"])
                let remoteSkins = Set(array.map(normalizeSkinID))
                let merged = Array(localSkins.union(remoteSkins)).sorted()
                defaults.set(merged, forKey: key)
            } else if boolOrMergeKeys.contains(key), let remoteBool = value as? Bool {
                let localBool = defaults.bool(forKey: key)
                let winner = localBool || remoteBool
                defaults.set(winner, forKey: key)
                if winner != remoteBool {
                    store.set(winner, forKey: key)
                }
            } else if key == "EquippedSkin", let string = value as? String {
                let remoteValue = normalizeSkinID(string)
                if remoteTimestampIsNewer(forKey: key) {
                    defaults.set(remoteValue, forKey: key)
                    syncTimestampToLocal(forKey: key)
                } else {
                    pushLocalSettingBack(forKey: key)
                }
            } else if settingsKeys.contains(key) {
                if remoteTimestampIsNewer(forKey: key) {
                    defaults.set(value, forKey: key)
                    syncTimestampToLocal(forKey: key)
                } else {
                    pushLocalSettingBack(forKey: key)
                }
            } else if maxMergeKeys.contains(key), let remoteInt = value as? Int {
                let localInt = defaults.integer(forKey: key)
                let winner = max(localInt, remoteInt)
                defaults.set(winner, forKey: key)
                if winner != remoteInt {
                    store.set(winner, forKey: key)
                }
            } else {
                defaults.set(value, forKey: key)
            }
        }
    }

    private func remoteTimestampIsNewer(forKey key: String) -> Bool {
        let tsKey = "\(key)__ts"
        guard let remoteTS = store.object(forKey: tsKey) as? Double else {
            return defaults.object(forKey: tsKey) == nil
        }
        guard let localTS = defaults.object(forKey: tsKey) as? Double else {
            return true
        }
        return remoteTS > localTS
    }

    private func syncTimestampToLocal(forKey key: String) {
        let tsKey = "\(key)__ts"
        if let remoteTS = store.object(forKey: tsKey) as? Double {
            defaults.set(remoteTS, forKey: tsKey)
        }
    }

    private func pushLocalSettingBack(forKey key: String) {
        if key == "EquippedSkin" {
            store.set(normalizeSkinID(defaults.string(forKey: key) ?? "circle"), forKey: key)
        } else if let localValue = defaults.object(forKey: key) {
            store.set(localValue, forKey: key)
        }
        let tsKey = "\(key)__ts"
        if let localTS = defaults.object(forKey: tsKey) as? Double {
            store.set(localTS, forKey: tsKey)
        }
    }

    private func pushToCloud() {
        for key in syncedKeys {
            if key == "UnlockedSkins" {
                let array = (defaults.stringArray(forKey: key) ?? ["circle"]).map(normalizeSkinID)
                store.set(Array(Set(array)).sorted(), forKey: key)
            } else if key == "EquippedSkin" {
                store.set(normalizeSkinID(defaults.string(forKey: key) ?? "circle"), forKey: key)
            } else if let value = defaults.object(forKey: key) {
                store.set(value, forKey: key)
            }

            if settingsKeys.contains(key) {
                let tsKey = "\(key)__ts"
                if let localTS = defaults.object(forKey: tsKey) as? Double {
                    store.set(localTS, forKey: tsKey)
                }
            }
        }

        store.synchronize()
    }

    private func migrateLegacySkinIDs() {
        let unlocked = (defaults.stringArray(forKey: "UnlockedSkins") ?? ["circle"]).map(normalizeSkinID)
        defaults.set(Array(Set(unlocked)).sorted(), forKey: "UnlockedSkins")
        defaults.set(normalizeSkinID(defaults.string(forKey: "EquippedSkin") ?? "circle"), forKey: "EquippedSkin")
    }

    private func normalizeSkinID(_ id: String) -> String {
        switch id {
        case "boss_crown": return "royal"
        case "boss_flame": return "blaze"
        case "boss_chromatic": return "prism"
        default: return id
        }
    }
}
