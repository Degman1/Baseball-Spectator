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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GenericMessageView(isViewShowing: self.$selectedPlayer.isExpanded, message: self.text, closable: true)
                
                Button(action: {
                    self.selectedPlayer.previousPlayer()
                    self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                }) {
                    HStack {
                        Text("  <  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(cornerRad)
                        Text("Previous")
                            .foregroundColor(self.colorScheme == .dark ? .white : .black)
                    }
                }.offset(x: (-geometry.size.width / 2) + 70, y: (geometry.size.height / 2) - 30)
                
                Button(action: {
                    self.selectedPlayer.nextPlayer()
                    self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                }) {
                    HStack {
                        Text("Next")
                            .foregroundColor(self.colorScheme == .dark ? .white : .black)
                        Text("  >  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(cornerRad)
                    }
                }.offset(x: (geometry.size.width / 2) - 55, y: (geometry.size.height / 2) - 30)
            }
        }
    }
    
    var text: Text {
        if self.selectedPlayer.positionID != nil && !self.webScraper.playerInfo.isEmpty {
            return Text(self.webScraper.playerInfo[self.selectedPlayer.positionID!].detailedDescription)
        } else {
            return Text("Currently unable to retrive player statistics")
        }
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
