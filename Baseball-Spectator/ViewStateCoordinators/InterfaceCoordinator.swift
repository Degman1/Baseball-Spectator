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
}
