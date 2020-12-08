//
//  FileIO.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 5/29/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class FileIO {
    private var path: URL
    
    init(fileName name: String, fileExtension ext: String) {
        path = FileIO.getDocumentsDirectory().appendingPathComponent(name).appendingPathExtension(ext)
        try! write(data: "")    // to create the file in the documents directory
    }
    
    func setPath(fileName name: String, fileExtension ext: String) {
        path = FileIO.getDocumentsDirectory().appendingPathComponent(name).appendingPathExtension(ext)
        try! write(data: "")    // to create the file in the documents directory
    }
    
    func getPath() -> URL {
        return path
    }
    
    func read() throws -> String {
        return try String(contentsOf: path, encoding: String.Encoding.utf8)
    }
    
    func write(data: String) throws {
        try data.write(to: path, atomically: true, encoding: String.Encoding.utf8)
    }
    
    static func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    enum FileIOError: Error {
        case badPath
    }
}
