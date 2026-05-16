import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DBManager {

    static let shared = DBManager()
    private var db: OpaquePointer?

    private init() {
        openDB()
        createTables()
    }

    // MARK: - Open DB

    private func openDB() {
#if targetEnvironment(simulator)
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = projectRoot
            .appendingPathComponent("TapLingoDB")
            .appendingPathComponent("quiz.sqlite3")

        let folder = path.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )
    #else
        let docURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("quiz.sqlite3")

        if let bundleURL = Bundle.main.url(forResource: "quiz", withExtension: "sqlite3") {
            try? FileManager.default.removeItem(at: docURL)
            try? FileManager.default.copyItem(at: bundleURL, to: docURL)
        }

        let path = docURL
    #endif

        print("DB PATH:", path.path)

        if sqlite3_open(path.path, &db) != SQLITE_OK {
            print("DB open error")
            return
        }

        sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil)
    }

    // MARK: - Create Tables

    private func createTables() {
        let questionsSQL = """
        CREATE TABLE IF NOT EXISTS questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            explanation TEXT,
            correct_index INTEGER,
            difficulty TEXT DEFAULT '',
            question_type TEXT DEFAULT ''
        );
        """

        let choicesSQL = """
        CREATE TABLE IF NOT EXISTS choices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question_id INTEGER,
            text TEXT,
            position INTEGER DEFAULT 0,
            FOREIGN KEY(question_id) REFERENCES questions(id)
        );
        """

        sqlite3_exec(db, questionsSQL, nil, nil, nil)
        sqlite3_exec(db, choicesSQL, nil, nil, nil)

        // Add columns to existing DBs (silently ignored if already present)
        sqlite3_exec(db, "ALTER TABLE questions ADD COLUMN difficulty TEXT DEFAULT '';", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE questions ADD COLUMN question_type TEXT DEFAULT '';", nil, nil, nil)
    }

    // MARK: - CSV Seed

    func seedFromCSV() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "csv"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return }

        clearQuestions()

        let lines = raw.components(separatedBy: "\n").dropFirst()
        for line in lines {
            let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let cols = parseCSVLine(line)
            guard cols.count >= 7 else { continue }
            let text        = cols[0]
            let choices     = Array(cols[1...4])
            let correctIndex = Int(cols[5]) ?? 0
            let explanation = cols[6]
            insert(text: text, explanation: explanation, correctIndex: correctIndex, choices: choices)
        }
    }

    private func clearQuestions() {
        guard let db = db else { return }
        sqlite3_exec(db, "DELETE FROM choices;", nil, nil, nil)
        sqlite3_exec(db, "DELETE FROM questions;", nil, nil, nil)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let ch = line[i]
            if ch == "\"" {
                let next = line.index(after: i)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    i = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if ch == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }

    // MARK: - Insert

    func insert(text: String, explanation: String, correctIndex: Int, choices: [String],
                difficulty: String = "", questionType: String = "") {
        guard let db = db else { return }

        var checkStmt: OpaquePointer?
        sqlite3_prepare_v2(db, "SELECT id FROM questions WHERE text = ?;", -1, &checkStmt, nil)
        sqlite3_bind_text(checkStmt, 1, text, -1, SQLITE_TRANSIENT)
        let exists = sqlite3_step(checkStmt) == SQLITE_ROW
        sqlite3_finalize(checkStmt)
        if exists { return }

        var stmt: OpaquePointer?
        let sql = "INSERT INTO questions (text, explanation, correct_index, difficulty, question_type) VALUES (?, ?, ?, ?, ?);"

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("Insert prepare error")
            return
        }

        sqlite3_bind_text(stmt, 1, text, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, explanation, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 3, Int32(correctIndex))
        sqlite3_bind_text(stmt, 4, difficulty, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, questionType, -1, SQLITE_TRANSIENT)

        if sqlite3_step(stmt) != SQLITE_DONE {
            print("Insert error")
        }
        sqlite3_finalize(stmt)

        let id = sqlite3_last_insert_rowid(db)
        for (index, c) in choices.enumerated() {
            var cStmt: OpaquePointer?
            let choiceSQL = "INSERT INTO choices (question_id, text, position) VALUES (?, ?, ?);"
            if sqlite3_prepare_v2(db, choiceSQL, -1, &cStmt, nil) != SQLITE_OK { continue }
            sqlite3_bind_int64(cStmt, 1, id)
            sqlite3_bind_text(cStmt, 2, c, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(cStmt, 3, Int32(index))
            sqlite3_step(cStmt)
            sqlite3_finalize(cStmt)
        }
    }

    // MARK: - Fetch

    func fetch() -> [Question] {
        guard let db = db else { return [] }

        var result: [Question] = []
        var stmt: OpaquePointer?

        let sql = "SELECT id, text, explanation, correct_index, difficulty, question_type FROM questions;"

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            print("Fetch prepare error")
            return []
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)

            guard
                let textC = sqlite3_column_text(stmt, 1),
                let expC  = sqlite3_column_text(stmt, 2)
            else { continue }

            let text        = String(cString: textC)
            let explanation = String(cString: expC)
            let correct     = Int(sqlite3_column_int(stmt, 3))
            let difficulty  = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
            let questionType = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
            let choices     = getChoices(id: id)

            result.append(Question(
                id: id,
                text: text,
                choices: choices,
                correctIndex: correct,
                explanation: explanation,
                difficulty: difficulty,
                questionType: questionType
            ))
        }

        sqlite3_finalize(stmt)
        return result
    }

    // MARK: - Choices

    private func getChoices(id: Int64) -> [String] {
        guard let db = db else { return [] }

        var arr: [String] = []
        var stmt: OpaquePointer?

        let sql = "SELECT text FROM choices WHERE question_id = ? ORDER BY position;"

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            return []
        }

        sqlite3_bind_int64(stmt, 1, id)

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cText = sqlite3_column_text(stmt, 0) {
                arr.append(String(cString: cText))
            }
        }

        sqlite3_finalize(stmt)
        return arr
    }
}
