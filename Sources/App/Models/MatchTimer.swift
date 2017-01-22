//
//  MatchTimer.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 12/25/16.
//
//

import Foundation

final class MatchTimer {
    private var timer: DispatchSourceTimer?
    var timeRemaining: TimeInterval

    var action: (Void) throws -> Void = {}

    var isRunning: Bool {
        return timer != nil
    }

    init(duration: TimeInterval) {
        self.timeRemaining = duration
    }

    func start() {
        let queue = DispatchQueue(label: "timerQueue")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now() + 0.1, interval: .seconds(1), leeway: .milliseconds(100))

        timer?.setEventHandler { [weak self] in
            guard let welf = self else { return }
            welf.timeRemaining -= 1
            if welf.timeRemaining <= 0 {
                welf.stop()
            }
            do {
                try welf.action()
            } catch(let error) {
                print("Timer action failed with error: \(error)")
            }
        }

        timer?.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func reset(time: TimeInterval) {
        stop()
        timeRemaining = time
    }
}
