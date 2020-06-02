//
//  FileIO.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class FileIO {
    var playersByPosition: [[CGPoint]] = []
    var filePath: String
    
    init() {
        filePath = Bundle.main.path(forResource: "ProcessingResult", ofType: "txt")!
    }
    
    func loadData() throws {
        // This makes it so that if running on the simulator vs. iPhone, differentiate which path to use that points to the processing results
        
        let contents = try! String(contentsOfFile: self.filePath)
                        
        let splitByPosition = contents.split(separator: "\n")
        
        if splitByPosition.count != 9 {              // processing failed
            self.playersByPosition = []
            return
        }
        
        self.playersByPosition = [
            [], [], [], [], [], [], [], [], []
        ]   //has 9 spots for the 9 field positions
        
        for i in 0..<splitByPosition.count {
            if splitByPosition[i] == "-" {continue}
            let splitByPlayer = splitByPosition[i].split(separator: " ")
            for coord in splitByPlayer {
                let splitCoord = coord.split(separator: ",")
                self.playersByPosition[i].append(CGPoint(x: Int(splitCoord[0])!, y: Int(splitCoord[1])!))
            }
        }
    }
  
    static func read(from path: String) throws-> String {
        return try String(contentsOfFile: path, encoding: String.Encoding.utf8)

    }
    
    static func write(_ path: String, data: String) throws {
        try data.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.utf8)
    }
    
    enum FileIOError: Error {
        case badPath
    }
}
