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
            toGray()
            Text("\(OpenCVWrapper.openCVVersionString())")
                .background(Color.white)
        }
    }
    
    func toGray() -> some View {
        let source = UIImage(named: "image1.jpg")!
        let gray = OpenCVWrapper.convert(toGrayscale: source)
        return Image(uiImage: gray)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
