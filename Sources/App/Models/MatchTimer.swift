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
    private var timeRemaining: TimeInterval

//    private var handler: (Void) -> Void

    init(duration: TimeInterval) {
        self.timeRemaining = duration
//        self.handler = handler
    }

    func start() {
        let queue = DispatchQueue(label: "timerQueue")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(1), leeway: .seconds(1))

        timer?.setEventHandler { [weak self] in
            guard let welf = self else { return }
            welf.timeRemaining -= 1
            if welf.timeRemaining <= 0 {
                welf.stop()
            }
//            welf.handler()
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
