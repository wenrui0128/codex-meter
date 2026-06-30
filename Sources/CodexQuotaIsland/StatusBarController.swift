import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let store: QuotaStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()

    init(store: QuotaStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configurePopover()
        bind()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "Codex")
        button.imagePosition = .imageLeading
        button.action = #selector(togglePopover(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusTitle()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: QuotaPopoverView(store: store)
        )
    }

    private func bind() {
        store.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusTitle() }
            .store(in: &cancellables)

        store.$now
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusTitle() }
            .store(in: &cancellables)
    }

    private func updateStatusTitle() {
        let remaining = store.snapshot.fiveHourWindow?.remainingPercent.map { "\($0)%" } ?? "--"
        let countdown = store.snapshot.fiveHourWindow?.resetAt?.menuCountdown(from: store.now) ?? "--:--"
        statusItem.button?.title = " \(remaining) \(countdown)"
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            showPopover()
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        popover.isShown ? popover.performClose(sender) : showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.refresh, action: #selector(refreshNow), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshNow() {
        Task { await store.refresh() }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private extension Date {
    func menuCountdown(from now: Date) -> String {
        let seconds = max(0, Int(timeIntervalSince(now)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60

        if hours > 99 {
            let days = hours / 24
            return "\(days)d"
        }

        return String(format: "%d:%02d", hours, minutes)
    }
}
