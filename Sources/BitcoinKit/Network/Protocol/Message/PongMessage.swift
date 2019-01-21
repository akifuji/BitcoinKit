//
//  PongMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct PongMessage: Message {
    static var command: String {
        return "pong"
    }
    let nonce: UInt64

    func serialized() -> Data {
        return Data() + nonce
    }

    static func deserialize(_ data: Data) throws -> PongMessage {
        throw ProtocolError.notImplemented
    }
}
