//
//  Match.swift
//  corner-judge-trainer-web

//
//  Created by Maya Saxena on 2/21/17.
//  Copyright © 2017 Maya Saxena. All rights reserved.
//

import Vapor
import Foundation

public enum MatchStatus: String {
    case new, ongoing, completed
}

public final class Match {

    public static let pointGapThresholdRound = 2
    public static let pointGapValue = 20
    public static let maxPenalties = 10

    private struct Constants {
        static let matchIDLength = 3
        static let maxScore = 99
    }

    public var status: MatchStatus = .new

    public let id: Int
    public let date = Date()

    public var redScore: Int = 0 {
        didSet {
            redScore = min(redScore, Constants.maxScore)
        }
    }

    public var redPenalties: Int = 0 {
        didSet {
            redPenalties = min(redPenalties, Match.maxPenalties)
        }
    }

    public var blueScore: Int = 0 {
        didSet {
            blueScore = min(blueScore, Constants.maxScore)
        }
    }

    public var bluePenalties: Int = 0 {
        didSet {
            bluePenalties = min(bluePenalties, Match.maxPenalties)
        }
    }

    public var winningPlayer: Player?

    fileprivate(set) var type: MatchType

    fileprivate(set) var redPlayer: Player
    fileprivate(set) var bluePlayer: Player

    init(
        id: Int = Int.random(3),
        redPlayerName: String? = nil,
        bluePlayerName: String? = nil,
        type: MatchType = .none
    ) {
        self.id = id
        self.redPlayer = Player(color: .red, name: redPlayerName)
        self.bluePlayer = Player(color: .blue, name: bluePlayerName)
        self.type = type
    }

    public func determineWinner() {
        if redScore == blueScore {
            winningPlayer = nil
        } else {
            winningPlayer = redScore > blueScore ? redPlayer : bluePlayer
        }
    }
}

extension String {
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyy h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: self)
    }
}

// MARK: - MatchType

public enum MatchType: Int {
    case aTeam
    case bTeam
    case cTeam
    case custom
    case none

    var displayName: String {
        switch self {
        case .aTeam:
            return "A Team".uppercased()
        case .bTeam:
            return "B Team".uppercased()
        case .cTeam:
            return "C Team".uppercased()
        case .custom:
            return "Custom".uppercased()
        case .none:
            return "None".uppercased()
        }
    }
}

extension Int {
    static func random(_ length: Int = 3) -> Int {
        return random(min: 10^^(length - 1), max: (10^^length) - 1)
    }
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence

func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}
