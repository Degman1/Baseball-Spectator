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
    @State var selectedTeam: ActiveTeam = .Defense
    let fileInterface: FileIO = FileIO(fileName: "ProcessingResult", fileExtension: "txt")
    @ObservedObject var webScraper: WebScraper = WebScraper(baseURL: "https://www.lineups.com/mlb/lineups/", debug: true)
    @ObservedObject var processingCoordinator = ProcessingCoordinator()
    @ObservedObject var selectedPlayer = SelectedPlayer()
    
    init() {
        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.testProcessing(imageID: self.imageID)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                DraggableOverlayView(geometry: geometry, fileInterface: self.fileInterface, imageID: self.$imageID, processingCoordinator: self.processingCoordinator, selectedPlayer: self.selectedPlayer)
                    .disabled(self.selectedPlayer.isExpanded)
                
                VStack {
                    Spacer()
                    
                    Stepper(onIncrement: {
                        if self.imageID < 11 {
                            self.imageID += 1
                        }
                        self.processingCoordinator.processingState = .UserSelectHome
                        self.selectedPlayer.unselectPlayer()
                        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
                    }, onDecrement: {
                        if self.imageID > 1 {
                            self.imageID -= 1
                        }
                        self.processingCoordinator.processingState = .UserSelectHome
                        self.selectedPlayer.unselectPlayer()
                        self.webScraper.fetchLineupInformation(teamLookupName: BOSTON_RED_SOX.lookupName)
                    }, label: {
                        return Text("ImageID: \(self.imageID)").background(Color.white)
                    })
                    
                    HStack {
                        if self.processingCoordinator.processingState == .UserSelectHome {
                            Text("Select Home Plate").background(Color.white)
                        } else {
                            Text("All Set!").background(Color.white)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                                                
                        Picker("Select Team:", selection: self.$selectedTeam) {
                            Text("Offense").tag(ActiveTeam.Offense)
                            Text("Defense").tag(ActiveTeam.Defense)
                        }.pickerStyle(SegmentedPickerStyle())
                            .font(.largeTitle)
                            .background(opaqueWhite)    // so that it can be seen on top of any background
                            .cornerRadius(8)
                            .padding()
                            .frame(width: geometry.size.width / 3)
                                                
                        Spacer()
                    }
                }.disabled(self.selectedPlayer.isExpanded)
                
                if !self.selectedPlayer.isExpanded {
                    PlayerInfoBarViewTesting(geometry: geometry, imageID: self.$imageID, selectedPlayer: self.selectedPlayer, webScraper: self.webScraper)
                }
            
                if self.selectedPlayer.isExpanded {
                    PlayerExpandedView(webScraper: self.webScraper, selectedPlayer: self.selectedPlayer)
                }
            }
        }
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
