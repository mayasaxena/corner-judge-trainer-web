//
//  Match.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/1/16.
//
//

import Vapor
import Foundation

public final class Match: MatchSessionDelegate, JSONRepresentable {

    var id: Int {
        return properties.id
    }

    private let properties = MatchProperties()
    private let session = MatchSession()

    init() {
        session.delegate = self
    }

    convenience init(redPlayerName: String, bluePlayerName: String) {
        self.init()
        properties.add(redPlayerName: redPlayerName, bluePlayerName: bluePlayerName)
    }

    public func makeNode() throws -> Node {
        return try properties.makeNode()
    }

    func received(event: Event, from socket: WebSocket) throws {
        try session.received(event: event, from: socket)
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        properties.updateScore(scoringEvent: scoringEvent)
    }

    // MARK: - JSONRepresentable

    public func makeJSON() throws -> JSON {
        return try properties.makeJSON()
    }
}
