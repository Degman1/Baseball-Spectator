//
//  InterfaceCoordinator.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class InterfaceCoordinator: ObservableObject {
    @Published var showHomePlateMessageView = true
    @Published var disableControls = true
    @Published var selectedTeam: ActiveTeam = .Defense
    
    // this published variable is implemented through ConsoleCommunication, but is located here instead to be able to actively affect the UI since ConsoleCommunication is a static, non-observable class
    // TODO: make error handling more dynamic based on the type of error and where it occurred
    @Published var wasError = false
}
