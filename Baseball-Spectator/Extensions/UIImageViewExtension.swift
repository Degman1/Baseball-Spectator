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
