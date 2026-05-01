#!/usr/bin/env python3
import sqlite3
import csv
import sys
import os

DB  = "/Users/jojo/Desktop/NativeSense/NativeSenseDB/quiz.sqlite3"
CSV = "/Users/jojo/Desktop/NativeSense/questions.csv"

if not os.path.exists(CSV):
    print(f"CSVファイルが見つかりません: {CSV}")
    sys.exit(1)

conn = sqlite3.connect(DB)
cur  = conn.cursor()

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
