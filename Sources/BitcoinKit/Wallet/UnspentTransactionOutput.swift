//
//  UnspentTransactionOutput.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/19.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct UnspentTransactionOutput {
    public let hash: Data
    public let pubKeyHash: Data
    public let index: UInt32
    public let value: UInt64
}
