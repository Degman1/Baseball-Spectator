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
    let playerRemoteInfo: [Player]
    @Binding var imageID: Int
    @ObservedObject var selectedPlayer: SelectedPlayer
    
    var body: some View {
        ZStack {
            if self.selectedPlayer.positionID != nil && self.playerRemoteInfo.count > 0 {
                Button(action: {
                    self.selectedPlayer.isExpanded = true
                }) {
                    Text(self.playerRemoteInfo[self.selectedPlayer.positionID!].description + " >")
                        .padding(5.0)
                        .background(Color.green)
                        .border(Color.black)
                        .foregroundColor(.black)
                }.offset(calculateOffset())
            } else if self.selectedPlayer.positionID != nil && self.playerRemoteInfo.count == 0 {
                Text(self.selectedPlayer.description)
                    .padding(5.0)
                    .background(Color.green)
                    .border(Color.black)
                    .foregroundColor(.black)
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
        
        //TODO: write the highest point to the result file if the player is above the halfway mark of the image, otherwise return the lowest point. Not for processing, just for closest click and for info bar placement
        
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
