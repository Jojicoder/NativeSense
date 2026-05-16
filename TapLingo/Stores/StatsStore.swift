import Foundation

enum StatsStore {
    private static let key = "quizStats"

    static func load() -> QuizStats {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(QuizStats.self, from: data) else {
            return QuizStats()
        }
        return stats
    }

    static func save(_ stats: QuizStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
