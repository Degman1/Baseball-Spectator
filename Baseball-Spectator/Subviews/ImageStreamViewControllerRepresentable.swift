//
//  ViewControllerRepresentable.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

struct ImageStreamViewControllerRepresentable: UIViewControllerRepresentable {
    var processingResultParser: ProcessingResultParser
    var processingCoordinator: ProcessingCoordinator
    
    func makeUIViewController(context: Context) -> UIViewController {
        return ImageStreamViewController(processingResultParser: processingResultParser, processingCoordinator: processingCoordinator)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
