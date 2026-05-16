import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                QuizHeaderView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let question = viewModel.currentQuestion {
                            QuestionCard(question: question)

                            VStack(spacing: 10) {
                                ForEach(question.choices.indices, id: \.self) { index in
                                    ChoiceButton(
                                        index: index,
                                        text: question.choices[index],
                                        state: viewModel.choiceState(for: index, question: question)
                                    ) {
                                        viewModel.answer(index, question: question)
                                    }
                                }
                            }
                        } else {
                            EmptyStateView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, viewModel.showAnswer ? 260 : 32)
                }
            }

            if viewModel.showAnswer, let question = viewModel.currentQuestion {
                ResultBottomPanel(
                    question: question,
                    selectedIndex: viewModel.selectedIndex,
                    nextAction: viewModel.next
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.showAnswer)
    }
}

private struct QuizHeaderView: View {
    @ObservedObject var viewModel: QuizViewModel

    private var progress: CGFloat {
        let total = viewModel.questions.count
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.currentIndex + 1) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button(action: viewModel.goHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 38, height: 38)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(viewModel.isReviewQuiz ? "復習" : "問題")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewModel.currentIndex + 1) / \(max(viewModel.questions.count, 1))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 7)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, Color(red: 0.18, green: 0.72, blue: 0.55)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 7)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 7)
                }

                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                    Text("\(viewModel.stats.currentStreak)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
            }

            HStack(spacing: 8) {
                QuizStatChip(icon: "square.and.pencil", label: "今日", value: "\(viewModel.stats.todayAnswered)", color: .blue)
                QuizStatChip(icon: "target", label: "正答率", value: "\(viewModel.stats.accuracy)%", color: .green)
                QuizStatChip(icon: "checkmark.seal", label: "正解数", value: "\(viewModel.stats.todayCorrect)", color: .indigo)
            }
        }
    }
}

private struct QuizStatChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
