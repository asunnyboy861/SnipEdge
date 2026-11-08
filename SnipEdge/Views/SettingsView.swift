import SwiftUI

struct SettingsView: View {
    @StateObject private var purchase = SubscriptionManager.shared
    @StateObject private var viewModel = ProofViewModel()
    @AppStorage("snipedge.notifications.enabled") private var notificationsEnabled = false
    @State private var permissionDenied = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                proSection
                engineSection
                notificationsSection
                legalSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .task {
                await purchase.refreshEntitlements()
                if purchase.isPro == false { await purchase.loadProducts() }
            }
        }
    }

    private var proSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(purchase.isPro ? "SnipEdge Pro" : "Free plan")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(purchase.isPro ? "ACTIVE" : "LIMITED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(purchase.isPro ? Theme.up : Theme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((purchase.isPro ? Theme.up : Theme.warning).opacity(0.15), in: Capsule())
                }
                Text(purchase.isPro
                     ? "\(purchase.officialRemaining()) deep analyses left this month · \(purchase.credits) credits"
                     : "3 on-device grades per day. Deep analysis unlocks verified levels and the win-rate library.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                NavigationLink {
                    PaywallView()
                } label: {
                    Text(purchase.isPro ? "Manage subscription" : "Upgrade to Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.brand)
                }
            }
            .padding(.vertical, 4)

            Button {
                Task { await purchase.restore() }
            } label: {
                Text("Restore Purchases")
                    .foregroundStyle(Theme.brand)
            }
            .accessibilityLabel("Restore purchases")
        } header: {
            Text("Subscription")
        }
        .listRowBackground(Theme.surface)
    }

    private var engineSection: some View {
        Section {
            NavigationLink {
                BYOEngineView()
            } label: {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(Theme.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI engine")
                            .foregroundStyle(Theme.textPrimary)
                        Text(BYOEngineStore.activeProfile == nil ? "Official cloud engine in use" : "Your own key is active")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        } header: {
            Text("AI")
        } footer: {
            Text("Your API key is stored only in this device's Keychain. Deep analysis with your own key is unlimited.")
        }
        .listRowBackground(Theme.surface)
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("72-hour grading alerts")
                        .foregroundStyle(Theme.textPrimary)
                    Text("We notify you when an analysis resolves as WIN or LOSS.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .tint(Theme.brand)
            .onChange(of: notificationsEnabled) { _, enabled in
                guard enabled else { return }
                Task {
                    let granted = await NotificationService.requestAuthorization()
                    if granted == false {
                        notificationsEnabled = false
                        permissionDenied = true
                    }
                }
            }
            if permissionDenied {
                Text("Notifications are disabled in iOS Settings. Enable them to receive outcome alerts.")
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
            }
        } header: {
            Text("Notifications")
        }
        .listRowBackground(Theme.surface)
    }

    private var legalSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundStyle(Theme.textPrimary)
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundStyle(Theme.textPrimary)
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/terms.html")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
                    .foregroundStyle(Theme.textPrimary)
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/SnipEdge/support.html")!) {
                Label("Support", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(Theme.textPrimary)
            }
        } header: {
            Text("Legal & Support")
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(appVersion)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
            DisclaimerBanner()
        } header: {
            Text("About")
        }
        .listRowBackground(Theme.surface)
    }
}
