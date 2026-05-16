import Foundation

enum AchievementStore {
    private static let key = "shownStreakAchievements"

    static func loadShownDays() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: key) as? [Int] ?? [])
    }

    static func markShown(_ days: Int) {
        var shown = loadShownDays()
        shown.insert(days)
        UserDefaults.standard.set(Array(shown), forKey: key)
    }
}
