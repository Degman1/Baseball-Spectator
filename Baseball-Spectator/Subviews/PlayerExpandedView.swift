//
//  PlayerExpandedView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/10/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerExpandedView: View {
    @EnvironmentObject var webScraper: WebScraper
    @EnvironmentObject var selectedPlayer: SelectedPlayer
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if self.selectedPlayer.positionID != nil && !self.webScraper.playerInfo.isEmpty && self.webScraper.playerInfo[self.selectedPlayer.positionID!].avg != nil {
                    GenericMessageView(message:
                        HStack {
                            VStack {
                                Image.load(url: URL(string: "https://images.cdn2.stockunlimited.net/preview1300/silhouette-of-a-baseball-player_1501256.jpg")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: geometry.size.height / 2.5)
                                //URL(string: self.webScraper.playerInfo[self.selectedPlayer.positionID!].imageLink!)
                                Text(self.webScraper.playerInfo[self.selectedPlayer.positionID!].name)
                            }.padding(10)
                            VStack {
                            Text("AVG: " + "\(self.webScraper.playerInfo[self.selectedPlayer.positionID!].avg!)").padding(5)
                            Text("RBI: " + "\(self.webScraper.playerInfo[self.selectedPlayer.positionID!].rbi!)").padding(5)
                            Text("OBP: " + "\(self.webScraper.playerInfo[self.selectedPlayer.positionID!].obp!)").padding(5)
                            Text("SLG: " + "\(self.webScraper.playerInfo[self.selectedPlayer.positionID!].slg!)").padding(5)
                            }
                        }, closableBinding: self.$selectedPlayer.isExpanded) {
                            self.selectedPlayer.unselectPlayer()
                    }
                } else if ConsoleCommunication.encounteredError() {
                    GenericMessageView(message: Text("ERROR: Please see console for details"),
                                       closableBinding: self.$selectedPlayer.isExpanded) {
                            self.selectedPlayer.unselectPlayer()
                    }
                } else {
                    GenericMessageView(message: Text("Loading Statistics..."),
                                       closableBinding: self.$selectedPlayer.isExpanded) {
                            self.selectedPlayer.unselectPlayer()
                    }
                }
                
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
}
/*
struct PlayerExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        let player = SelectedPlayer()
        player.positionID = 5
        let scraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/")
        return PlayerExpandedView(webScraper: scraper, selectedPlayer: player)
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
*/
