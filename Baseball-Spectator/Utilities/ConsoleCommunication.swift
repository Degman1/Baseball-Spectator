//
//  ConsoleCommunication.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/19/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class ConsoleCommunication {
    static private func generateOutput(messageType: String, withMessage: String, source: String) {
        print("\(messageType): (\(source == "" ? "No Source Provided" : source)) \(withMessage)")
    }
    
    static func printWarning(withMessage: String, source: String = "") {
        generateOutput(messageType: "⚠️ WARNING", withMessage: withMessage, source: source)
    }

    static func printDocumentation(withMessage: String, source: String = "") {
        generateOutput(messageType: "📝 DOCUMENTATION", withMessage: withMessage, source: source)
    }
    
    static func printResult(withMessage: String, source: String = "") {
        generateOutput(messageType: "✅ RESULT", withMessage: withMessage, source: source)
    }
    
    static func printError(withMessage: String, source: String = "") {
        generateOutput(messageType: "💥 ERROR", withMessage: withMessage, source: source)
    }
}
