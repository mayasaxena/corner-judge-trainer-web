//
//  MatchController.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/1/16.
//
//

import Vapor
import HTTP

public final class MatchController {
    let drop: Droplet
    var matches: [Int : Match] = [:]

    public init(droplet: Droplet) {
        drop = droplet
    }

    // MARK: - Routes

    public func index(_ request: Request) throws -> ResponseRepresentable {
        if MOCKING {
            populateMatches()
        }

        let matchNodes = try matches.map { try $0.value.makeNode() }
        let context = [
            "matches" : Node.array(matchNodes),
            "match-count" : Node(matchNodes.count)
        ] as Node

        if request.headers["Content-Type"] == "application/json" {
            return JSON(context)
        } else {
            return try drop.view.make("index", context)
        }
    }

    public func create(request: Request) throws -> ResponseRepresentable {
        let match = Match()
        matches[match.properties.id] = match
        return Response(redirect: "show")
    }

    public func edit(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        return try drop.view.make("edit-match", Node(node: ["id" : id]))
    }

    public func show(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        guard let match = matches[id] else { throw Abort.notFound }
        return try drop.view.make("match", match.makeNode())
    }

    public func addConnection(socket: WebSocket, forJudgeID judgeID: String, toMatchID matchID: Int) throws {
        guard let match = matches[matchID] else { throw Abort.notFound }
        match.session.connections[judgeID] = socket
    }

    public func handle(event: String, forColor color: String, fromJudgeID judgeID: String, forMatchID matchID: Int) throws {
        guard let match = matches[matchID] else { throw Abort.notFound }
        try match.session.received(event: event, forColor: color, fromJudgeWithID: judgeID)
    }

    private func populateMatches() {
        matches = [:]

        let playerNames: [(String, String)] = [
            ("Kira Tomlinson", "Eliza Schreibman"),
            ("Pulkit Jain", "Jaydev Dave"),
            ("Yennie Jun", "Julia Richieri"),
            ("Margot Day", "Jennifer Sohn")
        ]

        for (red, blue) in playerNames {
            let match = Match()
            match.properties.add(redPlayerName: red, bluePlayerName: blue)
            matches[match.properties.id] = match
        }
    }
}

extension MatchController: ResourceRepresentable {
    public func makeResource() -> Resource<Int> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: edit
        )
    }
}

extension Double {
    var formattedString: String {
        return String(Int(self))
    }
}
