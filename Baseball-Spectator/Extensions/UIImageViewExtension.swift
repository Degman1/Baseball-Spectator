//
//  UIImageViewExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/25/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation
import SwiftUI

extension Image {
    // function to load an image from the web onto the view using an seperate thread to load the image without inturrupting the rest of the program
    static func load(url: URL) -> Image {
        var im: Image = Image("sil")
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        im = Image(uiImage: image)
                    }
                }
            }
        }
        return im
    }
}
