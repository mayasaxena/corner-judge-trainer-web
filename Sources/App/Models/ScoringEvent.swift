//
//  ScoringEvent.swift
//  CornerJudgeTrainer
//
//  Created by Maya Saxena on 7/29/16.
//  Copyright © 2016 Maya Saxena. All rights reserved.
//

import Foundation

public struct ScoringEvent {
    let type: ScoringEventType
    let color: PlayerColor
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
