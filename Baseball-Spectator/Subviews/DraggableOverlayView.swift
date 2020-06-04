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
    @Binding var positionID: Int
    @Binding var imageID: Int
    @Binding var clickedPosition: String;
    @Binding var processingState: ProcessingState
    @Binding var expectedHomePlateAngle: Double
    
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
        if processingState == .Processing && fileInterface.playersByPosition.count == 0 { return }
        
        let res = TEST_IMAGE_RESOLUTIONS[self.imageID - 1]
        let imageDisplayWidth = (res.width / res.height) * geometry.size.height
        
        if value.location.x < 0 || value.location.y < 0 || value.location.x > imageDisplayWidth || value.location.y > geometry.size.height {
            return
        }
        
        let loc = value.location.scale(from: CGSize(width: imageDisplayWidth, height: geometry.size.height), to: res)
                
        if processingState == .UserSelectHome {
            guard let closestPositionToDrag = loc.getClosestPointFromHere(to: fileInterface.playersByPosition[0]) else {
                return
            }
            
            if let a = try! fileInterface.getExpectedHomePlateAngle(point: closestPositionToDrag) {
                self.expectedHomePlateAngle = a
                self.processingState = .Processing
                return
            }
        } else {
            guard let closestPlayerCoordinateToDrag = loc.getClosestPointFromHere(to: fileInterface.playersByPosition.flatMap{$0}) else {
                return
            }
            
            for i in 0..<9 {
                for position in fileInterface.playersByPosition[i] {
                    if position == closestPlayerCoordinateToDrag {
                        self.positionID = i
                        
                        switch i {
                        case 0:
                            self.clickedPosition = "pitcher"
                        case 1:
                            self.clickedPosition = "catcher"
                        case 2:
                            self.clickedPosition = "first"
                        case 3:
                            self.clickedPosition = "second"
                        case 4:
                            self.clickedPosition = "shortstop"
                        case 5:
                            self.clickedPosition = "third"
                        case 6:
                            self.clickedPosition = "leftfield"
                        case 7:
                            self.clickedPosition = "centerfield"
                        case 8:
                            self.clickedPosition = "rightfield"
                        default:
                            self.clickedPosition = "failed"
                        }
                        
                        return
                    }
                }
            }
        }
        
    }
}
