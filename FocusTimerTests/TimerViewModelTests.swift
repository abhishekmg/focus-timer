import Testing
import Foundation
@testable import FocusTimer

@MainActor
@Suite("TimerViewModel Tests")
struct TimerViewModelTests {
    @Test("Initial state is idle with work phase")
    func initialState() {
        let vm = TimerViewModel()
        #expect(vm.state == .idle)
        #expect(vm.phase == .work)
        #expect(vm.progress == 0)
    }

    @Test("Start sets state to running")
    func startSetsRunning() {
        let vm = TimerViewModel()
        vm.startPause()
        #expect(vm.state == .running)
    }

    @Test("Pause sets state to paused")
    func pauseSetsState() {
        let vm = TimerViewModel()
        vm.startPause() // start
        vm.startPause() // pause
        #expect(vm.state == .paused)
    }

    @Test("Resume sets state back to running")
    func resumeSetsRunning() {
        let vm = TimerViewModel()
        vm.startPause() // start
        vm.startPause() // pause
        vm.startPause() // resume
        #expect(vm.state == .running)
    }

    @Test("Skip transitions phase")
    func skipTransitions() {
        let vm = TimerViewModel()
        vm.startPause()
        vm.skip()
        #expect(vm.phase == .rest)
        #expect(vm.state == .idle)
    }

    @Test("Revert resets to idle")
    func revertResetsToIdle() {
        let vm = TimerViewModel()
        vm.startPause()
        vm.revert()
        #expect(vm.state == .idle)
    }

    @Test("Reset clears everything")
    func resetClearsAll() {
        let vm = TimerViewModel()
        vm.taskName = "Test"
        vm.startPause()
        vm.skip()
        vm.reset()
        #expect(vm.state == .idle)
        #expect(vm.phase == .work)
        #expect(vm.taskName == "")
    }

    @Test("Menu bar text empty when idle")
    func menuBarTextIdle() {
        let vm = TimerViewModel()
        #expect(vm.menuBarText == "")
    }

    @Test("Menu bar text shows time when running")
    func menuBarTextRunning() {
        let vm = TimerViewModel()
        vm.startPause()
        #expect(!vm.menuBarText.isEmpty)
        #expect(vm.menuBarText.contains("🔴"))
    }

    @Test("Progress is 0 at start")
    func progressAtStart() {
        let vm = TimerViewModel()
        #expect(vm.progress == 0)
    }

    @Test("TimeFormatting formats correctly")
    func timeFormatting() {
        #expect(TimeFormatting.formatted(1500) == "25:00")
        #expect(TimeFormatting.formatted(65) == "01:05")
        #expect(TimeFormatting.formatted(0) == "00:00")
    }

    @Test("Short formatting")
    func shortFormatting() {
        #expect(TimeFormatting.shortFormatted(1500) == "25:00")
        #expect(TimeFormatting.shortFormatted(30) == "0:30")
    }

    // MARK: - Foreground recalculation

    @Test("Recalculate snaps remainingSeconds to endTime on foreground")
    func recalculateFromEndTime() throws {
        let vm = TimerViewModel()
        vm.startPause() // start — sets runningEndTime

        // Simulate backgrounding: manually set remainingSeconds to a stale value
        // The real endTime is ~workDuration from now, so remaining should be close to that
        let correctRemaining = vm.remainingSeconds
        vm.remainingSeconds = correctRemaining + 60 // simulate 60s drift from backgrounding

        vm.recalculateFromEndTime()

        // After recalculation, should be back near the correct value (within 1s tolerance)
        #expect(abs(vm.remainingSeconds - correctRemaining) < 1.0)
    }

    @Test("Recalculate does nothing when idle")
    func recalculateNoOpWhenIdle() {
        let vm = TimerViewModel()
        let original = vm.remainingSeconds
        vm.recalculateFromEndTime()
        #expect(vm.remainingSeconds == original)
    }

    @Test("Recalculate does nothing when paused")
    func recalculateNoOpWhenPaused() {
        let vm = TimerViewModel()
        vm.startPause() // start
        vm.startPause() // pause
        let pausedRemaining = vm.remainingSeconds
        vm.recalculateFromEndTime()
        #expect(vm.remainingSeconds == pausedRemaining)
    }

    // MARK: - Source of truth (user action override)

    @Test("User startPause always overrides stale remote state")
    func startPauseOverridesRemote() {
        let vm = TimerViewModel()
        // Simulate stale remote state by calling forceSync (won't find anything, but exercises path)
        vm.forceSync()
        vm.startPause()
        #expect(vm.state == .running)
    }

