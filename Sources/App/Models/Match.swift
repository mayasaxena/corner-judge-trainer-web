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

    let info = MatchInfo()
    let session = MatchSession()

    init() {
        session.delegate = self
    }

    public func makeNode() throws -> Node {
        return try info.makeNode()
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        print("Confirmed \(scoringEvent)")
    }

    // MARK: - JSONRepresentable

    public func makeJSON() throws -> JSON {
        return try info.makeJSON()
    }
}
