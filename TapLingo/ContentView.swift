import SwiftUI
import AudioToolbox
import AVFoundation

private struct QuestionProgress: Codable {
    var correctCount = 0
    var wrongCount = 0
}

private struct DailyStudy: Codable {
    var answered = 0
    var correct = 0
}

private struct QuizStats: Codable {
    var dateKey = QuizStats.todayKey()
    var todayAnswered = 0
    var todayCorrect = 0
    var currentStreak = 0
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
    }

    var accuracy: Int {
        guard todayAnswered > 0 else { return 0 }
        return Int((Double(todayCorrect) / Double(todayAnswered) * 100).rounded())
    }

    var weakQuestionCount: Int {
        progressByQuestionID.values.filter { $0.wrongCount > $0.correctCount }.count
    }

    var currentMonthStudyDays: Int {
        let monthPrefix = String(QuizStats.todayKey().prefix(7))
        return dailyHistory.filter { key, value in
            key.hasPrefix(monthPrefix) && value.answered > 0
        }.count
    }

    var currentMonthAnswered: Int {
        let monthPrefix = String(QuizStats.todayKey().prefix(7))
        return dailyHistory.reduce(0) { total, entry in
            guard entry.key.hasPrefix(monthPrefix) else { return total }
            return total + entry.value.answered
        }
    }

    var studyDayStreak: Int {
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())

        while true {
            let key = QuizStats.dayKey(for: day)
            guard (dailyHistory[key]?.answered ?? 0) > 0 else { break }
            streak += 1
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }

        return streak
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
        let key = String(questionID)
        var progress = progressByQuestionID[key] ?? QuestionProgress()
        if isCorrect { progress.correctCount += 1 } else { progress.wrongCount += 1 }
        progressByQuestionID[key] = progress

        var dailyStudy = dailyHistory[dateKey] ?? DailyStudy()
        dailyStudy.answered += 1
        if isCorrect {
            dailyStudy.correct += 1
        }
        dailyHistory[dateKey] = dailyStudy
    }

    mutating func resetIfNeeded() {
        preserveCurrentDayIfNeeded()
        let today = QuizStats.todayKey()
        guard dateKey != today else { return }
        dateKey = today
        todayAnswered = 0
        todayCorrect = 0
        currentStreak = 0
    }

    private mutating func preserveCurrentDayIfNeeded() {
        guard todayAnswered > 0 else { return }
        let existing = dailyHistory[dateKey]
        guard existing == nil || existing?.answered == 0 else { return }
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
}

private enum StatsStore {
    private static let key = "quizStats"

    static func load() -> QuizStats {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            var stats = try? JSONDecoder().decode(QuizStats.self, from: data)
        else { return QuizStats() }
        stats.resetIfNeeded()
        return stats
    }

