//
//  SQLiteDatabase.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/07.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import SQLite3
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public protocol Database {
    // Block Header
    func addBlockHeader(_ blockHeader: Block, height: UInt32) throws
    func latestBlockHeader() throws -> Block?
    func selectBlockHeight(hash: Data) throws -> UInt32?
    func selectBlockHashes(from height: UInt32) throws -> [Data]   // get block hashes to latest block
    // UTXO
    func addUTXO(utxo: UnspentTransactionOutput) throws
    func unspentTransactionOutputs() throws -> [UnspentTransactionOutput]
    func selectUTXO(pubKeyHash: Data) throws -> [UnspentTransactionOutput]
    func calculateBalance(pubKeyHash: Data) throws -> UInt64
    // Payment
    func addPayment(_ payment: Payment) throws
    func payments() throws -> [Payment]
    func selectPaymentHeight(txID: Data) throws -> UInt32?
    func updatePaymentHeight(txID: Data, height: UInt32) throws
}

public class SQLiteDatabase: Database {
    public static func `default`() throws -> SQLiteDatabase {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return try SQLiteDatabase(file: cachesDirectory.appendingPathComponent("blockchain.sqlite"))
    }

    private var database: OpaquePointer?
    public var statements = [String: OpaquePointer]()

    public init(file: URL) throws {
        try execute { sqlite3_open(file.path, &database) }
        try execute { sqlite3_exec(database,
                                   """
                                    CREATE TABLE IF NOT EXISTS block_headers (
                                        id BLOB NOT NULL PRIMARY KEY,
                                        version INTEGER NOT NULL,
                                        prev_block BLOB NOT NULL,
                                        merkle_root BLOB NOT NULL,
                                        timestamp INTEGER NOT NULL,
                                        bits INTEGER NOT NULL,
                                        nonce INTEGER NOT NULL,
                                        tx_count INTEGER NOT NULL,
                                        height INTEGER NOT NULL
                                    );
                                    CREATE TABLE IF NOT EXISTS utxos (
                                        id BLOB NOT NULL PRIMARY KEY,
                                        out_index INTEGER NOT NULL,
                                        value INTEGER NOT NULL,
                                        locking_script BLOB NOT NULL,
                                        pubkey_hash BLOB NOT NULL,
                                        lock_time BLOB NOT NULL
                                    );
                                    CREATE TABLE IF NOT EXISTS payments (
                                        id BLOB NOT NULL PRIMARY KEY,
                                        direction BLOB NOT NULL,
                                        amount INTEGER NOT NULL,
                                        block_height INTEGER NOT NULL
                                    );
                                   """,
                                   nil,
                                   nil,
                                   nil)
        }
        statements["addBlockHeader"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             REPLACE INTO block_headers
                                                (id, version, prev_block, merkle_root, timestamp, bits, nonce, tx_count, height)
                                                VALUES
                                                (?,     ?,        ?,            ?,         ?,      ?,     ?,       ?,       ?);
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
        }()
        statements["latestBlockHeader"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT * FROM block_headers ORDER BY height DESC LIMIT 1 ;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["selectBlockHeight"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT height FROM block_headers WHERE id == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["selectBlockHashes"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT id FROM block_headers WHERE height >= ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["addUTXO"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             REPLACE INTO utxos
                                                (id, out_index, value, locking_script, pubkey_hash, lock_time)
                                                VALUES
                                                (?,    ?,     ?,          ?,            ?,          ?);
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["unspentTransactions"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT * FROM utxos;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["calculateBalance"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT value FROM utxos;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["selectUTXO"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT * FROM utxos WHERE pubkey_hash == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["addPayment"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             REPLACE INTO payments
                                                (id, direction, amount, block_height)
                                                VALUES
                                                (?,      ?,       ?,         ?);
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
        }()
        statements["payments"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT * FROM payments;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["selectPaymentHeight"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT block_height FROM payments WHERE id == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
        }()
        statements["updatePaymentHeight"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             UPDATE payments SET block_height = ? WHERE id == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
        }()
    }

    deinit {
        for statement in statements.values {
            try! execute { sqlite3_finalize(statement) }
        }
        try! execute { sqlite3_close(database) }
    }

    // MARK: Block Header

    public func addBlockHeader(_ blockHeader: Block, height: UInt32) throws {
        let statement = statements["addBlockHeader"]
        let hash = blockHeader.blockHash
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: blockHeader.version))) }
        try execute { blockHeader.prevBlock.withUnsafeBytes { sqlite3_bind_blob(statement, 3, $0, Int32(blockHeader.prevBlock.count), SQLITE_TRANSIENT) } }
        try execute { blockHeader.merkleRoot.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(blockHeader.merkleRoot.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 5, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: blockHeader.timestamp))) }
        try execute { sqlite3_bind_int64(statement, 6, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: blockHeader.bits))) }
        try execute { sqlite3_bind_int64(statement, 7, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: blockHeader.nonce))) }
        try execute { sqlite3_bind_int64(statement, 8, sqlite3_int64(bitPattern: blockHeader.transactionCount.underlyingValue)) }
        try execute { sqlite3_bind_int64(statement, 9, sqlite3_int64(bitPattern: UInt64(height))) }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func latestBlockHeader() throws -> Block? {
        let statement = statements["latestBlockHeader"]
        var block: Block?
        if sqlite3_step(statement) == SQLITE_ROW {
            let version = Int32(sqlite3_column_int64(statement, 1))
            guard let prevBlock = sqlite3_column_blob(statement, 2) else {
                return nil
            }
            guard let merkleRoot = sqlite3_column_blob(statement, 3) else {
                return nil
            }
            let timestamp = UInt32(sqlite3_column_int64(statement, 4))
            let bits = UInt32(sqlite3_column_int64(statement, 5))
            let nonce = UInt32(sqlite3_column_int64(statement, 6))
            let transactionCount = VarInt(UInt64(sqlite3_column_int64(statement, 7)))
            let height = UInt32(sqlite3_column_int64(statement, 8))
            block = Block(version: version, prevBlock: Data(bytes: prevBlock, count: 32), merkleRoot: Data(bytes: merkleRoot, count: 32), timestamp: timestamp, bits: bits, nonce: nonce, transactionCount: transactionCount, transactions: [], height: height)
        }
        try execute { sqlite3_reset(statement) }
        return block
    }

    public func selectBlockHeight(hash: Data) throws -> UInt32? {
        let statement = statements["selectBlockHeight"]
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        var height: UInt32?
        if sqlite3_step(statement) == SQLITE_ROW {
            height = UInt32(sqlite3_column_int64(statement, 1))
        }
        try execute { sqlite3_reset(statement) }
        return height
    }

    public func selectBlockHashes(from height: UInt32) throws -> [Data] {
        let statement = statements["selectBlockHashes"]
        try execute { sqlite3_bind_int(statement, 1, Int32(height)) }
        var hashes = [Data]()
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let hash = sqlite3_column_blob(statement, 0) else {
                continue
            }
            hashes.append(Data(bytes: hash, count: 32))
        }
        try execute { sqlite3_reset(statement) }
        return hashes
    }

    // MARK: UTXO

    public func addUTXO(utxo: UnspentTransactionOutput) throws {
        let statement = statements["addUTXO"]
        let hash = utxo.hash
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: utxo.index))) }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: utxo.value))) }
        let lockingScript = utxo.lockingScript
        try execute { lockingScript.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(lockingScript.count), SQLITE_TRANSIENT) } }
        let pubkeyHash = utxo.pubkeyHash
        try execute { pubkeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 5, $0, Int32(pubkeyHash.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 6, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: utxo.lockTime))) }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func unspentTransactionOutputs() throws -> [UnspentTransactionOutput] {
        let statement = statements["unspentTransactionOutputs"]
        var utxos = [UnspentTransactionOutput]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let hash = Data(bytes: sqlite3_column_blob(statement, 0)!, count: 32)
            let index = UInt32(sqlite3_column_int64(statement, 1))
            let value = UInt64(sqlite3_column_int64(statement, 2))
            let scriptLength = Int(sqlite3_column_bytes(statement, 3))
            let script = Data(bytes: sqlite3_column_blob(statement, 3)!, count: scriptLength)
            let pubkeyHash = Data(bytes: sqlite3_column_blob(statement, 4)!, count: 20)
            let lockTime = UInt32(sqlite3_column_int64(statement, 5))
            utxos.append(UnspentTransactionOutput(hash: hash, index: index, value: value, lockingScript: script, pubkeyHash: pubkeyHash, lockTime: lockTime))
        }
        try execute { sqlite3_reset(statement) }
        return utxos
    }

    public func selectUTXO(pubKeyHash: Data) throws -> [UnspentTransactionOutput] {
        let statement = statements["selectUTXO"]
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }
        var utxos = [UnspentTransactionOutput]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let hash = Data(bytes: sqlite3_column_blob(statement, 0)!, count: 32)
            let index = UInt32(sqlite3_column_int64(statement, 1))
            let value = UInt64(sqlite3_column_int64(statement, 2))
            let scriptLength = Int(sqlite3_column_bytes(statement, 3))
            let script = Data(bytes: sqlite3_column_blob(statement, 3)!, count: scriptLength)
            let lockTime = UInt32(sqlite3_column_int64(statement, 4))
            utxos.append(UnspentTransactionOutput(hash: hash, index: index, value: value, lockingScript: script, pubkeyHash: pubKeyHash, lockTime: lockTime))
        }
        try execute { sqlite3_reset(statement) }
        return utxos
    }

    public func calculateBalance(pubKeyHash: Data) throws -> UInt64 {
        let statement = statements["calculateBalance"]
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }
        var balance: UInt64 = 0
        while sqlite3_step(statement) == SQLITE_ROW {
            balance += UInt64(sqlite3_column_int64(statement, 0))
        }
        try execute { sqlite3_reset(statement) }
        return balance
    }

    // MARK: Payment

    public func addPayment(_ payment: Payment) throws {
        let statement = statements["addPayment"]
        let txID = payment.txID
        try execute { txID.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(txID.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int(statement, 2, payment.direction.rawValue) }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(payment.amount)) }
        try execute { sqlite3_bind_int64(statement, 4, sqlite3_int64(payment.blockHeight)) }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func payments() throws -> [Payment] {
        let statement = statements["payments"]
        var payments = [Payment]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let txID = Data(bytes: sqlite3_column_blob(statement, 0)!, count: 32)
            guard let direction = Payment.Direction(rawValue: Int32(sqlite3_column_int64(statement, 1))) else {
                break
            }
            let amount = UInt64(sqlite3_column_int64(statement, 2))
            let blockHeight = UInt32(sqlite3_column_int64(statement, 3))
            payments.append(Payment(txID: txID, direction: direction, amount: amount, blockHeight: blockHeight))
        }
        try execute { sqlite3_reset(statement) }
        return payments
    }

    public func selectPaymentHeight(txID: Data) throws -> UInt32? {
        let statement = statements["selectPaymentHeight"]
        try execute { txID.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(txID.count), SQLITE_TRANSIENT) } }
        var height: UInt32?
        if sqlite3_step(statement) == SQLITE_ROW {
            height = UInt32(sqlite3_column_int64(statement, 0))
        }
        try execute { sqlite3_reset(statement) }
        return height
    }

    public func updatePaymentHeight(txID: Data, height: UInt32) throws {
        let statement = statements["updatePaymentHeight"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: height))) }
        try execute { txID.withUnsafeBytes { sqlite3_bind_blob(statement, 2, $0, Int32(txID.count), SQLITE_TRANSIENT) } }
        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    // MARK: others

    private func execute(_ closure: () -> Int32) throws {
        let code = closure()
        if code != SQLITE_OK {
            throw SQLiteError.error(code)
        }
    }

    private func executeUpdate(_ closure: () -> Int32) throws {
        let code = closure()
        if code != SQLITE_DONE {
            throw SQLiteError.error(code)
        }
    }
}

enum SQLiteError: Error {
    case error(Int32)
}

#endif
