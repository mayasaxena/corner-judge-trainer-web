//
//  ScoringEvent.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/1/17.
//

import Foundation
import Vapor

// BACKEND RECEIVE ONLY

struct ScoringEvent: Event {
    enum Category: String {
        case body
        case head
        case technical

        var displayName: String {
            return rawValue.capitalized
        }

        var pointValue: Int {
            switch self {
            case .body:
                return 2
            case .head:
                return 3
            case .technical:
                return 1
            }
        }
    }

    let eventType: EventType = .scoring
    let participantID: String
//    let data: [String : String]

    let category: Category

//    var category: Category {
//        guard
//            let categoryRaw = data[JSONKey.category],
//            let category = Category(rawValue: categoryRaw)
//            else { fatalError("Scoring event must contain category data") }
//        return category
//    }

    let color: PlayerColor

//    var color: PlayerColor {
//        guard
//            let colorRaw = data[JSONKey.color],
//            let color = PlayerColor(rawValue: colorRaw)
//            else { fatalError("Scoring event must contain player color") }
//        return color
//    }

//    init(judgeID: String, data: [String : String]) {
//        self.judgeID = judgeID
////        self.data = data
//
//        if data[JSONKey.category] == nil {
//            fatalError("Event data must contain category data")
//        }
//    }

    init(judgeID: String, category: Category, color: PlayerColor) {
        self.participantID = judgeID
        self.category = category
        self.color = color
    }

    init(json: JSON) throws {
        participantID = try json.get(JSONKey.participantID)

        guard let category = (try json.get(path: [JSONKey.data, JSONKey.category]) { Category(rawValue: $0)}) else {
            throw Abort(.badRequest, reason: "Scoring event data must contain valid category")
        }

        self.category = category

        guard let color = (try json.get(path: [JSONKey.data, JSONKey.color]) { PlayerColor(rawValue: $0)}) else {
            throw Abort(.badRequest, reason: "Scoring event data must contain valid player color")
        }

        self.color = color
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(participantID, JSONKey.participantID)

        var dataJSON = JSON()
        try dataJSON.set(JSONKey.category, category.rawValue)
        try dataJSON.set(JSONKey.color, color.rawValue)

        try json.set(JSONKey.data, dataJSON)

        return json
    }
}

extension ScoringEvent {
    public var description: String {
        return "[\(color.displayName) \(category.rawValue.capitalized)]"
    }
}

extension ScoringEvent: Equatable {
    public static func ==(lhs: ScoringEvent, rhs: ScoringEvent) -> Bool {
        return  lhs.category == rhs.category &&
            lhs.color == rhs.color
    }
}
