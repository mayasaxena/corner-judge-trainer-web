//
//  StatusUpdate.swift
//  corner-judge-trainer-webPackageDescription
//
//  Created by Maya Saxena on 12/11/17.
//

import Vapor

// BACKEND SEND ONLY

private struct StatusJSONKey {
    static let event = "event"
    static let data = "data"
    static let score = "score"
    static let penalties = "penalties"
    static let red = "red"
    static let blue = "blue"
    static let timer = "timer"
    static let displayTime = "display_time"
    static let scoringDisabled = "scoring_disabled"
    static let round = "round"
    static let won = "winning_player"
}

enum StatusUpdate: JSONRepresentable {
    case score(red: Int, blue: Int)
    case penalties(red: Int, blue: Int)
    case timer(displayTime: String, scoringDisabled: Bool)
    case round(round: Int?)
    case won(winningColor: PlayerColor)

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(StatusJSONKey.event, "status")

        var dataJSON = JSON()

        switch self {
        case .score(let red, let blue):
            var scoreJSON = JSON()
            try scoreJSON.set(StatusJSONKey.red, red)
            try scoreJSON.set(StatusJSONKey.blue, blue)
            try dataJSON.set(StatusJSONKey.score, scoreJSON)
        case .penalties(let red, let blue):
            var penaltiesJSON = JSON()
            try penaltiesJSON.set(StatusJSONKey.red, red)
            try penaltiesJSON.set(StatusJSONKey.blue, blue)
            try dataJSON.set(StatusJSONKey.penalties, penaltiesJSON)
        case .timer(let displayTime, let scoringDisabled):
            var timerJSON = JSON()
            try timerJSON.set(StatusJSONKey.displayTime, displayTime)
            try timerJSON.set(StatusJSONKey.scoringDisabled, scoringDisabled)
            try dataJSON.set(StatusJSONKey.timer, timerJSON)
        case .round(let round):
            try dataJSON.set(StatusJSONKey.round, round)
        case .won(let winningColor):
            try dataJSON.set(StatusJSONKey.won, winningColor.rawValue)
        }

        try json.set(StatusJSONKey.data, dataJSON)
        return json
    }
}

/*
 "event": "status",
 "data" : {
     "score: {
         "red" : "5"
         "blue" : "5"
     }
 // OR
     "penalties: {
         "red" : "5"
         "blue" : "5"
     }
 // OR
     "timer" : {
        "display_time" : "1:10"
        "scoring_disabled" : "false"
     }
 // OR
    "round" : "1",
 // OR
    "won" : "blue",
}
 */
