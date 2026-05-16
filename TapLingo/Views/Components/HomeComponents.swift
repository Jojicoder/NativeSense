import SwiftUI

// MARK: - FilterCard

struct FilterCard: View {
    @Binding var filter: QuizFilter
    let availableTypes: [String]
    let filteredCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("フィルター")
                    .font(.headline.weight(.bold))
                Spacer()
                if filter.isActive {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = QuizFilter()
                        }
                    } label: {
                        Text("クリア")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.green.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // 難易度
            VStack(alignment: .leading, spacing: 8) {
                Text("難易度")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(QuizFilter.Difficulty.allCases) { level in
                        FilterChip(
                            label: level.label,
                            isSelected: filter.difficulty == level
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                filter.difficulty = level
                            }
                        }
                    }
                }
            }

            // カテゴリ
            VStack(alignment: .leading, spacing: 8) {
                Text("カテゴリ")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "全部",
                            isSelected: filter.questionType.isEmpty
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                filter.questionType = ""
                            }
                        }
                        ForEach(availableTypes, id: \.self) { type in
                            FilterChip(
                                label: type.categoryLabel,
                                isSelected: filter.questionType == type
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    filter.questionType = type
                                }
                            }
                        }
                    }
                }
            }

            if filter.isActive {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 13))
                    Text("\(filteredCount)問が対象")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(filter.isActive ? Color.green.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: filter.isActive ? Color.green.opacity(0.08) : Color.black.opacity(0.04),
                radius: 12, x: 0, y: 6)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.green)
                        : AnyShapeStyle(Color.secondary.opacity(0.1)),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AchievementUnlockedView

struct AchievementUnlockedView: View {
    let days: Int
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.24))
                    .frame(width: 54, height: 54)
                Image(systemName: "rosette")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("バッジ獲得")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Text("\(days)日連続学習を達成！")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("この調子で続けよう")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.82), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.yellow.opacity(0.13), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.orange.opacity(0.24), lineWidth: 1)
        )
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }
}

struct StreakBonusView: View {
    let streakDays: Int

    private let milestones = [
        StreakMilestone(days: 3, title: "3日連続", icon: "leaf.fill"),
        StreakMilestone(days: 7, title: "7日連続", icon: "flame.fill"),
        StreakMilestone(days: 14, title: "14日連続", icon: "crown.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("連続学習ボーナス")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(streakDays)日")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
            }

            HStack(spacing: 10) {
                ForEach(milestones) { milestone in
                    StreakBadge(
                        milestone: milestone,
                        isUnlocked: streakDays >= milestone.days
                    )
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}

struct StudyCalendarView: View {
    let stats: QuizStats

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let calendarCellCount = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学習カレンダー")
                        .font(.headline.weight(.bold))
                    Text("1日の問題数が多いほど濃い緑になります")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stats.currentMonthStudyDays)日")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.green)
                    Text("今月")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(calendarDays(), id: \.key) { item in
                    VStack(spacing: 3) {
                        Text(item.day)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(item.isCurrentMonth ? Color.primary : Color.secondary.opacity(0.45))
                            .minimumScaleFactor(0.7)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(calendarColor(answered: item.answered))
                            .frame(minHeight: 24)
                            .aspectRatio(1.25, contentMode: .fit)
                            .overlay(
                                Text(item.answered > 0 ? "\(item.answered)" : "")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(item.answered >= 50 ? .white : .secondary)
                                    .minimumScaleFactor(0.65)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(item.isCurrentMonth ? 1 : 0.35)
                }
            }

        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func calendarDays() -> [(key: String, day: String, answered: Int, isCurrentMonth: Bool)] {
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let monthRange = calendar.range(of: .day, in: .month, for: now) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) - 1
        let totalCells = max(calendarCellCount, Int(ceil(Double(firstWeekday + monthRange.count) / 7.0)) * 7)

        return (0..<totalCells).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - firstWeekday, to: monthInterval.start) else {
                return nil
            }
            let key = QuizStats.dayKey(for: date)
            let day = String(calendar.component(.day, from: date))
            let isCurrentMonth = calendar.isDate(date, equalTo: now, toGranularity: .month)
            return (
                key: key,
                day: day,
                answered: stats.dailyHistory[key]?.answered ?? 0,
                isCurrentMonth: isCurrentMonth
            )
        }
    }

    private func calendarColor(answered: Int) -> Color {
        switch answered {
        case 200...:
            return Color(red: 0.03, green: 0.25, blue: 0.12)
        case 100...:
            return Color(red: 0.05, green: 0.42, blue: 0.19)
        case 50...:
            return Color(red: 0.13, green: 0.62, blue: 0.30)
        case 25...:
            return Color(red: 0.35, green: 0.78, blue: 0.47)
        case 1...:
            return Color(red: 0.69, green: 0.91, blue: 0.72)
        default:
            return Color.secondary.opacity(0.12)
        }
    }
}

struct StreakMilestone: Identifiable {
    let days: Int
    let title: String
    let icon: String
    var id: Int { days }
}

struct StreakBadge: View {
    let milestone: StreakMilestone
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? .green.opacity(0.16) : .secondary.opacity(0.08))
                    .frame(width: 46, height: 46)
                Image(systemName: isUnlocked ? milestone.icon : "lock.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isUnlocked ? .green : .secondary.opacity(0.55))
            }

            Text(milestone.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isUnlocked ? .green.opacity(0.08) : .white.opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isUnlocked ? .green.opacity(0.22) : .black.opacity(0.05), lineWidth: 1)
        )
    }
}
