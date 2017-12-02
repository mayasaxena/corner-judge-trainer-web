//
//  ScoringEvent.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/1/17.
//

import Foundation

// MARK: - ScoringEvent

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
    let judgeID: String
    let data: [String : String]

    var category: Category {
        guard
            let categoryRaw = data[JSONKey.category],
            let category = Category(rawValue: categoryRaw)
            else { fatalError("Scoring event must contain category data") }
        return category
    }

    var color: PlayerColor {
        guard
            let colorRaw = data[JSONKey.color],
            let color = PlayerColor(rawValue: colorRaw)
            else { fatalError("Scoring event must contain player color") }
        return color
    }

    init(judgeID: String, data: [String : String]) {
        self.judgeID = judgeID
        self.data = data

        if data[JSONKey.category] == nil {
            fatalError("Event data must contain category data")
        }
    }

    init(judgeID: String, category: Category, color: PlayerColor) {
        let data = [
            JSONKey.category : category.rawValue,
            JSONKey.color : color.rawValue
        ]
        self.init(judgeID: judgeID, data: data)
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
