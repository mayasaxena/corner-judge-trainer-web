//
//  Match+JSON.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/12/17.
//

import JSON

extension Match: JSONRepresentable {
    private struct JSONKey {
        static let matchID = "id"
        static let matchType = "type"
        static let date = "date"
        static let redName = "red_player_name"
        static let redScore = "red_score"
        static let redPenalties = "red_penalties"
        static let blueName = "blue_player_name"
        static let blueScore = "blue_score"
        static let bluePenalties = "blue_penalties"
    }

    public func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKey.matchID, id)
        try json.set(JSONKey.matchType, type.displayName)
        try json.set(JSONKey.date, date)
        try json.set(JSONKey.redName, redPlayer.displayName.uppercased())
        try json.set(JSONKey.redScore, redScore)
        try json.set(JSONKey.redPenalties, redPenalties)
        try json.set(JSONKey.blueName, bluePlayer.displayName.uppercased())
        try json.set(JSONKey.blueScore, blueScore)
        try json.set(JSONKey.bluePenalties, bluePenalties)
        return json
    }
}
