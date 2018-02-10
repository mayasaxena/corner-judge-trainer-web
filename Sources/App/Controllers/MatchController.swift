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
    var matchManagers: [Int : MatchManager] = [:]

    public init(droplet: Droplet) {
        drop = droplet
        Logging.isEnabled = true
        Logging.shouldLogSocketStream = true
    }

    // MARK: - Routes

    public func index(_ request: Request) throws -> ResponseRepresentable {
        if MOCKING {
            populateMatchesIfNecessary()
        }

        let matchesJSON = try matchManagers.values
            .filter { $0.match.status != .completed }
            .map { try $0.match.makeJSON() }

        var json = JSON()
        try json.set("matches", matchesJSON)
        try json.set("match-count", matchesJSON.count)

        if request.headers["Content-Type"] == "application/json" {
            return json
        } else {
            return try drop.view.make("index", json)
        }
    }

    public func create(request: Request) throws -> ResponseRepresentable {
        return try drop.view.make("create-match")
    }

    public func store(request: Request) throws -> ResponseRepresentable {
        let match = try request.createMatch()
        matchManagers[match.id] = MatchManager(match: match)
        return Response(redirect: "/")
    }

    public func edit(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        return try drop.view.make("edit-match", Node(node: ["id" : id]))
    }

    public func show(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        guard let manager = matchManagers[id] else { throw Abort.notFound }
        return try drop.view.make("match", manager.makeJSON())
    }

    public func destroy(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        if let index = matchManagers.index(forKey: id) {
            matchManagers.remove(at: index)
        }
        return Response(redirect: "/")
    }

    private func populateMatchesIfNecessary() {
        guard matchManagers.isEmpty else { return }

        let playerNames: [(String, String)] = [
            ("Kira Tomlinson", "Eliza Schreibman"),
            ("Pulkit Jain", "Jaydev Dave"),
            ("Yennie Jun", "Julia Richieri"),
            ("Margot Day", "Jennifer Sohn")
        ]

        for (red, blue) in playerNames {
            let match = Match(redPlayerName: red, bluePlayerName: blue, type: .bTeam)
            matchManagers[match.id] = MatchManager(match: match)
        }
    }

    // MARK: - Event Handling

    public func handle(_ json: JSON, matchID: Int, socket: WebSocket) throws {
        guard let manager = matchManagers[matchID] else { throw Abort.notFound }
        guard let event = json.createEvent() else { throw Abort.badRequest }
        try manager.received(event: event, from: socket)
    }

    public func handleDisconnect(matchID: Int, socket: WebSocket) throws {
        guard let manager = matchManagers[matchID] else { throw Abort.notFound }
        manager.disconnect(socket: socket)
    }
}

extension MatchController: ResourceRepresentable {
    public func makeResource() -> Resource<Int> {
        return Resource(
            index: index,
            create: create,
            store: store,
            show: show,
            edit: edit,
            destroy: destroy
        )
    }
}

extension Request {
    func createMatch() throws -> Match {
        guard let formURLEncoded = formURLEncoded else { throw Abort.badRequest }
        return try Match(json: JSON(node: formURLEncoded))
    }
}
