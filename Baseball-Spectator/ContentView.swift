//
//  ContentView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 1/3/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let fileInterface = FileIO()
    
    var body: some View {
        TestImageProcessingView(fileInterface: fileInterface)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
