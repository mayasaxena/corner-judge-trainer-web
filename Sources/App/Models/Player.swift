//
//  Player.swift
//  CornerJudgeTrainer
//
//  Created by Maya Saxena on 8/24/16.
//  Copyright © 2016 Maya Saxena. All rights reserved.
//

import Foundation

public enum PlayerColor: String {
    case blue, red
    
    var displayName: String {
        return rawValue.capitalized
    }
}

public struct Player {
    struct Constants {
        static let DefaultName = "Anonymous"
    }
    
    var name: String
    var color: PlayerColor
    
    init(color: PlayerColor) {
        self.init(color: color, name: Constants.DefaultName + " " + color.displayName)
    }
    
    init(color: PlayerColor, name: String) {
        self.color = color
        self.name = name
    }
}

extension Player {
    static var defaultName: String {
        return Constants.DefaultName
    }
    
    var displayName: String {
        return name.contains(Player.defaultName) ? "" : name
    }
}
