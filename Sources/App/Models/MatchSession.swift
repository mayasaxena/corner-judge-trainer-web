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

    private typealias ParticipantConnection = (type: ParticipantType, socket: WebSocket)
    private var connections: [String: ParticipantConnection] = [:]

    private var judgeIDs: [String] {
        return connections
            .filter { $0.value.type == .judge }
            .map { $0.key }
    }

    private var operatorIDs: [String] {
        return connections
            .filter { $0.value.type == .operator }
            .map { $0.key }
    }

    private var receivedEventInfo: (event: ScoringEvent, count: Int)?

    weak var delegate: MatchSessionDelegate?

    func addConnection(participantID: String, participantType: ParticipantType, socket: WebSocket) {
        connections[participantID] = (participantType, socket)
    }

    func removeConnection(socket: WebSocket) {
        if let idToRemove = getID(for: socket) {
            connections.removeValue(forKey: idToRemove)
        }
    }

    private func getID(for socket: WebSocket) -> String? {
        return connections.filter ({ $0.value.socket === socket }).first?.key
    }

    func isOperator(participantID: String) -> Bool {
        return operatorIDs.contains(participantID)
    }

    func send(statusUpdate: StatusUpdate) throws {
        try send(jsonString: statusUpdate.jsonString)
    }

    private func send(jsonString: String?) throws {

        guard let json = jsonString else {
            let message = "Could not convert event to JSON"
            log(message)
            throw Abort(.badRequest, reason: message)
        }

        for (_, connection) in connections {
            try connection.socket.send(json)
        }
    }

    // TODO: Refactor to allow events other than first received to be confirmed
    func received(event: ScoringEvent) throws {
        guard judgeIDs.contains(event.participantID) else { return }

        if receivedEventInfo != nil {
            if event == receivedEventInfo?.event {
                receivedEventInfo?.count += 1
            } else {
                log("Received conflicting scoring event: \(event.description)")
            }
        } else {
            receivedEventInfo = (event: event, count: 1)
            droplet.console.wait(seconds: Constants.confirmationInterval)
            try confirmScoringEvent()
        }
    }

    private func confirmScoringEvent() throws {
        guard let confirmationInfo = receivedEventInfo else { return }
        log("\(confirmationInfo.event.description) scored by \(confirmationInfo.count) of \(judgeIDs.count) judges")

        if confirmationInfo.count >= Int(ceil(Double(judgeIDs.count) / 2)) {
            delegate?.sessionDidConfirmScoringEvent(scoringEvent: confirmationInfo.event)
            log("\(confirmationInfo.event.description) confirmed")
        } else {
            log("\(confirmationInfo.event.description) not confirmed")
        }

        receivedEventInfo = nil
    }

}
