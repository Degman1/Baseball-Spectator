//
//  MainView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        ZStack {
            ImageStreamViewControllerRepresentable()
            VStack {
                HStack {
                    Scoreboard()
                        .padding(EdgeInsets(top: 11, leading: 10, bottom: 0, trailing: 0))
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
/*
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().previewLayout(.fixed(width: 818, height: 414))
    }
}*/
