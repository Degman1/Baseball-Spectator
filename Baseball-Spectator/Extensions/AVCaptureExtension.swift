//
//  AVCaptureExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    func set(frameRate: Double) {
        guard let range = activeFormat.videoSupportedFrameRateRanges.first,
            range.minFrameRate...range.maxFrameRate ~= frameRate
            else {
                ConsoleCommunication.printError(withMessage: "requested FPS is not supported by the device's activeFormat", source: "\(#function)")
                return
        }

        do { try lockForConfiguration()
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            unlockForConfiguration()
        } catch {
            ConsoleCommunication.printError(withMessage: "\(error.localizedDescription)", source: "\(#function)")
        }
    }
}
