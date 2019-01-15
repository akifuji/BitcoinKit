//
//  TransactionOutPoint.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/08.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct TransactionOutPoint {
    public let hash: Data
    public let index: UInt32

    public func serialized() -> Data {
        var data = Data()
        data += hash
        data += index
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionOutPoint {
        let hash = Data(byteStream.read(Data.self, count: 32))
        let index = byteStream.read(UInt32.self)
        return TransactionOutPoint(hash: hash, index: index)
    }
}
