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
    let fileInterface: FileIO
    @Binding var imageID: Int
    @ObservedObject var processingCoordinator: ProcessingCoordinator
    @ObservedObject var selectedPlayer: SelectedPlayer
    
    var body: some View {
        Rectangle()
            .foregroundColor(.white)
            .opacity(0.1)
            .frame(
                width: TEST_IMAGE_RESOLUTIONS[self.imageID - 1].width / TEST_IMAGE_RESOLUTIONS[self.imageID - 1].height * geometry.size.height,
                height: self.geometry.size.height)
            .gesture(DragGesture(minimumDistance: CGFloat.zero, coordinateSpace: .local)
                .onChanged { value in
                    self.dragOperation(value: value)
                }
            )
    }
    
    func dragOperation(value: DragGesture.Value) {
        if self.processingCoordinator.processingState == .Processing && self.fileInterface.playersByPosition.count == 0 { return }
        
        let res = TEST_IMAGE_RESOLUTIONS[self.imageID - 1]
        let imageDisplayWidth = (res.width / res.height) * geometry.size.height
        
        if value.location.x < 0 || value.location.y < 0 || value.location.x > imageDisplayWidth || value.location.y > geometry.size.height {
            return
        }
        
        let loc = value.location.scale(from: CGSize(width: imageDisplayWidth, height: geometry.size.height), to: res)
        
        // if the use has not yet selected which base is home plate
        if self.processingCoordinator.processingState == .UserSelectHome {
            guard let closestPositionToDrag = loc.getClosestPointFromHere(to: self.fileInterface.playersByPosition[0]) else {
                return
            }
            
            if let a = try! fileInterface.getExpectedHomePlateAngle(point: closestPositionToDrag) {
                self.processingCoordinator.expectedHomePlateAngle = a
                self.processingCoordinator.processingState = .Processing
                return
            }
        } else {        // if the app is  in the process of processing images
            guard let closestPlayerCoordinateToDrag = loc.getClosestPointFromHere(to: self.fileInterface.playersByPosition.flatMap{$0}) else {
                return
            }
            
            for i in 0..<9 {
                for position in self.fileInterface.playersByPosition[i] {
                    if position == closestPlayerCoordinateToDrag {
                        self.selectedPlayer.positionID = i
                        self.selectedPlayer.coordinate = position
                        
                        return
                    }
                }
            }
        }
        
    }
}
