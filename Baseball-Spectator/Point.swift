//
//  Point.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

struct Point: CustomStringConvertible {
    var description: String {
        return "(\(x), \(y))"
    }
    
    let x: Int
    let y: Int
    
    func getDistanceToPoint(pt: Point) -> Double {
        let diff1 = (x - pt.x) * (x - pt.x)
        let diff2 = (y - pt.y) * (y - pt.y)
        return sqrt(Double(diff1 + diff2))
    }
}
