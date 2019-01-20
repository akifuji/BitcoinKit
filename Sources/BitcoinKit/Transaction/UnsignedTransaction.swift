//
//  UnsignedTransaction.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/19.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct UnsignedTransaction {
    let tx: Transaction
    let utxos: [UnspentTransactionOutput]
}
