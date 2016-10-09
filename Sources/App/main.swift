import Vapor

let drop = Droplet()

let match = MatchController(droplet: drop)
drop.resource("/", match)

drop.get("scoring", handler: match.scoring)

drop.run()
