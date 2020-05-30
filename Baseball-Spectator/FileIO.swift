//
//  FileIO.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class FileIO {
    var playersByPosition: [[Point]] = []
    var content: String = ""
    
    func loadData() throws {
        // This makes it so that if running on the simulator vs. iPhone, differentiate which path to use that points to the processing results
        #if targetEnvironment(simulator)
        
        let contents = try FileIO.read(from: "/Users/David/git/Baseball-Spectator/Baseball-Spectator/OpenCVWrapper/ProcessingResult.txt")
        
        #else
        
        let path = Bundle.main.path(forResource: "ProcessingResult", ofType: "txt")
        let contents = try! String(contentsOfFile: path!)
        
        #endif
        
        self.content = contents
        
        let splitByPosition = contents.split(separator: "\n")
        
        if contents.count != 9 {              // processing failed
            self.playersByPosition = []
            return
        }
        
        self.playersByPosition = [
            [], [], [], [], [], [], [], [], []
        ]   //has 9 spots for the 9 field positions
        
        for i in 0..<splitByPosition.count {
            let splitByPlayer = splitByPosition[i].split(separator: " ")
            for coord in splitByPlayer {
                let splitCoord = coord.split(separator: ",")
                self.playersByPosition[i].append(Point(x: Int(splitCoord[0])!, y: Int(splitCoord[1])!))
            }
        }
    }
  
    static func read(from path: String) throws-> String {
        return try String(contentsOfFile: path, encoding: String.Encoding.utf8)

    }
    
    static func write(_ path: String, data: String) throws {
        //let url = NSURL.fileURL(withPathComponents: path.split(separator:"/").map(String.init))!
        try data.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.utf8)
    }
    
    enum FileIOError: Error {
        case badPath
    }
}
