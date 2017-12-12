//
//  Event.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 12/25/16.
//
//

import Vapor

enum EventType: String {
    case control, scoring, newParticipant
}

extension EventType {
    init?(value: String?) {
        guard
            let value = value,
            let eventType = EventType(rawValue: value)
            else { return nil }

        self = eventType
    }
}

protocol Event: JSONConvertible {
    var eventType: EventType { get }
    var participantID: String { get }
}

struct JSONKey {
    static let eventType = "event"
    static let participantID = "sent_by"
    static let data = "data"
    static let category = "category"
    static let color = "color"
    static let time = "time"
    static let scoringDisabled = "scoringDisabled"
    static let round = "round"
    static let value = "value"
    static let participantType = "participant_type"
}

extension JSONRepresentable {
    var jsonString: String? {
        return try? makeJSON().makeBytes().makeString()
    }
}


// BACKEND RECEIVE ONLY

struct NewParticipantEvent: Event {

    enum ParticipantType: String {
        case judge
        case `operator`
        case viewer
    }

    let eventType = EventType.newParticipant
    let participantID: String
    let participantType: ParticipantType

    init(participantID: String, participantType: ParticipantType) {
        self.participantID = participantID
        self.participantType = participantType
    }

    init(json: JSON) throws {
        participantID = try json.get(JSONKey.participantID)
        let createParticipantType: (String) throws -> ParticipantType = {
            guard let type = ParticipantType(rawValue: $0) else {
                throw Abort(.badRequest, reason: "Participant request must contain valid participant type")
            }
            return type
        }
        participantType = try json.get(path: [JSONKey.data, JSONKey.participantType], transform: createParticipantType)
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKey.eventType, eventType.rawValue)
        try json.set(JSONKey.participantID, participantID)
        try json.set(JSONKey.participantType, participantType.rawValue)
        return json
    }
}
