//
//  PlayerInfoBarView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/10/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerInfoBarView: View {
    let geometry: GeometryProxy
    @ObservedObject var selectedPlayer: SelectedPlayer
    @ObservedObject var webScraper: WebScraper
    
    var body: some View {
        ZStack {
            if self.selectedPlayer.positionID != nil && self.webScraper.playerInfo.count > 0 {
                Button(action: {
                    self.selectedPlayer.isExpanded = true
                    self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                }) {
                    Text(self.webScraper.playerInfo[self.selectedPlayer.positionID!].description)
                        .padding(6.0)
                        .background(darkGreen)
                        .cornerRadius(cornerRad)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRad)
                                .stroke(Color.white, lineWidth: 5)
                        )
                        .foregroundColor(.black)
                        .opacity(0.8)
                        .shadow(color: Color.black, radius: 30)
                }.offset(calculateOffset())
            } else if self.selectedPlayer.positionID != nil && self.webScraper.playerInfo.count == 0 {
                Text(self.selectedPlayer.description)
                    .padding(6.0)
                    .background(darkGreen)
                    .foregroundColor(.black)
                    .cornerRadius(cornerRad)
                    .offset(calculateOffset())
            }
        }
    }
    
    func calculateOffset() -> CGSize {
        if self.selectedPlayer.viewCoordinate == nil {  // should never get here
            return CGSize(width: 0, height: 0)
        }
        
        let imageWidth = 1080.0       //TODO: Change this for the real thing - hardcode this
        
        // the view starts in the center of the screen, so shift it to be at  (0, 0) of the image and add the player coordinate
        let x0 = -imageWidth / 2
        let y0 = -geometry.size.height / 2
        
        let offset = self.selectedPlayer.viewCoordinate!.y > (self.geometry.size.height / 2) ? CGFloat(-35) : CGFloat(20)
        
        //TODO: write the highest point to the result file if the player is above the halfway mark of the image, otherwise return the lowest point. Not for processing, just for closest click and for info bar placement
        
        return CGSize(width: CGFloat(x0) + self.selectedPlayer.viewCoordinate!.x,
                      height: y0 + self.selectedPlayer.viewCoordinate!.y + offset)
    }
}
/*
struct PlayerInfoBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerInfoBarView(selectedPlayer: SelectedPlayer())
    }
}
*/
