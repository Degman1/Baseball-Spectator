//
//  ConsoleCommunication.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/19/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class ConsoleCommunication {
    static var debug = false
    
    static private func printMessage(messageType: String, withMessage: String, source: String) {
        print("\(messageType): (source: \(source == "" ? "No Source Provided" : source)) \(withMessage)")
    }
    
    static func printWarning(withMessage: String, source: String = "") {
        printMessage(messageType: "⚠️ WARNING", withMessage: withMessage, source: source)
    }

    static func printDocumentation(withMessage: String, source: String = "") {
        printMessage(messageType: "📝 DOCUMENTATION", withMessage: withMessage, source: source)
    }
    
    static func printResult(withMessage: String, source: String = "") {
        if debug {
            printMessage(messageType: "✅ RESULT", withMessage: withMessage, source: source)
        }
    }
    
    static func printError(withMessage: String, source: String = "") {
        printMessage(messageType: "💥 ERROR", withMessage: withMessage, source: source)
    }
}
