import SwiftUI

struct DisclaimerBanner: View {
    var compact: Bool = false

    var body: some View {
        Text("Educational analysis only. Not financial advice.")
            .font(compact ? .caption2 : .caption)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Disclaimer: educational analysis only, not financial advice")
    }
}

struct GradeBadge: View {
    let letter: String
    var size: CGFloat = 44

    var body: some View {
        Text(letter)
            .font(.system(size: size, weight: .heavy, design: .monospaced))
            .foregroundStyle(Theme.gradeColor(letter))
            .frame(width: size * 1.35, height: size * 1.35)
            .background(Theme.gradeColor(letter).opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.32))
            .accessibilityLabel("Grade \(letter)")
    }
}

struct RiskBar: View {
    let card: GradeCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let stopX = width * 0.18
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.down.opacity(0.25)).frame(height: 10)
                    Capsule().fill(Theme.up.opacity(0.25)).frame(width: width - stopX, height: 10).offset(x: stopX)
                    Circle().fill(Theme.down).frame(width: 12, height: 12).offset(x: stopX - 6)
                    Circle().fill(Theme.brand).frame(width: 12, height: 12).offset(x: stopX + (width - stopX) * 0.34 - 6)
                    Circle().fill(Theme.up).frame(width: 12, height: 12).offset(x: width - 14)
                }
            }
            .frame(height: 14)

            HStack {
                priceTag("Stop", value: card.stop, color: Theme.down)
                Spacer()
                priceTag("Entry", value: card.entry, color: Theme.brand)
                Spacer()
                priceTag("TP1", value: card.tp1, color: Theme.up)
                Spacer()
                priceTag("TP2", value: card.tp2, color: Theme.up)
            }
        }
    }

    private func priceTag(_ label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(Theme.price(value))
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: label == "TP2" ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }
}

struct WinRateRing: View {
    let winRate: Double?
    let sampleSize: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(Theme.separator, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: winRate ?? 0)
                    .stroke(winRate == nil ? Theme.textSecondary : Theme.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(winRate == nil ? "—" : "\(Int((winRate ?? 0) * 100))%")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text("Historical win rate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(winRate == nil ? "Not enough data" : "Based on \(sampleSize) similar setups")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct TermChip: View {
    let title: String
    let value: String
    var tint: Color = Theme.brand
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.brand.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(Color.black)
    }
}

struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
