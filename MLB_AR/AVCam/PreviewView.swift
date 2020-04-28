//
//  PreviewView.swift
//  MLB_AR
//
//  Created by Joey Cohen on 4/28/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import AVFoundation

class PreviewView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    
    init() {
        super.init(frame: .zero)

        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()

        if !allowedAccess {
            print("!!! NO ACCESS TO CAMERA")
            return
        }

        // setup session
        // Step 3. AVCaptureSession
        let session = AVCaptureSession()
        session.beginConfiguration()

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for : .video, position: .front) //alternate AVCaptureDevice.default(for: .video)
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {
            print("!!! NO CAMERA DETECTED")
            return
        }
        session.addInput(videoDeviceInput)


        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)


        session.commitConfiguration()
        self.captureSession = session
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    // wrapping dispatch
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspect
            self.captureSession?.startRunning()
        } else {
            self.captureSession?.stopRunning()

        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        print("Got a frame!")
    }
}
