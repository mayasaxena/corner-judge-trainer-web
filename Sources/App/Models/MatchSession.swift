//
//  Session.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/21/16.
//
//

import Vapor
import Foundation

protocol MatchSessionDelegate: class {
    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent)
}

public final class MatchSession {
    struct Constants {
        static let ConfirmationInterval = 1.0
    }
    var connections: [String: WebSocket] = [:]

    var scoringTimer: Timer?
    var eventConfirmationInfo: (event: ScoringEvent, count: Int)?

    weak var delegate: MatchSessionDelegate?

    public func received(event: String, forColor color: String, fromJudgeWithID id: String) throws {
        guard
            let eventType = ScoringEventType(rawValue: event.capitalized),
            let playerColor = PlayerColor(rawValue: color.capitalized)
        else {
            return
        }

        let receivedScoringEvent = ScoringEvent(type: eventType, color: playerColor)

        if var eventConfirmationInfo = eventConfirmationInfo {
            if receivedScoringEvent == eventConfirmationInfo.event {
                eventConfirmationInfo.count += 1
            } else {
                print("RECEIVED CONFLICTING SCORING EVENT: \(receivedScoringEvent)")
            }
        } else {
            eventConfirmationInfo = (event: receivedScoringEvent, count: 1)
            drop.console.wait(seconds: Constants.ConfirmationInterval)
            try confirmScoringEvent()
        }
    }

    dynamic public func confirmScoringEvent() throws {
        guard let confirmationInfo = eventConfirmationInfo else { return }
        if confirmationInfo.count >= Int(ceil(Double(connections.count / 2))) {
            delegate?.sessionDidConfirmScoringEvent(scoringEvent: confirmationInfo.event)
            for (_, socket) in connections {
                try socket.send("scored \(confirmationInfo.event)")
            }
        } else {
            print("Event not confirmed")
        }
    }
}

public func After(_ after: TimeInterval, on queue: DispatchQueue = DispatchQueue.main, op: @escaping () -> ()) {
    let seconds = Int64(after * Double(NSEC_PER_SEC))
    let dispatchTime = DispatchTime.now() + Double(seconds) / Double(NSEC_PER_SEC)

    queue.asyncAfter(deadline: dispatchTime, execute: op)
}
