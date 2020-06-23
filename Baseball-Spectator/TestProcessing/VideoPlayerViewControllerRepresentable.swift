//
//  VideoPlayerViewControllerRepresentable.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI
import AVKit

struct VideoPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let path = Bundle.main.path(forResource: "sampleVideo", ofType:"mp4")!
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerController = AVPlayerViewController()
        playerController.player = player
        //player.play()
        return playerController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
