//
//  MainView.swift
//  Baseball-Spectator
//
//  Created by Joey Cohen on 5/20/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct MainView: View {
    let fileInterface = FileIO(fileName: "ProcessingResult", fileExtension: "txt")
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    
    var body: some View {
        ZStack {
            ImageStreamViewControllerRepresentable(fileInterface: fileInterface, processingCoordinator: processingCoordinator)
            VStack {
                HStack {
                    Scoreboard()
                        .padding(EdgeInsets(top: 11, leading: 10, bottom: 0, trailing: 0))
                    
                    Spacer()

                    importButton
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                        .offset(y: -68)
                }
                Spacer()
            }
        }
    }
    
    var importButton: some View {
        Button(action: {
            print("import")
        }) {
            Image(systemName: "plus.square")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().previewLayout(.fixed(width: 818, height: 414))
    }
}
