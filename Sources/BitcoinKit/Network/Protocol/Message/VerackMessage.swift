//
//  VerackMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct VerackMessage: Message {
    static var command: String {
        return "verack"
    }
    func serialized() -> Data {
        return Data()
    }
    static func deserialize(_ data: Data) throws -> VerackMessage {
        return VerackMessage()
    }
}