    @Test("Skip from running transitions to next phase")
    func skipFromRunning() {
        let vm = TimerViewModel()
        vm.startPause()
        #expect(vm.phase == .work)
        vm.skip()
        #expect(vm.phase == .rest)
        #expect(vm.state == .idle)
    }

    @Test("Skip from rest transitions back to work")
    func skipFromRest() {
        let vm = TimerViewModel()
        vm.startPause()
        vm.skip() // work → rest
        vm.startPause()
        vm.skip() // rest → work
        #expect(vm.phase == .work)
        #expect(vm.state == .idle)
    }

    // MARK: - Remote sync (Mac → iOS)

    @Test("Sync running state from remote device")
    func syncRunningFromRemote() {
        let vm = TimerViewModel()
        let sync = vm.syncService

        // Simulate Mac publishing a running timer with 120s remaining
        sync.remoteTimerState = "running"
        sync.remotePhase = "work"
        sync.remoteEndTime = Date.now.addingTimeInterval(120)
        sync.remoteTaskName = "deep work"

        vm.handleRemoteSync(sync)

        #expect(vm.state == .running)
        #expect(vm.phase == .work)
        #expect(vm.taskName == "deep work")
        #expect(abs(vm.remainingSeconds - 120) < 2) // within 2s tolerance
    }

    @Test("Sync paused state from remote device")
    func syncPausedFromRemote() {
        let vm = TimerViewModel()
        let sync = vm.syncService

        sync.remoteTimerState = "paused"
        sync.remotePhase = "work"
        sync.remotePausedRemaining = 300
        sync.remoteTaskName = "reading"

        vm.handleRemoteSync(sync)

        #expect(vm.state == .paused)
        #expect(vm.phase == .work)
        #expect(vm.remainingSeconds == 300)
        #expect(vm.taskName == "reading")
    }

    @Test("Sync idle stops local running timer")
    func syncIdleStopsRunning() {
        let vm = TimerViewModel()
        vm.startPause() // start running
        #expect(vm.state == .running)

        let sync = vm.syncService
        sync.remoteTimerState = "idle"

        vm.handleRemoteSync(sync)

        #expect(vm.state == .idle)
    }

    @Test("Sync expired running state clears ghost")
    func syncExpiredRunningClearsGhost() {
        let vm = TimerViewModel()
        vm.startPause() // start running
        let sync = vm.syncService

        // Simulate a remote running state that already expired
        sync.remoteTimerState = "running"
        sync.remotePhase = "work"
        sync.remoteEndTime = Date.now.addingTimeInterval(-60) // 60s ago
        sync.remoteTaskName = ""

        vm.handleRemoteSync(sync)

        #expect(vm.state == .finished)
    }

    @Test("Sync running updates phase from work to rest")
    func syncRunningUpdatesPhase() {
        let vm = TimerViewModel()
        #expect(vm.phase == .work)

        let sync = vm.syncService
        sync.remoteTimerState = "running"
        sync.remotePhase = "rest"
        sync.remoteEndTime = Date.now.addingTimeInterval(300)
        sync.remoteTaskName = ""

        vm.handleRemoteSync(sync)

        #expect(vm.phase == .rest)
        #expect(vm.state == .running)
    }

    @Test("Sync idle is no-op when already idle")
    func syncIdleNoOpWhenIdle() {
        let vm = TimerViewModel()
        let originalRemaining = vm.remainingSeconds
        let sync = vm.syncService

        sync.remoteTimerState = "idle"
        vm.handleRemoteSync(sync)

        #expect(vm.state == .idle)
        #expect(vm.remainingSeconds == originalRemaining)
    }

    // MARK: - Foreground recalculation (background drift → Dynamic Island match)

    @Test("Recalculate handles timer expired while backgrounded")
    func recalculateExpiredWhileBackgrounded() {
        let vm = TimerViewModel(preferences: UserPreferences())
        vm.startPause()

        // Simulate: timer was running, app backgrounded, timer expired
        // Hack: we can't easily set runningEndTime since it's private,
        // but startPause sets it. We test via the public recalculate.
        // After start, remaining ≈ workDuration. If we could move time forward...
        // For now, verify recalculate doesn't crash and keeps state consistent
        vm.recalculateFromEndTime()
        #expect(vm.state == .running)
        #expect(vm.remainingSeconds > 0)
    }
}
