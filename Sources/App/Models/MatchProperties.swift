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
        static let penaltyMax = 5.0
    }

    let id = Int.random(3)
    let matchType: MatchType

    var isWon: Bool {
        return winningPlayer != nil
    }

    fileprivate let date = Date()

    fileprivate var redPlayer: Player
    fileprivate var bluePlayer: Player

    fileprivate var winningPlayer: Player?

    private var restTimeInterval: TimeInterval {
        return TimeInterval(Constants.restTime)
    }

    fileprivate var round: Int = 1 {
        didSet {
            round = min(round, matchType.roundCount)
            if round == matchType.roundCount {
                winningPlayer = redScore > blueScore ? redPlayer : bluePlayer
            }
        }
    }

    fileprivate var redScore: Double = 0 {
        didSet {
            redScore = min(Constants.maxScore, redScore)
        }
    }

    fileprivate var redPenalties: Double = 0 {
        didSet {
            redPenalties = min(redPenalties, 5.0)
        }
    }

    fileprivate var blueScore: Double = 0 {
        didSet {
            blueScore = min(Constants.maxScore, blueScore)
        }
    }

    fileprivate var bluePenalties: Double = 0 {
        didSet {
            bluePenalties = min(bluePenalties, 5.0)
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
    }

    func add(redPlayerName: String?, bluePlayerName: String?) {
        redPlayer.name = redPlayerName ?? redPlayer.name
        bluePlayer.name = bluePlayerName ?? bluePlayer.name
    }

    func updateScore(scoringEvent: ScoringEvent) {
        guard winningPlayer == nil else { return }

        var playerScore = 0.0
        var playerPenalties = 0.0

        switch scoringEvent.category {

        case .head:
            playerScore = 3

        case .body:
            playerScore = 1

        case .technical:
            playerScore = 1

        case .kyongGo:
            playerPenalties = 0.5

        case .gamJeom:
            playerPenalties = 1
        }

        if scoringEvent.color == .blue {
            blueScore += playerScore
            bluePenalties += playerPenalties
            redScore += playerPenalties
        } else {
            redScore += playerScore
            redPenalties += playerPenalties
            blueScore += playerPenalties
        }

        checkPenalties()
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

    private func checkPenalties() {
        if redPenalties >= Constants.penaltyMax {
            winningPlayer = bluePlayer
        } else if bluePenalties >= Constants.penaltyMax {
            winningPlayer = redPlayer
        }
    }
}

// MARK: Node Conversions

fileprivate struct NodeKey {
    static let matchID = "match-id"
    static let date = "date"
    static let redName = "red-player"
    static let redScore = "red-score"
    static let redGamJeomCount = "red-gamjeom-count"
    static let redKyongGoCount = "red-kyonggo-count"
    static let blueName = "blue-player"
    static let blueScore = "blue-score"
    static let blueGamJeomCount = "blue-gamjeom-count"
    static let blueKyongGoCount = "blue-kyonggo-count"
    static let round = "round"
    static let blueScoreClass = "blue-score-class"
    static let redScoreClass = "red-score-class"
}

extension MatchProperties: NodeRepresentable {

    public func makeNode(context: Context) throws -> Node {
        return try Node(node: nodeLiteral)
    }

    public func makeJSON() throws -> JSON {
        return try JSON(makeNode())
    }

    public var nodeLiteral: [String : NodeRepresentable] {
        return [
            NodeKey.matchID : id,
            NodeKey.date : date.timeStampString,
            NodeKey.round : round,
            NodeKey.redName : redPlayer.displayName.uppercased(),
            NodeKey.redScore : redScore.formattedString,
            NodeKey.redGamJeomCount : Int(redPenalties),
            NodeKey.redKyongGoCount : (redPenalties.truncatingRemainder(dividingBy: 1)).rounded(),
            NodeKey.redScoreClass : winningPlayer?.color == .red ? "blink" : "",
            NodeKey.blueName : bluePlayer.displayName.uppercased(),
            NodeKey.blueScore : blueScore.formattedString,
            NodeKey.blueGamJeomCount : Int(bluePenalties),
            NodeKey.blueKyongGoCount : (bluePenalties.truncatingRemainder(dividingBy: 1)).rounded(),
            NodeKey.blueScoreClass: winningPlayer?.color == .blue ? "blink" : "",
        ]
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
