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
    
    var body: some View {
        Rectangle()
            .foregroundColor(.black)
            .opacity(0.3)
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
        if fileInterface.playersByPosition.count == 0 { return }
        let res = TEST_IMAGE_RESOLUTIONS[self.imageID - 1]
        let imageDisplayWidth = (res.width / res.height) * geometry.size.height
        
        if value.location.x < 0 || value.location.y < 0 || value.location.x > imageDisplayWidth || value.location.y > geometry.size.height {
            return
        }
        
        let loc = value.location.scale(from: CGSize(width: imageDisplayWidth, height: geometry.size.height), to: res)
        
        guard let closestPlayerCoordinateToDrag = loc.getClosestPointFromHere(to: fileInterface.playersByPosition.flatMap{$0}) else {
            return
        }
                
        for i in 0..<9 {
            for position in fileInterface.playersByPosition[i] {
                if position == closestPlayerCoordinateToDrag {
                    self.positionID = i
                    
                    switch i {
                    case 0:
                    print("pitcher")
                    case 1:
                    print("catcher")
                    case 2:
                    print("first")
                    case 3:
                    print("second")
                    case 4:
                    print("shortstop")
                    case 5:
                    print("third")
                    case 6:
                    print("leftfield")
                    case 7:
                    print("centerfield")
                    case 8:
                    print("rightfield")
                    default:
                    print("failed...")
                    }
                    
                    print()
                    return
                }
            }
        }
    }
}
