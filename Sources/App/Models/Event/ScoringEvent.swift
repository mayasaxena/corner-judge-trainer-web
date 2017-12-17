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
    let category: Category
    let color: PlayerColor

    init(judgeID: String, category: Category, color: PlayerColor) {
        self.participantID = judgeID
        self.category = category
        self.color = color
    }

    init(json: JSON) throws {
        participantID = try json.get(EventCodingKey.participantID.rawValue)

        guard let category = (try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.category.rawValue]) { Category(rawValue: $0)}) else {
            throw Abort(.badRequest, reason: "Scoring event data must contain valid category")
        }

        self.category = category

        guard let color = (try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.color.rawValue]) { PlayerColor(rawValue: $0)}) else {
            throw Abort(.badRequest, reason: "Scoring event data must contain valid player color")
        }

        self.color = color
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(participantID, EventCodingKey.participantID.rawValue)

        var dataJSON = JSON()
        try dataJSON.set(EventCodingKey.category.rawValue, category.rawValue)
        try dataJSON.set(EventCodingKey.color.rawValue, color.rawValue)

        try json.set(EventCodingKey.data.rawValue, dataJSON)

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
