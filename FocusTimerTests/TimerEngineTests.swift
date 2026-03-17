import Testing
import Foundation
@testable import FocusTimer

@MainActor
@Suite("TimerEngine Tests")
struct TimerEngineTests {
    @Test("Engine starts and reports running")
    func engineStarts() {
        let engine = TimerEngine()
        engine.start { }
        #expect(engine.isRunning)
        engine.stop()
    }

    @Test("Engine stops and reports not running")
    func engineStops() {
        let engine = TimerEngine()
        engine.start { }
        engine.stop()
        #expect(!engine.isRunning)
    }

    @Test("Engine is not running initially")
    func engineInitialState() {
        let engine = TimerEngine()
        #expect(!engine.isRunning)
    }
}
