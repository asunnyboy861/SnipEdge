import SwiftUI

enum SupportSubject: String, CaseIterable, Identifiable {
    case general, feature, bug, usage, performance, ui, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .feature: return "Feature Suggestion"
        case .bug: return "Bug Report"
        case .usage: return "Usage Question"
        case .performance: return "Performance Issue"
        case .ui: return "UI Improvement"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .feature: return "lightbulb.fill"
        case .bug: return "ant.fill"
        case .usage: return "questionmark.circle.fill"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .ui: return "paintpalette.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct ContactSupportView: View {
    @State private var subject: SupportSubject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var banner: Banner?

    private let messageLimit = 1000

    struct Banner: Identifiable {
        let id = UUID()
        let text: String
        let success: Bool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                subjectGrid
                if subject == .other {
                    customSubjectField
                }
                inputFields
                submitButton
                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                if let banner {
                    HStack(spacing: 6) {
                        Image(systemName: banner.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(banner.text)
                    }
                    .font(.caption)
                    .foregroundStyle(banner.success ? Theme.up : Theme.down)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((banner.success ? Theme.up : Theme.down).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is this about?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SupportSubject.allCases.filter { $0 != .other }) { item in
                    subjectTile(item)
                }
            }
            subjectTile(.other)
        }
    }

    private func subjectTile(_ item: SupportSubject) -> some View {
        Button {
            subject = item
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                Image(systemName: subject == item ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                    .opacity(subject == item ? 1 : 0.35)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(subject == item ? Theme.brand : Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(subject == item ? Color.black : Theme.textPrimary)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(subject == item ? Theme.brand : Theme.separator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(subject == item ? .isSelected : [])
    }

    private var customSubjectField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Custom subject")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField("Tell us the topic", text: $customSubject)
                .padding(12)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(title: "Name", placeholder: "Your name", text: $name)
            field(title: "Email", placeholder: "yourname@example.com", text: $email, keyboard: .emailAddress)

            VStack(alignment: .leading, spacing: 6) {
                Text("Message")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextEditor(text: $message)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(8)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Theme.textPrimary)
                    .onChange(of: message) { _, value in
                        if value.count > messageLimit {
                            message = String(value.prefix(messageLimit))
                        }
                    }
                Text("\(message.count) / \(messageLimit)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func field(title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textContentType(keyboard == .emailAddress ? .emailAddress : .name)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(12)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            if isSending {
                ProgressView()
                    .tint(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("Submit")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(canSubmit == false || isSending)
        .opacity(canSubmit ? 1 : 0.5)
    }

    private var canSubmit: Bool {
        let subjectValue = subject == .other ? customSubject : subject.title
        return name.trimmingCharacters(in: .whitespaces).isEmpty == false
            && isValidEmail(email)
            && message.trimmingCharacters(in: .whitespaces).isEmpty == false
            && subjectValue.trimmingCharacters(in: .whitespaces).isEmpty == false
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func submit() async {
        isSending = true
        banner = nil
        let subjectValue = subject == .other ? customSubject : subject.title
        do {
            try await SupportService.submit(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                subject: subjectValue,
                message: message.trimmingCharacters(in: .whitespaces)
            )
            banner = Banner(text: "Thank you! Your feedback has been sent.", success: true)
            message = ""
            customSubject = ""
            subject = .general
        } catch {
            banner = Banner(text: error.localizedDescription, success: false)
        }
        isSending = false
    }
}
