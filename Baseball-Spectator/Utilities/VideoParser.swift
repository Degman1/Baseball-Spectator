//
//  VideoParser.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI

class VideoParser: ObservableObject {
    @Published var imageIndex = 0
    private var duration: Float? = nil
    var fps: Float = 1
    private var videoURL: URL? = nil
    var frames: [UIImage] = []
    private var generator: AVAssetImageGenerator! = nil
    
    func getVideoURL() -> URL? {
        return videoURL
    }
    
    func setVideoURL(forResource name: String, ofType ext: String) -> Bool {
        guard let path = Bundle.main.path(forResource: name, ofType: ext) else {
            ConsoleCommunication.printError(withMessage: "could not find a video matching the provided path", source: "\(#function)")
            return false
        }
        self.videoURL = URL(fileURLWithPath: path)
        return true
    }
    
    func getAllFrames(fps: Float) -> [UIImage] {
        guard let url = videoURL else {
            return []
        }
        
        self.fps = fps
        
        let asset: AVAsset = AVAsset(url: url)
        let duration = Float(CMTimeGetSeconds(asset.duration))
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.frames = []
        
        var index: Float = 0.0
        
        while index < duration {
            self.getFrame(fromTime:Float64(index))
            index += 1 / self.fps
        }
        
        return self.frames
    }

    private func getFrame(fromTime: Float64) {
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:600)
        let image: CGImage
        do {
           try image = self.generator.copyCGImage(at:time, actualTime:nil)
        } catch {
           return
        }
        self.frames.append(UIImage(cgImage:image))
    }
    
    func playFrames() {
        let queue = DispatchQueue(label: "com.playback.queue")
        
        queue.async {
            while true {
                usleep(UInt32(1000000 / self.fps))
                DispatchQueue.main.async {
                    self.imageIndex = (self.imageIndex + 1) % self.frames.count
                }
            }
        }
    }
}
