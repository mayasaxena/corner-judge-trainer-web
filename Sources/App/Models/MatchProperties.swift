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

public final class MatchProperties {

    static let current = Match()

    private struct Constants {
        static let matchIDLength = 3
        static let maxScore = 99.0
        static let restTime = 30.0
        static let pointGapValue = 12.0
    }

    let id = Int.random(3)
    let date = Date()

    var redPlayer: Player
    var bluePlayer: Player
    let matchTimer: MatchTimer

    var winningPlayer: Player?
    var matchType: MatchType

    var restTimeInterval: TimeInterval {
        return TimeInterval(Constants.restTime)
    }

    var round: Int = 1 {
        didSet {
            round = min(round, matchType.roundCount)
            if round == matchType.roundCount {
                winningPlayer = redScore > blueScore ? redPlayer : bluePlayer
            }
        }
    }

    var redScore: Double = 0 {
        didSet {
            redScore = min(Constants.maxScore, redScore)
        }
    }
    var blueScore: Double = 0 {
        didSet {
            blueScore = min(Constants.maxScore, blueScore)
        }
    }

    convenience init() {
        self.init(redPlayer: Player(color: .red), bluePlayer: Player(color: .blue), type: .none)
    }

    convenience init(type: MatchType) {
        self.init(redPlayer: Player(color: .red), bluePlayer: Player(color: .blue), type: type)
    }

    init(redPlayer: Player, bluePlayer: Player, type: MatchType) {
        self.redPlayer = redPlayer
        self.bluePlayer = bluePlayer

        matchType = type
        matchTimer = MatchTimer(duration: matchType.roundDuration)
        matchTimer.start()
    }

    func add(redPlayerName: String?, bluePlayerName: String?) {
        redPlayer.name = redPlayerName ?? redPlayer.name
        bluePlayer.name = bluePlayerName ?? bluePlayer.name
    }

    func updateScore(scoringEvent: ScoringEvent) {
        updateScore(for: scoringEvent.color, scoringEvent: scoringEvent.category)
    }

    func updateScore(for playerColor: PlayerColor, scoringEvent: ScoringEvent.Category) {
        guard winningPlayer == nil else { return }

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
            if redScore - blueScore >= Constants.pointGapValue {
                winningPlayer = redPlayer
            } else if blueScore - redScore >= Constants.pointGapValue {
                winningPlayer = bluePlayer
            }
        }
    }
}

// MARK: Node Conversions

extension MatchProperties {

    public func makeNode() throws -> Node {
        return try Node(node: [
            "match-id" : id,
            "date" : date.timeStampString,
            "red-player" : redPlayer.displayName.uppercased(),
            "red-score" : redScore.formattedString,
            "blue-player" : bluePlayer.displayName.uppercased(),
            "blue-score" : blueScore.formattedString,
            "round" : round,
            "blue-win" : winningPlayer?.color == .blue ? "blink" : "",
            "red-win" : winningPlayer?.color == .red ? "blink" : "",
        ])
    }

    public func makeJSON() throws -> JSON {
        return try JSON(makeNode())
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

extension Int {

    static func random(_ length: Int = 3) -> Int {
        return random(min: 10^^(length - 1), max: (10^^length) - 1)
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

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}
