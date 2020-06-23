//
//  VideoParser.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import AVKit

class VideoParser {
    private var videoURL: URL? = nil
    var frames: [UIImage] = []
    private var generator: AVAssetImageGenerator! = nil
    
    func getVideoURL() -> URL? {
        return videoURL
    }
    
    func setVideoURL(forResource name: String, ofType ext: String) -> Bool {
        guard let path = Bundle.main.path(forResource: name, ofType: ext) else {
            ConsoleCommunication.printError(withMessage: "could not find a video matching the provided path", source: "VideoParser")
            return false
        }
        self.videoURL = URL(fileURLWithPath: path)
        return true
    }
    
    func getAllFrames() -> [UIImage] {
        guard let url = videoURL else {
            return []
        }
        
        let asset: AVAsset = AVAsset(url: url)
        let duration: Float64 = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.frames = []
        
        for index in 0..<Int(duration) {
            self.getFrame(fromTime:Float64(index))
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

}
