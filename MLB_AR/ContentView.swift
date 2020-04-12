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
        ZStack{
            blur(uiimage: UIImage(named: "image1.jpg")!, radius: 10.0)
            Text("\(OpenCVWrapper.openCVVersionString())")
                .background(Color.white)
        }
    }
    
    func toGray(uiimage: UIImage) -> some View {
        let gray = OpenCVWrapper.convert(toGrayscale: uiimage)
        return Image(uiImage: gray)
    }
    
    func blur(uiimage: UIImage, radius: Double) -> some View {
        let blurred = OpenCVWrapper.blur(uiimage, radius: radius)
        return Image(uiImage: blurred)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
