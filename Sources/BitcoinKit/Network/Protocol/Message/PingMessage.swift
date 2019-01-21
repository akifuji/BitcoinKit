//
//  PingMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct PingMessage: Message {
    static var command: String {
        return "ping"
    }

    let nonce: UInt64

    func serialized() -> Data {
        return Data() // not implemented
    }

    static func deserialize(_ data: Data) -> PingMessage {
        let byteStream = ByteStream(data)
        let nonce = byteStream.read(UInt64.self)
        return PingMessage(nonce: nonce)
    }
}
