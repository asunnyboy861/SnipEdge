import SwiftUI
import SwiftData

struct ProofView: View {
    @Query(sort: \GradeRecord.createdAt, order: .reverse) private var records: [GradeRecord]
    @StateObject private var viewModel = ProofViewModel()
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    statsGrid
                    if records.isEmpty {
                        emptyState
                    } else {
                        history
                    }
                    DisclaimerBanner()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 64)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("Proof")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await OutcomeTracker.resolvePending(context: context)
                viewModel.refresh(records: records)
            }
            .onChange(of: records.count) { _, _ in
                viewModel.refresh(records: records)
            }
        }
    }

    private var header: some View {
        SectionCard {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your personal win rate")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(viewModel.stats.total == 0 ? "—" : "\(Int(viewModel.stats.winRate * 100))%")
                        .font(.system(size: 48, weight: .heavy, design: .monospaced))
                        .foregroundStyle(viewModel.stats.winRate >= 0.5 ? Theme.up : Theme.warning)
                    Text("\(viewModel.stats.wins)W · \(viewModel.stats.losses)L · \(viewModel.stats.total) graded")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if viewModel.stats.currentStreak >= 5 {
                    VStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 40))
                        Text("\(viewModel.stats.currentStreak) streak")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.warning)
                    }
                    .accessibilityLabel("Hot streak, \(viewModel.stats.currentStreak) wins in a row")
                }
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCard(title: "Average R", value: String(format: "%.2f", viewModel.stats.averageR))
            statCard(title: "Best streak", value: "\(viewModel.stats.bestStreak)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var emptyState: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Proof builds itself", systemImage: "checkmark.seal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brand)
                Text("Save graded charts and come back after 72 hours. We check whether the target or the stop was hit first and update this page automatically.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            ForEach(records) { record in
                NavigationLink {
                    RecordDetailView(record: record)
                } label: {
                    RecordRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
