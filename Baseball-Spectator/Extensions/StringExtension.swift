//
//  StringExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/8/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

extension String {
    // removes all the whitespace occurences of the string
    func removeWhiteSpace() -> String {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "")
    }
    
    func removeNewLines() -> String {
        return self.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .joined(separator: "")
    }
    
    // converts string into JSON style dictionary
    func toJSONStyle() -> [String:AnyObject]? {
        if let data = self.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                return nil
            }
        }
        return nil
    }
    
    // finds all indices of a certain substring inside of the string
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
    
    // Finds the first index of a substring in the string
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    
    func getSubstring(from startIndex: Index, to endIndex: Index) -> String {
        return String(self[startIndex..<endIndex])
    }
    
    func getSubstring(from startIndex: Int, to endIndicator: Character) -> String {
        var offset = 0
        var substring = ""
        var ind = self.index(self.startIndex, offsetBy: startIndex)
        while self[ind] != endIndicator {
            substring += String(self[ind])
            offset += 1
            ind = self.index(self.startIndex, offsetBy: startIndex + offset)
        }
        
        return substring
    }
    
    func getSubstring(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    // this method is not working
    /*func getSubstring(from startIndex: Int, to endIndicator: String) -> String {
        var offset = 0
        var substring = ""
        var ind = self.index(self.startIndex, offsetBy: startIndex)
        var finished = true
        print(self)
        while finished {
            if startIndex + offset == self.count {
                finished = false
                continue
            }
            
            if self[ind] == endIndicator[endIndicator.startIndex] && getSubstring(from: ind, to: index(ind, offsetBy: endIndicator.count)) == endIndicator {
                finished = false
                continue
            }
            
            substring += String(self[ind])
            offset += 1
            ind = self.index(self.startIndex, offsetBy: startIndex + offset)
        }
        
        return substring
    }*/
    
    // Gets the substring range from the start index to the next index in endIndices
    func getSubstringUnknownEndpoint(from startIndex: Int, to endIndices: [Int]) -> String? {
        var endIndex: Int = -1
        
        for index in endIndices {
            if index > startIndex {
                endIndex = index       // the table ends at the </table> that occurs first after the start index
                break
            }
        }
        
        if endIndex == -1 {
            return nil
        }
        
        // must turn the int values into string index values to get the substring
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: endIndex)
        
        return String(self[start...end])
    }
}
