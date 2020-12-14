//
//  ConsoleCommunication.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/19/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class ConsoleCommunication {
    /*** Static class to print messages to the console. Cannot be ObservableObject since every file in this project must be able to interact with it regaurdless of its interaction with SwiftUI ***/
    static private var debug = false
    // wasError variable is located in the InterfaceCoordinator so that the app UI can actively interact with it
    static private var interfaceCoordinator: InterfaceCoordinator? = nil
    
    static func setInterfaceCoordinator(coordinator: InterfaceCoordinator) {
        interfaceCoordinator = coordinator
    }
    
    static func didErrorOccur() -> Bool {
        if interfaceCoordinator == nil { return false }
        return interfaceCoordinator!.wasError
    }
    
    static func encounteredError() {
        // Just in case this function is run on a background thread... must change published variable on the main thread
        DispatchQueue.main.async {
            if interfaceCoordinator != nil { interfaceCoordinator!.wasError = true }
        }
    }
    
    static func clearError() {
        // Just in case this function is run on a background thread... must change published variable on the main thread
        DispatchQueue.main.async {
            if interfaceCoordinator != nil { interfaceCoordinator!.wasError = false }
        }
    }
    
    static func isConsoleInDebugMode() -> Bool { return debug }
    static func enterDebugMode() { debug = true }
    static func exitDebugMode() { debug = false }
    
    static private func printMessage(messageType: String, withMessage: String, source: String) {
        let seperator = withMessage.contains("\n") ? "...\n" : " "
        print("\(messageType): (source: \(source == "" ? "No Source Provided" : source))\(seperator)\(withMessage)")
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
    
    static func printDebug(withMessage: String, source: String = "") {
        if debug {
            printMessage(messageType: "🐞 DEBUG", withMessage: withMessage, source: source)
        }
    }
    
    static func printError(withMessage: String, source: String = "") {
        encounteredError()
        printMessage(messageType: "💥 ERROR", withMessage: withMessage, source: source)
    }
}
