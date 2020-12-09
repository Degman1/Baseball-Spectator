//
//  TestImageProcessingView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/28/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct TestImageProcessingView: View {
    @State var imageID = 1
    let processingResultParser = ProcessingResultParser()
    @ObservedObject var webScraper: WebScraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/")
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    @ObservedObject var selectedPlayer = SelectedPlayer()
    @ObservedObject var interfaceCoordinator = InterfaceCoordinator()
    @Environment(\.colorScheme) var colorScheme
    
    init() {
        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
    }
    
    var disableControls: Bool {
        return self.selectedPlayer.isExpanded || self.processingCoordinator.processingState == .UserSelectHome
    }
    
    func getImageWidth(geometry: GeometryProxy) -> CGFloat {
        return TEST_IMAGE_RESOLUTIONS[self.imageID - 1].width / TEST_IMAGE_RESOLUTIONS[self.imageID - 1].height * geometry.size.height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                DraggableOverlayView(geometry: geometry, processingResultParser: self.processingResultParser, originalImageDimensions: TEST_IMAGE_RESOLUTIONS[self.imageID - 1], imageID: self.$imageID, processingCoordinator: self.processingCoordinator, selectedPlayer: self.selectedPlayer)
                    .disabled(self.selectedPlayer.isExpanded || self.interfaceCoordinator.showHomePlateMessageView)
                
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
                        .padding(geometry.size.height / 4)
                }
                                
                // player info bar on top of the selected player
                if !self.selectedPlayer.isExpanded {
                    PlayerInfoBarViewTesting(
                        viewImageDimensions: CGSize(width: TEST_IMAGE_RESOLUTIONS[self.imageID - 1].width /                                                 TEST_IMAGE_RESOLUTIONS[self.imageID - 1].height *
                                                                geometry.size.height,
                                                    height: geometry.size.height), imageID: self.$imageID,
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
        Stepper(onIncrement: {
            if self.imageID < 11 {
                self.imageID += 1
            }
            //self.processingCoordinator.processingState = .UserSelectHome
            self.selectedPlayer.unselectPlayer()
            //self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
            //self.interfaceCoordinator.showHomePlateMessageView = true
        }, onDecrement: {
            if self.imageID > 1 {
                self.imageID -= 1
            }
            //self.processingCoordinator.processingState = .UserSelectHome
            self.selectedPlayer.unselectPlayer()
            //self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
            //self.interfaceCoordinator.showHomePlateMessageView = true
        }, label: {
            return Text("ImageID: \(self.imageID)")
        })
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: self.processingCoordinator.expectedHomePlateAngle, filePath: self.processingResultParser.getPath(), processingState: Int32(self.processingCoordinator.processingState.rawValue))
        try! processingResultParser.loadDataIntoPlayersByPosition()
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView()
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
