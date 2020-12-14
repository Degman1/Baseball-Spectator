//
//  WebScraper.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/5/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

class WebScraper: ObservableObject {
    let baseURL: String = "https://www.lineups.com/mlb/lineups/"
    @Published var playerInfo: [Player] = []
    private var selectedPlayerIndex: Int? = nil        // set when the fetchStatistics method is called to store the selected player index since the selected player index is an observable object in the view
    
    /*init(baseURL: String) {
        self.baseURL = baseURL
    }*/
    
    func createURLSessionTask(toRun action: @escaping (String) -> Void, withURL url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {       // don't clear playerInfo, so if not having network connection, it just shows the last data it could fetch from the webpage
                ConsoleCommunication.printError(withMessage: "\(error!)", source: "\(#function)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                ConsoleCommunication.printError(withMessage: "\(response!)", source: "\(#function)")
                return
            }
            
            guard let data = data else {
                ConsoleCommunication.printError(withMessage: "the downloaded HTML data was nil", source: "\(#function)")
                return
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                ConsoleCommunication.printError(withMessage: "couldn't cast html data into a String", source: "\(#function)")
                return
            }
            
            action(htmlString)
        }
        
        task.resume()
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load statistics of selected player
    
    func fetchStatistics(selectedPlayerIndex: Int) {
        // fetches the html code from the provided player stats
        // adds the player statistics to the playerInfo player
        
        self.selectedPlayerIndex = selectedPlayerIndex
        
        guard let playerURL = URL(string: playerInfo[selectedPlayerIndex].statisticsLink) else {
            ConsoleCommunication.printError(withMessage: "the team URL cannot be converted from a string to a URL", source: "\(#function)")
            return
        }
        
        self.createURLSessionTask(toRun: fetchStatisticsURLSessionTaskHelper, withURL: playerURL)
    }
    
    private func fetchStatisticsURLSessionTaskHelper(_ html: String) {
        // method to be passed to createURLSessionTask(:, :) in the above fetchStatistics(:) method
        
        if self.selectedPlayerIndex == nil { return }
                
        let start = "class=\"inner-col-switch\" data-title=\"YEAR\">"
        let end = "</table>"
        
        guard let statsTable = html.getSubstring(from: start, to: end) else {
            ConsoleCommunication.printError(withMessage: "could not find the player statistics table entries", source: "\(#function)")
            return
        }
        
        let statsByYear = statsTable.components(separatedBy: start).map({$0.removeWhiteSpace()})
        
        //[year:[statisticName:statisticValue]]
        var statsDict: [String: [String: String]] = [:]
        
        for s in statsByYear {
            var year = ""
            var i = 0
            
            while s[s.index(s.startIndex, offsetBy: i)] != "<" {
                year += String(s[s.index(s.startIndex, offsetBy: i)])
                i += 1
            }
            
            var stats = [String: String]()
            
            if year != "Overall" {
                if let TEAM = s.getSubstring(from: "class=\"link-black-underline\"href=\"/\">", to: "<"){
                    stats["TEAM"] = TEAM
                } else {
                    ConsoleCommunication.printError(withMessage: "could not find statistic (SLG)", source: #function)
                }
            }
            
            // games played
            if let GP = s.getSubstring(from: "GP\">", to: "<") {
                stats["GP"] = GP
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (GP)", source: #function)
            }
            
            // plate appearances
            if let PA = s.getSubstring(from: "PA\">", to: "<") {
                stats["PA"] = PA
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (PA)", source: #function)
            }
            
            // hits
            if let H = s.getSubstring(from: "H\">", to: "<") {
                stats["H"] = H
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (H)", source: #function)
            }
            
            if let B2 = s.getSubstring(from: "2B\">", to: "<") {
                stats["2B"] = B2
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (2B)", source: #function)
            }
            
            if let B3 = s.getSubstring(from: "3B\">", to: "<") {
                stats["3B"] = B3
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (3B)", source: #function)
            }
            
            if let HR = s.getSubstring(from: "HR\">", to: "<") {
                stats["HR"] = HR
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (HR)", source: #function)
            }
            
            if let R = s.getSubstring(from: "R\">", to: "<") {
                stats["R"] = R
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (R)", source: #function)
            }
            
            // runs batted in
            if let RBI = s.getSubstring(from: "RBI\">", to: "<") {
                stats["RBI"] = RBI
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (RBI)", source: #function)
            }
            
            // stolen bases
            if let SB = s.getSubstring(from: "SB\">", to: "<") {
                stats["SB"] = SB
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (SB)", source: #function)
            }
            
            // caught stealing
            if let CS = s.getSubstring(from: "CS\">", to: "<") {
                stats["CS"] = CS
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (CS)", source: #function)
            }
            
            // base on balls
            if let BB = s.getSubstring(from: "BB\">", to: "<") {
                stats["BB"] = BB
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (BB)", source: #function)
            }
            
            // hit by pitch
            if let HBP = s.getSubstring(from: "2B\">", to: "<") {
                stats["HBP"] = HBP
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (HBP)", source: #function)
                return
            }
            
            if let AVG = s.getSubstring(from: "AVG\">", to: "<") {
                stats["AVG"] = AVG
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (AVG)", source: #function)
            }
            
            // on base percentage
            if let OBP = s.getSubstring(from: "OBP\">", to: "<") {
                stats["OBP"] = OBP
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (OBP)", source: #function)
            }
            
            if let SLG = s.getSubstring(from: "SLG\">", to: "<") {
                stats["SLG"] = SLG
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (SLG)", source: #function)
            }
            
            // on base percentage and slugging percentage combined
            if let OPS = s.getSubstring(from: "OPS\">", to: "<") {
                stats["OPS"] = OPS
            } else {
                ConsoleCommunication.printError(withMessage: "could not find statistic (OPS)", source: #function)
            }
            
            statsDict[year] = stats
        }
        
        DispatchQueue.main.async {      // cannot mutate published properties in an observed object from a background thread, so must do so in the main thread
            self.playerInfo[self.selectedPlayerIndex!].statistics = statsDict
            self.playerInfo[self.selectedPlayerIndex!].imageLink = ""       //TODO
        }
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load Line-up (names,  positions, statistics links)
    
    func fetchLineupInformation(teamLookupName: String) {
        // fetches the html code from the provided webpage and provided team to look up
        // searches for the up to date lineup and places the player information in playerInfo
        
        guard let teamURL = URL(string: self.baseURL + teamLookupName) else {
            ConsoleCommunication.printError(withMessage: "the team URL cannot be converted from a string to a URL", source: "\(#function)")
            return
        }
        
        self.createURLSessionTask(toRun: fetchLineUpURLSessionTaskHelper, withURL: teamURL)
    }
    
    private func fetchLineUpURLSessionTaskHelper(_ html: String) {
        // wrapping method to be passed to createURLSessionTask(:, :)
        
        guard let table = self.extractLineupTablesFromHTML(htmlString: html) else {
            return
        }
        
        self.loadPlayerInfoFromLineupTable(html: html, table: table)
    }
    
    private func loadPlayerInfoFromLineupTable(html: String, table: String) {
        var playerInfoTemp: [Player] = []
        
        guard let scNumLoc = table.index(of: "_ngcontent-sc") else {
            ConsoleCommunication.printError(withMessage: "could not locate the scNum related to this version of the HTML script", source: #function)
            return
        }
        
        // this seems to change, so must find what it is in the latest download of html script
        guard let scNum = Int(table.getSubstring(from: table.distance(from: table.startIndex, to: scNumLoc) + 13, to: "=")) else {
            ConsoleCommunication.printError(withMessage: "could not convert scNum to an Int", source: "\(#function)")
            return
        }
        
        let positionIdentifier = """
            <td _ngcontent-sc\(scNum)="" class="position-col">
            """
        
        let nameIdentifier = """
            <span class="player-name-col-lg">
            """
        
        let positionIndices = table.indices(of: positionIdentifier)
        let nameIndices = table.indices(of: nameIdentifier)
        
        if positionIndices.count != nameIndices.count || positionIndices.count < 9 {    // could be more than 9 positions since there could be designated hitters (DH)
            ConsoleCommunication.printError(withMessage: "the number of positions and/or player names is incorrect in website stats fetching", source: #function)
            return
        }
        
        for i in 0..<positionIndices.count {
            let position = table.getSubstring(from: positionIndices[i] + positionIdentifier.count, to: "<")
            let name = table.getSubstring(from: nameIndices[i] + nameIdentifier.count, to: "<")
            
            let linkIdentifier = """
                "@type":"Person","name":"\(name)","url":"
                """
            let linkIndex = html.indices(of: linkIdentifier)[0]
            let link = html.getSubstring(from: linkIndex + linkIdentifier.count, to: """
            "
            """)
            
            playerInfoTemp.append(Player(name: name, position: position, statisticsLink: link))
        }
        
        DispatchQueue.main.async {      // cannot mutate published properties in an observed object from a background thread, so must do so in the main thread
            self.playerInfo = playerInfoTemp.sorted(by: { $0.positionID < $1.positionID })
        }
    }
    
    private func extractLineupTablesFromHTML(htmlString: String) -> String? {
        // finds the characters wrapped by the occurenceNumber (1st, 2nd, 3rd...) occurence of the start indicator and the end indicator
        // return the table containing the (1st) pitcher's stats and (2nd) the rest of the players' stats

        /*
         lookup for info table (must be second occurence):
             <table _ngcontent-sc211="" class="static-table stats-table table table-bordered starting-pitcher-table">
         end (first occurence after the startIndicator): </table>
         
         lookup for player position:
             <td _ngcontent-sc211="" class="position-col">
         end: <
         
         lookup for player name (occurence must be the first one after the player position)
             <span class="player-name-col-lg">
         end: <
        */
                
        // don't include the sc # since it changes
        let tableStartID = """
            class="static-table stats-table table table-bordered starting-pitcher-table">
            """
        let tableStartIndices = htmlString.indices(of: tableStartID)
        
        if tableStartIndices.count < 2 {
            ConsoleCommunication.printError(withMessage: "extracting data from hmtlString failed, there was no table start index found", source: #function)
            return nil
        }
        
        let tableEndIndices = htmlString.indices(of: "</table>")
        
        guard let table1 = htmlString.getSubstringUnknownEndpoint(from: tableStartIndices[0], to: tableEndIndices), let table2 = htmlString.getSubstringUnknownEndpoint(from: tableStartIndices[1], to: tableEndIndices) else {
            ConsoleCommunication.printError(withMessage: "extracting data from hmtlString failed, there was no table end index found", source: #function)
            return nil
        }
        
        return table1 + table2
    }
}
