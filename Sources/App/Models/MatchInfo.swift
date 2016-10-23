//
//  MatchInfo.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/21/16.
//
//

import Vapor
import Foundation
import Random

public final class MatchInfo {

    struct Constants {
        static let MatchIDLength = 6
        static let MaxScore = 99.0
        static let RestTime = 30.0
        static let PointGapValue = 12.0
    }

    var restTimeInterval: TimeInterval {
        return TimeInterval(Constants.RestTime)
    }

    let redPlayer: Player
    let bluePlayer: Player

    var winningPlayer: Player?

    var matchID: String
    var date: Date

    var matchType: MatchType

    var round: Int = 1 {
        didSet {
            round = min(round, matchType.roundCount)
            if round == matchType.roundCount {
                winningPlayer = redScore > blueScore ? redPlayer : bluePlayer
            }
        }
    }

    var redScore: Double {
        didSet {
            redScore = min(Constants.MaxScore, redScore)
        }
    }
    var blueScore: Double {
        didSet {
            blueScore = min(Constants.MaxScore, blueScore)
        }
    }

    static let current = Match()

    convenience init() {
        self.init(redPlayer: Player(color: .red), bluePlayer: Player(color: .blue), type: .none)
    }

    convenience init(type: MatchType) {
        self.init(redPlayer: Player(color: .red), bluePlayer: Player(color: .blue), type: type)
    }

    init(redPlayer: Player, bluePlayer: Player, type: MatchType) {
        self.redPlayer = redPlayer
        self.bluePlayer = bluePlayer

        self.matchID = String.random(Constants.MatchIDLength)
        self.date = Date()
        self.redScore = 0
        self.blueScore = 0

        matchType = type
    }

    public func add(redPlayerName: String?, bluePlayerName: String?) {
        redPlayer.name = redPlayerName ?? redPlayer.name
        bluePlayer.name = bluePlayerName ?? bluePlayer.name
    }

    public func updateScore(scoringEvent: ScoringEvent) {
        updateScore(for: scoringEvent.color, scoringEvent: scoringEvent.type)
    }

    public func updateScore(for playerColor: PlayerColor, scoringEvent: ScoringEventType) {
        var playerScore = 0.0
        var otherPlayerScore = 0.0

        switch scoringEvent {

        case .head:
            playerScore = 3

        case .body:
            playerScore = 1

        case .technical:
            playerScore = 1

        // TODO: Fix so # of kyonggos increase instead
        case .kyongGo:
            otherPlayerScore = 0.5

        case .gamJeom:
            otherPlayerScore = 1
        }

        if playerColor == .blue {
            blueScore += playerScore
            redScore += otherPlayerScore
        } else {
            redScore += playerScore
            blueScore += otherPlayerScore
        }

        checkPointGap()
    }

    private func checkPointGap() {
        if round > matchType.pointGapThresholdRound {
            if redScore - blueScore >= Constants.PointGapValue {
                winningPlayer = redPlayer
            } else if blueScore - redScore >= Constants.PointGapValue {
                winningPlayer = bluePlayer
            }
        }
    }
}

// MARK: Node Conversions

extension MatchInfo {

    public func makeNode() throws -> Node {
        return try Node(node: [
            "match-id" : matchID,
            "date" : date.timeStampString,
            "red-score" : redScore.formattedString,
            "blue-score" : blueScore.formattedString,
            "round" : round,
        ])
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

    var roundDuration: TimeInterval {
        switch self {
        case .aTeam:
            return TimeInterval(2 * 60.0)
        case .bTeam:
            return TimeInterval(1.5 * 60.0)
        case .cTeam:
            return TimeInterval(1 * 60.0)
        default:
            return TimeInterval(10.0)
        }
    }

    var roundCount: Int {
        switch self {
        case .aTeam, .bTeam, .cTeam:
            return 2
        case .none:
            return 0
        default:
            return 3
        }
    }

    var pointGapThresholdRound: Int {
        switch self {
        case .aTeam, .bTeam, .cTeam, .none:
            return 0
        default:
            return 0
        }
    }

    static let caseCount = MatchType.countCases()

    fileprivate static func countCases() -> Int {
        // starting at zero, verify whether the enum can be instantiated from the Int and increment until it cannot
        var count = 0
        while let _ = MatchType(rawValue: count) { count += 1 }
        return count
    }
}

extension String {

    static func random(_ length: Int = 20) -> String {

        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""

        for _ in 0..<length {
            let randomValue = URandom.uint % UInt(base.characters.count)
            randomString += "\(base[base.characters.index(base.startIndex, offsetBy: Int(randomValue))])"
        }

        return randomString
    }
}

extension Date {
    var timeStampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyy h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
