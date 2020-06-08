//
//  PlayerInfo.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/8/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

struct PlayerInfo: CustomStringConvertible {
    let name: String
    let number: Int
    let position: String
    
    // statistics
    let avg: Float      // batting average
    let slg: Float      // slugging percentage
    let rbi: Int        // runs batted in
    let obp: Float      // on base perentage
    
    var description: String {
        return "\(name), \(position)"
    }
}
