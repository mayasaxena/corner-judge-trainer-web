//
//  ControlEvent.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/1/17.
//

import Foundation
import Vapor

// BACKEND RECEIVE ONLY

struct ControlEvent: Event {
    enum Category: String {
        case playPause
        case status
        case endMatch
        case giveGamJeom
        case removeGamJeom
        case adjustScore
    }

    let eventType: EventType = .control
    let participantID: String

    let category: Category
    let color: PlayerColor?
    let value: Int?

    init(operatorID: String, category: Category, color: PlayerColor? = nil, value: Int? = nil) {
        self.participantID = operatorID
        self.category = category
        self.color = color
        self.value = value
    }

    init(json: JSON) throws {
        participantID = try json.get(JSONKey.participantID)
        guard let category = (try json.get(path: [JSONKey.data, JSONKey.category]) { Category(rawValue: $0) }) else {
            throw Abort(.badRequest, reason: "Control event data must include valid category")
        }
        self.category = category

        do {
            self.color = try json.get(path: [JSONKey.data, JSONKey.color]) { PlayerColor(rawValue: $0) }
        } catch {
            self.color = nil
        }

        do {
            self.value = try json.get(path: [JSONKey.data, JSONKey.value]) { $0 }
        } catch {
            self.value = nil
        }
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(participantID, JSONKey.participantID)

        var dataJSON = JSON()
        try dataJSON.set(JSONKey.category, category.rawValue)

        if let color = color {
            try dataJSON.set(JSONKey.color, color.rawValue)
        }

        if let value = value {
            try dataJSON.set(JSONKey.value, value)
        }

        try json.set(JSONKey.data, dataJSON)

        return json
    }
}

extension JSON {
    func createEvent() -> Event? {
        guard let eventType = EventType(value: self[JSONKey.eventType]?.string) else { return nil }

        switch eventType {
        case .scoring:
            return try? ScoringEvent(json: self)
        case .control:
            return try? ControlEvent(json: self)
        case .newParticipant:
            return try? NewParticipantEvent(json: self)
        }
    }
}

// MARK: - Timer Events

extension ControlEvent {
    static let statusParticipantID = "status"

    static func status(time: String, scoringDisabled: Bool, round: Int?) -> ControlEvent {
        var data = [
            JSONKey.category : ControlEvent.Category.status.rawValue,
            JSONKey.time : time,
            JSONKey.scoringDisabled : String(scoringDisabled)
        ]

        if let round = round {
            data[JSONKey.round] = String(round)
        }

        return ControlEvent(operatorID: statusParticipantID, category: .status)
    }
}

private extension Double {
    var toInt: Int? {
        return Int(self)
    }
}
