//
//  GenericMessageView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/20/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct GenericMessageView: View {
    var isViewShowing: Binding<Bool>?   // do this instead of @Binding in order to be able to make the variable an optional
    let message: Text
    let textAlignment: Alignment
    
    // use this initializer for a closable message view
    init(message: Text, textAlignment: Alignment = .center, closableBinding: Binding<Bool>?) {
        self.isViewShowing = closableBinding
        self.message = message
        self.textAlignment = textAlignment
    }
    
    // use this initializer for an unclosable message view
    init(message: Text, textAlignment: Alignment = .center) {
        self.isViewShowing = nil
        self.message = message
        self.textAlignment = textAlignment
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.getViewBackground(geometry: geometry)
                
                HStack {
                    if self.textAlignment == .trailing {
                        Spacer()
                    }
                    
                    self.message
                        .frame(alignment: self.textAlignment)
                        .padding(.leading)
                    
                    if self.textAlignment == .leading {
                        Spacer()
                    }
                }
                
                if self.isViewShowing != nil {
                    Button(action: {
                        self.isViewShowing!.wrappedValue = false
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
