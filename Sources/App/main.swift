import Vapor
import Leaf

let DEBUG = false
let MOCKING = true

let drop = Droplet()

if let leaf = drop.view as? LeafRenderer {
    leaf.stem.register(GreaterThan())
}

let matchController = MatchController(droplet: drop)

drop.get(handler: matchController.index)

drop.resource("match", matchController)

drop.socket("match", Int.self) { request, socket, id in
    socket.onText = { socket, text in
        print(text)

        let jsonObject = try JSON(bytes: Array(text.utf8)).object
        guard let judgeID = jsonObject?["judge"]?.string else { return }
        matchController.addJudge(withID: judgeID, socket: socket)

        if let event = jsonObject?["scored"]?.string,
            let color = jsonObject?["color"]?.string {
            try matchController.handle(event: event, forColor: color, fromJudgeWithID: judgeID)
        }
    }
}

drop.run()
