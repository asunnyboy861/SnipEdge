import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    @StateObject private var purchase = SubscriptionManager.shared
    @StateObject private var viewModel = AnalysisViewModel()
    @Query(sort: \GradeRecord.createdAt, order: .reverse) private var records: [GradeRecord]

    @State private var pickedItem: PhotosPickerItem?
    @State private var showAnalysis = false
    @State private var showPaywall = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    quotaCard
                    captureButtons
                    shareHint
                    archive
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 64)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("SnipEdge")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: purchase.isPro ? "checkmark.seal.fill" : "sparkles")
                            .foregroundStyle(purchase.isPro ? Theme.up : Theme.brand)
                    }
                    .accessibilityLabel(purchase.isPro ? "Pro active" : "Upgrade to Pro")
                }
            }
            .sheet(isPresented: $showAnalysis, onDismiss: { viewModel.reset() }) {
                AnalysisSheetView(viewModel: viewModel, purchase: purchase, onUpgrade: { showPaywall = true })
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    showCamera = false
                    start(image)
                }
            }
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                loadPicked(item)
            }
            .onChange(of: appState.pendingImage) { _, image in
                guard let image else { return }
                appState.pendingImage = nil
                start(image)
            }
            .task {
                viewModel.refreshQuota()
                await OutcomeTracker.resolvePending(context: context)
                if let image = appState.pendingImage {
                    appState.pendingImage = nil
                    start(image)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Snap a chart.")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Get the grade.")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Theme.brand)
            Text("Verified levels, historical win rate, and a plan in about 10 seconds.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var quotaCard: some View {
        SectionCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.isPro ? "Pro active" : "Free grades left today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(purchase.isPro ? "\(purchase.officialRemaining()) + \(purchase.credits) deep analyses" : "\(viewModel.freeRemaining) / 3")
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundStyle(purchase.isPro ? Theme.up : Theme.textPrimary)
                }
                Spacer()
                Button {
                    if purchase.isPro == false { showPaywall = true }
                } label: {
                    Text(purchase.isPro ? "Manage" : "Go Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.brand)
                }
                .accessibilityLabel(purchase.isPro ? "Manage subscription" : "Upgrade to Pro")
            }
        }
    }

    private var captureButtons: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Grade a chart from Photos")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Color.black)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose a chart screenshot from Photos")

            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Capture with Camera")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Capture a chart with the camera")
        }
    }

    private var shareHint: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Zero-input shortcut", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brand)
                Text("In any charting app, tap Share and choose SnipEdge. The chart opens here automatically — no taps inside the app.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent analyses")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if records.isEmpty == false {
                    Text("\(records.count)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if records.isEmpty {
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No grades yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Your graded charts appear here with WIN, LOSS, or OPEN status after 72 hours.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
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

    private func loadPicked(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                await MainActor.run { start(image) }
            }
            await MainActor.run { pickedItem = nil }
        }
    }

    private func start(_ image: UIImage) {
        showAnalysis = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            await viewModel.start(image: image, context: context, purchase: purchase)
        }
    }
}

struct RecordRow: View {
    let record: GradeRecord

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(record.timeframe)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(record.patternName)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                GradeBadge(letter: record.letter, size: 26)
                OutcomeChip(outcome: record.outcome)
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.symbol) \(record.timeframe), grade \(record.letter), \(record.outcome.label)")
    }

    private var thumbnail: some View {
        Group {
            if let image = AnalysisOrchestrator.image(named: record.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Theme.surfaceElevated
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OutcomeChip: View {
    let outcome: Outcome

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: outcome.symbolName)
            Text(outcome.label)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityLabel(outcome.label)
    }

    private var color: Color {
        switch outcome {
        case .win: return Theme.up
        case .loss: return Theme.down
        case .open, .ambiguous: return Theme.warning
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void

        init(onImage: @escaping (UIImage) -> Void) {
            self.onImage = onImage
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
