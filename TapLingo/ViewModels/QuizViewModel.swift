import AudioToolbox
import AVFoundation
import Combine
import SwiftUI

@MainActor
final class QuizViewModel: ObservableObject {
    // Full pool loaded from DB (never filtered)
    @Published var allQuestions: [Question] = []
    // Active quiz session pool (filtered + shuffled)
    @Published var questions: [Question] = []
    @Published var currentIndex = 0
    @Published var selectedIndex: Int? = nil
    @Published var showAnswer = false
    @Published var isQuizActive = false
    @Published var isTimeAttackActive = false
    @Published var isReviewQuiz = false
    @Published var stats = StatsStore.load()
    @Published var pendingAchievementDays: Int? = nil
    @Published var timeAttackQuestions: [Question] = []
    @Published var timeAttackIndex = 0
    @Published var timeRemaining = 60
    @Published var timeAttackScore = 0
    @Published var timeAttackAnswered = 0
    @Published var timeAttackFinished = false
    @Published var bestTimeAttackScore = TimeAttackStore.loadBestScore()
    @Published var filter = QuizFilter()

    let timeAttackDuration = 60

    private let streakMilestoneDays = [3, 7, 14]
    private var correctAudioPlayer: AVAudioPlayer?
    private var incorrectAudioPlayer: AVAudioPlayer?
    private var hasAppeared = false

