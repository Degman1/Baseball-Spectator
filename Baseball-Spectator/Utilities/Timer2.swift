//
//  Timer2.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/25/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class Timer2 {
    var startTaskms: Double = 0
    var endTaskms: Double = 0
    
    func getCurrentMillis() -> Double {
        return Double(NSDate().timeIntervalSince1970 * 1000)
    }
    
    func startTimer() {
        startTaskms = getCurrentMillis()
    }
    
    func endTimer() {
        endTaskms = getCurrentMillis()
    }
    
    func elapsedTimems() -> Double {
        return Double(endTaskms - startTaskms)
    }
    
    func elapsedTimeSeconds() -> Int {
        return Int(elapsedTimems() / 1000)
    }
    
    func elapsedTimeTenthsSeconds() -> Int {
        return Int(elapsedTimems() / 100)
    }
}
