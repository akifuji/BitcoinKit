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

    static func buildP2PKHUnlockingScript(signature: Data, pubkey: PublicKey) -> Data {
        var script = Data([UInt8(signature.count + 1)]) + signature + 0x01 // SIGHASH_ALL
        let pubkeyData = pubkey.data
        script += VarInt(pubkeyData.count).serialized() + pubkeyData
        return script
    }
}

enum ScriptError: Error {
    case error(String)
}
