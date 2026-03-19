import AppKit
import SwiftUI
import SwiftData

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var dropdownPanel: NSPanel?
    private var floatingPanel: FloatingPanel?
    private let viewModel: TimerViewModel
    private var displayTimer: Timer?
    private var eventMonitor: Any?
    private var modelContainer: ModelContainer?

    init(viewModel: TimerViewModel, modelContainer: ModelContainer) {
        self.viewModel = viewModel
        self.modelContainer = modelContainer
        super.init()
        setupStatusItem()
        startDisplayUpdates()
    }

    private static let timerFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
            button.action = #selector(togglePanel)
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
            button.attributedTitle = NSAttributedString()
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
        } else {
            button.image = nil
            let attrs: [NSAttributedString.Key: Any] = [.font: Self.timerFont]
            button.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        }
    }

    // MARK: - Dropdown Panel

    @objc private func togglePanel() {
        if let panel = dropdownPanel, panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem?.button,
              let buttonWindow = button.window,
              let container = modelContainer else { return }

        // Get button's right edge in screen coordinates — this never moves
        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrameInWindow)
        let rightEdgeX = buttonScreenFrame.maxX

        let panelWidth = Constants.popoverWidth
        let panelHeight = Constants.popoverHeight

        // Position: right edge of panel aligns with right edge of button, just below menu bar
        let panelX = rightEdgeX - panelWidth
        let panelY = buttonScreenFrame.minY - panelHeight

        let panel = KeyablePanel(
            contentRect: NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let contentView = TimerPopoverView(viewModel: viewModel, onDetach: { [weak self] in
            self?.detachToFloatingPanel()
        }, onClose: { [weak self] in
            self?.closePanel()
        })
        .modelContainer(container)

        panel.contentView = NSHostingView(rootView: contentView)
        panel.orderFrontRegardless()
        panel.makeKey()

        dropdownPanel = panel

        // Close when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        dropdownPanel?.contentView = nil
        dropdownPanel?.orderOut(nil)
        dropdownPanel = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func detachToFloatingPanel() {
        closePanel()

        let size: CGFloat = 250
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: size, height: size))
        panel.minSize = NSSize(width: 150, height: 150)

        let contentView = FloatingTimerView(viewModel: viewModel, onClose: { [weak self] in
            self?.floatingPanel?.contentView = nil
            self?.floatingPanel?.orderOut(nil)
            self?.floatingPanel = nil
        })
        panel.contentView = NSHostingView(rootView: contentView)
        panel.center()
        panel.orderFrontRegardless()

        floatingPanel = panel
    }
}
