//
//  InventoryMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/11.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct InventoryMessage: Message {
    static var command: String {
        return "inv"
    }
    let count: VarInt
    let inventoryItems: [InventoryItem]

    func serialized() -> Data {
        var data = Data()
        data += count.serialized()
        data += inventoryItems.flatMap { $0.serialized() }
        return data
    }

    static func deserialize(_ data: Data) -> InventoryMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        var items = [InventoryItem]()
        for _ in 0..<Int(count.underlyingValue) {
            items.append(InventoryItem.deserialize(byteStream))
        }
        return InventoryMessage(count: count, inventoryItems: items)
    }
}
