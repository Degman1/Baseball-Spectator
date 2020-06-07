//
//  TestImageProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestImageProcessingView: View {
    var fileInterface: FileIO
    @State var imageID = 1
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    @ObservedObject var selectedPlayer = SelectedPlayer()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, imageID: self.$imageID, processingCoordinator: self.processingCoordinator, selectedPlayer: self.selectedPlayer)
                
                VStack {
                    Stepper(onIncrement: {
                        if self.imageID < 11 {
                            self.imageID += 1
                        }
                        self.processingCoordinator.processingState = .UserSelectHome
                    }, onDecrement: {
                        if self.imageID > 1 {
                            self.imageID -= 1
                        }
                        self.processingCoordinator.processingState = .UserSelectHome
                    }, label: {
                        return Text("ImageID: \(self.imageID)").background(Color.white)
                        
                    })
                    //Stepper("ImageID: \(self.imageID)", value: self.$imageID, in: 1...11)
                    HStack {
                        if self.processingCoordinator.processingState == .UserSelectHome {
                            Text("Select Home Plate").background(Color.white)
                        } else {
                            Text("All Set!").background(Color.white)
                        }
                        Spacer()
                    }
                }
                
                if self.selectedPlayer.coordinate != nil {
                    PlayerInfoBarView(geometry: geometry, imageID: self.$imageID, selectedPlayer: self.selectedPlayer)
                }
            }
        }
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: self.processingCoordinator.expectedHomePlateAngle, filePath: self.fileInterface.filePath, processingState: Int32(self.processingCoordinator.processingState.rawValue))
        try! fileInterface.loadDataIntoPlayersByPosition()
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView(fileInterface: FileIO(fileName: "ProcessingResult", fileExtension: "txt"))
            .previewLayout(.fixed(width: 568, height: 320))
    }
}
