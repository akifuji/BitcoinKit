//
//  GetHeadersMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct GetHeadersMessage: Message {
    static var command: String {
        return "getheaders"
    }

    let version: UInt32
    let hashCount: VarInt
    let blockLocatorHashes: Data
    let hashStop: Data

    func serialized() -> Data {
        var data = Data()
        data += version
        data += hashCount.serialized()
        data += blockLocatorHashes
        data += hashStop
        return data
    }

    static func deserialize(_ data: Data) throws -> GetHeadersMessage {
        throw ProtocolError.notImplemented
    }
}
