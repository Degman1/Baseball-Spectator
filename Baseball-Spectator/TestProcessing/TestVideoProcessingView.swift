//
//  TestVideoProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/1/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestVideoProcessingView: View {
    let fileInterface: FileIO = FileIO(fileName: "ProcessingResult", fileExtension: "txt")
    @ObservedObject var videoParser = VideoParser()
    @ObservedObject var webScraper: WebScraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/", debug: true)
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    @ObservedObject var selectedPlayer = SelectedPlayer()
    @ObservedObject var interfaceCoordinator = InterfaceCoordinator()
    @Environment(\.colorScheme) var colorScheme
    var originalImageDimensions: CGSize? = nil
    
    init() {
        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
        
        let res = self.videoParser.setVideoURL(forResource: "sampleVideo", ofType: "mp4")
        if !res {
            return
        }
        let _ = self.videoParser.getAllFrames()
        
        self.originalImageDimensions = CGSize(width: self.videoParser.frames[0].size.width, height: self.videoParser.frames[0].size.height)
        //videoParser.playFrames()
    }
    
    var disableControls: Bool {
        return self.selectedPlayer.isExpanded || self.processingCoordinator.processingState == .UserSelectHome
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageIndex: self.videoParser.imageIndex)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                if self.originalImageDimensions != nil {
                    DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, originalImageDimensions: self.originalImageDimensions!, imageID: self.$videoParser.imageIndex, processingCoordinator: self.processingCoordinator, selectedPlayer: self.selectedPlayer)
                    .disabled(self.selectedPlayer.isExpanded || self.interfaceCoordinator.showHomePlateMessageView)
                }
                
                VStack {
                    HStack {
                        Scoreboard(processingCoordinator: self.processingCoordinator)
                            .disabled(self.disableControls)
                        Spacer()
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
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.8)
                }

                // player info bar on top of the selected player
                if !self.selectedPlayer.isExpanded && self.originalImageDimensions != nil {
                    PlayerInfoBarViewTesting(
                        viewImageDimensions: CGSize(width: self.originalImageDimensions!.width /                                                            self.originalImageDimensions!.height *
                                                                geometry.size.height,
                                                    height: geometry.size.height),
                        imageID: self.$videoParser.imageIndex,
                        selectedPlayer: self.selectedPlayer,
                        webScraper: self.webScraper)
                }
                
                // expanded player statistics view
                if self.selectedPlayer.isExpanded {
                    PlayerExpandedView(webScraper: self.webScraper, selectedPlayer: self.selectedPlayer)
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
        Stepper("", value: self.$videoParser.imageIndex, in: 0...(self.videoParser.frames.count - 1))
    }
    
    func testProcessing(imageIndex: Int) -> Image {
        if self.videoParser.frames.count == 0 {
            return Image("image1")
        }
        let res = OpenCVWrapper.processImage(self.videoParser.frames[imageIndex % self.videoParser.frames.count], expectedHomePlateAngle: self.processingCoordinator.expectedHomePlateAngle, filePath: fileInterface.filePath, processingState: Int32(self.processingCoordinator.processingState.rawValue))
        
        try! fileInterface.loadDataIntoPlayersByPosition()
        ConsoleCommunication.printResult(withMessage: "frame \(imageIndex) - \(fileInterface.playersByPosition)", source: "\(#function)")
        
        return Image(uiImage: res)
    }
}

struct TestVideoProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestVideoProcessingView()
    }
}
