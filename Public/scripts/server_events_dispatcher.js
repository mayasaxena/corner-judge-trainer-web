/*
The MIT License (MIT)

Copyright (c) 2014 Ismael Celis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-------------------------------*/
/*
Simplified WebSocket events dispatcher (no channels, no users)

// bind to server events
socket.bind('some_event', function(data){
  alert(data.name + ' says: ' + data.message)
});

// broadcast events to all connected users
socket.trigger( 'some_event', {name: 'ismael', message : 'Hello world'} );
*/

var ServerEventsDispatcher = function(url) {
    var socket = new WebSocket(url);
    console.log(url)
    var callbacks = {};

    var sender = randomString()

    this.bind = function(event_name, callback) {
        callbacks[event_name] = callbacks[event_name] || [];
        callbacks[event_name].push(callback);
        return this; // chainable
    };

    this.trigger = function(event_name, event_data) {
        var payload = JSON.stringify({
            "event" : event_name,
            "sent_by": sender,
            "data" : event_data
        });
        socket.send(payload); // <= send JSON data to socket server
        console.log(payload)
        return this;
    };

    var dispatch = function(event_name, message) {
        var chain = callbacks[event_name];
        if (typeof chain == 'undefined') return; // no callbacks for this event
        for (var i = 0; i < chain.length; i++) {
            chain[i](message)
        }
    }

    socket.onclose = function() { dispatch('close', null) }
    socket.onopen = function() { dispatch('open', null) }

    // dispatch event to handlers
    socket.onmessage = function(event) {
        var json = JSON.parse(event.data)
        dispatch(json.event, json.data)
    };

    function randomString() {
        var result = '';
        var chars = '0123456789abcdefghijklmnopqrstuvwxyz'
        for (var i = 5; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
        return result;
    }
};


/*
EVENTS STRUCTURE
-----------------

Control
{
    "event" : "control",
    "sent_by" : <judgeID>,
    "data" : {
        "category" : <category>,
        "<data-field>" : <data>
    }
}
categories:
    pause
    play
    addJudge

Scoring
{
    "event" : "scoring",
    "sent_by" : <judgeID>,
    "data" : {
        "category" : <category>,
        "color" : "red" or "blue"
    }
}

categories:
    body
    head
    technical
    kyongGo
    gamJeom
*/
