import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var purchase = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = SubscriptionManager.yearlyID
    @State private var purchasing = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    featureList
                    tierPicker
                    actions
                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(Theme.warning)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    legal
                    creditPack
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("SnipEdge Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if purchase.products.isEmpty { await purchase.loadProducts() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.brand)
            Text("Verified analysis, unlimited archive")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
            Text("7-day free trial on both plans. Cancel anytime.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                feature("Deep vision analysis with verified price levels")
                feature("Historical win-rate library from real market data")
                feature("Unlimited analysis archive")
                feature("Watermark-free share cards")
                feature("Full Proof page with win rate and streaks")
            }
        }
    }

    private func feature(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.up)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var tierPicker: some View {
        VStack(spacing: 10) {
            tierRow(id: SubscriptionManager.yearlyID, title: "Annual", badge: "SAVE 50%")
            tierRow(id: SubscriptionManager.monthlyID, title: "Monthly", badge: nil)
        }
    }

    private func tierRow(id: String, title: String, badge: String?) -> some View {
        Button {
            selectedID = id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedID == id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selectedID == id ? Theme.brand : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.brand, in: Capsule())
                        }
                    }
                    Text(subtitle(for: id))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(priceText(for: id))
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedID == id ? Theme.brand : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) plan, \(priceText(for: id))")
    }

    private func subtitle(for id: String) -> String {
        id == SubscriptionManager.yearlyID
            ? "90 deep analyses per month · 7-day free trial"
            : "60 deep analyses per month · 7-day free trial"
    }

    private func priceText(for id: String) -> String {
        if let product = purchase.product(id: id) {
            return id == SubscriptionManager.yearlyID
                ? "\(product.displayPrice)/yr"
                : "\(product.displayPrice)/mo"
        }
        return id == SubscriptionManager.yearlyID ? "$59.99/yr" : "$9.99/mo"
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await subscribe() }
            } label: {
                if purchasing {
                    ProgressView()
                        .tint(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14))
                } else {
                    Text("Start 7-day free trial")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(purchasing)

            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)

            Button {
                Task { await purchase.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.brand)
            }
        }
    }

    private var creditPack: some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("100 deep analyses")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("One-time credit pack. Never expires.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button {
                    Task { await buyCredits() }
                } label: {
                    Text(creditPrice)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.brand)
                }
            }
        }
    }

    private var creditPrice: String {
        purchase.product(id: SubscriptionManager.creditsID)?.displayPrice ?? "$4.99"
    }

    private var legal: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/privacy.html")!)
                .font(.caption2)
                .foregroundStyle(Theme.brand)
            Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/terms.html")!)
                .font(.caption2)
                .foregroundStyle(Theme.brand)
            Link("Support", destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/support.html")!)
                .font(.caption2)
                .foregroundStyle(Theme.brand)
        }
        .padding(.top, 4)
    }

    private func subscribe() async {
        purchasing = true
        message = nil
        guard let product = purchase.product(id: selectedID) else {
            purchasing = false
            message = "Purchase options are still loading. Please try again."
            return
        }
        let success = await purchase.purchase(product)
        purchasing = false
        if success { dismiss() } else { message = purchase.loadError ?? "Purchase was not completed." }
    }

    private func buyCredits() async {
        guard let product = purchase.product(id: SubscriptionManager.creditsID) else {
            message = "Credit pack is still loading. Please try again."
            return
        }
        let success = await purchase.purchase(product)
        if success { message = "100 analyses added to your account." }
    }
}
