//
//  WebScraper.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/5/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

class WebScraper: ObservableObject {
    var baseURL: String
    @Published var playerInfo: [Player] = []
    let debug: Bool
    var selectedPlayerID: Int? = nil        // set when the fetchStatistics method is called
    
    init(baseURL: String, debug: Bool = false) {
        self.baseURL = baseURL
        self.debug = debug
    }
    
    func createURLSessionTask(toRun action: @escaping (String) -> Void, withURL url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {       // don't clear playerInfo, so if not having network connection, it just shows the last data it could fetch from the webpage
                if self.debug {
                    print("ERROR: \(error!)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                if self.debug {
                    print(response!)
                }
                return
            }
            
            guard let data = data else {
                if self.debug {
                    print("ERROR: html data was nil")
                }
                return
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                if self.debug {
                    print("ERROR: couldn't cast html data into String")
                }
                return
            }
            
            action(htmlString)
        }
        
        task.resume()
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load statistics of selectedplayer
    
    func fetchStatistics(selectedPlayerID: Int) {
        // fetches the html code from the provided player stats
        // adds the player statistics to the playerInfo player
        
        self.selectedPlayerID = selectedPlayerID
        
        guard let playerURL = URL(string: playerInfo[selectedPlayerID].statisticsLink) else {
            print("ERROR: the team URL cannot be converted from a string to a URL")
            return
        }
        
        self.createURLSessionTask(toRun: fetchStatisticsTaskHelper, withURL: playerURL)
    }
    
    func fetchStatisticsTaskHelper(_ html: String) {
        // method to be passed to createURLSessionTask(:, :)
        
        if self.selectedPlayerID == nil { return }

        guard let i = html.index(of: "<td _ngcontent-sc") else {
            print("ERROR: Could not locate the scNum related to this version of the HTML script")
            return
        }

        // this number changes, so must find what it is in the latest download of html script
        guard let scNum = Int(html.getSubstring(from: html.distance(from: html.startIndex, to: i) + 17, to: "=")) else {
            print("ERROR: Could not convert scNum to an Int")
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
            print("ERROR: Could not find the player statistics table entries")
            return
        }
        
        let dividor = """
            </td><td_ngcontent-sc\(scNum)=\"\">
            """
        let stats = statsString.removeWhiteSpace().components(separatedBy: dividor)
        
        DispatchQueue.main.async {      // cannot mutate published properties in an observed object from a background thread, so must do so in the main thread
            self.playerInfo[self.selectedPlayerID!].rbi = stats[8]
            self.playerInfo[self.selectedPlayerID!].avg = stats[11]
            self.playerInfo[self.selectedPlayerID!].obp = stats[12]
            self.playerInfo[self.selectedPlayerID!].slg = stats[13]
        }
    }
    
    //------------------------------------------------------------------------------------------------------
    // Load Line-up (names,  positions, statistics links)
    
    func fetchLineUpInformation(teamLookupName: String) {
        // fetches the html code from the provided webpage and provided team to look up
        // searches for the up to date lineup and places the player information in playerInfo
        
        guard let teamURL = URL(string: self.baseURL + teamLookupName) else {
            print("ERROR: the team URL cannot be converted from a string to a URL")
            return
        }
        
        self.createURLSessionTask(toRun: fetchLineUpTaskHelper, withURL: teamURL)
    }
    
    private func fetchLineUpTaskHelper(_ html: String) {
        // wrapping method to be passed to createURLSessionTask(:, :)
        
        guard let table = self.extractLineupTablesFromHTML(htmlString: html) else {
            return
        }
        
        self.loadPlayerInfoFromLineupTable(html: html, table: table)
    }
    
    private func loadPlayerInfoFromLineupTable(html: String, table: String) {
        var playerInfoTemp: [Player] = []
        
        guard let i = table.index(of: "_ngcontent-sc") else {
            print("ERROR: Could not locate the scNum related to this version of the HTML script")
            return
        }
        
        // this number changes, so must find what it is in the latest download of html script
        guard let scNum = Int(table.getSubstring(from: table.distance(from: table.startIndex, to: i) + 13, to: "=")) else {
            print("ERROR: Could not convert scNum to an Int")
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
            print("ERROR: the number of positions and/or player names is incorrect in website stats fetching")
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
