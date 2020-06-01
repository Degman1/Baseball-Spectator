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
    var fileInterface: FileIO
    
    var body: some View {
        ZStack {
            self.testProcessing(imageID: imageID)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Stepper("ImageID: \(imageID)", value: $imageID, in: 1...12)
        }
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: HOME_PLATE_ANGLES[imageID - 1], filePath: fileInterface.filePath)
        
        try! fileInterface.loadData()
        for pos in fileInterface.playersByPosition {
            print(pos)
        }
        
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView(fileInterface: FileIO())
    }
}
