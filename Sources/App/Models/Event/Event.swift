//
//  Event.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 12/25/16.
//
//

import Vapor

struct JSONKey {
    static let eventType = "event"
    static let judgeID = "sent_by"
    static let data = "data"
    static let category = "category"
    static let color = "color"
    static let time = "time"
    static let scoringDisabled = "scoringDisabled"
    static let round = "round"
}

enum EventType: String {
    case control, scoring
}

extension EventType {
    init?(value: String?) {
        guard
            let value = value,
            let eventType = EventType(rawValue: value)
            else {
                return nil
        }

        self = eventType
    }
}

protocol Event: JSONConvertible {

    var eventType: EventType { get }
    var judgeID: String { get }
    var data: [String : String] { get }

    init(judgeID: String, data: [String: String])
}

extension Event {

    init?(node: Node) {
        guard
            let judgeID = node[JSONKey.judgeID]?.string,
            let dataObject = node[JSONKey.data]?.pathIndexableObject
            else { return nil }

        let data = dataObject.reduce([String : String]()) { dict, entry in
            var dictionary = dict
            dictionary[entry.key] = entry.value.string
            return dictionary
        }

        self.init(judgeID: judgeID, data: data)
    }

    var jsonString: String? {
        return try? makeJSON().makeBytes().makeString()
    }

    init(json: JSON) throws {
        try self.init(judgeID: json.get(JSONKey.judgeID), data: json.get(JSONKey.data))
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKey.eventType, eventType.rawValue)
        try json.set(JSONKey.data, data)
        try json.set(JSONKey.judgeID, judgeID)
        return json
    }
}
