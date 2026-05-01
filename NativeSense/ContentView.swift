import SwiftUI

struct ContentView: View {

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedIndex: Int? = nil
    @State private var showAnswer = false

    var body: some View {

        VStack {

            if questions.isEmpty {
                Text("No questions")
            } else {

                let q = questions[currentIndex]

                Text(q.text)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                ForEach(Array(q.choices.enumerated()), id: \.offset) { (offset, choice) in
                    Button {
                        selectedIndex = offset
                        showAnswer = true
                    } label: {
                        Text(choice)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(color(offset))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(showAnswer)
                }

                if showAnswer {
                    Text(selectedIndex == q.correctIndex ? "Correct!" : "Wrong")
                        .font(.headline)
                        .padding(.top, 20)

                    Text(q.explanation)
                        .padding()

                    Button("Next") {
                        next()
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding()
        .onAppear {
            loadQuestions()
        }
    }

    func loadQuestions() {
        questions = DBManager.shared.fetch().shuffled()
        currentIndex = 0
        selectedIndex = nil
        showAnswer = false
    }

    func color(_ i: Int) -> Color {
        guard showAnswer else { return .blue }

        if i == questions[currentIndex].correctIndex {
            return .green
        } else if i == selectedIndex {
            return .red
        } else {
            return .gray
        }
    }

    func next() {
        guard !questions.isEmpty else { return }

        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            questions.shuffle()
            currentIndex = 0
        }
        selectedIndex = nil
        showAnswer = false
    }
}

#Preview {
    ContentView()
}
