//
//  PlayerInfoBarViewTesting.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerInfoBarViewTesting: View {
    let viewImageDimensions: CGSize
    @Binding var imageID: Int
    @EnvironmentObject var selectedPlayer: SelectedPlayer
    @EnvironmentObject var webScraper: WebScraper
    
    var body: some View {
        ZStack {
            if self.selectedPlayer.positionID != nil && self.webScraper.playerInfo.count > 0 {
                GenericButton(label: self.webScraper.playerInfo[self.selectedPlayer.positionID!].description) {
                    self.selectedPlayer.isExpanded = true
                    self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                }
                    .offset(calculateOffset())
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
        
        // the view starts in the center of the screen, so shift it to be at  (0, 0) of the image and add the player coordinate
        let x0 = -self.viewImageDimensions.width / 2
        let y0 = -self.viewImageDimensions.height / 2
        
        let offset = self.selectedPlayer.viewCoordinate!.y > (self.viewImageDimensions.height / 2) ? CGFloat(-35) : CGFloat(20)
        
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
