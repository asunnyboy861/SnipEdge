import SwiftUI

struct RefusalView: View {
    let refusal: AnalysisRefusal
    var onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 34))
                        .foregroundStyle(Theme.warning)
                    Spacer()
                }
                Text(refusal.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(refusal.detail)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)

                SectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to capture a readable chart")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(refusal.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.brand)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }

                Button {
                    onRetry()
                } label: {
                    Text("Try another screenshot")
                }
                .buttonStyle(PrimaryButtonStyle())

                DisclaimerBanner()
            }
            .padding(20)
        }
        .background(Theme.background)
    }
}

struct RecordDetailView: View {
    let record: GradeRecord
    @StateObject private var purchase = SubscriptionManager.shared

    var body: some View {
        GradeCardView(
            card: record.card,
            image: AnalysisOrchestrator.image(named: record.imageFileName),
            watermark: purchase.isPro == false
        )
        .navigationTitle(record.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topTrailing) {
            OutcomeChip(outcome: record.outcome)
                .padding(.trailing, 20)
                .padding(.top, 8)
        }
    }
}
