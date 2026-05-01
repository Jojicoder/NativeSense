import Foundation

extension DBManager {
    // Fallback shared instance if not already present in the class.
    // If DBManager already defines `shared`, this line will cause a duplicate symbol.
    // Therefore, we DO NOT redefine it here.

    // Fetch all questions. If a real storage exists elsewhere, you can replace this with that logic.
    func fetchQuestions() -> [Question] {
        // Try to use QuestionData if available as a simple in-memory fallback
        if let questions = (try? _QuestionDataAccessor.questions()) {
            return questions
        }
        return []
    }

    // Fetch questions that were answered wrong. Fallback returns all for now.
    func fetchWrongQuestions() -> [Question] {
        // Without a backing store, return all as a simple fallback.
        return fetchQuestions()
    }

    // Save a wrong answer by id. Fallback is a no-op to keep the app running.
    func saveWrong(questionId: Int64) {
        // No-op fallback
    }
}

// Helper to access QuestionData.questions without introducing a hard dependency crash if missing.
private enum _QuestionDataAccessor {
    static func questions() throws -> [Question] {
        // This relies on QuestionData being present in the project.
        return QuestionData.questions
    }
}
