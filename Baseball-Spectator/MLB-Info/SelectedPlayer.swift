//
//  SelectedPlayer.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

class SelectedPlayer: CustomStringConvertible, ObservableObject {
    @Published var positionID: Int? = nil
    @Published var coordinate: CGPoint? = nil
    
    func setSelectedPlayer(positionID: Int, coordinate: CGPoint) {
        self.positionID = positionID
        self.coordinate = coordinate
    }
    
    var description: String {
        switch self.positionID {
            case 0:
                return "Pitcher"
            case 1:
                return "Catcher"
            case 2:
                return "First"
            case 3:
                return "Second"
            case 4:
                return "Shortstop"
            case 5:
                return "Third"
            case 6:
                return "Leftfield"
            case 7:
                return "Centerfield"
            case 8:
                return "Rightfield"
            case nil:
                return "No Selection"
            default:
                return "player-selection-failure"
        }
    }
}
