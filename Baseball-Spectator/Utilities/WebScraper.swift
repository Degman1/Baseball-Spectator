//
//  WebScraper.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/5/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class WebScraper {
    var baseURL: String
    var webpageHTML: String? = nil
    var playerInfo: [Player] = []
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func getWebsiteHTML(teamLookupName: String) {
        // fetches the html code from the provided webpage and provided team to look up
        // places the html in the class property webpageHTML for later reference
        
        let url = URL(string: self.baseURL + teamLookupName)!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {       // don't clear playerInfo, so if not having network connection, it just shows the last data it could fetch from the webpage
                print(error!)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print(response!)
                return
            }
            
            guard let data = data else {
                print("data was nil")
                return
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("couldn't cast data into String")
                return
            }
            
            self.webpageHTML = htmlString
            
            guard let table = self.extractLineupTablesFromHTML(htmlString: htmlString) else {
                return
            }
                        
            self.loadPlayerInfoFromLineupTable(table: table)
        }
        
        task.resume()
    }
    
    func loadPlayerInfoFromLineupTable(table: String) {
        var playerInfoTemp: [Player] = []
        
        // this number changes, so must find what it is in the latest download of html script
        let scNum = table.getSubstring(from: table.index(of: "_ngcontent-sc")!.encodedOffset + 13, to: "=")
        
        let positionIdentifier = """
            <td _ngcontent-sc\(scNum)="" class="position-col">
            """
        
        let nameIdentifier = """
            <span class="player-name-col-lg">
            """
        
        let positionIndices = table.indices(of: positionIdentifier)
        let nameIndices = table.indices(of: nameIdentifier)
        
        if positionIndices.count != nameIndices.count || positionIndices.count != 9 {
            print("ERROR: the number of positions and/or player names is incorrect in website stats fetching")
            return
        }
        
        for i in 0..<9 {
            let position = table.getSubstring(from: positionIndices[i] + positionIdentifier.count, to: "<")
            let name = table.getSubstring(from: nameIndices[i] + nameIdentifier.count, to: "<")
            playerInfoTemp.append(Player(name: name, position: position))
        }
        
        if playerInfoTemp.count == 9 {
            playerInfo = playerInfoTemp.sorted(by: { $0.positionID < $1.positionID })
        }
    }
    
    func extractLineupTablesFromHTML(htmlString: String) -> String? {
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
            print("ERROR: Extracting data from hmtlString failed - no table start index found")
            return nil
        }
        
        let tableEndIndices = htmlString.indices(of: "</table>")
        
        guard let table1 = htmlString.getHTMLsnippetUnknownEndpoint(from: tableStartIndices[0], to: tableEndIndices), let table2 = htmlString.getHTMLsnippetUnknownEndpoint(from: tableStartIndices[1], to: tableEndIndices) else {
            print("ERROR: Extracting data from hmtlString failed - no table end index found")
            return nil
        }
        
        return table1 + table2
    }
}
