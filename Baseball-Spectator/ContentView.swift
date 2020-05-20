//
//  ContentView.swift
//  Baseball-Spectator
//
//  Created by Joey Cohen on 1/3/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var imageID = 1
    
    var body: some View {
        //Text("\(OpenCVWrapper.openCVVersionString()) Hello")
        //ImageViewViewController()

        ZStack {
            self.testProcessing(uiimage: UIImage(named: "image\(imageID).jpg")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
            //Text("\(OpenCVWrapper.openCVVersionString())")
            //    .background(Color.white)
            Stepper("ImageID: \(imageID)", value: $imageID, in: 1...11)
        }
    }
    
    func testProcessing(uiimage: UIImage) -> Image {
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: 176.74)
        return Image(uiImage: res)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
