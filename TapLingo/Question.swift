import Foundation

// Data model for a quiz question
struct Question: Identifiable {
    let id: Int64
    let text: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
}
