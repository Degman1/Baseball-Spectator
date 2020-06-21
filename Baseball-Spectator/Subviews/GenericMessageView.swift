//
//  GenericMessageView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct GenericMessageView: View {
    @Binding var isViewShowing: Bool    // throw something random in here is not needed
    let message: String
    let widthPercent: CGFloat     // percent of the total height provided by GeometryReader
    let heightPercent: CGFloat    // percent of the total width "                          "
    let closable: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.getViewBackground(geometry: geometry)
                
                Text(self.message)
                
                if self.closable {
                    Button(action: {
                        self.isViewShowing = false
                    }) {
                        Text("  x  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(20)
                    }.offset(x: -geometry.size.width * (self.widthPercent / 2) + 30,
                             y: -geometry.size.height * (self.heightPercent / 2) + 30)
                }
            }
        }
    }
    
    func getViewBackground(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: geometry.size.width * self.widthPercent, height: geometry.size.height * self.heightPercent)
            .foregroundColor(darkGreen)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 5)
            )
            .opacity(0.9)
            .shadow(color: Color.black, radius: 30)
    }
}
/*
struct GenericLargeMessageView_Previews: PreviewProvider {
    static var previews: some View {
        GenericLargeMessageView()
    }
}
*/
