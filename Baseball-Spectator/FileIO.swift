//
//  FileIO.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

enum FileIO {
  
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
