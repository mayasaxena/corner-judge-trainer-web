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

    /**
     At the root, the board view is rendered with the items
     on the board and a form to post new items.
     */
    public func index(_ request: Request) throws -> ResponseRepresentable {

        return try drop.view.make("match", match.makeNode())
    }
}

extension MatchController: ResourceRepresentable {
    public func makeResource() -> Resource<String> {
        return Resource(index: index)
    }
}

extension Double {
    var formattedString: String {
        return String(Int(self))
    }
}
