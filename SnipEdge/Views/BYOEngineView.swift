import SwiftUI

struct BYOEngineView: View {
    @StateObject private var viewModel = BYOEngineViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                providerPicker
                fields
                testRow
                saveButton
                profilesSection
                DisclaimerBanner()
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("AI Engine")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.reload() }
    }

    private var intro: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bring your own key")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brand)
                Text("Deep analysis is unlimited with your own key. Keys are stored only in this device's Keychain and never leave the device.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Provider")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AIProvider.allCases) { provider in
                        Button {
                            viewModel.provider = provider
                            viewModel.applyProviderDefaults()
                        } label: {
                            Text(provider.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(viewModel.provider == provider ? Color.black : Theme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(viewModel.provider == provider ? Theme.brand : Theme.surface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Provider \(provider.title)")
                    }
                }
            }
        }
    }

    private var fields: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                field(title: "Base URL", text: $viewModel.baseURL, placeholder: "https://api.example.com/v1")
                field(title: "Model", text: $viewModel.model, placeholder: "model name")
                Toggle(isOn: $viewModel.supportsVision) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vision capable")
                            .foregroundStyle(Theme.textPrimary)
                        Text("Deep analysis needs a model that can read images. Text-only models are used for text tasks only.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .tint(Theme.brand)

                VStack(alignment: .leading, spacing: 6) {
                    Text("API key")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    SecureField(viewModel.editingID == nil ? "Paste your key" : "Leave empty to keep the saved key", text: $viewModel.apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.textPrimary)
                }

                if let profile = viewModel.profiles.first(where: { $0.id == viewModel.editingID }), profile.keySuffix.isEmpty == false {
                    Text("Saved key ending ••••\(profile.keySuffix)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(12)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var testRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await viewModel.testConnection() }
            } label: {
                HStack {
                    if viewModel.isTesting {
                        ProgressView()
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text("Test connection")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isTesting)

            if let connection = viewModel.connection {
                HStack(spacing: 6) {
                    Image(systemName: connection.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(connection.success ? Theme.up : Theme.down)
                    Text(connection.message)
                        .font(.caption)
                        .foregroundStyle(connection.success ? Theme.up : Theme.down)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            viewModel.saveProfile()
        } label: {
            Text(viewModel.editingID == nil ? "Save profile" : "Update profile")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.canSave == false)
        .opacity(viewModel.canSave ? 1 : 0.5)
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved profiles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            if viewModel.profiles.isEmpty {
                Text("No saved profiles yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(viewModel.profiles) { profile in
                    HStack(spacing: 10) {
                        Button {
                            viewModel.activate(profile)
                        } label: {
                            Image(systemName: profile.isActive ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(profile.isActive ? Theme.brand : Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(profile.isActive ? "Active profile" : "Activate profile")

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(profile.provider.title) · \(profile.model)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(profile.supportsVision ? "Vision enabled" : "Text only — not used for deep analysis")
                                .font(.caption2)
                                .foregroundStyle(profile.supportsVision ? Theme.textSecondary : Theme.warning)
                        }
                        Spacer()
                        Button {
                            viewModel.beginEditing(profile)
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit profile")

                        Button {
                            viewModel.delete(profile)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.down)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete profile")
                    }
                    .padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