    static func save(_ stats: QuizStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Main View

struct ContentView: View {
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedIndex: Int? = nil
    @State private var showAnswer = false
    @State private var isQuizActive = false
    @State private var stats = StatsStore.load()
    @State private var correctAudioPlayer: AVAudioPlayer? = nil
    @State private var resultScale: CGFloat = 0.8
    @State private var resultOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if isQuizActive {
                quizView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                HomeView(
                    stats: stats,
                    questionCount: questions.count,
                    startAction: startQuiz
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.24), value: isQuizActive)
        .onAppear {
            loadQuestions()
            stats.resetIfNeeded()
            StatsStore.save(stats)
            prepareCorrectSound()
        }
    }

    var quizView: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 16) {
                    statsRow

                    if questions.isEmpty {
                        emptyStateView
                    } else {
                        let q = questions[currentIndex]
                        questionCard(q)
                        choicesView(q)
                        if showAnswer {
                            resultCard(q)
                                .scaleEffect(resultScale)
                                .opacity(resultOpacity)
                                .onAppear {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        resultScale = 1.0
                                        resultOpacity = 1
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: Header

    var headerView: some View {
        HStack(alignment: .center) {
            Button {
                isQuizActive = false
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.indigo)
                    .frame(width: 36, height: 36)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("ホーム")

            VStack(alignment: .leading, spacing: 2) {
                Text("TapLingo")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.34, blue: 0.95), Color(red: 0.65, green: 0.35, blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                Text("今日も一緒に学ぼう")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if !questions.isEmpty {
                HStack(spacing: 4) {
                    Text("\(currentIndex + 1)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.indigo)
                    Text("/ \(questions.count)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.indigo.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: Stats Row

    var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(icon: "checkmark.circle.fill", value: "\(stats.todayAnswered)", label: "今日", color: .blue)
            StatPill(icon: "scope",                value: "\(stats.accuracy)%",      label: "正確率", color: .green)
            StatPill(icon: "flame.fill",           value: "\(stats.currentStreak)",  label: "連続",   color: .orange)
            StatPill(icon: "bolt.fill",            value: "\(stats.weakQuestionCount)", label: "苦手", color: .red)
        }
    }

    // MARK: Question Card

    func questionCard(_ q: Question) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label("問題", systemImage: "questionmark.bubble.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
            }

            Text(q.text)
                .font(.system(size: 22, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: Choices

    func choicesView(_ q: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { offset, choice in
                ChoiceButton(
                    label: String(UnicodeScalar(65 + offset)!),
                    text: choice,
                    state: choiceState(offset, q: q)
                ) {
                    answer(offset, question: q)
                }
                .disabled(showAnswer)
            }
        }
    }

    func choiceState(_ i: Int, q: Question) -> ChoiceState {
        guard showAnswer else { return .idle }
        if i == q.correctIndex { return .correct }
        if i == selectedIndex  { return .wrong }
        return .dim
    }

    // MARK: Result Card

    func resultCard(_ q: Question) -> some View {
        let isCorrect = selectedIndex == q.correctIndex
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isCorrect ? .green : .red)
                Text(isCorrect ? "正解！素晴らしい 🎉" : "不正解…次は頑張ろう")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isCorrect ? .green : .red)
            }

            if !q.explanation.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("解説", systemImage: "lightbulb.max.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text(q.explanation)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }

            Button(action: next) {
                HStack(spacing: 6) {
                    Text("次の問題へ")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.34, blue: 0.95), Color(red: 0.65, green: 0.35, blue: 0.95)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: Empty State

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text("問題がありません")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: Logic

    func loadQuestions() {
        questions = DBManager.shared.fetch().shuffled()
        currentIndex = 0
        selectedIndex = nil
        showAnswer = false
    }

    func startQuiz() {
        if questions.isEmpty {
            loadQuestions()
        }
        guard !questions.isEmpty else { return }
        selectedIndex = nil
        showAnswer = false
        isQuizActive = true
    }

    func answer(_ index: Int, question: Question) {
        guard !showAnswer else { return }
        selectedIndex = index
        showAnswer = true
        resultScale = 0.8
        resultOpacity = 0
        let isCorrect = index == question.correctIndex
        stats.record(questionID: question.id, isCorrect: isCorrect)
        StatsStore.save(stats)
        playAnswerSound(isCorrect: isCorrect)
    }

    func next() {
        guard !questions.isEmpty else { return }
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            questions.shuffle()
            currentIndex = 0
        }
        selectedIndex = nil
        showAnswer = false
    }

    func prepareCorrectSound() {
        guard let url = Bundle.main.url(forResource: "クイズ正解2", withExtension: "mp3") else { return }
        correctAudioPlayer = try? AVAudioPlayer(contentsOf: url)
        correctAudioPlayer?.prepareToPlay()
    }

    func playAnswerSound(isCorrect: Bool) {
        if isCorrect {
            correctAudioPlayer?.currentTime = 0
            correctAudioPlayer?.play()
        } else {
            AudioServicesPlaySystemSound(1053)
        }
    }
}

// MARK: - Supporting Views

private struct HomeView: View {
    let stats: QuizStats
    let questionCount: Int
    let startAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                heroView
                progressView
                StreakBonusView(streak: stats.studyDayStreak)
                StudyCalendarView(stats: stats)
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 36)
            .padding(.bottom, 48)
        }
    }

    var heroView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.34, blue: 0.95), Color(red: 0.65, green: 0.35, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(stats.studyDayStreak)日連続")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    Text("\(questionCount)問")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("TapLingo")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("英語フレーズをテンポよく覚える")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 5)
    }

    var progressView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今日の進捗")
                .font(.system(size: 18, weight: .bold))

            HStack(spacing: 10) {
                StatPill(icon: "checkmark.circle.fill", value: "\(stats.todayAnswered)", label: "回答", color: .blue)
                StatPill(icon: "scope", value: "\(stats.accuracy)%", label: "正確率", color: .green)
            }

            HStack(spacing: 10) {
                StatPill(icon: "calendar", value: "\(stats.currentMonthStudyDays)", label: "今月", color: .purple)
                StatPill(icon: "bolt.fill", value: "\(stats.weakQuestionCount)", label: "苦手", color: .red)
            }
        }
    }

    var startButton: some View {
        Button(action: startAction) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(questionCount == 0 ? "問題がありません" : "クイズを始める")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: questionCount == 0
                        ? [Color.gray.opacity(0.55), Color.gray.opacity(0.45)]
                        : [Color(red: 0.35, green: 0.34, blue: 0.95), Color(red: 0.65, green: 0.35, blue: 0.95)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: questionCount == 0 ? .clear : .indigo.opacity(0.28), radius: 10, x: 0, y: 5)
        }
        .disabled(questionCount == 0)
    }
}

private struct StreakBonusView: View {
    let streak: Int

    private let milestones = [
        StreakMilestone(days: 3, title: "3日", icon: "sparkles", color: Color.orange),
        StreakMilestone(days: 7, title: "7日", icon: "flame.fill", color: Color.red),
        StreakMilestone(days: 14, title: "14日", icon: "crown.fill", color: Color.purple)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("連続学習ボーナス")
                        .font(.system(size: 18, weight: .bold))
                    Text(nextGoalText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Label("\(streak)日", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                ForEach(milestones) { milestone in
                    StreakBadge(milestone: milestone, isUnlocked: streak >= milestone.days)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    var nextGoalText: String {
        guard let next = milestones.first(where: { streak < $0.days }) else {
            return "すべてのバッジを達成中"
        }

        return "あと\(next.days - streak)日で\(next.title)バッジ"
    }
}

private struct StreakMilestone: Identifiable {
    let days: Int
    let title: String
    let icon: String
    let color: Color

    var id: Int { days }
}

private struct StreakBadge: View {
    let milestone: StreakMilestone
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? milestone.color.opacity(0.16) : Color(.secondarySystemBackground))
                    .frame(width: 48, height: 48)
                Image(systemName: milestone.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isUnlocked ? milestone.color : .secondary.opacity(0.45))
            }

            Text(milestone.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? .primary : .secondary)
            Text(isUnlocked ? "達成" : "未達成")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isUnlocked ? milestone.color : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isUnlocked ? milestone.color.opacity(0.08) : Color(.secondarySystemBackground).opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isUnlocked ? milestone.color.opacity(0.28) : Color.clear, lineWidth: 1)
        )
        .accessibilityLabel("\(milestone.title)連続学習バッジ、\(isUnlocked ? "達成" : "未達成")")
    }
}

private struct StudyCalendarView: View {
    let stats: QuizStats

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("学習カレンダー")
                        .font(.system(size: 18, weight: .bold))
                    Text(monthTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Label("\(stats.currentMonthAnswered)問", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    calendarCell(for: date)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
    }

    var monthCells: [Date?] {
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard
            let firstDay = calendar.date(from: components),
            let dayRange = calendar.range(of: .day, in: .month, for: firstDay)
        else {
            return []
        }

        let leadingEmptyCount = calendar.component(.weekday, from: firstDay) - 1
        let dates = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }

        return Array(repeating: nil, count: leadingEmptyCount) + dates
    }

