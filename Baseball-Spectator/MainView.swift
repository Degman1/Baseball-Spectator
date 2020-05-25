//
//  MainView.swift
//  Baseball-Spectator
//
//  Created by Joey Cohen on 5/20/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        ZStack {
            NavigationView {
                HStack {
                    VStack {
                        importButton
                            .offset(x: -60, y: -75)
                        
                        Spacer()
                        
                        scoreboard
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 50, trailing: 0))
                    }
                    Spacer()
                }
            }
            
            FrameExtractorViewControllerRepresentable()
        }
    }
    
    var importButton: some View {
        Button(action: {
            print("import")
        }) {
            Image(systemName: "plus.square")
        }
    }
    
    var scoreboard: some View {
        Scoreboard()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
