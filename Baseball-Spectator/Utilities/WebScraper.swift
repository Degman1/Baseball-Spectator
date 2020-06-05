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
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func getWebsiteHTML(teamLookupName: String) -> String? {
        let url = URL(string: self.baseURL + teamLookupName)!
        
        var html = ""
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print("data was nil")
                return
            }
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("couldn't cast data into String")
                return
            }
            
            html = htmlString
        }
        
        return html
    }
}
