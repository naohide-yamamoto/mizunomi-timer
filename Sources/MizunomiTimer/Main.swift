import AppKit

@MainActor
private var strongAppDelegate: AppDelegate?

@main
enum MizunomiTimerMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        strongAppDelegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
