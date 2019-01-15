//
//  TransactionOutput.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/08.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct TransactionOutput {
    public let value: UInt64
    public var scriptLength: VarInt {
        return VarInt(lockingScript.count)
    }
    public let lockingScript: Data

    public func serialized() -> Data {
        var data = Data()
        data += value
        data += scriptLength.serialized()
        data += lockingScript
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionOutput {
        let value = byteStream.read(UInt64.self)
        let scriptLength = byteStream.read(VarInt.self)
        let lockingScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))
        return TransactionOutput(value: value, lockingScript: lockingScript)
    }
}
