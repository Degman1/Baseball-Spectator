//
//  TestProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestProcessingView: View {
    @State var imageID = 1
    var fileInterface: FileIO
    
    var body: some View {
        ZStack {
            self.testProcessing(imageID: imageID)
                .resizable()
                .aspectRatio(contentMode: .fit)
            //Text("\(OpenCVWrapper.openCVVersionString())")
            //    .background(Color.white)
            Stepper("ImageID: \(imageID)", value: $imageID, in: 1...11)
        }
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: HOME_PLATE_ANGLES[imageID - 1])
        
        try! fileInterface.loadData()
        print(fileInterface.content)
        print(fileInterface.playersByPosition)
        
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestProcessingView(fileInterface: FileIO())
    }
}
