//
//  MainView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct MainView: View {
    let processingResultParser = ProcessingResultParser()
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    
    var body: some View {
        ZStack {
            ImageStreamViewControllerRepresentable(processingResultParser: processingResultParser, processingCoordinator: processingCoordinator)
            VStack {
                HStack {
                    Scoreboard(processingCoordinator: self.processingCoordinator)
                        .padding(EdgeInsets(top: 11, leading: 10, bottom: 0, trailing: 0))
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().previewLayout(.fixed(width: 818, height: 414))
    }
}
