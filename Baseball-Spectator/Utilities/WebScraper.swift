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
    var playerInfo: [PlayerInfo] = []
    
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
        var playerInfoTemp: [PlayerInfo] = []
        
        let positionIdentifier = """
            <td _ngcontent-sc211="" class="position-col">
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
            playerInfoTemp.append(PlayerInfo(name: name, position: position))
        }
        
        if playerInfoTemp.count == 9 {
            print(playerInfoTemp)
            playerInfo = playerInfoTemp
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
        
        let tableStartID = """
            <table _ngcontent-sc211="" class="static-table stats-table table table-bordered starting-pitcher-table">
            """
        let tableStartIndices = htmlString.indices(of: tableStartID)
        
        if tableStartIndices.count < 2 {
            print("ERROR: Extracting data from hmtlString failed - no table start index found")
            return nil
        }
        
        let tableEndIndices = htmlString.indices(of: "</table>")
        
        guard let table1 = self.getHTMLsnippetUnknownEndpoint(string: htmlString, from: tableStartIndices[0], to: tableEndIndices), let table2 = self.getHTMLsnippetUnknownEndpoint(string: htmlString, from: tableStartIndices[1], to: tableEndIndices) else {
            print("ERROR: Extracting data from hmtlString failed - no table end index found")
            return nil
        }
        
        return table1 + table2
    }
    
    func getHTMLsnippetUnknownEndpoint(string: String, from startIndex: Int, to endIndices: [Int]) -> String? {
        // gets the substring range from the start index to the next index in endIndices
        
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
        let start = string.index(string.startIndex, offsetBy: startIndex)
        let end = string.index(string.startIndex, offsetBy: endIndex)
        
        return String(string[start...end])
    }
}
