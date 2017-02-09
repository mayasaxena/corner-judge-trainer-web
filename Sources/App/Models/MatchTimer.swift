//
//  MatchTimer.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 12/25/16.
//
//

import Foundation
import Dispatch

final class MatchTimer {
    private var timer: DispatchSourceTimer?
    var timeRemaining: TimeInterval

    var action: (Void) -> Void = {}

    var isRunning: Bool {
        return timer != nil
    }

    var isDone: Bool {
        return timeRemaining <= 0
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

            if welf.timeRemaining <= 0 {
                welf.stop()
            } else {
                welf.timeRemaining -= 1
            }
            welf.action()
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
