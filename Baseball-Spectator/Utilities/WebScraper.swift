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
    let baseURL: String
    let debug: Bool
    @Published var playerInfo: [Player] = []
    private var selectedPlayerIndex: Int? = nil        // set when the fetchStatistics method is called
                                                       // to store the selected player index since an observable object
    
    init(baseURL: String, debug: Bool = false) {
        self.baseURL = baseURL
        self.debug = debug
    }
    
    func createURLSessionTask(toRun action: @escaping (String) -> Void, withURL url: URL) {
        let source = "WebScraper - createURLSessionTask"
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {       // don't clear playerInfo, so if not having network connection, it just shows the last data it could fetch from the webpage
                if self.debug {
                    ConsoleCommunication.printError(withMessage: "\(error!)", source: source)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                if self.debug {
                    ConsoleCommunication.printError(withMessage: "\(response!)", source: source)
                }
                return
            }
            
            guard let data = data else {
                if self.debug {
                    ConsoleCommunication.printError(withMessage: "the downloaded HTML data was nil", source: source)
                }
                return
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                if self.debug {
                    ConsoleCommunication.printError(withMessage: "couldn't cast html data into a String", source: source)
                }
                return
            }
            
            action(htmlString)
        }
        
        task.resume()
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load statistics of selectedplayer
    
    func fetchStatistics(selectedPlayerIndex: Int) {
        // fetches the html code from the provided player stats
        // adds the player statistics to the playerInfo player
        
        self.selectedPlayerIndex = selectedPlayerIndex
        
        guard let playerURL = URL(string: playerInfo[selectedPlayerIndex].statisticsLink) else {
            ConsoleCommunication.printError(withMessage: "the team URL cannot be converted from a string to a URL", source: "WebScraper - fetchStatistics")
            return
        }
        
        self.createURLSessionTask(toRun: fetchStatisticsURLSessionTaskHelper, withURL: playerURL)
    }
    
    private func fetchStatisticsURLSessionTaskHelper(_ html: String) {
        // method to be passed to createURLSessionTask(:, :)
        
        let source = "WebScraper - fetchStatisticsURLSessionTaskHelper"
        
        if self.selectedPlayerIndex == nil { return }

        guard let i = html.index(of: "<td _ngcontent-sc") else {
            ConsoleCommunication.printError(withMessage: "could not locate the scNum related to the current version of the downloaded HTML script", source: source)
            return
        }

        // this number changes, so must find what it is in the latest download of html script
        guard let scNum = Int(html.getSubstring(from: html.distance(from: html.startIndex, to: i) + 17, to: "=")) else {
            ConsoleCommunication.printError(withMessage: "could not convert scNum to an Int", source: source)
            return
        }

        let start = """
            <tr _ngcontent-sc\(scNum)="" class="t-content">
            """ + "\n                  " + """
            <td _ngcontent-sc\(scNum)="">
            """
            
        let end = """
            </td><!---->
            """ + "\n                " + """
            </tr><!---->
            """
        guard let statsString = html.getSubstring(from: start, to: end) else {
            ConsoleCommunication.printError(withMessage: "could not find the player statistics table entries", source: source)
            return
        }
        
        let dividor = """
            </td><td_ngcontent-sc\(scNum)=\"\">
            """
        let stats = statsString.removeWhiteSpace().components(separatedBy: dividor)
        
        DispatchQueue.main.async {      // cannot mutate published properties in an observed object from a background thread, so must do so in the main thread
            self.playerInfo[self.selectedPlayerIndex!].rbi = stats[8]
            self.playerInfo[self.selectedPlayerIndex!].avg = stats[11]
            self.playerInfo[self.selectedPlayerIndex!].obp = stats[12]
            self.playerInfo[self.selectedPlayerIndex!].slg = stats[13]
        }
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load Line-up (names,  positions, statistics links)
    
    func fetchLineupInformation(teamLookupName: String) {
        // fetches the html code from the provided webpage and provided team to look up
        // searches for the up to date lineup and places the player information in playerInfo
        
        guard let teamURL = URL(string: self.baseURL + teamLookupName) else {
            ConsoleCommunication.printError(withMessage: "the team URL cannot be converted from a string to a URL", source: "WebStatistics - fetchLineupInformation")
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
        let source = "WebStatistics - fetchLineupInformation"
        var playerInfoTemp: [Player] = []
        
        guard let i = table.index(of: "_ngcontent-sc") else {
            ConsoleCommunication.printError(withMessage: "could not locate the scNum related to this version of the HTML script", source: source)
            return
        }
        
        // this number changes, so must find what it is in the latest download of html script
        guard let scNum = Int(table.getSubstring(from: table.distance(from: table.startIndex, to: i) + 13, to: "=")) else {
            ConsoleCommunication.printError(withMessage: "could not convert scNum to an Int", source: source)
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
        
        if positionIndices.count != nameIndices.count || positionIndices.count != 9 {
            ConsoleCommunication.printError(withMessage: "the number of positions and/or player names is incorrect in website stats fetching", source: source)
            return
        }
        
        for i in 0..<9 {
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
        
        if playerInfoTemp.count == 9 {
            DispatchQueue.main.async {      // cannot mutate published properties in an observed object from a background thread, so must do so in the main thread
                self.playerInfo = playerInfoTemp.sorted(by: { $0.positionID < $1.positionID })
            }
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
        
        let source = "WebScraper - extractLineupTablesFromHTML"
        
        // don't include the sc # since it changes
        let tableStartID = """
            class="static-table stats-table table table-bordered starting-pitcher-table">
            """
        let tableStartIndices = htmlString.indices(of: tableStartID)
        
        if tableStartIndices.count < 2 {
            ConsoleCommunication.printError(withMessage: "extracting data from hmtlString failed, there was no table start index found", source: source)
            return nil
        }
        
        let tableEndIndices = htmlString.indices(of: "</table>")
        
        guard let table1 = htmlString.getHTMLsnippetUnknownEndpoint(from: tableStartIndices[0], to: tableEndIndices), let table2 = htmlString.getHTMLsnippetUnknownEndpoint(from: tableStartIndices[1], to: tableEndIndices) else {
            ConsoleCommunication.printError(withMessage: "extracting data from hmtlString failed, there was no table end index found", source: source)
            return nil
        }
        
        return table1 + table2
    }
}
