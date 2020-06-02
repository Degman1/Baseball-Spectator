//
//  CGPointExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import SwiftUI

extension CGPoint {
    func getDistanceToPoint(_ point: CGPoint) -> Double {
        let diff1 = (x - point.x) * (x - point.x)
        let diff2 = (y - point.y) * (y - point.y)
        return sqrt(Double(diff1 + diff2))
    }
    
    func getClosestPointFromHere(to arrayOfPoints: [CGPoint]) -> CGPoint? {
        if arrayOfPoints.count == 0 { return nil }
        
        var closestPoint: CGPoint = CGPoint()
        var closestDistance = -1.0
        
        for point in arrayOfPoints {
            let dist = getDistanceToPoint(point);
            if closestDistance == -1 || dist < closestDistance {
                closestPoint = point;
                closestDistance = dist;
            }
        }
        
        return closestPoint
    }
    
    func scale(from initialBounds: CGSize, to newBounds: CGSize) -> CGPoint {
        return CGPoint(x: (x / initialBounds.width) * newBounds.width,
                       y: (y / initialBounds.height) * newBounds.height)
    }
}
