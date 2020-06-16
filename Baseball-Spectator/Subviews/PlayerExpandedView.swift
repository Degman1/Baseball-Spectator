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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.8)
                    .foregroundColor(.green)
                    .border(Color.black)
                
                Text(self.webScraper.playerInfo[self.webScraper.selectedPlayerID!].description)
            }
        }
    }
}
/*
struct PlayerExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerExpandedView(webScraper: WebScraper(baseURL: ""))
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
*/
