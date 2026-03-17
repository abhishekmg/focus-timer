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
}