    var currentQuestion: Question? {
        guard !questions.isEmpty, questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var currentTimeAttackQuestion: Question? {
        guard !timeAttackQuestions.isEmpty, timeAttackQuestions.indices.contains(timeAttackIndex) else { return nil }
        return timeAttackQuestions[timeAttackIndex]
    }

    var filteredCount: Int {
        allQuestions.filter { filter.matches($0) }.count
    }

    var reviewSummary: ReviewSummary {
        stats.reviewSummary
    }

    var availableTypes: [String] {
        Array(Set(allQuestions.map { $0.questionType }))
            .filter { !$0.isEmpty }
            .sorted()
    }

    func onAppear() {
        stats.resetIfNeeded()
        StatsStore.save(stats)
        updatePendingAchievement()

        guard !hasAppeared else { return }
        hasAppeared = true
        loadQuestions()
        prepareAnswerSounds()
    }

    func loadQuestions() {
        allQuestions = DBManager.shared.fetch()
        questions = allQuestions.shuffled().map { $0.withShuffledChoices() }
    }

    func startQuiz() {
        let pool = allQuestions.filter { filter.matches($0) }
        questions = prioritizedQuestions(from: pool.isEmpty ? allQuestions : pool)
            .map { $0.withShuffledChoices() }
        currentIndex = 0
        selectedIndex = nil
        showAnswer = false
        isReviewQuiz = false
        isTimeAttackActive = false
        isQuizActive = true
    }

    func startReviewQuiz() {
        let reviewQuestions = allQuestions
            .filter { question in
                stats.reviewBucket(for: stats.progressByQuestionID[String(question.id)] ?? QuestionProgress()) != nil
            }

        questions = prioritizedQuestions(from: reviewQuestions.isEmpty ? allQuestions : reviewQuestions)
            .map { $0.withShuffledChoices() }
        currentIndex = 0
        selectedIndex = nil
        showAnswer = false
        isReviewQuiz = true
        isTimeAttackActive = false
        isQuizActive = true
    }

    func startTimeAttack() {
        if allQuestions.isEmpty { loadQuestions() }
        timeAttackQuestions = allQuestions.shuffled().map { $0.withShuffledChoices() }
        timeAttackIndex = 0
        timeRemaining = timeAttackDuration
        timeAttackScore = 0
        timeAttackAnswered = 0
        timeAttackFinished = false
        selectedIndex = nil
        showAnswer = false
        isReviewQuiz = false
        isQuizActive = false
        isTimeAttackActive = true
    }

    func tickTimeAttack() {
        guard isTimeAttackActive, !timeAttackFinished else { return }
        if timeRemaining > 0 { timeRemaining -= 1 }
        if timeRemaining == 0 { finishTimeAttack() }
    }

    func answerTimeAttack(_ index: Int, question: Question) {
        guard !timeAttackFinished else { return }
        let isCorrect = index == question.correctIndex
        stats.record(questionID: question.id, isCorrect: isCorrect)
        StatsStore.save(stats)
        timeAttackAnswered += 1
        if isCorrect { timeAttackScore += 1 }
        playAnswerSound(isCorrect: isCorrect)
        advanceTimeAttackQuestion()
    }

    func advanceTimeAttackQuestion() {
        if timeAttackIndex + 1 < timeAttackQuestions.count {
            timeAttackIndex += 1
        } else {
            timeAttackQuestions = allQuestions.shuffled().map { $0.withShuffledChoices() }
            timeAttackIndex = 0
        }
    }

    func finishTimeAttack() {
        guard !timeAttackFinished else { return }
        timeAttackFinished = true
        if timeAttackScore > bestTimeAttackScore {
            bestTimeAttackScore = timeAttackScore
            TimeAttackStore.saveBestScore(timeAttackScore)
        }
        updatePendingAchievement()
    }

    func goHome() {
        isQuizActive = false
        isTimeAttackActive = false
        isReviewQuiz = false
        selectedIndex = nil
        showAnswer = false
        stats.resetIfNeeded()
        StatsStore.save(stats)
        updatePendingAchievement()
    }

    func updatePendingAchievement() {
        let shown = AchievementStore.loadShownDays()
        pendingAchievementDays = streakMilestoneDays
            .filter { stats.studyDayStreak >= $0 && !shown.contains($0) }
            .max()
    }

    func dismissAchievement() {
        guard let pendingAchievementDays else { return }
        AchievementStore.markShown(pendingAchievementDays)
        updatePendingAchievement()
    }

    func answer(_ index: Int, question: Question) {
        guard selectedIndex == nil else { return }
        selectedIndex = index
        showAnswer = true

        let isCorrect = index == question.correctIndex
        stats.record(questionID: question.id, isCorrect: isCorrect)
        StatsStore.save(stats)
        updatePendingAchievement()
        playAnswerSound(isCorrect: isCorrect)
    }

    func next() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            questions = questions.shuffled().map { $0.withShuffledChoices() }
            currentIndex = 0
        }
        selectedIndex = nil
        showAnswer = false
    }

    func choiceState(for index: Int, question: Question) -> ChoiceState {
        guard let selectedIndex else { return .idle }
        if index == question.correctIndex { return .correct }
        if index == selectedIndex { return .wrong }
        return .dim
    }

    private func prepareAnswerSounds() {
        correctAudioPlayer = makeAudioPlayer(resource: "クイズ正解2", extension: "mp3")
        incorrectAudioPlayer = makeAudioPlayer(resource: "incorrect", extension: "wav")
    }

    private func prioritizedQuestions(from pool: [Question]) -> [Question] {
        pool.shuffled().sorted { first, second in
            reviewPriority(for: first) > reviewPriority(for: second)
        }
    }

    private func reviewPriority(for question: Question) -> Int {
        let progress = stats.progressByQuestionID[String(question.id)] ?? QuestionProgress()
        guard let bucket = stats.reviewBucket(for: progress) else {
            return progress.answered >= 2 && progress.accuracy < 0.7 ? 1 : 0
        }
        return bucket.priority + 1
    }

    private func playAnswerSound(isCorrect: Bool) {
        if isCorrect, let correctAudioPlayer {
            correctAudioPlayer.currentTime = 0
            correctAudioPlayer.play()
        } else if !isCorrect, let incorrectAudioPlayer {
            incorrectAudioPlayer.currentTime = 0
            incorrectAudioPlayer.play()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func makeAudioPlayer(resource: String, extension fileExtension: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
}
