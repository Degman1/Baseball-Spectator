//
//  TestImageProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestImageProcessingView: View {
    @State var imageID = 1
    @State var positionID = -1  // represents no selection
    var fileInterface: FileIO
    @State var clickedPosition: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, positionID: self.$positionID, imageID: self.$imageID, clickedPosition: self.$clickedPosition)
                VStack {
                    Stepper("ImageID: \(self.imageID)", value: self.$imageID, in: 1...11)
                    HStack {
                        Text(self.clickedPosition).background(Color.white)
                        Spacer()
                    }
                }
            }
        }
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: HOME_PLATE_ANGLES[imageID - 1], filePath: fileInterface.filePath)
        try! fileInterface.loadData()
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView(fileInterface: FileIO(fileName: "ProcessingResult", fileExtension: "txt"))
    }
}
