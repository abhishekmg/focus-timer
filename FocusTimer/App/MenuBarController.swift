import AppKit
import SwiftUI
import SwiftData

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var floatingPanel: FloatingPanel?
    private let viewModel: TimerViewModel
    private var displayTimer: Timer?

    init(viewModel: TimerViewModel, modelContainer: ModelContainer) {
        self.viewModel = viewModel
        super.init()
        setupStatusItem()
        setupPopover(modelContainer: modelContainer)
        startDisplayUpdates()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func startDisplayUpdates() {
        let t = Timer(timeInterval: 0.5, target: self, selector: #selector(fireDisplayUpdate), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        displayTimer = t
    }

    @objc private func fireDisplayUpdate() {
        guard let button = statusItem?.button else { return }
        let text = viewModel.menuBarText
        if text.isEmpty {
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
        } else {
            button.image = nil
            button.title = text
        }
    }

    private func setupPopover(modelContainer: ModelContainer) {
        let contentView = TimerPopoverView(viewModel: viewModel, onDetach: { [weak self] in
            self?.detachToPanel(modelContainer: modelContainer)
        })
        .modelContainer(modelContainer)

        popover.contentSize = NSSize(
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        )
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func detachToPanel(modelContainer: ModelContainer) {
        popover.performClose(nil)

        let panel = FloatingPanel(contentRect: NSRect(
            x: 0, y: 0,
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        ))

        let contentView = TimerPopoverView(viewModel: viewModel)
            .modelContainer(modelContainer)
        panel.contentView = NSHostingView(rootView: contentView)
        panel.center()
        panel.orderFrontRegardless()

        floatingPanel = panel
    }
}
