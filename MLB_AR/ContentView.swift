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
