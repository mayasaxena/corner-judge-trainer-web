import Vapor

let drop = Droplet()

let match = MatchController(droplet: drop)
drop.resource("match", match)

drop.socket("match", "scoring") { request, socket in
    socket.onText = { socket, text in
        print(text)
    }
}

drop.run()
