//
//  Event.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 12/25/16.
//
//

import Vapor

enum EventType: String {
    case control, scoring
}

extension EventType {
    init(value: String?) throws {
        guard
            let value = value,
            let eventType = EventType(rawValue: value)
            else {
                throw Abort.custom(
                    status: .badRequest,
                    message: "Event data must contain event type"
                )
            }

        self = eventType
    }
}

protocol Event: NodeRepresentable {
    var eventType: EventType { get }
    var judgeID: String { get }
}

extension Event {
    var jsonString: String? {
        do {
            return try JSON(makeNode()).makeBytes().string()
        } catch {
            return nil
        }
    }
}

fileprivate struct JSONKey {
    static let eventType = "event"
    static let judgeID = "sent_by"
    static let data = "data"

    static let category = "category"

    static let color = "color"
}

// MARK: - ScoringEvent

struct ScoringEvent: Event {
    enum Category: String {
        case body, head, technical, kyongGo, gamJeom
    }

    let eventType: EventType = .scoring
    let judgeID: String

    let color: PlayerColor
    let category: Category

    init(node: Node) throws {
        guard
            let judgeID = node[JSONKey.judgeID]?.string,
            let dataObject = node[JSONKey.data]?.nodeObject,
            let color = dataObject[JSONKey.color]?.string,
            let category = dataObject[JSONKey.category]?.string
            else { throw Abort.badRequest }

        try self.init(color: color, category: category, judgeID: judgeID)
    }

    init(color: String, category: String, judgeID: String) throws {
        guard
            let playerColor = PlayerColor(rawValue: color),
            let category = ScoringEvent.Category(rawValue: category)
            else {
                throw Abort.badRequest
            }
        self.judgeID = judgeID
        self.color = playerColor
        self.category = category
    }

    func makeNode(context: Context) throws -> Node {
        let data = [
            JSONKey.color : color.rawValue,
            JSONKey.category : category.rawValue
        ]
        return try Node(node: [
            JSONKey.eventType : eventType.rawValue,
            JSONKey.data : data.makeNode()
        ])
    }
}

extension ScoringEvent: Equatable {
    public static func ==(lhs: ScoringEvent, rhs: ScoringEvent) -> Bool {
        return  lhs.category == rhs.category &&
                lhs.color == rhs.color
    }
}

// MARK: - ControlEvent

struct ControlEvent: Event {
    enum Category: String {
        case play, pause, addJudge
    }

    let eventType: EventType = .control
    let judgeID: String

    let category: Category

    init(node: Node) throws {
        guard
            let judgeID = node[JSONKey.judgeID]?.string,
            let dataObject = node[JSONKey.data]?.nodeObject,
            let categoryRaw = dataObject[JSONKey.category]?.string
            else { throw Abort.badRequest }

        try self.init(category: categoryRaw, judgeID: judgeID)
    }

    init(category: String, judgeID: String) throws {
        guard let category = ControlEvent.Category(rawValue: category) else {
                throw Abort.badRequest
        }
        self.judgeID = judgeID
        self.category = category
    }

    func makeNode(context: Context) throws -> Node {
        let data = [ JSONKey.category : category.rawValue ]
        return try Node(node: [
            JSONKey.eventType : eventType.rawValue,
            JSONKey.data : data.makeNode()
        ])
    }
}

extension Node {
    func createEvent() throws -> Event {
        let eventType = try EventType(value: self["event"]?.string)

        switch eventType {
        case .scoring:
            return try ScoringEvent(node: node)
        case .control:
            return try ControlEvent(node: node)
        }
    }
}
