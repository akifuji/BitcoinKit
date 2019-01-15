//
//  HeadersMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct HeadersMessage: Message {
    static var command: String {
        return "headers"
    }
    static let maxHeaders: Int = 2000
    var count: VarInt {
        return VarInt(headers.count)
    }
    let headers: [Block]

    func serialized() -> Data {
        var data = Data()
        data += count.serialized()
        return headers.reduce (data) { $0 + $1.serialized() }
    }

    static func deserialize(_ data: Data) throws -> HeadersMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        let countValue = count.underlyingValue
        guard countValue <= maxHeaders else {
            throw ProtocolError.error("malformed headers message, #headers is \(countValue), should be less than \(maxHeaders)")
        }
//        guard data.count > (81 * Int(countValue) + count.data.count) else {
//            throw ProtocolError.error("malformed headers message, data length is \(data.count), should be \(81 * Int(countValue) + count.data.count) for \(countValue) header(s)")
//        }
        var blockHeaders = [Block]()
        for _ in 0..<countValue {
            let blockHeader: Block = Block.deserialize(byteStream)
            guard blockHeader.transactions.isEmpty else {
                throw ProtocolError.error("malformed headers message, block header should not have transaction")
            }
            blockHeaders.append(blockHeader)
        }
        return HeadersMessage(headers: blockHeaders)
    }
}
