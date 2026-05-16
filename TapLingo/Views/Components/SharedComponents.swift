import SwiftUI

enum ChoiceState {
    case idle
    case correct
    case wrong
    case dim
}

struct StatPill: View {
    let icon: String
    let title: String
    let value: String
    var accentColor: Color = .green

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}

struct ChoiceButton: View {
    let index: Int
    let text: String
    let state: ChoiceState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(letterColor)
                    .frame(width: 30, height: 30)
                    .background(letterBackground, in: Circle())

                Text(text)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)

                statusIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        case .wrong:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)
        default:
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary.opacity(0.45))
                .font(.footnote.weight(.bold))
        }
    }

    private var buttonBackground: Color {
        switch state {
        case .correct:
            Color.green.opacity(0.16)
        case .wrong:
            Color.red.opacity(0.13)
        case .dim:
            Color.white.opacity(0.55)
        case .idle:
            Color.white
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct:
            Color.green.opacity(0.45)
        case .wrong:
            Color.red.opacity(0.35)
        default:
            Color.black.opacity(0.06)
        }
    }

    private var letterBackground: Color {
        switch state {
        case .correct:
            Color.green
        case .wrong:
            Color.red
        default:
            Color.green.opacity(0.12)
        }
    }

    private var letterColor: Color {
        switch state {
        case .correct, .wrong:
            Color.white
        default:
            Color.green
        }
    }

    private var textColor: Color {
        state == .dim ? .secondary : .primary
    }

    private var shadowColor: Color {
        state == .idle ? .black.opacity(0.06) : .clear
    }
}

struct QuestionCard: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.72, blue: 0.38), Color(red: 0.18, green: 0.62, blue: 0.85)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(
                .rect(topLeadingRadius: 24, topTrailingRadius: 24)
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(.green)
                    Text("この表現の意味は？")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Text(question.text)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
    }
}

struct ResultBottomPanel: View {
    let question: Question
    let selectedIndex: Int?
    let nextAction: () -> Void

    private var isCorrect: Bool { selectedIndex == question.correctIndex }

    private var gradientColors: [Color] {
        isCorrect
            ? [Color(red: 0.1, green: 0.72, blue: 0.38), Color(red: 0.05, green: 0.52, blue: 0.28)]
            : [Color(red: 0.95, green: 0.45, blue: 0.1), Color(red: 0.82, green: 0.30, blue: 0.05)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.35))
                .frame(width: 38, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isCorrect ? "正解！" : "惜しい！")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        if !isCorrect {
                            Text("正解: \(question.choices[question.correctIndex])")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(2)
                        }
                    }
                }

                if !question.explanation.isEmpty {
                    Text(question.explanation)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: nextAction) {
                    HStack(spacing: 8) {
                        Text("次の問題へ")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isCorrect ? .green : .orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .bottom)
        )
        .clipShape(TopRoundedShape(radius: 28))
        .shadow(color: gradientColors[0].opacity(0.35), radius: 20, x: 0, y: -6)
    }
}

private struct TopRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                    radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                    radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.green)
            Text("問題がまだありません")
                .font(.title3.bold())
            Text("データベースに問題を追加すると、ここに表示されます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
