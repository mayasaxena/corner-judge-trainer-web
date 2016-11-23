//
//  GreaterThan.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 11/24/16.
//
//

import Leaf
import Foundation

class GreaterThan: BasicTag {
    enum Error: Swift.Error {
        case expectedTwoArguments
    }

    let name = "greaterThan"

    public func run(arguments: [Argument]) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Node?
        ) -> Bool {
        guard
            let variable = arguments.first?.value?.int,
            let value = arguments.last?.value?.int
            else {
                return false
        }
        return variable > value
    }
}
