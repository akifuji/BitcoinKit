//
//  Script.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/12.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public class Script {
    public static func getPublicKeyHash(from script: Data) -> Data {
        guard script.count >= 23 else {
            return Data()
        }
        return script[3..<23]
    }

    static func buildP2PKHLockingScript(pubKeyHash: Data) -> Data {
        let script: Data = Data() + OpCode.OP_DUP + OpCode.OP_HASH160 + UInt8(pubKeyHash.count) + pubKeyHash
        return script + OpCode.OP_EQUALVERIFY + OpCode.OP_CHECKSIG
    }

    static func isP2PKHLockingScript(_ script: Data) -> Bool {
        return script.count == 25 &&
            script[0] == OpCode.OP_DUP.rawValue && script[1] == OpCode.OP_HASH160.rawValue && script[2] == 20 &&
            script[23] == OpCode.OP_EQUALVERIFY.rawValue && script[24] == OpCode.OP_CHECKSIG.rawValue
    }
}

enum ScriptError: Error {
    case error(String)
}
