import Vapor
import Leaf

let DEBUG = false
let MOCKING = true

let drop = Droplet()

if let leaf = drop.view as? LeafRenderer {
    leaf.stem.register(GreaterThan())
    leaf.stem.register(Repeat())
}

let matchController = MatchController(droplet: drop)

drop.get(handler: matchController.index)
drop.resource("match", matchController)

drop.socket("match-ws", Int.self) { request, socket, matchID in
    socket.onText = { socket, text in
        print(text)

        try background {
            while socket.state == .open {
                try? socket.ping()
                drop.console.wait(seconds: 10) // every 10 seconds
            }
        }

        let node = try JSON(bytes: Array(text.utf8)).node
        try matchController.handle(node, matchID: matchID, socket: socket)
    }
}

drop.run()
