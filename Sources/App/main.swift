import Vapor

let drop = Droplet()

drop.get { req in
    let lang = req.headers["Accept-Language"]?.string ?? "en"
    return try drop.view.make("match", [
    	"score": Node.string("0")
    ])
}

drop.run()
