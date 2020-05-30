//
//  ViewController.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var skipFrame = 0;
    private let context = CIContext()
    public var playersByPosition: [[Point]] = []
    var fileInterface: FileIO
    
    init(fileInterface: FileIO) {
        self.fileInterface = fileInterface
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.getFrames()
        self.captureSession.startRunning()
        
        if imageView == nil {
            imageView = UIImageView(image: UIImage(named: "image1"))   //just to initialize the view
        }
        imageView.frame.size.width = UIScreen.main.bounds.width
        imageView.frame.size.height = UIScreen.main.bounds.height
        view.addSubview(imageView)
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
                fatalError("No back camera device found, please make sure to run Baseball Spectator in an iOS device and not a simulator")
        }
        device.set(frameRate: 20)
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if UIDevice.current.orientation == .landscapeLeft {
            connection.videoOrientation = .landscapeRight
        } else if UIDevice.current.orientation == .landscapeRight {
            connection.videoOrientation = .landscapeLeft
        }
        
        // here we can process the frame
        let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)!
        
        DispatchQueue.main.async {
            if self.skipFrame % 2 == 0 {
                self.imageView.image = OpenCVWrapper.processImage(image, expectedHomePlateAngle: HOME_PLATE_ANGLES[4])
            }
            
            self.skipFrame += 1
        }
        
        try! fileInterface.loadData()
    }
    
    private func getFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        self.captureSession.addOutput(videoDataOutput)
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported, connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .landscapeRight
        connection.isVideoMirrored = false
    }
}
