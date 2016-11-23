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
    var matches: [String : Match] = [:]

    public init(droplet: Droplet) {
        drop = droplet
    }

    // MARK: - Routes

    public func index(_ request: Request) throws -> ResponseRepresentable {
        if MOCKING {
            populateMatches()
        }

        let matchNodes = try matches.map { try $0.value.makeNode() }
        let context = ["matches" : Node.array(matchNodes)] as Node

        if request.headers["Content-Type"] == "application/json" {
            return JSON(context)
        } else {
            return try drop.view.make("index", context)
        }
    }

    public func create(request: Request) throws -> ResponseRepresentable {
        let match = Match()
        matches[match.properties.matchID] = match
        return Response(redirect: "show")
    }

    public func edit(_ request: Request, _ id: String) throws -> ResponseRepresentable {
        return try drop.view.make("edit-match", Node(node: ["id" : id]))
    }

    public func show(_ request: Request, _ id: String) throws -> ResponseRepresentable {
        guard let match = matches[id] else { throw Abort.notFound }
        return try drop.view.make("match", match.makeNode())
    }

    public func addJudge(withID id: String, socket: WebSocket) {
//        match.session.connections[id] = socket
    }

    public func handle(event: String, forColor color: String, fromJudgeWithID id: String) throws {
//        try match.session.received(event: event, forColor: color, fromJudgeWithID: id)
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
            matches[match.properties.matchID] = match
        }
    }
}

extension MatchController: ResourceRepresentable {
    public func makeResource() -> Resource<String> {
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
