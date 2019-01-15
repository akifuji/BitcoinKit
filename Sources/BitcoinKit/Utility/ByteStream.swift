//
//  ByteStream.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/05.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

internal class ByteStream {
    let data: Data
    private var offset = 0

    var availableBytes: Int {
        return data.count - offset
    }

    init(_ data: Data) {
        self.data = data
    }

    func read<T>(_ type: T.Type) -> T {
        let size = MemoryLayout<T>.size
        let value = data[offset..<(offset + size)].to(type: type)
        offset += size
        return value
    }

    func read(_ type: VarInt.Type) -> VarInt {
        let value: UInt64
        let length = data[offset..<(offset + 1)].to(type: UInt8.self)
        offset += 1
        switch length {
        case 0...252:
            value = UInt64(length)
        case 0xfd:
            value = UInt64(data[offset..<(offset + 2)].to(type: UInt16.self))
            offset += 2
        case 0xfe:
            value = UInt64(data[offset..<(offset + 4)].to(type: UInt32.self))
            offset += 4
        case 0xff:
            fallthrough
        default:
            value = data[offset..<(offset + 8)].to(type: UInt64.self)
            offset += 8
        }
        return VarInt(value)
    }

    func read(_ type: VarString.Type) -> VarString {
        let length = Int(read(VarInt.self).underlyingValue)
        let value = data[offset..<(offset + length)].to(type: String.self)
        offset += length
        return VarString(value)
    }

    func read(_ type: Data.Type, count: Int) -> Data {
        let value = data[offset..<(offset + count)]
        offset += count
        return Data(value)
    }
}
