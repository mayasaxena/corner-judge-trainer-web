//
//  GreaterThan.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 11/24/16.
//
//

import Leaf
import Foundation

class GreaterThan: Tag {
    enum Error: Swift.Error {
        case expectedTwoArguments
    }

    let name = "greaterThan"

    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments }
        return nil
    }

    func shouldRender(tagTemplate: TagTemplate, arguments: ArgumentList, value: Node?) -> Bool {
        guard
            let variable = arguments.first?.int,
            let value = arguments.last?.int
            else { return false }
        return variable > value
    }
}
