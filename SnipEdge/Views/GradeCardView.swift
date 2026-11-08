import SwiftUI
import UIKit

struct AnalysisSheetView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @ObservedObject var purchase: SubscriptionManager
    var onUpgrade: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .idle:
                    progress(stage: "Preparing")
                case .running(let stage):
                    progress(stage: stage)
                case .ready(let result):
                    GradeCardView(card: result.card, image: result.image, watermark: purchase.isPro == false)
                case .refused(let refusal):
                    RefusalView(refusal: refusal) { dismiss() }
                case .failed(let message):
                    failure(message)
                }
            }
            .background(Theme.background)
            .navigationTitle("Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func progress(stage: String) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.separator, lineWidth: 10)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: max(viewModel.stageProgress, 0.08))
                    .stroke(Theme.brand, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.stageProgress)

            Text(stage)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Reading the axis, then verifying levels against real market data.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.warning)
            Text("Could not grade this chart")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 28)
            Button {
                dismiss()
                onUpgrade()
            } label: {
                Text("See Pro options")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 28)
            Spacer()
        }
    }
}

struct GradeCardView: View {
    let card: GradeCard
    let image: UIImage?
    var watermark: Bool = false

    @State private var whyItem: WhyItem?
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                chartCard
                gradeBlock
                riskBlock
                termGrid
                whySection
                actions
                DisclaimerBanner()
            }
            .padding(20)
        }
        .background(Theme.background)
        .sheet(item: $whyItem) { item in
            WhyDetailView(item: item, card: card)
        }
        .sheet(isPresented: Binding(get: { shareImage != nil }, set: { if !$0 { shareImage = nil } })) {
            if let shareImage {
                ActivityView(items: [shareImage])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var chartCard: some View {
        Group {
            if let image {
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    GeometryReader { geometry in
                        let pixelHeight = Double(image.cgImage?.height ?? 1)
                        ForEach(card.levels) { level in
                            let y = CGFloat(level.yPixel / pixelHeight) * geometry.size.height
                            let color = level.verified ? Theme.brand : Theme.warning
                            if y > 0, y < geometry.size.height {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(color)
                                        .frame(height: 2)
                                        .shadow(color: color.opacity(0.7), radius: 6)
                                        .offset(y: y)
                                    Text("\(level.kind == .support ? "S" : "R") \(Theme.price(level.price))")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(color)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Theme.background.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
                                        .offset(x: 6, y: max(y - 16, 0))
                                }
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .frame(height: 200)
                    .overlay {
                        Text("Chart image unavailable")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
            }
        }
    }

    private var gradeBlock: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    Text(card.letter)
                        .font(.system(size: 88, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.gradeColor(card.letter))
                        .accessibilityLabel("Grade \(card.letter)")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.symbol)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(card.timeframe)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(card.patternName)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                Text(card.verdict)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    badge(
                        text: card.isVerified ? "VERIFIED" : "UNVERIFIED",
                        icon: card.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        color: card.isVerified ? Theme.up : Theme.warning
                    )
                    badge(
                        text: "R:R 1:\(String(format: "%.1f", card.riskReward))",
                        icon: "target",
                        color: Theme.brand
                    )
                    Spacer()
                }
            }
        }
    }

    private func badge(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
    }

    private var riskBlock: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Trade plan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                RiskBar(card: card)
                WinRateRing(winRate: card.winRate, sampleSize: card.sampleSize)
            }
        }
    }

    private var termGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            TermChip(title: "Trend", value: trendText)
            TermChip(title: "Confluence", value: String(format: "%.0f%%", card.confluenceScore * 100))
            TermChip(title: "Risk", value: String(format: "%.1f%%", card.riskPercent), tint: Theme.warning)
            TermChip(title: "Levels", value: "\(Int(card.verifiedRatio * 100))% verified", tint: card.isVerified ? Theme.up : Theme.warning)
        }
    }

    private var whySection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Why this grade")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                ForEach(WhyItem.allCases) { item in
                    Button {
                        whyItem = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(item.summary(card: card))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title). \(item.summary(card: card))")
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                renderShareCard()
            } label: {
                Label("Share card", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share this grade card")
        }
    }

    private var trendText: String {
        switch card.trend {
        case .up: return "Up"
        case .down: return "Down"
        case .range: return "Range"
        }
    }

    private func renderShareCard() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        shareImage = ShareCardRenderer.render(card: card, watermark: watermark)
    }
}

enum WhyItem: String, CaseIterable, Identifiable {
    case trend, structure, levels, risk, winRate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trend: return "Trend direction"
        case .structure: return "Structure and pattern"
        case .levels: return "Support and resistance"
        case .risk: return "Stop placement"
        case .winRate: return "Historical win rate"
        }
    }

    func summary(card: GradeCard) -> String {
        switch self {
        case .trend:
            return AppleTutorService.trendNote(for: card)
        case .structure:
            return "\(card.patternName) with \(Int(card.confluenceScore * 100))% confluence."
        case .levels:
            return "\(Int(card.verifiedRatio * 100))% of levels matched real price data."
        case .risk:
            return AppleTutorService.riskNote(for: card)
        case .winRate:
            if let winRate = card.winRate {
                return "\(Int(winRate * 100))% over \(card.sampleSize) similar setups."
            }
            return "Not enough matched setups in the sample yet."
        }
    }
}

struct WhyDetailView: View {
    let item: WhyItem
    let card: GradeCard

    @Environment(\.dismiss) private var dismiss
    @State private var explanation: String = ""
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(item.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)

                    if isLoading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Writing a plain-English explanation…")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    } else {
                        Text(explanation)
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Key numbers")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Text("Grade \(card.letter) · Confluence \(String(format: "%.0f%%", card.confluenceScore * 100)) · R:R 1:\(String(format: "%.1f", card.riskReward))")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    DisclaimerBanner()
                }
                .padding(20)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            explanation = await AppleTutorService.explain(card: card)
            isLoading = false
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
