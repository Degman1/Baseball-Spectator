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
    
    // reset every x seconds automatically
    let name: String
    let position: String
    let statisticsLink: String
    
    // reset when the player is selected
    // just keep the values as strings b/c don't need to do anything with them except display
    var avg: String? = nil      // batting average
    var slg: String? = nil      // slugging percentage
    var rbi: String? = nil        // runs batted in
    var obp: String? = nil      // on base perentage
    
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
    
    var detailedDescription: String {
        if self.avg != nil {
            return "\(name), (\(position))\n\tavg: \(avg!), slg: \(slg!), rbi: \(rbi!), obp: \(obp!)"
        } else {
            return "\(name) (\(position))"
        }
    }
    
    var description: String {
        return "\(name) (\(position))"
    }
}
