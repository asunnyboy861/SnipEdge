import SwiftUI

struct ShareCardView: View {
    let card: GradeCard
    var watermark: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("SnipEdge")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.brand)
                Spacer()
                Text(card.isVerified ? "VERIFIED" : "UNVERIFIED")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(card.isVerified ? Theme.up : Theme.warning)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(card.letter)
                    .font(.system(size: 220, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.gradeColor(card.letter))
                Text(card.verdict)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("\(card.symbol) · \(card.timeframe)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(card.patternName)
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENTRY")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(Theme.price(card.entry))
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.brand)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("STOP")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(Theme.price(card.stop))
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.down)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("TP1")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(Theme.price(card.tp1))
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.up)
                }
            }

            Spacer()

            HStack {
                Text("R:R 1:\(String(format: "%.1f", card.riskReward))")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if watermark {
                    Text("Graded by SnipEdge")
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(card.disclaimer)
                .font(.system(size: 18))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(64)
        .frame(width: 1080, height: 1350, alignment: .topLeading)
        .background(Theme.background)
    }
}

@MainActor
enum ShareCardRenderer {
    static func render(card: GradeCard, watermark: Bool) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(card: card, watermark: watermark))
        renderer.scale = 1
        return renderer.uiImage
    }
}
