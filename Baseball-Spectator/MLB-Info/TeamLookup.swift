//
//  TeamLookup.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/5/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

let BOSTON_RED_SOX = Team("Boston Red Sox", .American, .East)
let NEW_YORK_YANKEES = Team("New York Yankees", .American, .East)

let teams: [String: Team] = [
    BOSTON_RED_SOX.lookupName: BOSTON_RED_SOX,
    NEW_YORK_YANKEES.lookupName: NEW_YORK_YANKEES
]
