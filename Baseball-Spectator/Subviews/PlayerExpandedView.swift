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
                self.getViewBackground(geometry: geometry)
                
                if self.selectedPlayer.positionID != nil && !self.webScraper.playerInfo.isEmpty {
                    Text(self.webScraper.playerInfo[self.selectedPlayer.positionID!].description)
                }
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
                    .frame(width: geometry.size.width * 0.7 - (geometry.size.height * 0.02),
                           height: geometry.size.height * 0.8 - (geometry.size.height * 0.02))
                    .foregroundColor(lightGreen)
                    /*.background(
                        RadialGradient(gradient: Gradient(colors: [darkGreen, .white]), center: .center, startRadius: 200, endRadius: geometry.size.height * 0.4)
                    )*/
                    .cornerRadius(geometry.size.height / 15)
            )
            
            .shadow(radius: geometry.size.height / 20)
            .opacity(0.7)
            
    }
}

struct PlayerExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        let player = SelectedPlayer()
        player.positionID = 5
        let scraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/")
        return PlayerExpandedView(webScraper: scraper, selectedPlayer: player)
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
