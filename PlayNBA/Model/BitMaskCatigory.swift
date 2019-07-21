//
//  BitMaskCatigory.swift
//  PlayNBA
//
//  Created by Сергей Калмыков on 7/20/19.
//  Copyright © 2019 Сергей Калмыков. All rights reserved.
//

import Foundation

struct BitMaskCategory {    
    static let ball: UInt32 = 0x1 << 0
    static let board: UInt32 = 0x1 << 1
    static let firstBody: UInt32 = 0x1 << 2
    static let secondBody: UInt32 = 0x1 << 3
}
