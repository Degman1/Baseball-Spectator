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
    @State var processingState: ProcessingState = .UserSelectHome
    @State var expectedHomePlateAngle: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, positionID: self.$positionID, imageID: self.$imageID, clickedPosition: self.$clickedPosition, processingState: self.$processingState, expectedHomePlateAngle: self.$expectedHomePlateAngle)
                VStack {
                    Stepper(onIncrement: {
                        if self.imageID < 11 {
                            self.imageID += 1
                        }
                        self.processingState = .UserSelectHome
                    }, onDecrement: {
                        if self.imageID > 1 {
                            self.imageID -= 1
                        }
                        self.processingState = .UserSelectHome
                    }, label: {
                        return Text("ImageID: \(self.imageID)").background(Color.white)
                        
                    })
                    //Stepper("ImageID: \(self.imageID)", value: self.$imageID, in: 1...11)
                    HStack {
                        Text(self.clickedPosition).background(Color.white)
                        Spacer()
                    }
                    HStack {
                        if self.processingState == .UserSelectHome {
                            Text("Select Home Plate").background(Color.white)
                        } else {
                            Text("All Set!").background(Color.white)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: self.expectedHomePlateAngle, filePath: self.fileInterface.filePath, processingState: Int32(self.processingState.rawValue))
        try! fileInterface.loadDataIntoPlayersByPosition()
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView(fileInterface: FileIO(fileName: "ProcessingResult", fileExtension: "txt"))
    }
}
