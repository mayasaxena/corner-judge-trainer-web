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
    private let queue = DispatchQueue(label: "timerQueue")

    private var timer: DispatchSourceTimer?
    private var timeRemaining: TimeInterval

    var action: (Void) -> Void = {}

    var isRunning: Bool {
        return timer != nil
    }

    var isDone: Bool {
        return timeRemaining <= 0
    }

    var displayTime: String {
        return timeRemaining.formattedTimeString
    }

    init(duration: TimeInterval) {
        self.timeRemaining = duration
    }

    func start() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now() + 0.1, interval: .seconds(1), leeway: .milliseconds(100))

        timer?.setEventHandler { [weak self] in
            guard let welf = self else { return }

            welf.timeRemaining -= 1

            welf.action()

            if welf.timeRemaining < 1 {
                welf.stop()
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

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
}

private extension TimeInterval {
    var formattedTimeString: String {
        return String(format: "%d:%02d", Int(self / 60.0),  Int(ceil(self.truncatingRemainder(dividingBy: 60))))
    }
}
