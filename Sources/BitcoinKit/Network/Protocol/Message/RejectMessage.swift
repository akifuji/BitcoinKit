//
//  RejectMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/20.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct RejectMessage: Message {
    static var command: String {
        return "reject"
    }
    let message: VarString
    let ccode: UInt8
    let reason: VarString
    let data: Data

    func serialized() -> Data {
        return Data() // not implemented
    }

    static func deserialize(_ data: Data) -> RejectMessage {
        let byteStream = ByteStream(data)
        let message = byteStream.read(VarString.self)
        let ccode = byteStream.read(UInt8.self)
        let reason = byteStream.read(VarString.self)
        return RejectMessage(message: message, ccode: ccode, reason: reason, data: data)
    }

    enum CCode: UInt8 {
        case malformed = 0x01
        case invalid = 0x10
        case obsolete = 0x11
        case duplicate = 0x12
        case nonstandard = 0x40
        case dust = 0x41
        case insufficientFee = 0x42
        case checkpoint = 0x43
    }
}
