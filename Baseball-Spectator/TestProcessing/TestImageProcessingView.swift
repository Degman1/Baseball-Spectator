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
    let fileInterface: FileIO = FileIO(fileName: "ProcessingResult", fileExtension: "txt")
    @ObservedObject var webScraper: WebScraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/", debug: true)
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    @ObservedObject var selectedPlayer = SelectedPlayer()
    @ObservedObject var interfaceCoordinator = InterfaceCoordinator()
    
    init() {
        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
    }
    
    var disableControls: Bool {
        return self.selectedPlayer.isExpanded || self.processingCoordinator.processingState == .UserSelectHome
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, imageID: self.$imageID, processingCoordinator: self.processingCoordinator, selectedPlayer: self.selectedPlayer)
                    .disabled(self.selectedPlayer.isExpanded || self.interfaceCoordinator.showHomePlateMessageView)
                
                VStack {
                    HStack {
                        Scoreboard()
                        Spacer()
                    }
                    
                    Spacer()
                    
                    self.getStepper()
                    
                    Spacer()
                    
                    HStack {
                        GenericMessageView(isViewShowing: self.$interfaceCoordinator.showHomePlateMessageView, message: "Select Home Plate", closable: false, textAlignment: .leading)
                            .frame(width: geometry.size.width / 3.5, height: 40)
                            .opacity(self.processingCoordinator.processingState == .UserSelectHome && !self.interfaceCoordinator.showHomePlateMessageView ? 1.0: 0.0)
                            
                        Spacer()
                        
                        self.getPicker(geometry: geometry)
                        
                        Spacer()
                        
                        self.getResetHomePlateSelectionButton(geometry: geometry)
                            .opacity(self.processingCoordinator.processingState == .UserSelectHome ? 0.5 : 1.0)
                    }
                }.padding()
                    .disabled(self.disableControls)
                    .blur(radius: self.interfaceCoordinator.showHomePlateMessageView || self.selectedPlayer.isExpanded ? 8 : 0)
                
                // large home plate message view
                if self.processingCoordinator.processingState == .UserSelectHome && self.interfaceCoordinator.showHomePlateMessageView {
                    GenericMessageView(isViewShowing: self.$interfaceCoordinator.showHomePlateMessageView, message: "Please Select the Circle Representing Home Plate", closable: true)
                        .padding(geometry.size.height / 4)
                }
                                
                // player info bar on top of the selected player
                if !self.selectedPlayer.isExpanded {
                    PlayerInfoBarViewTesting(geometry: geometry, imageID: self.$imageID, selectedPlayer: self.selectedPlayer, webScraper: self.webScraper)
                }
                
                // expanded player statistics view
                if self.selectedPlayer.isExpanded {
                    PlayerExpandedView(webScraper: self.webScraper, selectedPlayer: self.selectedPlayer)
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
                .frame(width: geometry.size.width / 4, height: 40)
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
            .background(opaqueWhite)    // so that it can be seen on top of any background
            .cornerRadius(8)
            .frame(width: geometry.size.width / 3)
    }
    
    func getStepper() -> some View {
        Stepper(onIncrement: {
            if self.imageID < 11 {
                self.imageID += 1
            }
            self.processingCoordinator.processingState = .UserSelectHome
            self.selectedPlayer.unselectPlayer()
            self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
            self.interfaceCoordinator.showHomePlateMessageView = true
        }, onDecrement: {
            if self.imageID > 1 {
                self.imageID -= 1
            }
            self.processingCoordinator.processingState = .UserSelectHome
            self.selectedPlayer.unselectPlayer()
            self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
            self.interfaceCoordinator.showHomePlateMessageView = true
        }, label: {
            return Text("ImageID: \(self.imageID)")
        })
    }
    
    func testProcessing(imageID: Int) -> Image {
        let uiimage = UIImage(named: "image\(imageID).jpg")!
        let res = OpenCVWrapper.processImage(uiimage, expectedHomePlateAngle: self.processingCoordinator.expectedHomePlateAngle, filePath: self.fileInterface.filePath, processingState: Int32(self.processingCoordinator.processingState.rawValue))
        try! fileInterface.loadDataIntoPlayersByPosition()
        return Image(uiImage: res)
    }
}

struct TestProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        TestImageProcessingView()
            .previewLayout(.fixed(width: 1792, height: 828))
    }
}
