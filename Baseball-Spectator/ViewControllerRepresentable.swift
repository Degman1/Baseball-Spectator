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
    static var playersByPosition: [[Point]] = []
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = ViewController()
        ViewControllerRepresentable.playersByPosition = view.playersByPosition
        return view
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
