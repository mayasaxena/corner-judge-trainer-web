//
//  ScoringEvent.swift
//  CornerJudgeTrainer
//
//  Created by Maya Saxena on 7/29/16.
//  Copyright © 2016 Maya Saxena. All rights reserved.
//

import Foundation

public enum ScoringEvent {
    case head
    case body
    case technical
    case kyongGo
    case gamJeom
    
    var displayName: String {
        switch self {
        case .head:
            return "Head"
        case .body:
            return "Body"
        case .technical:
            return "Technical"
        case .kyongGo:
            return "Kyong-Go"
        case .gamJeom:
            return "Gam-Jeom"
        }
    }
}
