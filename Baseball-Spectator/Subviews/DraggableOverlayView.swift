//
//  DraggableOverlayView.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/2/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

struct DraggableOverlayView: View {
    let geometry: GeometryProxy
    let processingResultParser: ProcessingResultParser
    let originalImageDimensions: CGSize
    let viewImageDimensions: CGSize
    @Binding var imageID: Int
    @ObservedObject var processingCoordinator: ProcessingCoordinator
    @ObservedObject var selectedPlayer: SelectedPlayer
    
    init(geometry: GeometryProxy, processingResultParser: ProcessingResultParser, originalImageDimensions: CGSize, imageID: Binding<Int>, processingCoordinator: ProcessingCoordinator, selectedPlayer: SelectedPlayer) {
        self.geometry = geometry
        self.processingResultParser = processingResultParser
        self.originalImageDimensions = originalImageDimensions
        self._imageID = imageID
        self.processingCoordinator = processingCoordinator
        self.selectedPlayer = selectedPlayer
        // only need to set this once since the frame size should not change one the app is running
        self.viewImageDimensions = CGSize(width: self.originalImageDimensions.width / self.originalImageDimensions.height * geometry.size.height,
                                         height: geometry.size.height)
    }
    
    var body: some View {
        Rectangle()
            .foregroundColor(.white)
            .opacity(0.01)
            .frame(width: self.viewImageDimensions.width, height: self.viewImageDimensions.height)
            .gesture(DragGesture(minimumDistance: CGFloat.zero, coordinateSpace: .local)
                .onEnded { value in
                    self.dragOperation(value: value)
                }
            )
    }
    
    func dragOperation(value: DragGesture.Value) {
        if self.processingCoordinator.processingState == .Processing && self.processingResultParser.playersByPosition.count == 0 { return }
        
        // click anywhere to deselect player: (include this snippet)
        if self.selectedPlayer.positionID != nil {
            self.selectedPlayer.unselectPlayer()
            return
        }
                
        if value.location.x < 0 || value.location.y < 0 || value.location.x > self.viewImageDimensions.width || value.location.y > geometry.size.height {
            return
        }
        
        let loc = value.location.scale(from: self.viewImageDimensions, to: self.originalImageDimensions)
        
        // if the use has not yet selected which base is home plate
        if self.processingCoordinator.processingState == .UserSelectHome {
            guard let closestPositionToDrag = loc.getClosestPointFromHere(to: self.processingResultParser.playersByPosition[0]) else {
                return
            }
            
            if let a = try! processingResultParser.getExpectedHomePlateAngle(point: closestPositionToDrag) {
                self.processingCoordinator.expectedHomePlateAngle = a
                self.processingCoordinator.processingState = .Processing
                return
            }
        } else {        // if the app is in the process of processing images
            guard let closestPlayerCoordinateToDrag = loc.getClosestPointFromHere(to: self.processingResultParser.playersByPosition.flatMap{$0}) else {
                return
            }
            
            let viewCoordinate = closestPlayerCoordinateToDrag.scale(from: self.originalImageDimensions, to: self.viewImageDimensions)
            
            // find the player information associated with the chosen baseball position closest to the drag point
            for i in 0..<9 {        // loop through each position
                for position in self.processingResultParser.playersByPosition[i] {  // loop through each player found  of the given position (could be multiple contours assigned to the same position)
                    if position == closestPlayerCoordinateToDrag {
                        self.selectedPlayer.selectPlayer(positionID: i, realCoordinate: closestPlayerCoordinateToDrag, viewCoordinate: viewCoordinate)
                        
                        return
                    }
                }
            }
        }
        
    }
}