    @ViewBuilder
    func calendarCell(for date: Date?) -> some View {
        if let date {
            let key = QuizStats.dayKey(for: date)
            let answered = stats.dailyHistory[key]?.answered ?? 0
            let isToday = calendar.isDateInToday(date)

            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12, weight: isToday ? .bold : .semibold, design: .rounded))
                .foregroundColor(answered > 0 ? .white : (isToday ? .indigo : .secondary))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(calendarColor(answered: answered))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.indigo : Color.clear, lineWidth: 2)
                )
                .accessibilityLabel(accessibilityLabel(for: date, answered: answered))
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    func calendarColor(answered: Int) -> Color {
        switch answered {
        case 50...:
            return Color(red: 0.02, green: 0.46, blue: 0.2)
        case 20...:
            return Color(red: 0.08, green: 0.63, blue: 0.3)
        case 10...:
            return Color(red: 0.18, green: 0.78, blue: 0.39)
        case 1...:
            return Color(red: 0.56, green: 0.86, blue: 0.64)
        default:
            return Color(.secondarySystemBackground)
        }
    }

    func accessibilityLabel(for date: Date, answered: Int) -> String {
        let day = calendar.component(.day, from: date)
        if answered > 0 {
            return "\(day)日、\(answered)問学習"
        }
        return "\(day)日、未学習"
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

enum ChoiceState { case idle, correct, wrong, dim }

struct ChoiceButton: View {
    let label: String
    let text: String
    let state: ChoiceState
    let action: () -> Void

    private var accentColor: Color {
        switch state {
        case .idle:    return .indigo
        case .correct: return .green
        case .wrong:   return .red
        case .dim:     return Color(.systemGray3)
        }
    }

    private var isFilled: Bool { state == .correct || state == .wrong }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isFilled ? .white : accentColor)
                    .frame(width: 30, height: 30)
                    .background(isFilled ? accentColor : accentColor.opacity(0.12))
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isFilled ? .white : (state == .dim ? .secondary : .primary))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isFilled ? accentColor : Color(.systemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFilled ? Color.clear : accentColor.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: isFilled ? accentColor.opacity(0.25) : .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .animation(.easeOut(duration: 0.2), value: state)
    }
}

#Preview {
    ContentView()
}
