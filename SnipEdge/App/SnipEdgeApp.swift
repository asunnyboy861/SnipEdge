import SwiftUI
import SwiftData

@main
struct SnipEdgeApp: App {
    @StateObject private var appState = AppState()
    private let container: ModelContainer

    init() {
        container = (try? ModelContainer(for: GradeRecord.self)) ?? {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: GradeRecord.self, configurations: configuration)
        }()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onOpenURL { _ in
                    appState.consumeShareIfNeeded()
                }
                .task {
                    await SubscriptionManager.shared.refreshEntitlements()
                }
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else {
                TabView {
                    HomeView()
                        .tabItem { Label("Grade", systemImage: "chart.bar.xaxis") }
                    ProofView()
                        .tabItem { Label("Proof", systemImage: "checkmark.seal.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .tint(Theme.brand)
            }
        }
        .background(Theme.background)
    }
}
