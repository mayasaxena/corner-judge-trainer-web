//
//  Match.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/1/16.
//
//

import Vapor
import Foundation

public final class MatchManager: MatchSessionDelegate {

    private struct Constants {
        static let restTime: TimeInterval = 30.0
    }

    var id: Int {
        return match.id
    }

    fileprivate var round: Int = 1 {
        didSet {
            round = min(round, match.type.roundCount)
        }
    }

    public let match: Match
    private let session = MatchSession()

    private let matchTimer: MatchTimer

    private var isRestRound = false
    private var currentRoundDuration: TimeInterval = 0

    private var scoringDisabled: Bool {
        return !match.isWon && (!matchTimer.isRunning || isRestRound)
    }

    init(match: Match = Match()) {
        self.match = match

        currentRoundDuration = match.type.roundDuration

        matchTimer = MatchTimer(duration: currentRoundDuration)
        matchTimer.action = { [weak self] in
            guard let welf = self else { return }

            if welf.matchTimer.isDone {
                welf.handleEndOfRound()
            }

            welf.sendStatusEvent()
        }
        session.delegate = self
    }

    convenience init(redPlayerName: String, bluePlayerName: String, type: MatchType = .none) {
        let match = Match(
            redPlayerName: redPlayerName,
            bluePlayerName: bluePlayerName,
            type: type
        )
        self.init(match: match)
    }

    public func makeNode() throws -> Node {
        var nodeData = match.nodeLiteral
        nodeData[NodeKey.time] = Node(matchTimer.displayTime)
        nodeData[NodeKey.overlayVisible] = scoringDisabled
        nodeData[NodeKey.round] = round
        return try nodeData.makeNode(in: nil)
    }

    func received(event: Event, from socket: WebSocket) throws {
        switch event {
        case let scoringEvent as ScoringEvent:
            guard shouldScore(event: scoringEvent) else { return }
            try session.received(event: scoringEvent)

        case let controlEvent as ControlEvent:
            switch controlEvent.category {
            case .playPause:
                if match.status == .new {
                    match.status = .ongoing
                }

                guard !matchTimer.isDone && !match.isWon else { break }
                matchTimer.toggle()
                sendStatusEvent()
            default:
                break
            }
        case let newJudgeEvent as NewJudgeEvent:
            connect(judgeID: newJudgeEvent.judgeID, socket: socket)
        default:
            break
        }
    }

    func connect(judgeID: String, socket: WebSocket) {
        session.addConnection(judgeID: judgeID, socket: socket)
        sendStatusEvent()
    }

    func disconnect(socket: WebSocket) {
        session.removeConnection(socket: socket)
    }

    private func shouldScore(event: ScoringEvent) -> Bool {
        return  !match.isWon && (event.isPenalty || (matchTimer.isRunning && !isRestRound))
    }

    private func sendStatusEvent() {
        do {
            let statusEvent = ControlEvent.status(
                time: matchTimer.displayTime,
                scoringDisabled: scoringDisabled,
                round: isRestRound ? nil : round
            )
            try session.send(controlEvent: statusEvent)
        } catch(let error) {
            log(error: error)
        }
    }

    private func handleEndOfRound() {

        guard round < match.type.roundCount else {
            match.determineWinner()
            handleMatchEnded()
            return
        }

        let wasRestRound = isRestRound
        if wasRestRound {
            currentRoundDuration = match.type.roundDuration
            isRestRound = false
            round += 1
        } else {
            currentRoundDuration = Constants.restTime
            isRestRound = true
        }

        matchTimer.reset(time: currentRoundDuration)
        matchTimer.start(delay: 1)
    }

    func handleMatchEnded() {
        print(match.winningPlayer?.name ?? "No winning player")
        matchTimer.stop()
        match.status = .completed
        try? session.send(controlEvent: ControlEvent(category: .endMatch, judgeID: "timer"))
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        guard match.winningPlayer == nil else { return }

        var playerScore = 0
        var playerPenalties = 0

        switch scoringEvent.category {
        case .head:
            playerScore = 3
        case .body:
            playerScore = 2
        case .technical:
            playerScore = 1
        case .gamJeom:
            playerPenalties = 1
        }

        if scoringEvent.color == .blue {
            match.blueScore += playerScore
            match.bluePenalties += playerPenalties
            match.redScore += playerPenalties
        } else {
            match.redScore += playerScore
            match.redPenalties += playerPenalties
            match.blueScore += playerPenalties
        }

        match.checkPenalties()
        if round >= Match.pointGapThresholdRound {
            match.checkPointGap()
        }

        if match.isWon {
            handleMatchEnded()
        }
    }
}

private extension Match {

    var isWon: Bool {
        return winningPlayer != nil
    }

    func checkPointGap() {
        if redScore - blueScore >= Match.pointGapValue {
            winningPlayer = redPlayer
        } else if blueScore - redScore >= Match.pointGapValue {
            winningPlayer = bluePlayer
        }
    }

    func checkPenalties() {
        if redPenalties >= Match.maxPenalties {
            winningPlayer = bluePlayer
        } else if bluePenalties >= Match.maxPenalties {
            winningPlayer = redPlayer
        }
    }
}

fileprivate struct NodeKey {
    static let matchID = "match-id"
    static let matchType = "match-type"
    static let date = "date"
    static let redName = "red-player"
    static let redScore = "red-score"
    static let redGamJeomCount = "red-gamjeom-count"
    static let blueName = "blue-player"
    static let blueScore = "blue-score"
    static let blueGamJeomCount = "blue-gamjeom-count"
    static let round = "round"
    static let blueScoreClass = "blue-score-class"
    static let redScoreClass = "red-score-class"
    static let time = "time"
    static let overlayVisible = "overlay-visible"
    static let status = "status"
}

extension Match: NodeRepresentable {
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: nodeLiteral)
    }

    public func makeJSON() throws -> JSON {
        return try JSON(makeNode(in: nil))
    }

    public var nodeLiteral: [String : NodeRepresentable] {
        return [
            NodeKey.matchID : id,
            NodeKey.matchType : type.rawValue,
            NodeKey.date : date.timeStampString,
            NodeKey.redName : redPlayer.displayName.uppercased(),
            NodeKey.redScore : String(redScore),
            NodeKey.redGamJeomCount : redPenalties,
            NodeKey.redScoreClass : winningPlayer?.color == .red ? "blink" : "",
            NodeKey.blueName : bluePlayer.displayName.uppercased(),
            NodeKey.blueScore : String(blueScore),
            NodeKey.blueGamJeomCount : bluePenalties,
            NodeKey.blueScoreClass: winningPlayer?.color == .blue ? "blink" : "",
            NodeKey.status : status.rawValue
        ]
    }
}

extension MatchType {

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
            return 2
        default:
            return 3
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

extension Date {
    var timeStampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyy h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
