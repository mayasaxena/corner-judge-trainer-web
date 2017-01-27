function Scoring(host) {
    var scoring = this;

    var url = 'ws://' + host
    var server = new ServerEventsDispatcher(url)

    // TRIGGERS

    document.onkeypress = function(event) {
        event = event || window.event;
        var charCode = event.keyCode || event.which;
        var charString = String.fromCharCode(charCode);
        switch (charString) {
            // RED
            case 'f':
                scoring.send("body", "red")
                break;
            case 'v':
                scoring.send("head", "red");
                break;
            case 'g':
                scoring.send("technical", "red");
                break;

            // BLUE
            case 'j':
                scoring.send("body", "blue");
                break;
            case 'n':
                scoring.send("head", "blue");
                break;
            case 'h':
                scoring.send("technical", "blue");
                break;

            case ' ':
                scoring.playPause()
                $(".overlay").toggle()
                break;
            default:
                break;
        }
    };

    scoring.playPause = function() {
        server.trigger("control", {
            "category" : "playPause"
        })
    }

    scoring.send = function(category, color) {
        server.trigger("scoring", {
            "category" : category,
            "color" : color
        })
    }

    // BINDINGS

    server.bind("open", function() {
        server.trigger("control", {
            "category" : "addJudge"
        })
    })

    server.bind("scoring", function(event) {
        $('.scoring').load(document.URL +  ' .scoring > *');
    })

    server.bind("control", function(event) {
        console.log(event)
        $(".match-info").load(document.URL + " .match-info > *")
    })
};
