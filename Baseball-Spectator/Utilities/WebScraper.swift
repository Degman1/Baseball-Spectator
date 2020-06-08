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
        }
        
        task.resume()
    }
    
    func extractDataFromHTML(htmlString: String) {
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
        
        let tableStartIndicatorIndex = htmlString.indices(of: """
            <table _ngcontent-sc211="" class="static-table stats-table table table-bordered starting-pitcher-table">
        """)[1]
        
        let tableEndIndices = htmlString.indices(of: "</table>")
    }
}
