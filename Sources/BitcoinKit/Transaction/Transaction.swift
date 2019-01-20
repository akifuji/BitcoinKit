//
//  Transaction.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/08.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct Transaction: Message {
    static let unconfirmed = UINT32_MAX
    static var command: String {
        return "tx"
    }
    public let version: UInt32
    // public let flag: UInt8?
    public var txInCount: VarInt {
        return VarInt(inputs.count)
    }
    public let inputs: [TransactionInput]
    public var txOutCount: VarInt {
        return VarInt(outputs.count)
    }
    public let outputs: [TransactionOutput]
    public let lockTime: UInt32
    public var hash: Data {
        return Crypto.sha256sha256(serialized())
    }
    public var txID: Data {
        return Data(hash.reversed())
    }
    var blockHeight: UInt32 = unconfirmed

    init(version: UInt32, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: UInt32, blockHeight: UInt32 = unconfirmed) {
        self.version = version
        self.inputs = inputs
        self.outputs = outputs
        self.lockTime = lockTime
        self.blockHeight = blockHeight
    }

    public func serialized() -> Data {
        var data = Data()
        data += version
        data += txInCount.serialized()
        data += inputs.flatMap { $0.serialized() }
        data += txOutCount.serialized()
        data += outputs.flatMap { $0.serialized() }
        data += lockTime
        return data
    }

    public static func deserialize(_ data: Data) -> Transaction {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    static func deserialize(_ byteStream: ByteStream) -> Transaction {
        let version = byteStream.read(UInt32.self)
        let txInCount = byteStream.read(VarInt.self)
        var inputs = [TransactionInput]()
        for _ in 0..<Int(txInCount.underlyingValue) {
            inputs.append(TransactionInput.deserialize(byteStream))
        }
        let txOutCount = byteStream.read(VarInt.self)
        var outputs = [TransactionOutput]()
        for _ in 0..<Int(txOutCount.underlyingValue) {
            outputs.append(TransactionOutput.deserialize(byteStream))
        }
        let lockTime = byteStream.read(UInt32.self)
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime, blockHeight: unconfirmed)
    }
}
