import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let openButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.055, green: 0.067, blue: 0.086, alpha: 1)
        configureViews()
        loadSharedImage()
    }

    private func configureViews() {
        titleLabel.text = "Chart ready"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Grading continues in SnipEdge."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 0.62, green: 0.66, blue: 0.71, alpha: 1)
        subtitleLabel.textAlignment = .center

        openButton.setTitle("Open SnipEdge", for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        openButton.setTitleColor(.black, for: .normal)
        openButton.backgroundColor = UIColor(red: 0.078, green: 0.722, blue: 0.651, alpha: 1)
        openButton.layer.cornerRadius = 14
        openButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        openButton.addTarget(self, action: #selector(openHostApp), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, openButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadSharedImage() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            finish()
            return
        }
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                    guard let self else { return }
                    guard let data, let image = UIImage(data: data) else {
                        DispatchQueue.main.async { self.finish() }
                        return
                    }
                    _ = ShareInbox.write(image)
                    DispatchQueue.main.async {
                        self.subtitleLabel.text = "Saved. Tap below to grade it."
                        self.openHostApp()
                    }
                }
                return
            }
        }
        finish()
    }

    @objc private func openHostApp() {
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: URL(string: "snipedge://grade"))
                break
            }
            responder = current.next
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
