function Scoring(host) {
    var scoring = this;

    scoring.ws = new WebSocket('ws://' + host);

    $('.penalty').click(function() {
        scoring.send("1");
        console.log("scored body")
    });

    scoring.ws.onmessage = function(event) {
        var scoringEvent = JSON.parse(event.data);
        console.log("scored " + scoringEvent);
    }

    scoring.send = function(event) {
        scoring.ws.send(JSON.stringify({
            'scoring event': event
        }));
    }
};
