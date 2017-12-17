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
        participantID = try json.get(EventCodingKey.participantID.rawValue)
        guard let category = (try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.category.rawValue]) { Category(rawValue: $0) }) else {
            throw Abort(.badRequest, reason: "Control event data must include valid category")
        }
        self.category = category

        do {
            self.color = try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.color.rawValue]) { PlayerColor(rawValue: $0) }
        } catch {
            self.color = nil
        }

        do {
            self.value = try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.value.rawValue]) { $0 }
        } catch {
            self.value = nil
        }
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(participantID, EventCodingKey.participantID.rawValue)

        var dataJSON = JSON()
        try dataJSON.set(EventCodingKey.category.rawValue, category.rawValue)

        if let color = color {
            try dataJSON.set(EventCodingKey.color.rawValue, color.rawValue)
        }

        if let value = value {
            try dataJSON.set(EventCodingKey.value.rawValue, value)
        }

        try json.set(EventCodingKey.data.rawValue, dataJSON)

        return json
    }
}

extension JSON {
    func createEvent() -> Event? {
        guard let eventType = EventType(value: self[EventCodingKey.eventType.rawValue]?.string) else { return nil }

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

private extension Double {
    var toInt: Int? {
        return Int(self)
    }
}
