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

    private let properties = MatchProperties()
    private let session = MatchSession()

    private let matchTimer: MatchTimer

    init() {
        matchTimer = MatchTimer(duration: 30)
        matchTimer.action = { [weak self] in
            guard
                let welf = self,
                let eventString = ControlEvent(category: .timer, judgeID: "timer").jsonString
                else { return }
            try welf.session.send(jsonString: eventString)
        }
        session.delegate = self
    }

    convenience init(redPlayerName: String, bluePlayerName: String) {
        self.init()
        properties.add(redPlayerName: redPlayerName, bluePlayerName: bluePlayerName)
    }

    public func makeNode() throws -> Node {
        var nodeData = properties.nodeLiteral
        nodeData[NodeKey.time] = Node(matchTimer.timeRemaining.formattedTimeString)
        return try nodeData.makeNode()
    }

    func received(event: Event, from socket: WebSocket) throws {
        switch event {
        case let scoringEvent as ScoringEvent:
            guard matchTimer.isRunning || scoringEvent.isPenalty else { return }
            try session.received(event: scoringEvent)
        case let controlEvent as ControlEvent:
            switch controlEvent.category {
            case .addJudge:
                try session.addConnection(to: socket, forJudgeID: event.judgeID)
            case .playPause:
                toggleMatchTimer()
            default:
                break
            }
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
    static let overlayClass = "overlay-display"
}
