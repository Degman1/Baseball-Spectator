//
//  PlayerInfoBarView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct PlayerInfoBarView: View {
    let geometry: GeometryProxy
    @Binding var imageID: Int
    @ObservedObject var selectedPlayer: SelectedPlayer
    
    var body: some View {
        Text(self.selectedPlayer.description)
            .background(Color.green)
            .offset(calculateOffset())
    }
    
    func calculateOffset() -> CGSize {
        if self.selectedPlayer.coordinate == nil {  // should never get here
            return CGSize(width: self.geometry.size.width / 2, height: self.geometry.size.height / 2)
        }
        
        let imageWidth = TEST_IMAGE_RESOLUTIONS[self.imageID - 1].width / TEST_IMAGE_RESOLUTIONS[self.imageID - 1].height * self.geometry.size.height
        let x0 = (self.geometry.size.width - imageWidth) / 2
        return CGSize(width: x0 + self.selectedPlayer.coordinate!.x, height: self.selectedPlayer.coordinate!.y)
    }
}
/*
struct PlayerInfoBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerInfoBarView(selectedPlayer: SelectedPlayer())
    }
}
*/
