//
//  Match.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/1/16.
//
//

import Vapor
import Foundation

public final class Match: MatchSessionDelegate {

    var id: Int {
        return model.id
    }

    private let model: MatchModel
    private let session = MatchSession()

    private let matchTimer: MatchTimer

    private var isRestRound = false
    private var currentRoundDuration: TimeInterval = 0

    init(model: MatchModel = MatchModel()) {
        self.model = model

        currentRoundDuration = model.matchType.roundDuration

        matchTimer = MatchTimer(duration: currentRoundDuration)
        matchTimer.action = { [weak self] in
            guard let welf = self else { return }

            if welf.matchTimer.isDone {
                welf.handleEndOfRound()
            }

            welf.sendTimerEvent()
        }
        session.delegate = self
    }

    convenience init(redPlayerName: String, bluePlayerName: String, type: MatchType = .none) {
        let model = MatchModel(
            redPlayer: Player(color: .red, name: redPlayerName),
            bluePlayer: Player(color: .blue, name: bluePlayerName),
            type: type
        )
        self.init(model: model)
    }

    public func makeNode() throws -> Node {
        var nodeData = model.nodeLiteral
        nodeData[NodeKey.time] = Node(matchTimer.displayTime)
        nodeData[NodeKey.overlayVisible] = !model.isWon && (!matchTimer.isRunning || isRestRound)
        return try nodeData.makeNode()
    }

    func received(event: Event, from socket: WebSocket) throws {
        switch event {

        case let scoringEvent as ScoringEvent:
            guard shouldScore(event: scoringEvent) else { return }
            try session.received(event: scoringEvent)

        case let controlEvent as ControlEvent:
            if controlEvent.category == .addJudge {
                try session.addConnection(to: socket, forJudgeID: event.judgeID)
            } else {
                handleControlEvent(controlEvent)
            }

        default:
            break
        }
    }

    private func shouldScore(event: ScoringEvent) -> Bool {
        return  !model.isWon &&
                !isRestRound &&
                (matchTimer.isRunning || event.isPenalty)
    }

    private func handleControlEvent(_ event: ControlEvent) {
        switch event.category {
        case .playPause:
            guard !matchTimer.isDone && !model.isWon else { break }
            matchTimer.toggle()
            sendTimerEvent()
        default:
            break
        }
    }

    private func sendTimerEvent() {
        do {
            try session.send(controlEvent: ControlEvent(category: .timer, judgeID: "timer"))
        } catch(let error) {
            log(error: error)
        }
    }

    private func handleEndOfRound() {

        guard model.round < model.matchType.roundCount else {
            model.endMatch()
            try? session.send(controlEvent: ControlEvent(category: .endMatch, judgeID: "timer"))
            return
        }

        if isRestRound {
            // Set to normal round
            currentRoundDuration = model.matchType.roundDuration
            isRestRound = false
            model.round += 1
        } else {
            // Set to rest round
            currentRoundDuration = model.restTimeInterval
            isRestRound = true
        }

        matchTimer.reset(time: currentRoundDuration)
        matchTimer.start(delay: 1)
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        model.updateScore(scoringEvent: scoringEvent)
    }
}

fileprivate struct NodeKey {
    static let time = "time"
    static let overlayVisible = "overlay-visible"
}
