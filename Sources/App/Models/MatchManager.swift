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

    fileprivate let matchTimer: MatchTimer

    private var isRestRound = false
    private var currentRoundDuration: TimeInterval = 0

    fileprivate var scoringDisabled: Bool {
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

            welf.sendTimerUpdate()
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

    func received(event: Event, from socket: WebSocket) throws {
        switch event {
        case let scoringEvent as ScoringEvent:
            guard shouldScore(event: scoringEvent) else { return }
            try session.received(event: scoringEvent)

        case let controlEvent as ControlEvent:
            guard session.isOperator(participantID: controlEvent.participantID) else { return}
            handleControlEvent(controlEvent)

        case let newParticipantEvent as NewParticipantEvent:
            session.addConnection(participantID: newParticipantEvent.participantID, participantType: newParticipantEvent.participantType, socket: socket)
            sendTimerUpdate()
        default:
            break
        }
    }

    func handleControlEvent(_ event: ControlEvent) {
        switch event.category {
        case .playPause:
            if match.status == .new {
                match.status = .ongoing
            }
            guard !matchTimer.isDone && !match.isWon else { break }
            matchTimer.toggle()
            sendTimerUpdate()
        case .giveGamJeom:
            guard let color = event.color else { return }
            match.giveGamJeom(to: color)
            sendStatusUpdate(for: event)
        case .removeGamJeom:
            guard let color = event.color else { return }
            match.removeGamJeom(from: color)
            sendStatusUpdate(for: event)
        case .adjustScore:
            guard
                let color = event.color,
                let amount = event.value
                else { return }
            match.adjustScore(for: color, byAmount: amount)
            sendStatusUpdate(for: event)
        default:
            break
        }
    }

    func sendStatusUpdate(for event: ControlEvent) {
        switch event.category {
        case .giveGamJeom, .removeGamJeom:
            try? session.send(statusUpdate: .penalties(red: match.redPenalties, blue: match.bluePenalties))
            try? session.send(statusUpdate: .score(red: match.redScore, blue: match.blueScore))
        case .adjustScore:
            try? session.send(statusUpdate: .score(red: match.redScore, blue: match.blueScore))
        default:
            break
        }
        checkMatchStatus()
    }

    func disconnect(socket: WebSocket) {
        session.removeConnection(socket: socket)
    }

    private func shouldScore(event: ScoringEvent) -> Bool {
        return  !match.isWon && matchTimer.isRunning && !isRestRound
    }

    private func sendTimerUpdate() {
        do {
            try session.send(statusUpdate: .timer(displayTime: matchTimer.displayTime, scoringDisabled: scoringDisabled))
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
        if let winner = match.winningPlayer {
            try? session.send(statusUpdate: .won(winningColor: winner.color))
        }
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        guard match.winningPlayer == nil else { return }

        if scoringEvent.color == .blue {
            match.blueScore += scoringEvent.category.pointValue
        } else {
            match.redScore += scoringEvent.category.pointValue
        }

        try? session.send(statusUpdate: .score(red: match.redScore, blue: match.blueScore))
        checkMatchStatus()
    }

    func checkMatchStatus() {
        match.checkPenalties()
        if round >= Match.pointGapThresholdRound {
            match.checkPointGap()
        }

        if match.isWon {
            handleMatchEnded()
        }
    }
}

extension MatchManager: JSONRepresentable {
    private struct JSONKey {
        static let match = "match"
        static let round = "round"
        static let redScoreClass = "red_score_class"
        static let blueScoreClass = "blue_score_class"
        static let time = "time"
        static let overlayVisible = "overlay_visible"
        static let status = "status"
    }

    public func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKey.match, match.makeJSON())
        try json.set(JSONKey.round, round)
        try json.set(JSONKey.redScoreClass, match.winningPlayer?.color == .red ? "blink" : "")
        try json.set(JSONKey.blueScoreClass, match.winningPlayer?.color == .blue ? "blink" : "")
        try json.set(JSONKey.time, matchTimer.displayTime)
        try json.set(JSONKey.overlayVisible, scoringDisabled)
        try json.set(JSONKey.status, match.status.rawValue)
        return json
    }
}

private extension Match {

    var isWon: Bool {
        return winningPlayer != nil
    }

    func giveGamJeom(to color: PlayerColor) {
        switch color {
        case .blue:
            bluePenalties += 1
            redScore += 1
        case .red:
            redPenalties += 1
            blueScore += 1
        }
    }

    func removeGamJeom(from color: PlayerColor) {
        switch color {
        case .blue:
            guard bluePenalties > 0 else { return }
            bluePenalties -= 1
            redScore -= 1
        case .red:
            guard redPenalties > 0 else { return }
            redPenalties -= 1
            blueScore -= 1
        }
    }

    func adjustScore(for color: PlayerColor, byAmount amount: Int) {
        switch color {
        case .blue:
            if blueScore + amount >= 0 {
                blueScore += amount
            }
        case .red:
            if redScore + amount >= 0 {
                redScore += amount
            }
        }
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
