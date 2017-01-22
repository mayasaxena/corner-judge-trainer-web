function edit-match(host) {
    var editor = this;
    editor.ws = new WebSocket('ws://' + host);

    $('.body').click(function() {
        var color = $(this).parent().attr("id");
        editor.send("Body", color);
    });

    $('.head').click(function() {
        var color = $(this).parent().attr("id");
        editor.send("Head", color);
    });

    editor.ws.onmessage = function(event) {
        var scoringEvent = event.data;
        console.log(scoringEvent);
    }

    editor.send = function(event, color) {
        editor.ws.send(JSON.stringify({
            'judge' : 'web',
            'scored': event,
            'color' : color
        }));
    }
};
