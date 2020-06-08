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
    @Published var name: String? = nil
    @Published var realCoordinate: CGPoint? = nil   // corresponding to the full size image
    @Published var viewCoordinate: CGPoint? = nil   // corresponding to the image displayed on the screen
    
    func setPlayer(positionID: Int, realCoordinate: CGPoint, viewCoordinate: CGPoint) {
        self.positionID = positionID
        self.realCoordinate = realCoordinate
        self.viewCoordinate = viewCoordinate
    }
    
    func unselectPlayer() {
        self.positionID = nil
        self.realCoordinate = nil
        self.viewCoordinate = nil
    }
    
    var description: String {
        switch self.positionID {
            case 0:
                return "Pitcher"
            case 1:
                return "Catcher"
            case 2:
                return "First Base"
            case 3:
                return "Second Base"
            case 4:
                return "Shortstop"
            case 5:
                return "Third Base"
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
