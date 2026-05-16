import SwiftUI

struct HomeView: View {
    let stats: QuizStats
    let questionCount: Int
    let filteredCount: Int
    let bestTimeAttackScore: Int
    let pendingAchievementDays: Int?
    let availableTypes: [String]
    @Binding var filter: QuizFilter
    let startAction: () -> Void
    let startTimeAttackAction: () -> Void
    let dismissAchievementAction: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                heroView

                if let pendingAchievementDays {
                    AchievementUnlockedView(
                        days: pendingAchievementDays,
                        dismissAction: dismissAchievementAction
                    )
                }

                FilterCard(
                    filter: $filter,
                    availableTypes: availableTypes,
                    filteredCount: filteredCount
                )

                timeAttackScoreCard
                progressView
                StreakBonusView(streakDays: stats.studyDayStreak)
                StudyCalendarView(stats: stats)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }

    private var heroView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.16))
                        .frame(width: 56, height: 56)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の学習")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(stats.todayAnswered)問")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(stats.currentStreak)")
                        .font(.headline.weight(.bold))
                    Text("連続正解")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("TapLingo")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .minimumScaleFactor(0.75)

                actionButtons

                Text("英語表現をテンポよく解いて、毎日の学習を積み上げよう。")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(22)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: startAction) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text(filter.isActive
                         ? "クイズを始める (\(filteredCount)問)"
                         : "クイズを始める")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(.green, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: startTimeAttackAction) {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                    Text("タイムアタック")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(.green.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var timeAttackScoreCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("タイムアタック")
                    .font(.headline.weight(.bold))
                Text("ベストスコア")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(bestTimeAttackScore)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text("問")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.orange.opacity(0.22), lineWidth: 1)
        )
    }

    private var progressView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("進捗")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("全\(questionCount)問")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                StatPill(icon: "target", title: "正答率", value: "\(stats.accuracy)%", accentColor: .green)
                StatPill(icon: "checkmark.circle", title: "正解", value: "\(stats.todayCorrect)", accentColor: .indigo)
                StatPill(icon: "exclamationmark.triangle", title: "弱点", value: "\(stats.weakQuestionCount)", accentColor: .red)
            }

            HStack(spacing: 10) {
                StatPill(icon: "calendar", title: "今月の学習日", value: "\(stats.currentMonthStudyDays)", accentColor: .blue)
                StatPill(icon: "square.grid.3x3", title: "今月の問題数", value: "\(stats.currentMonthAnswered)", accentColor: .purple)
            }
        }
        .padding(18)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}
