#!/usr/bin/env python3
import sqlite3
import csv
import sys
import os
import shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
BUNDLE_DB = os.path.join(ROOT, "quiz.sqlite3")
SIMULATOR_DB = os.path.join(ROOT, "TapLingoDB", "quiz.sqlite3")
CSV = os.path.join(ROOT, "questions.csv")

def create_tables(cur):
    cur.execute("""
        CREATE TABLE IF NOT EXISTS questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            explanation TEXT,
            correct_index INTEGER,
            difficulty TEXT DEFAULT '',
            question_type TEXT DEFAULT ''
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS choices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question_id INTEGER,
            text TEXT,
            position INTEGER DEFAULT 0,
            FOREIGN KEY(question_id) REFERENCES questions(id)
        )
    """)

def reset_tables(cur):
    cur.execute("DROP TABLE IF EXISTS choices")
    cur.execute("DROP TABLE IF EXISTS questions")
    create_tables(cur)

def import_csv(db_path):
    if not os.path.exists(CSV):
        print(f"CSVファイルが見つかりません: {CSV}")
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("PRAGMA foreign_keys = ON")
    create_tables(cur)
    reset_tables(cur)

    added = 0
    skipped = 0

    with open(CSV, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            text = row["question_text"].replace("\\n", "\n").strip()
            exp = row["explanation"].strip()
            correct = int(row["correct_index"])
            choices = [
                row["choice_0"].strip(),
                row["choice_1"].strip(),
                row["choice_2"].strip(),
                row["choice_3"].strip()
            ]

            difficulty = row.get("difficulty", "").strip()
            question_type = row.get("type", "").strip()

            if not text or not all(choices):
                skipped += 1
                continue

            cur.execute(
                "INSERT INTO questions (text, explanation, correct_index, difficulty, question_type) VALUES (?, ?, ?, ?, ?)",
                (text, exp, correct, difficulty, question_type)
            )
            qid = cur.lastrowid
            for i, c in enumerate(choices):
                cur.execute(
                    "INSERT INTO choices (question_id, text, position) VALUES (?, ?, ?)",
                    (qid, c, i)
                )
            print(f"追加: [{qid}] {text[:30].replace(chr(10), ' / ')}")
            added += 1

    conn.commit()
    conn.close()
    return added, skipped

def main():
    os.makedirs(os.path.dirname(SIMULATOR_DB), exist_ok=True)
    added, skipped = import_csv(BUNDLE_DB)
    shutil.copy2(BUNDLE_DB, SIMULATOR_DB)

    print(f"\n完了: {added}問追加")
    if skipped:
        print(f"スキップ: {skipped}行")
    print(f"同梱DBを更新: {BUNDLE_DB}")
    print(f"シミュレータ用DBを更新: {SIMULATOR_DB}")

if __name__ == "__main__":
    main()
