//
//  ScoringEvent.swift
//  CornerJudgeTrainer
//
//  Created by Maya Saxena on 7/29/16.
//  Copyright © 2016 Maya Saxena. All rights reserved.
//

import Foundation
import Vapor

public struct ScoringEvent {
    let type: ScoringEventType
    let color: PlayerColor

    var jsonString: String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
            let string = String(data: jsonData, encoding: .utf8) {
            return string
        } else {
            return "fail"
        }
    }

    var dictionary: [String: String] {
        return [
            "type" : type.displayName,
            "color" : color.displayName
        ]
    }
}

extension ScoringEvent: Equatable {
    public static func ==(lhs: ScoringEvent, rhs: ScoringEvent) -> Bool {
        return lhs.type.rawValue == rhs.type.rawValue &&
                lhs.color.rawValue == rhs.color.rawValue
    }
}

public enum ScoringEventType: String {
    case head = "Head"
    case body = "Body"
    case technical = "Technical"
    case kyongGo = "Kyong-Go"
    case gamJeom = "Gam-Jeom"
    
    var displayName: String {
        return rawValue
    }
}
