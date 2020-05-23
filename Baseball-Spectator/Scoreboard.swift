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
    @State private var wFrame: CGFloat = 200
    @State private var hFrame: CGFloat = 100
    
    var body: some View {
            ZStack {
                HStack {
                    VStack {
                        HStack {
                            VStack {
                                Text(awayTeam).font(.largeTitle)
                                Text(homeTeam).font(.largeTitle)
                            }
                            ZStack {
                                VStack {
                                    Text("\(awayTeamScore)").font(.largeTitle)
                                    Text("\(homeTeamScore)").font(.largeTitle)
                                }
                                if isPressed {
                                   VStack {
                                       awayInnings
                                       homeInnings
                                   }.background(Color.green)
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
                                self.wFrame = 350
                                self.hFrame = 125
                            } else {
                                self.wFrame = 200
                                self.hFrame = 100
                            }
                        }) {
                            Divider().rotationEffect(.degrees(180))
                            if isPressed {
                                Image(systemName: "chevron.left")
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                            } else {
                                Image(systemName: "chevron.right")
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
                            }
                        }
                    }
                }.background(Color.green)
            }
            .frame(width: self.wFrame, height: self.hFrame)
            .rotationEffect(.degrees(-90))
    }
    
    var awayInnings: some View {
        HStack {
            VStack {
                Text("1")
                Text("\(awayInningOne)").font(.largeTitle)
            }
            VStack {
                Text("2")
                Text("\(awayInningTwo)").font(.largeTitle)
            }
            VStack {
                Text("3")
                Text("\(awayInningThree)").font(.largeTitle)
            }
            VStack {
                Text("4")
                Text("\(awayInningFour)").font(.largeTitle)
            }
            VStack {
                Text("5")
                Text("\(awayInningFive)").font(.largeTitle)
            }
            VStack {
                Text("6")
                Text("\(awayInningSix)").font(.largeTitle)
            }
            VStack {
                Text("7")
                Text("\(awayInningSeven)").font(.largeTitle)
            }
            VStack {
                Text("8")
                Text("\(awayInningEight)").font(.largeTitle)
            }
            VStack {
                Text("9")
                Text("\(awayInningNine)").font(.largeTitle)
            }
        }
    }
    
    var homeInnings: some View {
        HStack {
            VStack {
                Text("\(homeInningOne)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningTwo)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningThree)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningFour)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningFive)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningSix)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningSeven)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningEight)").font(.largeTitle)
            }
            VStack {
                Text("\(homeInningNine)").font(.largeTitle)
            }
        }
    }
    
    var ballstrikesView: some View {
        Text("\(balls)-\(strikes)").font(.largeTitle)
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
