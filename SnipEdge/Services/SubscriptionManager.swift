import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    static let monthlyID = "com.zzoutuo.snipedge.pro.monthly"
    static let yearlyID = "com.zzoutuo.snipedge.pro.yearly"
    static let dataPackID = "com.zzoutuo.snipedge.data.proplus"
    static let creditsID = "com.zzoutuo.snipedge.credits.100"

    @Published var isPro: Bool = false
    @Published var isAnnual: Bool = false
    @Published var hasDataPack: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var credits: Int = 0

    private var transactionListener: Task<Void, Never>?
    private let creditsKey = "snipedge.credits.balance"
    private let usageKey = "snipedge.official.usage"

    private init() {
        credits = UserDefaults.standard.integer(forKey: creditsKey)
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [
                Self.monthlyID, Self.yearlyID, Self.dataPackID, Self.creditsID
            ])
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                handleVerified(transaction)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed. Please try again."
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = "Restore failed. Please try again."
        }
    }

    func refreshEntitlements() async {
        var pro = false
        var annual = false
        var dataPack = false

        if let result = await Transaction.currentEntitlement(for: Self.monthlyID),
           case .verified(let transaction) = result,
           transaction.revocationDate == nil {
            pro = true
        }
        if let result = await Transaction.currentEntitlement(for: Self.yearlyID),
           case .verified(let transaction) = result,
           transaction.revocationDate == nil {
            pro = true
            annual = true
        }
        if let result = await Transaction.currentEntitlement(for: Self.dataPackID),
           case .verified(let transaction) = result,
           transaction.revocationDate == nil {
            dataPack = true
        }

        isPro = pro
        isAnnual = annual
        hasDataPack = dataPack
    }

    private func handleVerified(_ transaction: Transaction) {
        if transaction.productID == Self.creditsID {
            credits += 100
            UserDefaults.standard.set(credits, forKey: creditsKey)
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.handleVerified(transaction)
                await self?.refreshEntitlements()
            }
        }
    }

    var monthlyQuota: Int { isAnnual ? 90 : 60 }

    func officialUsageThisMonth() -> Int {
        let key = monthKey()
        let dict = UserDefaults.standard.dictionary(forKey: usageKey) as? [String: Int] ?? [:]
        return dict[key] ?? 0
    }

    func officialRemaining() -> Int {
        guard isPro else { return 0 }
        return max(monthlyQuota - officialUsageThisMonth(), 0)
    }

    var canUseOfficialEngine: Bool {
        (isPro && officialRemaining() > 0) || credits > 0
    }

    func consumeOfficialAnalysis() {
        if isPro, officialRemaining() > 0 {
            var dict = UserDefaults.standard.dictionary(forKey: usageKey) as? [String: Int] ?? [:]
            let key = monthKey()
            dict[key] = (dict[key] ?? 0) + 1
            UserDefaults.standard.set(dict, forKey: usageKey)
        } else if credits > 0 {
            credits -= 1
            UserDefaults.standard.set(credits, forKey: creditsKey)
        }
    }

    private func monthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: .now)
    }

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }
}
