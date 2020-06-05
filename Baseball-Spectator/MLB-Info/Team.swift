//
//  TeamList.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/5/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class Team: CustomStringConvertible {
    let name: String
    let lookupName: String
    let league: League
    let division: Division
    
    init(_ name: String, _ league: League, _ division: Division) {
        self.name = name
        self.lookupName = name.lowercased().split(separator: " ").joined(separator: "-")
        self.league = league
        self.division = division
    }
    
    var description: String {
        return name
    }
}

enum League {
    case National, American
}

enum Division {
    case East, Central, West
}
