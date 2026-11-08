import SwiftUI
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var pendingImage: UIImage?
    @Published var showOnboarding: Bool

    private let onboardingKey = "snipedge.onboarding.completed"

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: onboardingKey)
        consumeShareIfNeeded()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        showOnboarding = false
    }

    func consumeShareIfNeeded() {
        if let image = ShareInbox.consume() {
            pendingImage = image
        }
    }
}
