import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0
    @State private var requesting = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                TabView(selection: $page) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    Task { await advance() }
                } label: {
                    Text(page == 2 ? "Start grading" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(requesting)
            }
        }
    }

    private func advance() async {
        if page == 1 {
            requesting = true
            _ = await NotificationService.requestAuthorization()
            requesting = false
        }
        if page == 2 {
            appState.completeOnboarding()
        } else {
            withAnimation { page += 1 }
        }
    }

    private var pageOne: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Theme.brand)
            Text("Snap a chart.\nGet the grade.")
                .font(.system(size: 34, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
            Text("Share any chart screenshot and receive an A–F grade with verified levels, a trade plan, and historical win rate in about 10 seconds.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 28)
            DisclaimerBanner()
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var pageTwo: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Theme.warning)
            Text("We grade your past picks")
                .font(.system(size: 30, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
            Text("72 hours after you save an analysis we check whether the target or the stop was hit first, and notify you. That is how your Proof page builds itself.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var pageThree: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("3")
                .font(.system(size: 96, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.brand)
            Text("free grades every day")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Share a chart from any app to start. No account, no setup, no paywall in your way.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 28)
            Spacer()
        }
    }
}
