import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()

    private let timeAttackTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.98, blue: 0.94),
                    Color(red: 0.96, green: 0.98, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isTimeAttackActive {
                TimeAttackView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .onReceive(timeAttackTimer) { _ in
                        viewModel.tickTimeAttack()
                    }
            } else if viewModel.isQuizActive {
                QuizView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                HomeView(
                    stats: viewModel.stats,
                    questionCount: viewModel.allQuestions.count,
                    filteredCount: viewModel.filteredCount,
                    bestTimeAttackScore: viewModel.bestTimeAttackScore,
                    pendingAchievementDays: viewModel.pendingAchievementDays,
                    availableTypes: viewModel.availableTypes,
                    filter: $viewModel.filter,
                    startAction: viewModel.startQuiz,
                    startTimeAttackAction: viewModel.startTimeAttack,
                    dismissAchievementAction: viewModel.dismissAchievement
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.isQuizActive)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.isTimeAttackActive)
        .preferredColorScheme(.light)
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    ContentView()
}
