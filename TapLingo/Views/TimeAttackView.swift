import SwiftUI

struct TimeAttackView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                TimeAttackHeaderView(viewModel: viewModel)
                TimeAttackScoreboard(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    if viewModel.timeAttackFinished {
                        TimeAttackResultView(viewModel: viewModel)
                    } else if let question = viewModel.currentTimeAttackQuestion {
                        QuestionCard(question: question)

                        VStack(spacing: 12) {
                            ForEach(question.choices.indices, id: \.self) { index in
                                ChoiceButton(index: index, text: question.choices[index], state: .idle) {
                                    viewModel.answerTimeAttack(index, question: question)
                                }
                            }
                        }
                    } else {
                        EmptyStateView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct TimeAttackHeaderView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var timerPulse = false

    private var isUrgent: Bool { viewModel.timeRemaining <= 10 }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.finishTimeAttack()
                viewModel.goHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Time Attack")
                    .font(.headline.weight(.bold))
                Text("60秒で何問解けるか")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "timer")
                    .foregroundStyle(isUrgent ? .red : .green)
                Text("\(viewModel.timeRemaining)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isUrgent ? .red : .primary)
                    .contentTransition(.numericText())
                    .animation(.default, value: viewModel.timeRemaining)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                isUrgent ? Color.red.opacity(0.12) : Color.white.opacity(0.9),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isUrgent ? Color.red.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(timerPulse ? 1.12 : 1.0)
            .onChange(of: viewModel.timeRemaining) { _ in
                guard isUrgent else { return }
                withAnimation(.easeOut(duration: 0.12)) { timerPulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.easeIn(duration: 0.12)) { timerPulse = false }
                }
            }
        }
    }
}

private struct TimeAttackScoreboard: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        HStack(spacing: 10) {
            TimeAttackMetric(title: "スコア", value: "\(viewModel.timeAttackScore)", icon: "checkmark.circle.fill", color: .green, isPrimary: true)
            Divider()
                .frame(height: 28)
            TimeAttackMetric(title: "回答", value: "\(viewModel.timeAttackAnswered)", icon: "square.and.pencil", color: .blue)
            Divider()
                .frame(height: 28)
            TimeAttackMetric(title: "ベスト", value: "\(viewModel.bestTimeAttackScore)", icon: "trophy.fill", color: .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct TimeAttackMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isPrimary = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: isPrimary ? 13 : 11, weight: .bold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: isPrimary ? 18 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimeAttackResultView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.14))
                    .frame(width: 78, height: 78)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("タイムアップ")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("\(viewModel.timeAttackScore)問正解 / \(viewModel.timeAttackAnswered)問回答")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(action: viewModel.startTimeAttack) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("もう一度")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: viewModel.goHome) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.green.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}
