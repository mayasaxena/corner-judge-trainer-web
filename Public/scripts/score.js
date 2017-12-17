function Scoring(host) {
    var scoring = this;

    var url = 'ws://' + host
    var server = new ServerEventsDispatcher(url)
    var participantType = "operator"

    // TRIGGERS
    document.onkeypress = function(event) {
            event = event || window.event;
            var charCode = event.keyCode || event.which;
            var charString = String.fromCharCode(charCode);
        if (participantType == "judge") {
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

                default:
                    break;
            }
        } else if (participantType == "operator") {
            switch (charString) {
                case ' ':
                    scoring.playPause()
                    break;
                default:
                    break;
            }
        }
    };

    $(".overlay-wrapper").on("click", ".button", function() {
        if (participantType == "operator") {
            var classList = this.classList
            var color = classList[0]
            var category = classList[1]
            if (color == "red" || color == "blue") {
                if (category == "give-gam-jeom") {
                    if (confirm("Give gam-jeom to " + color + "?")) {
                        scoring.giveGamJeom(color)
                    }
                } else if (category == "remove-gam-jeom") {
                    if (confirm("Remove gam-jeom from " + color + "?")) {
                        scoring.removeGamJeom(color)
                    }
                } else {
                    var point = $(this).data('value');
                    var text = point + " point"
                    if (Math.abs(point) > 1) {
                        text += "s"
                    }
                    if (confirm(text + " to " + color + "?")) {
                        scoring.adjustScore(color, point)
                    }
                }
            }
        }
    });

    scoring.send = function(category, color) {
        server.trigger("scoring", {
            "category" : category,
            "color" : color
        })
    }

    scoring.playPause = function() {
        server.trigger("control", {
            "category" : "playPause"
        })
    }

    scoring.giveGamJeom = function(color) {
        server.trigger("control", {
            "category" : "giveGamJeom",
            "color" : color
        })
    }

    scoring.removeGamJeom = function(color) {
        server.trigger("control", {
            "category" : "removeGamJeom",
            "color" : color
        })
    }

    scoring.adjustScore = function(color, value) {
        server.trigger("control", {
            "category" : "adjustScore",
            "color" : color,
            "value" : value
        })
    }

    // BINDINGS

    server.bind("open", function() {
        server.trigger("newParticipant", {
            "participant_type" : participantType
        })
    })

    server.bind("status", function(data) {
        if (data.timer != undefined) {
            reloadMatchInfo()
            reloadOverlay()
        } else if (data.round != undefined) {
            reloadMatchInfo()
        } else if (data.score != undefined || data.penalties != undefined) {
            reloadScores()
        }
    })

    function reloadMatchInfo() {
        $(".match-info").load(document.URL + " .match-info > *")
    }

    function reloadOverlay() {
        $('.overlay-wrapper').load(document.URL +  ' .overlay-wrapper > *');
    }

    function reloadScores() {
        $('.scoring').load(document.URL +  ' .scoring > *');
    }
};
