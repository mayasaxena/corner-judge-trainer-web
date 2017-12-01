//
//  Repeat.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 1/22/17.
//
//

import Leaf
import Foundation

class Repeat: Tag {
    enum Error: Swift.Error {
        case expectedOneArgument
    }

    let name = "repeat"

    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedOneArgument }
        return arguments.first
    }

    func render(
        stem: Stem,
        context: Context,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard
            let count = value?.int,
            let item = value
            else { fatalError("run function MUST return an int") }

        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }

        var buffer = Bytes()
        for _ in 0..<count {
            buffer += try renderItem(item)
        }
        return buffer
    }

}
