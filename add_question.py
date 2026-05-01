#!/usr/bin/env python3
import sqlite3

DB = "/Users/jojo/Desktop/NativeSense/NativeSenseDB/quiz.sqlite3"

print("=== 問題追加 ===")
text        = input("問題文 (改行は \\n と入力): ").replace("\\n", "\n")
explanation = input("解説: ")
correct     = int(input("正解インデックス (0〜3): "))

choices = []
for i in range(4):
    choices.append(input(f"選択肢{i}: "))

conn = sqlite3.connect(DB)
cur  = conn.cursor()

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
