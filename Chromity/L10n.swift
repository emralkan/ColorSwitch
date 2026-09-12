import Foundation

struct L10n {
    static func highScore(_ n: Int) -> String { String(format: NSLocalizedString("HIGH_SCORE", comment: ""), n) }
    static let tapToPlay = NSLocalizedString("TAP_TO_PLAY", comment: "")
    static let jokerMode = NSLocalizedString("JOKER_MODE", comment: "")
    
    static let gameOver = NSLocalizedString("GAME_OVER", comment: "")
    static func score(_ n: Int) -> String { String(format: NSLocalizedString("SCORE", comment: ""), n) }
    static func best(_ n: Int) -> String { String(format: NSLocalizedString("BEST", comment: ""), n) }
    static let playAgain = NSLocalizedString("PLAY_AGAIN", comment: "")
    static let shareScore = NSLocalizedString("SHARE_SCORE", comment: "")
    static func continueCost(_ n: Int) -> String { String(format: NSLocalizedString("CONTINUE_COST", comment: ""), n) }
    static let watchAdContinue = NSLocalizedString("WATCH_AD_CONTINUE", comment: "")
    static let newBest = NSLocalizedString("NEW_BEST", comment: "")
    static func shareText(_ score: String) -> String { String(format: NSLocalizedString("SHARE_TEXT", comment: ""), score) }
    static let adNotAvailable = NSLocalizedString("AD_NOT_AVAILABLE", comment: "")
    
    static let settings = NSLocalizedString("SETTINGS", comment: "")
    static let privacyPolicy = NSLocalizedString("PRIVACY_POLICY", comment: "")
    static let contactUs = NSLocalizedString("CONTACT_US", comment: "")
    static let hapticsOn = NSLocalizedString("HAPTICS_ON", comment: "")
    static let hapticsOff = NSLocalizedString("HAPTICS_OFF", comment: "")
    static let soundOn = NSLocalizedString("SOUND_ON", comment: "")
    static let soundOff = NSLocalizedString("SOUND_OFF", comment: "")
    
    static let store = NSLocalizedString("STORE", comment: "")
    static let shapes = NSLocalizedString("SHAPES", comment: "")
    static let physics = NSLocalizedString("PHYSICS", comment: "")
    static let freeStars = NSLocalizedString("FREE_STARS", comment: "")
    static let equipped = NSLocalizedString("EQUIPPED", comment: "")
    static let owned = NSLocalizedString("OWNED", comment: "")
    static let watchAd = NSLocalizedString("WATCH_AD", comment: "")
    static let watchAdUnlock = NSLocalizedString("WATCH_AD_UNLOCK", comment: "")
    static let watch = NSLocalizedString("WATCH", comment: "")
    static let close = NSLocalizedString("CLOSE", comment: "")
    static let buy = NSLocalizedString("BUY", comment: "")
    static let needCoins = NSLocalizedString("NEED_COINS", comment: "")
    static let notEnoughStars = NSLocalizedString("NOT_ENOUGH_STARS", comment: "")
    
    static let paused = NSLocalizedString("PAUSED", comment: "")
    static let resume = NSLocalizedString("RESUME", comment: "")
    static let quit = NSLocalizedString("QUIT", comment: "")
    static let areYouSure = NSLocalizedString("ARE_YOU_SURE", comment: "")
    static let yes = NSLocalizedString("YES", comment: "")
    static let no = NSLocalizedString("NO", comment: "")
    
    static let backgrounds = NSLocalizedString("BACKGROUNDS", comment: "")
    static let customPhoto = NSLocalizedString("CUSTOM_PHOTO", comment: "")
    
