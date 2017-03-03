//
//  Logging.swift
//  corner-judge-trainer-web
//
//  Created by Maya Saxena on 2/10/17.
//
//

import Foundation

struct Logging {

    public static var isEnabled = false
    public static var shouldLogSocketStream = false

    fileprivate static var timestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy - H:mm:ss"

        return dateFormatter.string(from: Date())
    }
}

public func log(_ message: String) {
    guard Logging.isEnabled else { return }
    print("\(Logging.timestamp): \(message)")
}

public func log(fromSocket socketText: String) {
    guard Logging.isEnabled && Logging.shouldLogSocketStream else { return }
    print("\(Logging.timestamp): STREAM - \(socketText)")
}

public func log(error: Error) {
    guard Logging.isEnabled else { return }
    print("\(Logging.timestamp): ERROR - \(error)")
}


