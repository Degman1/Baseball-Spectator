//
//  TestVideoProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestVideoProcessingView: View {
    @ObservedObject var videoParser = VideoParser()
    @EnvironmentObject var webScraper: WebScraper
    @EnvironmentObject var processingCoordinator: ProcessingCoordinator
    @EnvironmentObject var selectedPlayer: SelectedPlayer
    @EnvironmentObject var interfaceCoordinator: InterfaceCoordinator
    @Environment(\.colorScheme) var colorScheme
    var timer = Timer2()
    
    init() {
        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
        
        let res = self.videoParser.setVideoURL(forResource: "sampleVideo", ofType: "mp4")
        if !res { return }
        videoParser.playFrames()
    }
    
    var disableControls: Bool {
        return self.selectedPlayer.isExpanded || self.processingCoordinator.processingState == .UserSelectHome
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                if self.videoParser.fetchingFramesWasSuccessful() {
                    DraggableOverlayView(geometry: geometry, originalImageDimensions: self.videoParser.getVideoDimensions()!, imageID: self.$videoParser.imageIndex)
                    .disabled(self.selectedPlayer.isExpanded || self.interfaceCoordinator.showHomePlateMessageView)
                }
                
                VStack {
                    HStack {
                        Scoreboard()
                            .disabled(self.disableControls)
                        Spacer()
                        
                        GenericButton(label: "Play") {
                            self.videoParser.playFrames()
                        }
                        GenericButton(label: "Pause") {
                            self.videoParser.pauseFrames()
                        }
                    }
                    
                    Spacer()
                    
                    self.getStepper()
                    
                    Spacer()
                    
                    HStack {
                        GenericMessageView(message: Text(self.processingCoordinator.processingState == .UserSelectHome ? "Select Home Plate" : "Tap Players for Statistics"), textAlignment: .leading)
                            .frame(width: geometry.size.width / 3.5, height: 40)
                            .opacity(!self.interfaceCoordinator.showHomePlateMessageView ? 1.0: 0.0)    // doing this makes sure that it is still there as a placeholder so formatting doesn't change
                            
                        Spacer()
                        
                        self.getPicker(geometry: geometry)
                            .disabled(self.disableControls)
                        
                        Spacer()
                        
                        GenericButton(label: "Reset Home Plate") {
                            self.processingCoordinator.processingState = .UserSelectHome
                            self.selectedPlayer.unselectPlayer()
                        }.opacity(self.processingCoordinator.processingState == .UserSelectHome ? 0.3 : 1.0)
                            .disabled(self.disableControls)
                    }
                }.padding()
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                // large home plate message view
                if self.processingCoordinator.processingState == .UserSelectHome && self.interfaceCoordinator.showHomePlateMessageView {
                    GenericMessageView(message: Text("Please Select the Circle Representing Home Plate"), closableBinding: self.$interfaceCoordinator.showHomePlateMessageView)
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.5)
                }

                // player info bar on top of the selected player
                if !self.selectedPlayer.isExpanded && self.videoParser.getVideoDimensions() != nil {
                    PlayerInfoBarViewTesting(
                        viewImageDimensions: CGSize(width: self.videoParser.getVideoDimensions()!.width / self.videoParser.getVideoDimensions()!.height * geometry.size.height,
                                                    height: geometry.size.height),
                        imageID: self.$videoParser.imageIndex)
                }
                
                // expanded player statistics view
                if self.selectedPlayer.isExpanded {
                    PlayerExpandedView()
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.7)
                }
            }
        }
    }
    
    func getResetHomePlateSelectionButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            self.processingCoordinator.processingState = .UserSelectHome
            self.selectedPlayer.unselectPlayer()
        }) {
            Text("Reset Home plate  >")
                .frame(width: geometry.size.width / 3.8, height: 40)
                .foregroundColor(.black)
                .background(Color.white)
                .cornerRadius(cornerRad)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRad)
                        .stroke(darkGreen, lineWidth: 5)
                )
                .shadow(color: Color.black, radius: 30)
        }
    }
    
    func getPicker(geometry: GeometryProxy) -> some View {
        Picker("Select Team:", selection: self.$interfaceCoordinator.selectedTeam) {
            Text("Offense").tag(ActiveTeam.Offense)
            Text("Defense").tag(ActiveTeam.Defense)
        }.pickerStyle(SegmentedPickerStyle())
            .font(.largeTitle)
            .background(self.colorScheme == .dark ? .gray : opaqueWhite)  // more visible this way
            .cornerRadius(8)
            .frame(width: geometry.size.width / 3)
    }
    
    func getStepper() -> some View {
        Stepper("", value: self.$videoParser.imageIndex, in: 0...(self.videoParser.getFramesCount() - 1))
    }
    
    func testProcessing() -> Image {
        if self.videoParser.getFramesCount() == 0 {
            return Image("image1")
        }
        
        timer.startTimer()
        
        let res = OpenCVWrapper.processImage(self.videoParser.getCurrentFrame(), expectedHomePlateAngle: self.processingCoordinator.expectedHomePlateAngle, filePath: self.processingCoordinator.getPath(), processingState: Int32(self.processingCoordinator.processingState.rawValue))
        
        try! self.processingCoordinator.loadDataIntoPlayersByPosition()
        ConsoleCommunication.printResult(withMessage: "frame \(self.videoParser.imageIndex) - \(self.processingCoordinator.playersByPosition)", source: "\(#function)")
        
        timer.endTimer()
        
        ConsoleCommunication.printResult(withMessage: "processing took \(timer.elapsedTimems())ms", source: "\(#function)")
                
        return Image(uiImage: res)
    }
}

struct TestVideoProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestVideoProcessingView()
    }
}
