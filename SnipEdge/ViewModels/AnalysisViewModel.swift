import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AnalysisViewModel: ObservableObject {
    enum Phase {
        case idle
        case running(String)
        case ready(AnalysisResult)
        case refused(AnalysisRefusal)
        case failed(String)
    }

    @Published var phase: Phase = .idle
    @Published var freeRemaining: Int = 3
    @Published var needsUpgrade: Bool = false
    @Published var stageProgress: Double = 0

    private let quotaKey = "snipedge.free.usage"

    init() {
        refreshQuota()
    }

    func refreshQuota() {
        let used = usageToday()
        freeRemaining = max(3 - used, 0)
    }

    private func usageToday() -> Int {
        let dict = UserDefaults.standard.dictionary(forKey: quotaKey) as? [String: Int] ?? [:]
        return dict[dayKey()] ?? 0
    }

    private func recordFreeUse() {
        var dict = UserDefaults.standard.dictionary(forKey: quotaKey) as? [String: Int] ?? [:]
        dict[dayKey()] = (dict[dayKey()] ?? 0) + 1
        UserDefaults.standard.set(dict, forKey: quotaKey)
        refreshQuota()
    }

    private func dayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    func start(image: UIImage, context: ModelContext, purchase: SubscriptionManager) async {
        needsUpgrade = false
        phase = .running("Reading the price axis")
        stageProgress = 0.1

        let engine: AnalysisEngine
        if let profile = BYOEngineStore.activeProfile, VisionClientFactory.client(for: profile) != nil {
            engine = .byo(profile)
        } else if purchase.canUseOfficialEngine {
            engine = .official
        } else if freeRemaining > 0 {
            engine = .onDevice
        } else {
            needsUpgrade = true
            phase = .failed("Your 3 free grades are used for today. Unlock Pro or add your own API key.")
            return
        }

        phase = .running("Detecting structure")
        stageProgress = 0.35

        do {
            let result = try await AnalysisOrchestrator.analyze(image: image, engine: engine)
            stageProgress = 0.8
            phase = .running("Checking levels against market data")

            switch engine {
            case .onDevice:
                recordFreeUse()
            case .official:
                purchase.consumeOfficialAnalysis()
            case .byo:
                break
            }

            let record = GradeRecord(
                imageHash: result.imageHash,
                imageFileName: result.imageFileName,
                card: result.card
            )
            context.insert(record)
            try? context.save()
            NotificationService.scheduleOutcome(symbol: result.card.symbol, entry: result.card.entry)
            trimFreeArchive(context: context, purchase: purchase)

            stageProgress = 1
            phase = .ready(result)
        } catch let refusal as AnalysisRefusal {
            phase = .refused(refusal)
        } catch {
            phase = .failed("Something went wrong while grading this chart. Please try again.")
        }
    }

    func reset() {
        phase = .idle
        stageProgress = 0
        needsUpgrade = false
    }

    private func trimFreeArchive(context: ModelContext, purchase: SubscriptionManager) {
        guard purchase.isPro == false else { return }
        let descriptor = FetchDescriptor<GradeRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let records = try? context.fetch(descriptor), records.count > 10 else { return }
        for record in records.dropFirst(10) {
            context.delete(record)
        }
        try? context.save()
    }
}
