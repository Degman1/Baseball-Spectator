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
    var fileInterface: FileIO
    var processingState: ProcessingState = .UserSelectHome
    var videoParser = VideoParser()
    
    init(fileInterface: FileIO) {
        self.fileInterface = fileInterface
        let res = self.videoParser.setVideoURL(forResource: "videoplayback", ofType: "mp4")
        if res {
            self.videoParser.getAllFrames()
        }
    }
    
    var body: some View {
        ZStack {
            self.testProcessing(imageIndex: imageIndex)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Stepper("ImageIndex: \(imageIndex)", value: $imageIndex, in: 0...(self.videoParser.frames.count - 1))
        }
    }
    
    func testProcessing(imageIndex: Int) -> Image {
        if self.videoParser.frames.count == 0 {
            return Image("image1")
        }
        let res = OpenCVWrapper.processImage(self.videoParser.frames[imageIndex], expectedHomePlateAngle: HOME_PLATE_ANGLES[0], filePath: fileInterface.filePath, processingState: Int32(self.processingState.rawValue))
        
        try! fileInterface.loadDataIntoPlayersByPosition()
        for pos in fileInterface.playersByPosition {
            ConsoleCommunication.printResult(withMessage: "\(pos)")
        }
        
        /*if self.videoParser.frames.count - 1 > self.imageIndex {
            self.imageIndex += 1
        }*/
        
        return Image(uiImage: res)
    }
}

struct TestVideoProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestVideoProcessingView(fileInterface: FileIO(fileName: "ProcessingResult", fileExtension: "txt"))
    }
}
