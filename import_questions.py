#!/usr/bin/env python3
import sqlite3
import csv
import sys
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(ROOT, "TapLingoDB", "quiz.sqlite3")
CSV = os.path.join(ROOT, "questions.csv")

def create_tables(cur):
    cur.execute("""
        CREATE TABLE IF NOT EXISTS questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            explanation TEXT,
            correct_index INTEGER
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

if not os.path.exists(CSV):
    print(f"CSVファイルが見つかりません: {CSV}")
    sys.exit(1)

os.makedirs(os.path.dirname(DB), exist_ok=True)
conn = sqlite3.connect(DB)
cur  = conn.cursor()
cur.execute("PRAGMA foreign_keys = ON")
create_tables(cur)

added = 0
skipped = 0

with open(CSV, encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        text    = row["text"].replace("\\n", "\n").strip()
        exp     = row["explanation"].strip()
        correct = int(row["correct_index"])
        choices = [row["choice0"].strip(), row["choice1"].strip(),
                   row["choice2"].strip(), row["choice3"].strip()]

        if not text or not all(choices):
            skipped += 1
            continue

        cur.execute("SELECT id FROM questions WHERE text = ?", (text,))
        if cur.fetchone():
            skipped += 1
            continue

        cur.execute(
            "INSERT INTO questions (text, explanation, correct_index) VALUES (?, ?, ?)",
            (text, exp, correct)
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
print(f"\n完了: {added}問追加")
