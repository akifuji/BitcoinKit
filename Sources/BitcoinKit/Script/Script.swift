//
//  Script.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/12.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public class Script {
    // An array of Data objects (pushing data) or UInt8 objects (containing opcodes)
    private var chunks: [ScriptChunk]

    // Cached serialized representations for -data and -string methods.
    private var dataCache: Data?
    private var stringCache: String?

    public var data: Data {
        // When we calculate data from scratch, it's important to respect actual offsets in the chunks as they may have been copied or shifted in subScript* methods.
        if let cache = dataCache {
            return cache
        }
        dataCache = chunks.reduce(Data()) { $0 + $1.chunkData }
        return dataCache!
    }

    public var string: String {
        if let cache = stringCache {
            return cache
        }
        stringCache = chunks.map { $0.string }.joined(separator: " ")
        return stringCache!
    }

    public var hex: String {
        return data.hex
    }

    public func toP2SH() -> Script {
        return try! Script()
            .append(.OP_HASH160)
            .appendData(Crypto.sha256ripemd160(data))
            .append(.OP_EQUAL)
    }

    public init() {
        self.chunks = [ScriptChunk]()
    }

    public init(chunks: [ScriptChunk]) {
        self.chunks = chunks
    }

    public convenience init?(data: Data) {
        // It's important to keep around original data to correctly identify the size of the script for BTC_MAX_SCRIPT_SIZE check
        // and to correctly calculate hash for the signature because in BitcoinQT scripts are not re-serialized/canonicalized.
        do {
            let chunks = try Script.parseData(data)
            self.init(chunks: chunks)
        } catch let error {
            print(error)
            return nil
        }
    }

    public convenience init?(hex: String) {
        guard let scriptData = Data(hex: hex) else {
            return nil
        }
        self.init(data: scriptData)
    }

    private static func parseData(_ data: Data) throws -> [ScriptChunk] {
        guard !data.isEmpty else {
            return [ScriptChunk]()
        }

        var chunks = [ScriptChunk]()

        var i: Int = 0
        let count: Int = data.count

        while i < count {
            // Exit if failed to parse
            let chunk = try ScriptChunkHelper.parseChunk(from: data, offset: i)
            chunks.append(chunk)
            i += chunk.range.count
        }
        return chunks
    }

    public var isPublicKeyScript: Bool {
        guard chunks.count == 2 else {
            return false
        }
        guard let pushdata = pushedData(at: 0) else {
            return false
        }
        return pushdata.count > 1 && opcode(at: 1) == OpCode.OP_CHECKSIG
    }

    public var isPayToPublicKeyHashScript: Bool {
        guard chunks.count == 5 else {
            return false
        }
        guard let dataChunk = chunk(at: 2) as? DataChunk else {
            return false
        }
        return opcode(at: 0) == OpCode.OP_DUP
            && opcode(at: 1) == OpCode.OP_HASH160
            && dataChunk.range.count == 21
            && opcode(at: 3) == OpCode.OP_EQUALVERIFY
            && opcode(at: 4) == OpCode.OP_CHECKSIG
    }

    public var isPayToScriptHashScript: Bool {
        guard chunks.count == 3 else {
            return false
        }
        return opcode(at: 0) == OpCode.OP_HASH160
            && pushedData(at: 1)?.count == 20 // this is enough to match the exact byte template, any other encoding will be larger.
            && opcode(at: 2) == OpCode.OP_EQUAL
    }

    // Returns true if the script ends with P2SH check.
    // Not used in CoreBitcoin. Similar code is used in bitcoin-ruby. I don't know if we'll ever need it.
    public var endsWithPayToScriptHash: Bool {
        guard chunks.count >= 3 else {
            return false
        }
        return opcode(at: -3) == OpCode.OP_HASH160
            && pushedData(at: -2)?.count == 20
            && opcode(at: -1) == OpCode.OP_EQUAL
    }

    public var isStandardOpReturnScript: Bool {
        guard chunks.count == 2 else {
            return false
        }
        return opcode(at: 0) == .OP_RETURN
            && pushedData(at: 1) != nil
    }

    public func standardOpReturnData() -> Data? {
        guard isStandardOpReturnScript else {
            return nil
        }
        return pushedData(at: 1)
    }

    // Include both PUSHDATA ops and OP_0..OP_16 literals.
    public var isDataOnly: Bool {
        return !chunks.contains { $0.opcodeValue > OpCode.OP_16 }
    }

    public var scriptChunks: [ScriptChunk] {
        return chunks
    }

    private func update(with updatedData: Data) throws {
        let updatedChunks = try Script.parseData(updatedData)
        chunks = updatedChunks
        dataCache = nil
        stringCache = nil
    }

    @discardableResult
    public func append(_ opcode: OpCode) throws -> Script {
        let invalidOpCodes: [OpCode] = [.OP_PUSHDATA1,
                                        .OP_PUSHDATA2,
                                        .OP_PUSHDATA4,
                                        .OP_INVALIDOPCODE]
        guard !invalidOpCodes.contains(where: { $0 == opcode }) else {
            throw ScriptError.error("\(opcode.name) cannot be executed alone.")
        }
        var updatedData: Data = data
        updatedData += opcode
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func appendData(_ newData: Data) throws -> Script {
        guard !newData.isEmpty else {
            throw ScriptError.error("Data is empty.")
        }

        guard let addedScriptData = ScriptChunkHelper.scriptData(for: newData, preferredLengthEncoding: -1) else {
            throw ScriptError.error("Parse data to pushdata failed.")
        }
        var updatedData: Data = data
        updatedData += addedScriptData
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func appendScript(_ otherScript: Script) throws -> Script {
        guard !otherScript.data.isEmpty else {
            throw ScriptError.error("Script is empty.")
        }

        var updatedData: Data = self.data
        updatedData += otherScript.data
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func deleteOccurrences(of data: Data) throws -> Script {
        guard !data.isEmpty else {
            return self
        }

        let updatedData = chunks.filter { ($0 as? DataChunk)?.pushedData != data }.reduce(Data()) { $0 + $1.chunkData }
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func deleteOccurrences(of opcode: OpCode) throws -> Script {
        let updatedData = chunks.filter { $0.opCode != opcode }.reduce(Data()) { $0 + $1.chunkData }
        try update(with: updatedData)
        return self
    }

    public func subScript(from index: Int) throws -> Script {
        let subScript: Script = Script()
        for chunk in chunks[Range(index..<chunks.count)] {
            try subScript.appendData(chunk.chunkData)
        }
        return subScript
    }

    public func subScript(to index: Int) throws -> Script {
        let subScript: Script = Script()
        for chunk in chunks[Range(0..<index)] {
            try subScript.appendData(chunk.chunkData)
        }
        return subScript
    }

    // MARK: - Utility methods
    // Raise exception if index is out of bounds
    public func chunk(at index: Int) -> ScriptChunk {
        return chunks[index < 0 ? chunks.count + index : index]
    }

    // Returns an opcode in a chunk.
    // If the chunk is data, not an opcode, returns OP_INVALIDOPCODE
    // Raises exception if index is out of bounds.
    public func opcode(at index: Int) -> OpCode {
        let chunk = self.chunk(at: index)
        // If the chunk is not actually an opcode, return invalid opcode.
        guard chunk is OpcodeChunk else {
            return .OP_INVALIDOPCODE
        }
        return chunk.opCode
    }

    // Returns Data in a chunk.
    // If chunk is actually an opcode, returns nil.
    // Raises exception if index is out of bounds.
    public func pushedData(at index: Int) -> Data? {
        let chunk = self.chunk(at: index)
        return (chunk as? DataChunk)?.pushedData
    }

    public func execute(with context: ScriptExecutionContext) throws {
        for chunk in chunks {
            if let opChunk = chunk as? OpcodeChunk {
                try opChunk.opCode.execute(context)
            } else if let dataChunk = chunk as? DataChunk {
                if context.shouldExecute {
                    try context.pushToStack(dataChunk.pushedData)
                }
            } else {
                throw ScriptMachineError.error("Unknown chunk")
            }
        }

        guard context.conditionStack.isEmpty else {
            throw ScriptMachineError.error("Condition branches not balanced.")
        }
    }

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
