import Vapor

let drop = Droplet()

let match = MatchController(droplet: drop)
drop.resource("match", match)

drop.get("match", Int.self, "edit", handler: match.edit)

drop.socket("match", Int.self) { request, socket, id in
    socket.onText = { socket, text in
        print(text)
        let json = try JSON(bytes: Array(text.utf8))
        guard let event = json["scoring event"]?.string else { return }
        try socket.send(event)
    }
}

drop.run()
