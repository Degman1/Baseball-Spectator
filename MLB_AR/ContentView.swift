//
//  ContentView.swift
//  MLB_AR
//
//  Created by Joey Cohen on 1/3/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                self.testProcessing(uiimage: UIImage(named: "image5.jpg")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("\(OpenCVWrapper.openCVVersionString())")
                    .background(Color.white)
            }
        }
    }
    
    func toGray(uiimage: UIImage) -> Image {
        let gray = OpenCVWrapper.convert(toGrayscale: uiimage)
        return Image(uiImage: gray)
    }
    
    func blur(uiimage: UIImage, radius: Double) -> Image {
        let blurred = OpenCVWrapper.blur(uiimage, radius: radius)
        return Image(uiImage: blurred)
    }
    
    func testProcessing(uiimage: UIImage) -> Image {
        let res = OpenCVWrapper.convertRGBtoHSV(uiimage)
        return Image(uiImage: res)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
