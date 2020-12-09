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
    private var duration: Double? = nil
    private var fps: Double = 1.0
    private var videoURL: URL? = nil
    private var frames: [UIImage] = []
    private var generator: AVAssetImageGenerator! = nil
    private var timer: Timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in }
    
    func getCurrentFrame() -> UIImage {
        return frames[imageIndex]
    }
    
    func getFramesCount() -> Int {
        return frames.count
    }
    
    func fetchingFramesWasSuccessful() -> Bool {
        return !frames.isEmpty
    }
    
    func getVideoDimensions() -> CGSize? {
        if fetchingFramesWasSuccessful() { return self.frames[0].size }
        return nil
    }
    
    func setFPS(_ fps: Double) {
        self.fps = fps
    }
    
    func getFPS() -> Double {
        return fps
    }
    
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
    
    private func getAllFrames(fps: Double) -> [UIImage] {
        guard let url = videoURL else {
            return []
        }
        
        self.fps = fps
        
        let asset: AVAsset = AVAsset(url: url)
        let duration = Double(CMTimeGetSeconds(asset.duration))
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.generator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 100)
        self.generator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 100)
        self.frames = []
        
        var index: Double = 0.0
        
        while index < duration {
            self.getFrame(fromTime: Float64(index))
            index += 1.0 / self.fps
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
        pauseFrames()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / self.fps, repeats: true) { timer in
            self.imageIndex += 1
        }
    }
    
    func pauseFrames() {
        self.timer.invalidate()
    }
}
