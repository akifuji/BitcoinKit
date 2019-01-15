//
//  GetDataMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/09.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct GetDataMessage: Message {
    static var command: String {
        return "getdata"
    }
    let count: VarInt
    let inventoryItems: [InventoryItem]

    func serialized() -> Data {
        var data = Data()
        data += count.serialized()
        data += inventoryItems.flatMap { $0.serialized() }
        return data
    }

    static func deserialize(_ data: Data) -> GetDataMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        var items = [InventoryItem]()
        for _ in 0..<count.underlyingValue {
            let type = byteStream.read(Int32.self)
            let hash = byteStream.read(Data.self, count: 32)
            let item = InventoryItem(type: type, hash: hash)
            items.append(item)
        }
        return GetDataMessage(count: count, inventoryItems: items)
    }
}
