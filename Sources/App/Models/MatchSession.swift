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
        static let confirmationInterval = 1.0
    }

    private var connections: [String: WebSocket] = [:]

    private var receivedEventInfo: (event: ScoringEvent, count: Int)?

    weak var delegate: MatchSessionDelegate?

    func addConnection(to socket: WebSocket, forJudgeID judgeID: String) throws {
        connections[judgeID] = socket
    }

    func send(jsonString: String) throws {
        for (_, socket) in connections {
            try socket.send(jsonString)
        }
    }

    // TODO: Refactor to allow events other than first received to be confirmed
    func received(event: ScoringEvent) throws {

        if receivedEventInfo != nil {
            if event == receivedEventInfo?.event {
                receivedEventInfo?.count += 1
            } else {
                log("Received conflicting scoring event: \(event.description)")
            }
        } else {
            receivedEventInfo = (event: event, count: 1)
            drop.console.wait(seconds: Constants.confirmationInterval)
            try confirmScoringEvent()
        }
    }

    private func confirmScoringEvent() throws {
        guard let confirmationInfo = receivedEventInfo else { return }

        log("\(confirmationInfo.event.description) scored by \(confirmationInfo.count) of \(connections.count) judges")

        if confirmationInfo.count >= Int(ceil(Double(connections.count) / 2)) {
            delegate?.sessionDidConfirmScoringEvent(scoringEvent: confirmationInfo.event)
            guard let eventString = confirmationInfo.event.jsonString else { throw Abort.notFound }
            try send(jsonString: eventString)
            log("\(confirmationInfo.event.description) confirmed")
        } else {
            log("\(confirmationInfo.event.description) not confirmed")
        }
        receivedEventInfo = nil
    }

}
