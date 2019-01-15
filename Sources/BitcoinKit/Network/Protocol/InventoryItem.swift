//
//  InventoryItem.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/09.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct InventoryItem {
    public let type: Int32
    public let hash: Data

    public func serialized() -> Data {
        var data = Data()
        data += type
        data += hash
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> InventoryItem {
        let type = byteStream.read(Int32.self)
        let hash = byteStream.read(Data.self, count: 32)
        return InventoryItem(type: type, hash: hash)
    }

    public enum ObjectType: Int32 {
        case error = 0
        case transactionMessage = 1
        case blockMessage = 2
        case filteredBlockMessage = 3
        case compactBlockMessage = 4
        case unknown
    }
}
