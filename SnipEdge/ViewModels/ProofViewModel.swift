import Foundation

@MainActor
final class ProofViewModel: ObservableObject {
    @Published var stats = ProofStats(total: 0, wins: 0, losses: 0, winRate: 0, averageR: 0, currentStreak: 0, bestStreak: 0)

    func refresh(records: [GradeRecord]) {
        stats = OutcomeTracker.stats(from: records)
    }
}
