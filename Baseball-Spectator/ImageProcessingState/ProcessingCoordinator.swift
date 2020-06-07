//
//  ProcessingCoordinator.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class ProcessingCoordinator: ObservableObject {
    @Published var processingState: ProcessingState = .UserSelectHome
    @Published var expectedHomePlateAngle: Double = 0.0
}
