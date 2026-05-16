# TapLingo

SwiftUI で作った英語表現の4択クイズアプリ。問題はCSVで管理し、SQLiteに一括インポートしてアプリに同梱する。

## 機能

- 4択問題をランダム順で出題
- 回答後に正誤判定と解説を表示
- 難易度・カテゴリで問題を絞り込み
- 間違えた問題や弱点問題を優先して出題
- 60秒のタイムアタック
- 学習日数・問題数をカレンダーで表示

## 構成

```
TapLingo/             # Swift ソース
  ContentView.swift   # クイズ UI
  Question.swift      # データモデル
  DBManager.swift     # SQLite 操作
TapLingoDB/           # シミュレータ用DB置き場（.gitignore 対象）
add_question.py       # シミュレータ用DBへ1問追加する簡易ツール
import_questions.py   # CSV から一括インポート
questions.csv         # 問題データ
quiz.sqlite3          # アプリ同梱用DB
```

## 問題データの管理

### CSV から一括インポート

`questions.csv` のフォーマット：

```csv
external_id,question_text,choice_0,choice_1,choice_2,choice_3,correct_index,explanation,type,difficulty,tone,tags,usage_note
TP0001,問題文,選択肢A,選択肢B,選択肢C,選択肢D,0,解説,casual,easy,friendly,"tag1, tag2",補足
```

```bash
python3 import_questions.py
```

### 対話形式で1問追加

`TapLingoDB/quiz.sqlite3` へ直接追加する開発用の簡易ツール。CSVや同梱用DBを更新したい場合は `questions.csv` を編集して `python3 import_questions.py` を実行する。

```bash
python3 add_question.py
```

## 開発環境

- Xcode 16+
- iOS 17+ / macOS 14+
- Python 3（問題インポート用）

## DB パスについて

シミュレータ実行時は `TapLingoDB/quiz.sqlite3`（プロジェクト内）、実機ではアプリ内の `Documents/quiz.sqlite3` を使用する。

`TapLingoDB/quiz.sqlite3` はローカル実行用なので `.gitignore` 対象。`quiz.sqlite3` はアプリ同梱用のためGit管理する。
