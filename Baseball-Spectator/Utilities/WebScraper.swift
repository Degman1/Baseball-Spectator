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
            if error != nil {
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
            
            guard let table = self.extractLineupTableFromHTML(htmlString: htmlString) else {
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
        let endIndices = table.indices(of: "<")
        
        if positionIndices != nameIndices || positionIndices.count != 9 {
            print("ERROR: the number of player positions and/or player names is incorrect")
            return
        }
        
        for i in 0..<9 {
            var offset = 0
            var position = ""
            let i = table.index(table.startIndex, offsetBy: positionIndices[i] + positionIdentifier.count)
            while table[i] != "<" {
                i = table.index(table.startIndex, offsetBy: table[positionIndices[i] + positionIdentifier.count + offset])
                position += table[i]
                offset += 1
            }
            
            offset = 0
            var name = ""
            i = table.index(table.startIndex, offsetBy: nameIndices[i] + nameIdentifier.count)
            while table[i] != "<" {
                i = table.index(table.startIndex, offsetBy: table[nameIndices[i] + nameIdentifier.count + offset])
                name += table[i]
                offset += 1
            }
        }
    }
    
    func extractLineupTableFromHTML(htmlString: String) -> String? {
        // finds the characters wrapped by the occurenceNumber (1st, 2nd, 3rd...) occurence of the start indicator and the end indicator

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
        
        let tableStartIndices = htmlString.indices(of: """
            <table _ngcontent-sc211="" class="static-table stats-table table table-bordered starting-pitcher-table">
        """)
        
        if tableStartIndices.count < 2 {
            print("ERROR: Extracting data from hmtlString failed - no table start index found")
            return nil
        }
        
        let tableStartIndex = tableStartIndices[1]      // looking for the second table of that class name
        
        let tableEndIndices = htmlString.indices(of: "</table>")
        var tableEndIndex: Int = -1
        
        for index in tableEndIndices {
            if index > tableStartIndex {
                tableEndIndex = index       // the table ends at the </table> that occurs first after the start index
                break
            }
        }
        
        if tableEndIndex == -1 {
            print("ERROR: Extracting data from hmtlString failed - no table end index found")
            return nil
        }
        
        // must turn the int values into string index values to get the substring
        let start = htmlString.index(htmlString.startIndex, offsetBy: tableStartIndex)
        let end = htmlString.index(htmlString.startIndex, offsetBy: tableEndIndex)
        
        return String(htmlString[start...end])
    }
}
