#!/usr/bin/env python3
import sqlite3
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(ROOT, "TapLingoDB", "quiz.sqlite3")

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

print("=== 問題追加 ===")
text        = input("問題文 (改行は \\n と入力): ").replace("\\n", "\n")
explanation = input("解説: ")
correct     = int(input("正解インデックス (0〜3): "))

choices = []
for i in range(4):
    choices.append(input(f"選択肢{i}: "))

os.makedirs(os.path.dirname(DB), exist_ok=True)
conn = sqlite3.connect(DB)
cur  = conn.cursor()
cur.execute("PRAGMA foreign_keys = ON")
create_tables(cur)

cur.execute(
    "INSERT INTO questions (text, explanation, correct_index) VALUES (?, ?, ?)",
    (text, explanation, correct)
)
qid = cur.lastrowid

for i, c in enumerate(choices):
    cur.execute(
        "INSERT INTO choices (question_id, text, position) VALUES (?, ?, ?)",
        (qid, c, i)
    )

conn.commit()
conn.close()

print(f"\n追加完了 (id={qid})")
print(f"  問題: {text}")
for i, c in enumerate(choices):
    mark = " ← 正解" if i == correct else ""
    print(f"  {i}: {c}{mark}")
