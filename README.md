# NativeSense

SwiftUI で作った 4択クイズアプリ。問題は SQLite で管理し、Python スクリプトで追加・インポートできる。

## 機能

- 4択問題をランダム順で出題
- 回答後に正誤判定と解説を表示
- 全問終了後はシャッフルして繰り返し

## 構成

```
NativeSense/          # Swift ソース
  ContentView.swift   # クイズ UI
  Question.swift      # データモデル
  DBManager.swift     # SQLite 操作
NativeSenseDB/        # DB ファイル置き場（.gitignore 対象）
add_question.py       # 対話形式で1問追加
import_questions.py   # CSV から一括インポート
questions.csv         # 問題データ
```

## 問題データの管理

### CSV から一括インポート

`questions.csv` のフォーマット：

```csv
text,explanation,correct_index,choice0,choice1,choice2,choice3
問題文,解説,0,選択肢A,選択肢B,選択肢C,選択肢D
```

```bash
python3 import_questions.py
```

### 対話形式で1問追加

```bash
python3 add_question.py
```

## 開発環境

- Xcode 16+
- iOS 17+ / macOS 14+
- Python 3（問題インポート用）

## DB パスについて

シミュレータ実行時は `NativeSenseDB/quiz.sqlite3`（プロジェクト内）、実機では `Documents/quiz.sqlite3` を使用する。
