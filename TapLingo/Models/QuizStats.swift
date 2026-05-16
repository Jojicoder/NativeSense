import Foundation

struct QuestionProgress: Codable {
    var answered: Int = 0
    var correct: Int = 0
    var lastAnsweredDateKey: String?
    var lastWrongDateKey: String?

    private enum CodingKeys: String, CodingKey {
        case answered
        case correct
        case lastAnsweredDateKey
        case lastWrongDateKey
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answered = try container.decodeIfPresent(Int.self, forKey: .answered) ?? 0
        correct = try container.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        lastAnsweredDateKey = try container.decodeIfPresent(String.self, forKey: .lastAnsweredDateKey)
        lastWrongDateKey = try container.decodeIfPresent(String.self, forKey: .lastWrongDateKey)
    }

    var accuracy: Double {
        guard answered > 0 else { return 0 }
        return Double(correct) / Double(answered)
    }
}

struct DailyStudy: Codable {
    var answered: Int = 0
    var correct: Int = 0
}

struct QuizStats: Codable {
    var dateKey: String = QuizStats.todayKey()
    var todayAnswered: Int = 0
    var todayCorrect: Int = 0
    var currentStreak: Int = 0
    var dailyHistory: [String: DailyStudy] = [:]
    var progressByQuestionID: [String: QuestionProgress] = [:]

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case todayAnswered
        case todayCorrect
        case currentStreak
        case dailyHistory
        case progressByQuestionID
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateKey = try container.decodeIfPresent(String.self, forKey: .dateKey) ?? QuizStats.todayKey()
        todayAnswered = try container.decodeIfPresent(Int.self, forKey: .todayAnswered) ?? 0
        todayCorrect = try container.decodeIfPresent(Int.self, forKey: .todayCorrect) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        dailyHistory = try container.decodeIfPresent([String: DailyStudy].self, forKey: .dailyHistory) ?? [:]
        progressByQuestionID = try container.decodeIfPresent([String: QuestionProgress].self, forKey: .progressByQuestionID) ?? [:]
        preserveCurrentDayIfNeeded()
    }

    var accuracy: Int {
        guard todayAnswered > 0 else { return 0 }
        return Int((Double(todayCorrect) / Double(todayAnswered) * 100).rounded())
    }

    var weakQuestionCount: Int {
        progressByQuestionID.values.filter { $0.answered >= 2 && $0.accuracy < 0.7 }.count
    }

    var currentMonthStudyDays: Int {
        let prefix = String(dateKey.prefix(7))
        return dailyHistory.filter { key, value in
            key.hasPrefix(prefix) && value.answered > 0
        }.count
    }

    var currentMonthAnswered: Int {
        let prefix = String(dateKey.prefix(7))
        return dailyHistory.reduce(0) { partialResult, item in
            item.key.hasPrefix(prefix) ? partialResult + item.value.answered : partialResult
        }
    }

    var studyDayStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date()

        while true {
            let key = QuizStats.dayKey(for: date)
            guard (dailyHistory[key]?.answered ?? 0) > 0 else { break }
            streak += 1

            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDate
        }

        return streak
    }

    var reviewSummary: ReviewSummary {
        progressByQuestionID.values.reduce(into: ReviewSummary()) { summary, progress in
            guard let bucket = reviewBucket(for: progress) else { return }
            summary.add(bucket)
        }
    }

    func reviewBucket(for progress: QuestionProgress, today: Date = Date()) -> ReviewBucket? {
        guard let lastWrongDateKey = progress.lastWrongDateKey,
              let lastWrongDate = QuizStats.date(from: lastWrongDateKey) else {
            return nil
        }

        let daysSinceWrong = Calendar.current.dateComponents([.day], from: lastWrongDate, to: today).day ?? 0
        switch daysSinceWrong {
        case 7...:
            return .sevenDays
        case 3...:
            return .threeDays
        case 1...:
            return .oneDay
        default:
            return .today
        }
    }

    mutating func record(questionID: Int64, isCorrect: Bool) {
        resetIfNeeded()
        todayAnswered += 1
        if isCorrect {
            todayCorrect += 1
            currentStreak += 1
        } else {
            currentStreak = 0
        }

        let id = String(questionID)
        var progress = progressByQuestionID[id] ?? QuestionProgress()
        progress.answered += 1
        progress.lastAnsweredDateKey = dateKey
        if isCorrect {
            progress.correct += 1
        } else {
            progress.lastWrongDateKey = dateKey
        }
        progressByQuestionID[id] = progress

        var daily = dailyHistory[dateKey] ?? DailyStudy()
        daily.answered += 1
        if isCorrect {
            daily.correct += 1
        }
        dailyHistory[dateKey] = daily
    }

    mutating func resetIfNeeded() {
        let today = QuizStats.todayKey()
        guard dateKey != today else {
            preserveCurrentDayIfNeeded()
            return
        }

        preserveCurrentDayIfNeeded()
        dateKey = today
        todayAnswered = dailyHistory[today]?.answered ?? 0
        todayCorrect = dailyHistory[today]?.correct ?? 0
        currentStreak = 0
    }

    private mutating func preserveCurrentDayIfNeeded() {
        guard todayAnswered > 0 || todayCorrect > 0 else { return }
        dailyHistory[dateKey] = DailyStudy(answered: todayAnswered, correct: todayCorrect)
    }

    static func todayKey() -> String {
        dayKey(for: Date())
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

enum ReviewBucket {
    case today
    case oneDay
    case threeDays
    case sevenDays

    var priority: Int {
        switch self {
        case .sevenDays:  return 4
        case .threeDays:  return 3
        case .oneDay:     return 2
        case .today:      return 1
        }
    }
}

struct ReviewSummary {
    var today = 0
    var oneDay = 0
    var threeDays = 0
    var sevenDays = 0

    var total: Int {
        today + oneDay + threeDays + sevenDays
    }

    mutating func add(_ bucket: ReviewBucket) {
        switch bucket {
        case .today:
            today += 1
        case .oneDay:
            oneDay += 1
        case .threeDays:
            threeDays += 1
        case .sevenDays:
            sevenDays += 1
        }
    }
}
