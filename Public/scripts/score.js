function Scoring(host) {
    var scoring = this;
    scoring.ws = new WebSocket('ws://' + host);

    $('.body').click(function() {
        var color = $(this).parent().attr("id");
        scoring.send("Body", color);
    });

    $('.head').click(function() {
        var color = $(this).parent().attr("id");
        scoring.send("Head", color);
    });

    scoring.ws.onmessage = function(event) {
        var scoringEvent = event.data;
        console.log("scored " + scoringEvent);
    }

    scoring.send = function(event, color) {
        scoring.ws.send(JSON.stringify({
            'scoring event': event,
            'color' : color
        }));
    }
};
