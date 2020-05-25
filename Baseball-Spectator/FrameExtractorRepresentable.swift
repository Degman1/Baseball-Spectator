//
//  FrameExtractorRepresentable.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/25/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

struct FrameExtractorViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FrameExtractorViewController {
        return FrameExtractorViewController()
    }
    
    func updateUIViewController(_ uiViewController: FrameExtractorViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = FrameExtractorViewController
}
