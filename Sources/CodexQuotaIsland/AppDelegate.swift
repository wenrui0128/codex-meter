import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = QuotaStore(service: CodexQuotaService())
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController(store: store)

        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }
}
