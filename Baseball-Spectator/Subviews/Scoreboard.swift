//
//  Scoreboard.swift
//  Baseball-Spectator
//
//  Created by Joey Cohen on 5/23/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

import SwiftUI

struct Scoreboard: View {
    @State var homeTeam: String = "BOS"
    @State var awayTeam: String = "STL"
    @State var homeTeamScore: Int = 0
    @State var awayTeamScore: Int = 0
    @State var outs: Int = 0
    @State var balls: Int = 0
    @State var strikes: Int = 0
    
    @State var homeInningOne = 0
    @State var homeInningTwo = 0
    @State var homeInningThree = 0
    @State var homeInningFour = 0
    @State var homeInningFive = 0
    @State var homeInningSix = 0
    @State var homeInningSeven = 0
    @State var homeInningEight = 0
    @State var homeInningNine = 0
    
    @State var awayInningOne = 0
    @State var awayInningTwo = 0
    @State var awayInningThree = 0
    @State var awayInningFour = 0
    @State var awayInningFive = 0
    @State var awayInningSix = 0
    @State var awayInningSeven = 0
    @State var awayInningEight = 0
    @State var awayInningNine = 0
    
    @State private var isPressed = false
    @State private var wFrame: CGFloat = 160
    @State private var hFrame: CGFloat = 90
    
    var body: some View {
            ZStack {
                HStack {
                    VStack {
                        HStack {
                            VStack {
                                Text(awayTeam)
                                Text(homeTeam)
                            }
                            ZStack {
                                VStack {
                                    Text("\(awayTeamScore)")
                                    Text("\(homeTeamScore)")
                                }
                                if isPressed {
                                   VStack {
                                       awayInnings
                                       homeInnings
                                   }.background(darkGreen)
                                }
                            }
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        .offset(y: 15)
                        Divider()
                        HStack {
                            Spacer()
                            ballstrikesView
                            Spacer()
                            outsView
                            Spacer()
                        }
                        .offset(y: -10)
                    }
                    HStack {
                        Button(action: {
                            self.isPressed.toggle()
                            if self.isPressed {
                                self.wFrame = 250
                                self.hFrame = 90
                            } else {
                                self.wFrame = 160
                                self.hFrame = 90
                            }
                        }) {
                            Divider().rotationEffect(.degrees(180))
                            if isPressed {
                                Image(systemName: "chevron.left")
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "chevron.right")
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }.background(darkGreen.opacity(0.8))
            }
            .frame(width: self.wFrame, height: self.hFrame)
            .cornerRadius(cornerRad)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRad)
                    .stroke(Color.white, lineWidth: 5)
            )
            .shadow(color: Color.black, radius: 30)
    }
    
    var awayInnings: some View {
        HStack {
            VStack {
                Text("1")
                Text("\(awayInningOne)")
            }
            VStack {
                Text("2")
                Text("\(awayInningTwo)")
            }
            VStack {
                Text("3")
                Text("\(awayInningThree)")
            }
            VStack {
                Text("4")
                Text("\(awayInningFour)")
            }
            VStack {
                Text("5")
                Text("\(awayInningFive)")
            }
            VStack {
                Text("6")
                Text("\(awayInningSix)")
            }
            VStack {
                Text("7")
                Text("\(awayInningSeven)")
            }
            VStack {
                Text("8")
                Text("\(awayInningEight)")
            }
            VStack {
                Text("9")
                Text("\(awayInningNine)")
            }
        }
    }
    
    var homeInnings: some View {
        HStack {
            VStack {
                Text("\(homeInningOne)")
            }
            VStack {
                Text("\(homeInningTwo)")
            }
            VStack {
                Text("\(homeInningThree)")
            }
            VStack {
                Text("\(homeInningFour)")
            }
            VStack {
                Text("\(homeInningFive)")
            }
            VStack {
                Text("\(homeInningSix)")
            }
            VStack {
                Text("\(homeInningSeven)")
            }
            VStack {
                Text("\(homeInningEight)")
            }
            VStack {
                Text("\(homeInningNine)")
            }
        }
    }
    
    var ballstrikesView: some View {
        Text("\(balls)-\(strikes)")
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
    
    var expandedBallView: some View {
        HStack {
            if balls == 0 {
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
            } else if balls == 4 {
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
            }
        }
    }
    
    var expandedStrikeView: some View {
        HStack {
            if balls == 0 {
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
            } else if balls == 4 {
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
                Image(systemName: "circle.fill")
            }
        }
    }
}

struct Scoreboard_Previews: PreviewProvider {
    static var previews: some View {
        Scoreboard()
    }
}
