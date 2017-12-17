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

enum EventCodingKey: String, CodingKey {
    case eventType = "event"
    case participantID = "sent_by"
    case data
    case category
    case color
    case time
    case scoringDisabled = "scoring_disabled"
    case round
    case value
    case participantType = "participant_type"
}

extension JSONRepresentable {
    var jsonString: String? {
        return try? makeJSON().makeBytes().makeString()
    }
}

// BACKEND RECEIVE ONLY
enum ParticipantType: String {
    case judge
    case `operator`
    case viewer
}

struct NewParticipantEvent: Event {

    let eventType = EventType.newParticipant
    let participantID: String
    let participantType: ParticipantType

    init(participantID: String, participantType: ParticipantType) {
        self.participantID = participantID
        self.participantType = participantType
    }

    init(json: JSON) throws {
        participantID = try json.get(EventCodingKey.participantID.rawValue)
        let createParticipantType: (String) throws -> ParticipantType = {
            guard let type = ParticipantType(rawValue: $0) else {
                throw Abort(.badRequest, reason: "Participant request must contain valid participant type")
            }
            return type
        }
        participantType = try json.get(path: [EventCodingKey.data.rawValue, EventCodingKey.participantType.rawValue], transform: createParticipantType)
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(EventCodingKey.eventType.rawValue, eventType.rawValue)
        try json.set(EventCodingKey.participantID.rawValue, participantID)
        try json.set(EventCodingKey.participantType.rawValue, participantType.rawValue)
        return json
    }
}
