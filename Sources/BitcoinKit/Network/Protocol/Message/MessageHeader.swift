//
//  Message.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/05.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct MessageHeader {
    let magic: UInt32
    let command: String
    let length: UInt32
    let checksum: Data
    static let length = 24

    func serialized() -> Data {
        var data = Data()
        data += magic.bigEndian
        var bytes = [UInt8](command.data(using: .ascii)!)
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 12 - bytes.count))
        data += bytes
        data += length.littleEndian
        data += checksum
        return data
    }

    static func deserialize(_ data: Data) -> MessageHeader? {
        let byteStream: ByteStream = ByteStream(data)
        let magic = byteStream.read(UInt32.self)
        let command = byteStream.read(Data.self, count: 12).to(type: String.self)
        let length = byteStream.read(UInt32.self)
        let checksum = byteStream.read(Data.self, count: 4)
        return MessageHeader(magic: magic, command: command, length: length, checksum: checksum)
    }
}
