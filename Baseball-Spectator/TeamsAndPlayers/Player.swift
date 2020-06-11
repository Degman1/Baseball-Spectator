//
//  PlayerInfo.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/8/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

struct Player: CustomStringConvertible {
    // this is to be used only to store information on players gathered from online
    
    let name: String
    let position: String
    let statisticsLink: String
    
    // TODO: add this in later
    /*
    
    let number: Int
    let avg: Float      // batting average
    let slg: Float      // slugging percentage
    let rbi: Int        // runs batted in
    let obp: Float      // on base perentage
    */
    
    var positionID: Int {
        switch self.position {
        case "SP":
            return 0
        case "C":
            return 1
        case "1B":
            return 2
        case "2B":
            return 3
        case "SS":
            return 4
        case "3B":
            return 5
        case "LF":
            return 6
        case "CF":
            return 7
        case "RF":
            return 8
        default:
            return -1
        }
    }
    
    var description: String {
        return "\(name) (\(position))"
    }
}
