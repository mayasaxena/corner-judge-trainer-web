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
        return properties.id
    }

    private let properties: MatchProperties
    private let session = MatchSession()

    private let matchTimer: MatchTimer

    private lazy var matchTimerAction: (Void) -> Void = {
        let action = { [weak self] in
            guard
                let welf = self,
                let eventString = ControlEvent(category: .timer, judgeID: "timer").jsonString
                else { return }
            do {
                try welf.session.send(jsonString: eventString)
            } catch(let error) {
                log(error: error)
            }
        }
        return action
    }()

    init(properties: MatchProperties = MatchProperties()) {
        self.properties = properties

        matchTimer = MatchTimer(duration: properties.matchType.roundDuration)
        matchTimer.action = matchTimerAction
        session.delegate = self
    }

    convenience init(redPlayerName: String, bluePlayerName: String, type: MatchType = .none) {
        let properties = MatchProperties(
            redPlayer: Player(color: .red, name: redPlayerName),
            bluePlayer: Player(color: .blue, name: bluePlayerName),
            type: type
        )
        self.init(properties: properties)
    }

    public func makeNode() throws -> Node {
        var nodeData = properties.nodeLiteral
        nodeData[NodeKey.time] = Node(matchTimer.timeRemaining.formattedTimeString)
        nodeData[NodeKey.paused] = !matchTimer.isRunning
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
        return !properties.isWon && (matchTimer.isRunning || event.isPenalty)
    }

    private func handleControlEvent(_ event: ControlEvent) {
        switch event.category {
        case .playPause:
            guard !matchTimer.isDone && !properties.isWon else { break }
            toggleMatchTimer()
            matchTimerAction()
        default:
            break
        }
    }

    func toggleMatchTimer() {
        if matchTimer.isRunning {
            matchTimer.stop()
        } else {
            matchTimer.start()
        }
    }

    // MARK: - MatchSessionDelegate

    func sessionDidConfirmScoringEvent(scoringEvent: ScoringEvent) {
        properties.updateScore(scoringEvent: scoringEvent)
    }
}

private extension TimeInterval {
    var formattedTimeString: String {
        return String(format: "%d:%02d", Int(self / 60.0),  Int(ceil(self.truncatingRemainder(dividingBy: 60))))
    }
}

fileprivate struct NodeKey {
    static let time = "time"
    static let paused = "paused"
}
