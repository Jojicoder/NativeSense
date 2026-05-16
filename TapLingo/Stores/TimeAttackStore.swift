import Foundation

enum TimeAttackStore {
    private static let key = "bestTimeAttackScore"

    static func loadBestScore() -> Int {
        UserDefaults.standard.integer(forKey: key)
    }

    static func saveBestScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: key)
    }
}
