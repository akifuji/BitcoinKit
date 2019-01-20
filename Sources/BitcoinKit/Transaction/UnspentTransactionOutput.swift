//
//  UnspentTransactionOutput.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/19.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

// UnspentTransactionOutput is used for building a new transaction
struct UnspentTransactionOutput {
    let hash: Data
    let index: UInt32
    let value: UInt64
    let lockingScript: Data
    let pubkeyHash: Data
}

extension Sequence where Element == UnspentTransactionOutput {
    func sum() -> UInt64 {
        return reduce(0) { $0 + $1.value }
    }
}
