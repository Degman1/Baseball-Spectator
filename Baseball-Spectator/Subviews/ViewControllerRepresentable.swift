//
//  ViewControllerRepresentable.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    var fileInterface: FileIO
    
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController(fileInterface: fileInterface)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
