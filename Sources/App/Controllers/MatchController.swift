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
    let match = Match()

    public init(droplet: Droplet) {
        drop = droplet
    }

    // MARK: - Routes

    public func index(_ request: Request) throws -> ResponseRepresentable {
        return try drop.view.make("match", match.makeNode())
    }

    public func edit(_ request: Request, _ id: Int) throws -> ResponseRepresentable {
        return try drop.view.make("edit-match", Node(node: ["id" : id]))
    }

    public func addJudge(withID id: String, socket: WebSocket) {
        match.session.connections[id] = socket
    }

    public func handle(event: String, forColor color: String, fromJudgeWithID id: String) throws {
        try match.session.received(event: event, forColor: color, fromJudgeWithID: id)
    }
}

extension MatchController: ResourceRepresentable {
    public func makeResource() -> Resource<String> {
        return Resource(
            index: index
        )
    }
}

extension Double {
    var formattedString: String {
        return String(Int(self))
    }
}
