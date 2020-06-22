//
//  PlayerInfoBarViewTesting.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerInfoBarViewTesting: View {
    let geometry: GeometryProxy
    @Binding var imageID: Int
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
        
        let imageWidth = TEST_IMAGE_RESOLUTIONS[self.imageID - 1].width / TEST_IMAGE_RESOLUTIONS[self.imageID - 1].height * self.geometry.size.height
        
        // the view starts in the center of the screen, so shift it to be at  (0, 0) of the image and add the player coordinate
        let x0 = -imageWidth / 2
        let y0 = -geometry.size.height / 2
        
        let offset = self.selectedPlayer.viewCoordinate!.y > (self.geometry.size.height / 2) ? CGFloat(-35) : CGFloat(20)
        
        return CGSize(width: x0 + self.selectedPlayer.viewCoordinate!.x,
                      height: y0 + self.selectedPlayer.viewCoordinate!.y + offset)
    }
}
/*
struct PlayerInfoBarViewTesting_Previews: PreviewProvider {
    static var previews: some View {
        PlayerInfoBarView(selectedPlayer: SelectedPlayer())
    }
}
*/