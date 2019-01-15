//
//  FilterLoadMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/09.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct FilterLoadMessage: Message {
    static var command: String {
        return "filterload"
    }
    let filter: Data
    let hashFuncs: UInt32
    let tweak: UInt32
    let flags: UInt8

    func serialized() -> Data {
        var data = Data()
        data += VarInt(filter.count).serialized()
        data += filter
        data += hashFuncs
        data += tweak
        data += flags
        return data
    }

    static func deserialize(_ data: Data) throws -> FilterLoadMessage {
        throw ProtocolError.notImplemented
    }
}
