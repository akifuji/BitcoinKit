//
//  Payment.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/19.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct Payment {
    public enum Direction: Int32 {
        case sent = 0
        case received = 1
    }
    public let txID: Data
    public let direction: Direction
    public let amount: UInt64
    public var blockHeight: UInt32

    init(txID: Data, direction: Direction, amount: UInt64, blockHeight: UInt32 = Block.unknownHeight) {
        self.txID = txID
        self.direction = direction
        self.amount = amount
        self.blockHeight = blockHeight
    }
}