    static let colorMatching = NSLocalizedString("COLOR_MATCHING", comment: "")
    static let matchJumpSurvive = NSLocalizedString("MATCH_JUMP_SURVIVE", comment: "")
    static let howToPlay = NSLocalizedString("HOW_TO_PLAY", comment: "")
    static let tapToJump = NSLocalizedString("TAP_TO_JUMP", comment: "")
    static let tapScreenToJump = NSLocalizedString("TAP_SCREEN_TO_JUMP", comment: "")
    static let matchColors = NSLocalizedString("MATCH_COLORS", comment: "")
    static let passThroughColor = NSLocalizedString("PASS_THROUGH_COLOR", comment: "")
    static let collectStars = NSLocalizedString("COLLECT_STARS", comment: "")
    static let useCoinsDie = NSLocalizedString("USE_COINS_DIE", comment: "")
    static let proTips = NSLocalizedString("PRO_TIPS", comment: "")
    static let earnCoins = NSLocalizedString("EARN_COINS", comment: "")
    static let earnCoinsDesc = NSLocalizedString("EARN_COINS_DESC", comment: "")
    static let powerBar = NSLocalizedString("POWER_BAR", comment: "")
    static let fillShieldDesc = NSLocalizedString("FILL_SHIELD_DESC", comment: "")
    static let customize = NSLocalizedString("CUSTOMIZE", comment: "")
    static let unlockSkinsBg = NSLocalizedString("UNLOCK_SKINS_BG", comment: "")
    static let letsGo = NSLocalizedString("LETS_GO", comment: "")
    static let tapToContinue = NSLocalizedString("TAP_TO_CONTINUE", comment: "")
    static let tapButtonStart = NSLocalizedString("TAP_BUTTON_START", comment: "")
    
    static let dailyMissions = NSLocalizedString("DAILY_MISSIONS", comment: "")
    static let claim = NSLocalizedString("CLAIM", comment: "")
    static let challenges = NSLocalizedString("CHALLENGES", comment: "")
    static let challengeSubtitle = NSLocalizedString("CHALLENGE_SUBTITLE", comment: "")
    static func level(_ n: Int) -> String { String(format: NSLocalizedString("LEVEL_N", comment: ""), n) }
    static let complete = NSLocalizedString("COMPLETE", comment: "")
    static func reward(_ n: Int) -> String { String(format: NSLocalizedString("REWARD", comment: ""), n) }
    static let nextLevel = NSLocalizedString("NEXT_LEVEL", comment: "")
    static let mainMenu = NSLocalizedString("MAIN_MENU", comment: "")
    static func goal(_ n: Int) -> String { String(format: NSLocalizedString("GOAL", comment: ""), n) }
    static func missionPlayGames(_ n: Int) -> String { String(format: NSLocalizedString("MISSION_PLAY_GAMES", comment: ""), n) }
    static func missionCollectStars(_ n: Int) -> String { String(format: NSLocalizedString("MISSION_COLLECT_STARS", comment: ""), n) }
    static func missionReachScore(_ n: Int) -> String { String(format: NSLocalizedString("MISSION_REACH_SCORE", comment: ""), n) }
    static func missionCollectJokers(_ n: Int) -> String { String(format: NSLocalizedString("MISSION_COLLECT_JOKERS", comment: ""), n) }
    static let missionSubtitle = NSLocalizedString("MISSION_SUBTITLE", comment: "")
    static let claimed = NSLocalizedString("CLAIMED", comment: "")
    static func getReward(_ n: Int) -> String { String(format: NSLocalizedString("GET_REWARD", comment: ""), n) }
    
    static let reviveVip = NSLocalizedString("REVIVE_VIP", comment: "")
    static let vipReward = NSLocalizedString("VIP_REWARD", comment: "")
    static let vipBonusCoins = NSLocalizedString("VIP_BONUS_COINS", comment: "")
    static let vipWelcomeTitle = NSLocalizedString("VIP_WELCOME_TITLE", comment: "")
    static let vipWelcomeMsg = NSLocalizedString("VIP_WELCOME_MSG", comment: "")
    static let awesome = NSLocalizedString("AWESOME", comment: "")
    static let adsRemoved = NSLocalizedString("ADS_REMOVED", comment: "")
    static let removeAds = NSLocalizedString("REMOVE_ADS", comment: "")
    static let restorePurchases = NSLocalizedString("RESTORE_PURCHASES", comment: "")
    
    static let dailyBonusClaimed = NSLocalizedString("DAILY_BONUS_CLAIMED", comment: "")
    static func doubleCoins(_ n: Int) -> String { String(format: NSLocalizedString("DOUBLE_COINS", comment: ""), n) }

    static let updateAvailableTitle = NSLocalizedString("UPDATE_AVAILABLE_TITLE", comment: "")
    static func updateAvailableMsg(_ version: String) -> String { String(format: NSLocalizedString("UPDATE_AVAILABLE_MSG", comment: ""), version) }
    static let updateNow = NSLocalizedString("UPDATE_NOW", comment: "")
    static let later = NSLocalizedString("LATER", comment: "")
}
