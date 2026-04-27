import AppKit

@MainActor
final class AboutWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Mizunomi Timer"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        buildContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        let iconView = NSImageView(image: NSApp.applicationIconImage)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown

        let nameLabel = NSTextField(labelWithString: "Mizunomi Timer")
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.alignment = .center

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font = .systemFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        let copyrightLabel = NSTextField(labelWithString: "Copyright © 2026 Naohide Yamamoto")
        copyrightLabel.font = .systemFont(ofSize: 12)
        copyrightLabel.textColor = .secondaryLabelColor
        copyrightLabel.alignment = .center

        let stack = NSStackView(views: [iconView, nameLabel, versionLabel, copyrightLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
