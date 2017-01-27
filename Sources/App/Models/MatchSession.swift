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
    private struct Constants {
        static let ConfirmationInterval = 1.0
    }

    private var connections: [String: WebSocket] = [:]

    private var receivedEventInfo: (event: ScoringEvent, count: Int)?

    weak var delegate: MatchSessionDelegate?

    func received(event: ScoringEvent) throws {
        if receivedEventInfo != nil {
            if event == receivedEventInfo?.event {
                receivedEventInfo?.count += 1
            } else {
                print("RECEIVED CONFLICTING SCORING EVENT: \(event)")
            }
        } else {
            receivedEventInfo = (event: event, count: 1)
            drop.console.wait(seconds: Constants.ConfirmationInterval)
            try confirmScoringEvent()
        }
    }

    func addConnection(to socket: WebSocket, forJudgeID judgeID: String) throws {
        connections[judgeID] = socket
    }

    private func confirmScoringEvent() throws {
        guard let confirmationInfo = receivedEventInfo else { return }
        if confirmationInfo.count >= Int(ceil(Double(connections.count) / 2)) {
            delegate?.sessionDidConfirmScoringEvent(scoringEvent: confirmationInfo.event)
            guard let eventString = confirmationInfo.event.jsonString else { throw Abort.notFound }
            try send(jsonString: eventString)
        } else {
            print("Event not confirmed")
        }
        receivedEventInfo = nil
    }

    func send(jsonString: String) throws {
        for (_, socket) in connections {
            try socket.send(jsonString)
        }
    }
}
