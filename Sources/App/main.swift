import Foundation
import Vapor
import LeafProvider
import Sessions

let DEBUG = false
let MOCKING = true

let config = try Config()
try config.addProvider(LeafProvider.Provider.self)

let droplet = try Droplet(config)

if let leaf = droplet.view as? LeafRenderer {
    leaf.stem.register(GreaterThan())
    leaf.stem.register(Repeat())
}

let matchController = MatchController(droplet: droplet)

droplet.get(handler: matchController.index)
droplet.resource("match", matchController)

droplet.socket("match-ws", Int.parameter) { request, socket in

    let matchID = try request.parameters.next(Int.self)

    background {
        while socket.state == .open {
            try? socket.ping()
            droplet.console.wait(seconds: 10) // every 10 seconds
        }
    }

    socket.onText = { socket, text in
        log(fromSocket: text)

        let json = try JSON(bytes: Array(text.utf8))
        try matchController.handle(json, matchID: matchID, socket: socket)
    }

    socket.onClose = { socket, _, _, _ in
        try matchController.handleDisconnect(matchID: matchID, socket: socket)
    }
}

try droplet.run()
