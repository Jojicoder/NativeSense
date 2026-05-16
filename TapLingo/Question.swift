import Foundation

struct Question: Identifiable {
    let id: Int64
    let text: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let difficulty: String
    let questionType: String
}

extension Question {
    func withShuffledChoices() -> Question {
        let correctText = choices[correctIndex]
        let shuffled = choices.shuffled()
        let newCorrectIndex = shuffled.firstIndex(of: correctText) ?? correctIndex
        return Question(
            id: id,
            text: text,
            choices: shuffled,
            correctIndex: newCorrectIndex,
            explanation: explanation,
            difficulty: difficulty,
            questionType: questionType
        )
    }
}

// MARK: - QuizFilter

struct QuizFilter {
    enum Difficulty: String, CaseIterable, Identifiable {
        case all = ""
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:    return "全部"
            case .easy:   return "易しい"
            case .medium: return "普通"
            case .hard:   return "難しい"
            }
        }
    }

    var difficulty: Difficulty = .all
    var questionType: String = ""

    var isActive: Bool {
        difficulty != .all || !questionType.isEmpty
    }

    func matches(_ question: Question) -> Bool {
        let diffMatch = difficulty == .all || question.difficulty == difficulty.rawValue
        let typeMatch = questionType.isEmpty || question.questionType == questionType
        return diffMatch && typeMatch
    }
}

// MARK: - Category display labels

extension String {
    var categoryLabel: String {
        switch self {
        case "casual":    return "カジュアル"
        case "dating":    return "恋愛"
        case "idiom":     return "イディオム"
        case "indirect":  return "婉曲"
        case "slang":     return "スラング"
        case "texting":   return "テキスト"
        case "workplace": return "ビジネス"
        default:          return self
        }
    }
}
