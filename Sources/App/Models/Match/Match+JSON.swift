//
//  Match+JSON.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/12/17.
//

import JSON

extension Match: JSONRepresentable {
    private struct JSONKey {
        static let id = "id"
        static let type = "type"
        static let date = "date"
        static let red = "red"
        static let blue = "blue"
        static let name = "name"
        static let score = "score"
        static let penalties = "penalties"
    }

    public func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKey.id, id)
        try json.set(JSONKey.type, type.rawValue)
        try json.set(JSONKey.date, date.timeIntervalSince1970)

        var redJSON = JSON()
        try redJSON.set(JSONKey.name, redPlayer.displayName.uppercased())
        try redJSON.set(JSONKey.score, redScore)
        try redJSON.set(JSONKey.penalties, redPenalties)
        try json.set(JSONKey.red, redJSON)

        var blueJSON = JSON()
        try blueJSON.set(JSONKey.name, bluePlayer.displayName.uppercased())
        try blueJSON.set(JSONKey.score, blueScore)
        try blueJSON.set(JSONKey.penalties, bluePenalties)
        try json.set(JSONKey.blue, blueJSON)

        return json
    }
}
