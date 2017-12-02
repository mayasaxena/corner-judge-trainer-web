//
//  ControlEvent.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/1/17.
//

import Foundation
import JSON

struct ControlEvent: Event {
    enum Category: String {
        case playPause
        case status
        case endMatch
    }

    let eventType: EventType = .control
    let judgeID: String
    let data: [String : String]

    var category: Category {
        guard
            let categoryRaw = data[JSONKey.category],
            let category = Category(rawValue: categoryRaw)
            else { fatalError("Control event must contain category data") }
        return category
    }

    init(judgeID: String, data: [String : String]) {
        self.judgeID = judgeID
        self.data = data

        if data[JSONKey.category] == nil {
            fatalError("Event data must contain category data")
        }
    }

    init(category: Category, judgeID: String) {
        let data = [JSONKey.category : category.rawValue ]
        self.init(judgeID: judgeID, data: data)
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
        case .newJudge:
            return try? NewJudgeEvent(json: self)
        }
    }
}

// MARK: - Timer Events

extension ControlEvent {
    static let statusJudgeID = "status"

    static func status(time: String, scoringDisabled: Bool, round: Int?) -> ControlEvent {
        var data = [
            JSONKey.category : ControlEvent.Category.status.rawValue,
            JSONKey.time : time,
            JSONKey.scoringDisabled : String(scoringDisabled)
        ]

        if let round = round {
            data[JSONKey.round] = String(round)
        }

        return ControlEvent(judgeID: statusJudgeID, data: data)
    }
}
