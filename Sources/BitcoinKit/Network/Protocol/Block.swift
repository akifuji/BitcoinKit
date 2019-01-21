//
//  MerkleBlock.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct Block {
    static let unknownHeight: UInt32 = UINT32_MAX
    let version: Int32
    let prevBlock: Data
    let merkleRoot: Data
    let timestamp: UInt32
    let bits: UInt32
    let nonce: UInt32
    let transactionCount: VarInt
    let transactions: [Transaction]
    var height: UInt32

    var blockHash: Data {
        var data = Data()
        data += version
        data += prevBlock
        data += merkleRoot
        data += timestamp
        data += bits
        data += nonce
        return Data(Crypto.sha256sha256(data))
    }

    func serialized() -> Data {
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

    static func deserialize(_ data: Data) -> Block {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    static func deserialize(_ byteStream: ByteStream) -> Block {
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
