//
//  PlayerExpandedView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/10/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerExpandedView: View {
    @ObservedObject var webScraper: WebScraper
    @ObservedObject var selectedPlayer: SelectedPlayer
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text("Hello").font(.title)
                self.getViewBackground(geometry: geometry)
                
                //Text(self.webScraper.playerInfo[self.selectedPlayer.positionID!].description)   // force unwrap since this view should only be created if a player is selected
            }
        }
    }
    
    func getViewBackground(geometry: GeometryProxy) -> some View {
        Rectangle()
            .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.8)
            .foregroundColor(.white)
            .cornerRadius(geometry.size.height / 15)
            .overlay(
                Rectangle()
                    //.stroke(Color.white, lineWidth: 70)
                    .frame(width: geometry.size.width * 0.7 - (geometry.size.height * 0.02),
                           height: geometry.size.height * 0.8 - (geometry.size.height * 0.02))
                    .cornerRadius(geometry.size.height / 15)
                    .foregroundColor(darkGreen)
                    .opacity(0.7)
            )
            .shadow(radius: geometry.size.height / 20)
            
    }
}

struct PlayerExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        let player = SelectedPlayer()
        player.positionID = 5
        return PlayerExpandedView(webScraper: WebScraper(baseURL: ""), selectedPlayer: player)
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
