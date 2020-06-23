//
//  TestVideoProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestVideoProcessingView: View {
    @State var imageIndex = 0
    var processingState: ProcessingState = .UserSelectHome
    let fileInterface: FileIO = FileIO(fileName: "ProcessingResult", fileExtension: "txt")
    var videoParser = VideoParser()
    
    init() {
        let res = self.videoParser.setVideoURL(forResource: "sampleVideo", ofType: "mp4")
        if res {
            let _ = self.videoParser.getAllFrames()
        }
    }
    
    var body: some View {
        ZStack {
            self.testProcessing(imageIndex: imageIndex)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Stepper("ImageIndex: \(imageIndex)", value: $imageIndex, in: 0...(self.videoParser.frames.count))
        }
    }
    
    func testProcessing(imageIndex: Int) -> Image {
        if self.videoParser.frames.count == 0 {
            return Image("image1")
        }
        let res = OpenCVWrapper.processImage(self.videoParser.frames[imageIndex % self.videoParser.frames.count], expectedHomePlateAngle: HOME_PLATE_ANGLES[0], filePath: fileInterface.filePath, processingState: Int32(self.processingState.rawValue))
        
        try! fileInterface.loadDataIntoPlayersByPosition()
        ConsoleCommunication.printResult(withMessage: "frame \(imageIndex) - \(fileInterface.playersByPosition)", source: "TestVideoProcessingView")
        
        return Image(uiImage: res)
    }
}

struct TestVideoProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestVideoProcessingView()
    }
}
