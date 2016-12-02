function Scoring(host) {
    var scoring = this;
    scoring.ws = new WebSocket('ws://' + host);

    scoring.ws.onopen = function(event) {
        scoring.ws.send(JSON.stringify({
            'judge': "web"
        }));
    }

    document.onkeypress = function(event) {
        event = event || window.event;
        var charCode = event.keyCode || event.which;
        var charString = String.fromCharCode(charCode);
        switch (charString) {
            // RED
            case 'f':
                scoring.send("body", "red");
                break;
            case 'f':
                scoring.send("head", "red");
                break;
            case 'v':
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
                console.log("pause")
                break;
            default:
                break;
        }
    };

    scoring.ws.onmessage = function(event) {
        var scoringEvent = event.data;
        console.log(scoringEvent);
    }

    scoring.send = function(event, color) {
        scoring.ws.send(JSON.stringify({
            'judge' : 'web',
            'scored': event,
            'color' : color
        }));
    }
};
