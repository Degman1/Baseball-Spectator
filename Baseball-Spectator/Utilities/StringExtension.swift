//
//  StringExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/8/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

extension String {
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            
            indices.append(i)
            
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                                        break
            }
            
            position = index(after: after)
        }
        return indices
    }
    
    func getSubstring(from startIndex: Int, to endIndicator: String) -> String {
        var offset = 0
        var substring = ""
        var ind = self.index(self.startIndex, offsetBy: startIndex)
        while self[ind] != "<" {
            substring += String(self[ind])
            offset += 1
            ind = self.index(self.startIndex, offsetBy: startIndex + offset)
        }
        
        return substring
    }
}
