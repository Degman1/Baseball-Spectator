//
//  SelectHomePlateMessageView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct HomePlateMessageView: View {
    @Binding var showHomePlateMessageView: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.getViewBackground(geometry: geometry)
                
                Text("Select Which of the Following Circles Represents Home Plate")
                
                HStack {
                    Button(action: {
                        self.selectedPlayer.previousPlayer()
                        self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                    }) {
                        Text("  <  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(geometry.size.height / 15)
                    }
                    
                    Text("Previous")
                }.offset(x: -geometry.size.width * 0.26, y: geometry.size.height * 0.32)
                
                HStack {
                    Text("Next")
                    
                    Button(action: {
                        self.selectedPlayer.nextPlayer()
                        self.webScraper.fetchStatistics(selectedPlayerIndex: self.selectedPlayer.positionID!)
                    }) {
                        Text("  >  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(geometry.size.height / 15)
                    }.labelsHidden()
                }.offset(x: geometry.size.width * 0.275, y: geometry.size.height * 0.32)
                
            }
        }
    }
    
    func getViewBackground(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: geometry.size.height / 15)
            .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.8)
            .foregroundColor(darkGreen)
            .overlay(
                RoundedRectangle(cornerRadius: geometry.size.height / 15)
                    .stroke(Color.white, lineWidth: 5)
            )
            .opacity(0.9)
            .shadow(color: Color.black, radius: geometry.size.height / 20)
    }
}

struct SelectHomePlateMessageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePlateMessageView()
    }
}
