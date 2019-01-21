//
//  MerkleBlockMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/09.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct MerkleBlockMessage: Message {
    static let maxProofOfWork = UInt256(data: Data(hex: "00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff")!)!
    static var command: String {
        return "merkleblock"
    }
    let version: Int32
    let prevBlock: Data
    let merkleRoot: Data
    let timestamp: UInt32
    let bits: UInt32
    let nonce: UInt32
    let totalTransactions: UInt32
    let hashCount: VarInt
    let hashes: [Data]
    let flagBytes: VarInt
    let flags: [UInt8]
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
        data += totalTransactions
        data += hashCount.serialized()
        data += hashes.flatMap { $0 }
        data += flagBytes.serialized()
        data += flags
        return data
    }

    static func deserialize(_ data: Data) -> MerkleBlockMessage {
        let byteStream = ByteStream(data)
        let version = byteStream.read(Int32.self)
        let prevBlock = byteStream.read(Data.self, count: 32)
        let merkleRoot = byteStream.read(Data.self, count: 32)
        let timestamp = byteStream.read(UInt32.self)
        let bits = byteStream.read(UInt32.self)
        let nonce = byteStream.read(UInt32.self)
        let totalTransactions = byteStream.read(UInt32.self)
        let hashCount = byteStream.read(VarInt.self)
        var hashes = [Data]()
        for _ in 0..<hashCount.underlyingValue {
            hashes.append(byteStream.read(Data.self, count: 32))
        }
        let flagBytes = byteStream.read(VarInt.self)
        var flags = [UInt8]()
        for _ in 0..<flagBytes.underlyingValue {
            flags.append(byteStream.read(UInt8.self))
        }
        return MerkleBlockMessage(version: version, prevBlock: prevBlock, merkleRoot: merkleRoot, timestamp: timestamp, bits: bits, nonce: nonce, totalTransactions: totalTransactions, hashCount: hashCount, hashes: hashes, flagBytes: flagBytes, flags: flags, height: Block.unknownHeight)
    }

    func isValid() -> Bool {
        guard hashCount.underlyingValue == hashes.count else {
            return false
        }
        guard flagBytes.underlyingValue == flags.count else {
            return false
        }
        guard isValidProofOfWork() else {
            return false
        }
        do {
            guard try calculateMerkleRoot() == merkleRoot else {
                return false
            }
            return true
        } catch let error {
            print(error)
            return false
        }
    }

    private func isValidProofOfWork() -> Bool {
        let target: UInt256
        do {
            target = try UInt256(compact: bits)
        } catch UInt256.CompactError.error(let message) {
            print("compact parse error: \(message)")
            return false
        } catch let error {
            print(error.localizedDescription)
            return false
        }
        guard target != UInt256.zero && target <= MerkleBlockMessage.maxProofOfWork else {
            print("invalid target: \(target)")
            return false
        }
        guard let arithmeticHash = UInt256(data: blockHash) else {
            print("cannot parse blockhash into Uint256")
            return false
        }
        guard arithmeticHash <= target else {
            print("insufficient proof of work")
            return false
        }
        return true
    }

    private func calculateMerkleRoot() throws -> Data {
        let maxDepth: UInt = UInt(MerkleBlockMessage.ceilLog2(totalTransactions))
        var hashIterator = hashes.makeIterator()
        let boolFlag: [Bool] = (0..<Int(flagBytes.underlyingValue * 8)).compactMap {
            (flags[$0 / 8] & UInt8(1 << ($0 % 8))) != 0
        }
        var boolFlagIterator = boolFlag.makeIterator()
        let root = try buildPartialMerkleTree(hashIterator: &hashIterator, boolFlagIterator: &boolFlagIterator, depth: 0, maxDepth: maxDepth)
        return root.hash
    }

    private struct PartialMerkleTree {
        var hash: Data
        init(hash: Data) {
            self.hash = hash
        }
    }

    private func buildPartialMerkleTree(hashIterator: inout IndexingIterator<[Data]>, boolFlagIterator: inout IndexingIterator<[Bool]>, depth: UInt, maxDepth: UInt) throws -> PartialMerkleTree {
        guard let flag = boolFlagIterator.next() else {
            throw ProtocolError.error("flags is not enough size")
        }
        if !flag || depth == maxDepth {
            guard let hash = hashIterator.next() else {
                throw ProtocolError.error("hashes is not enough size")
            }
            return PartialMerkleTree(hash: hash)
        } else {
            let left = try buildPartialMerkleTree(hashIterator: &hashIterator, boolFlagIterator: &boolFlagIterator, depth: depth + 1, maxDepth: maxDepth)
            let right = (try? buildPartialMerkleTree(hashIterator: &hashIterator, boolFlagIterator: &boolFlagIterator, depth: depth + 1, maxDepth: maxDepth)) ?? left // if right branch is missing, duplicate left branch
            if left.hash == right.hash {
                guard hashIterator.next() == nil && boolFlagIterator.next() == nil else {
                    throw ProtocolError.error("should not iterate any more") // defend against (CVE-2012-2459)
                }
            }
            let hash = Crypto.sha256sha256(left.hash + right.hash)
            return PartialMerkleTree(hash: hash)
        }
    }

    private static func ceilLog2(_ x: UInt32) -> UInt32 {
        guard x > 0 else {
            return 0
        }
        var xx = x
        var r: UInt32 = (xx & (xx - 1)) != 0 ? 1 : 0
        while true {
            xx >>= 1
            if xx == 0 {
                break
            }
            r += 1
        }
        return r
    }
}
