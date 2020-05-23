//
//  Scoreboard.swift
//  Baseball-Spectator
//
//  Created by Joey Cohen on 5/23/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct Scoreboard: View {
    @State var homeTeam: String = ""
    @State var awayTeam: String = ""
    @State var homeTeamScore: Int = 0
    @State var awayTeamScore: Int = 0
    @State var bases: [Int] = []
    @State var outs: Int = 0
    @State var balls: Int = 0
    @State var strikes: Int = 0
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.green)
            HStack {
                VStack {
                    HStack {
                        Text(awayTeam)
                        Text("\(awayTeamScore)")
                    }
                    HStack {
                        Text(awayTeam)
                        Text("\(awayTeamScore)")
                    }
                }
                VStack {
                    basesView
                    outsView
                    ballstrikesView
                }
            }
        }
    }
    
    var outsView: some View {
        HStack {
            if outs == 0 {
                Image(systemName: "circle")
                Image(systemName: "circle")
                Image(systemName: "circle")
            } else if outs == 1 {
                Image(systemName: "circle.fill")
                Image(systemName: "circle")
                Image(systemName: "circle")
            } else if outs == 2 {
               Image(systemName: "circle.fill")
               Image(systemName: "circle.fill")
               Image(systemName: "circle")
            } else {
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
            }
        }
    }
    
    var basesView: some View {
        Text("bases")
    }
    
    var ballstrikesView: some View {
        Text("\(balls)-\(strikes)")
    }
}

struct Scoreboard_Previews: PreviewProvider {
    static var previews: some View {
        Scoreboard()
    }
}
