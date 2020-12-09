//
//  ProcessingCoordinator.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class ProcessingCoordinator: FileIO, ObservableObject {
    @Published var processingState: ProcessingState = .UserSelectHome
    @Published var expectedHomePlateAngle: Double = 0.0
    
    var playersByPosition: [[CGPoint]] = []
    
    init() {
        super.init(fileName: "ProcessingResult", fileExtension: "txt")
    }
    
    func loadDataIntoPlayersByPosition() throws {
        // load data from the filePath into playersByPosition
        
        self.playersByPosition = []
        
        let contents = try! read()
        
        let splitByPosition = contents.split(separator: "\n")
        
        if splitByPosition.count == 5 {             // processing state == .UserHomeSelection
            var corners: [CGPoint] = []
            
            for i in 0..<4 {
                let splitByCoordinate = splitByPosition[i].split(separator: ",")
                corners.append(CGPoint(x: Int(splitByCoordinate[0])!, y: Int(splitByCoordinate[1])!))
            }
            
            self.playersByPosition.append(corners)
            
            var pitcher: [CGPoint] = []
            let splitByCoordinate = splitByPosition[4].split(separator: ",")
            pitcher.append(CGPoint(x: Int(splitByCoordinate[0])!, y: Int(splitByCoordinate[1])!))
            self.playersByPosition.append(pitcher)
            
        } else if splitByPosition.count == 9 {      // processing state == .Processing
            self.playersByPosition = [
                [], [], [], [], [], [], [], [], []
            ]   //has 9 spots for the 9 field positions
            
            for i in 0..<9 {
                if splitByPosition[i] == "-" {continue}
                let splitByPlayer = splitByPosition[i].split(separator: " ")
                for coord in splitByPlayer {
                    let splitCoord = coord.split(separator: ",")
                    self.playersByPosition[i].append(CGPoint(x: Int(splitCoord[0])!, y: Int(splitCoord[1])!))
                }
            }
        }
    }
    
    func getExpectedHomePlateAngle(point: CGPoint) throws -> Double? {
        // calculate the expected angle between the pitchers mound and home plate
        
        if playersByPosition.count != 2 { return nil }      // one for bases, one for pitcher
        
        let x = point.x - playersByPosition[1][0].x;
        let y = playersByPosition[1][0].y - point.y;   // flip because y goes up as the pixel location goes down
        
        return Double(atan2(y, x)) * (180 / Double.pi)
    }
}
