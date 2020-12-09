//
//  IntExtension.swift
//  Baseball-Spectator
//
//  Created by David Gerard on 6/19/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

import Foundation

infix operator %%

extension Int {
    // The double modulo acts like the normal modulo, but changed its behavior with negative numbers, allowing the double modulo to loop the left around the right both forewards and backwards as opposed to just forewards (used to rotate selected players)
    static  func %% (_ left: Int, _ right: Int) -> Int {
        if left >= 0 { return left % right }
        if left >= -right { return (left+right) }
        return ((left % right)+right)%right
    }
}
