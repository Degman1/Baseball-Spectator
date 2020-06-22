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
    let closable: Bool
    let textAlignment: Alignment
    
    init(isViewShowing: Binding<Bool>, message: String, closable: Bool, textAlignment: Alignment = .center) {
        self._isViewShowing = isViewShowing
        self.message = message
        self.closable = closable
        self.textAlignment = textAlignment
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.getViewBackground(geometry: geometry)
                
                Text(self.message)
                    .frame(alignment: self.textAlignment)
                
                if self.closable {
                    Button(action: {
                        self.isViewShowing = false
                    }) {
                        Text("  x  ")
                            .padding(5)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .cornerRadius(cornerRad)
                    }.offset(x: (-geometry.size.width / 2) + 30,
                             y: (-geometry.size.height / 2) + 30)
                }
            }
        }
    }
    
    func getViewBackground(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: cornerRad)
            .foregroundColor(darkGreen)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRad)
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
