//
//  ContentView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 1/3/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var imageID = 1
    
    var body: some View {
        //Text("\(OpenCVWrapper.openCVVersionString()) Hello")
        //ImageViewViewController()
//        VStack {
//            MainView()
//        }
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
        return Image(uiImage: res)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
