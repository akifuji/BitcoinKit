//
//  MerkleBlock.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

private let unknownHeight: UInt32 = UINT32_MAX

public struct Block {
    public let version: Int32
    public let prevBlock: Data
    public let merkleRoot: Data
    public let timestamp: UInt32
    public let bits: UInt32
    public let nonce: UInt32
    public let transactionCount: VarInt
    public let transactions: [Transaction]
    public var height: UInt32

    public var blockHash: Data {
        var data = Data()
        data += version
        data += prevBlock
        data += merkleRoot
        data += timestamp
        data += bits
        data += nonce
        return Data(Crypto.sha256sha256(data))
    }

    public func serialized() -> Data {
        var data = Data()
        data += version
        data += prevBlock
        data += merkleRoot
        data += timestamp
        data += bits
        data += nonce
        data += transactionCount.serialized()
        data += transactions.flatMap { $0.serialized() }
        return data
    }

    public static func deserialize(_ data: Data) -> Block {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    internal static func deserialize(_ byteStream: ByteStream) -> Block {
        let version = byteStream.read(Int32.self)
        let prevBlock = byteStream.read(Data.self, count: 32)
        let merkleRoot = byteStream.read(Data.self, count: 32)
        let timestamp = byteStream.read(UInt32.self)
        let bits = byteStream.read(UInt32.self)
        let nonce = byteStream.read(UInt32.self)
        let transactionCount = byteStream.read(VarInt.self)
        var transactions = [Transaction]()
        for _ in 0..<transactionCount.underlyingValue {
            transactions.append(Transaction.deserialize(byteStream))
        }
        return Block(version: version, prevBlock: prevBlock, merkleRoot: merkleRoot, timestamp: timestamp, bits: bits, nonce: nonce, transactionCount: transactionCount, transactions: transactions, height: unknownHeight)
    }
}
