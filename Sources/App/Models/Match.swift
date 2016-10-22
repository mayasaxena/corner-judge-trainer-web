//
//  Match.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 10/1/16.
//
//

import Vapor
import Foundation
import Random

public final class Match {

    let info = MatchInfo()
    let session = MatchSession()

    public func makeNode() throws -> Node {
        return try Node(node: info.nodeDictionary)
    }
}
