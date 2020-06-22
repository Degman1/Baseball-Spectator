//
//  GenericButton.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/22/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct GenericButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.label)
                Image(systemName: "chevron.right")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 3))
            }.padding(8.0)
                .background(Color.white)
                .cornerRadius(cornerRad)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRad)
                        .stroke(darkGreen, lineWidth: 5)
                )
                .foregroundColor(.black)
                .opacity(0.9)
                .shadow(color: Color.black, radius: 30)
        }
    }
}

struct GenericButton_Previews: PreviewProvider {
    static var previews: some View {
        GenericButton(label: "Testing Mode", action: {print("Testing Mode")})
    }
}
