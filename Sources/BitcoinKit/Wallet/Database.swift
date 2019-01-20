//
//  BlockStore.swift
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

public class Database {
    public static func `default`() throws -> Database {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return try Database(file: cachesDirectory.appendingPathComponent("blockchain.sqlite"))
    }

    private var database: OpaquePointer?
    public var statements = [String: OpaquePointer]()

    public init(file: URL) throws {
        try execute { sqlite3_open(file.path, &database) }
        try execute { sqlite3_exec(database,
                                   """
                                    PRAGMA foreign_keys = ON;
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
                                    CREATE TABLE IF NOT EXISTS tx (
                                        id BLOB NOT NULL PRIMARY KEY,
                                        version INTEGER NOT NULL,
                                        flag INTEGER NOT NULL,
                                        tx_in_count INTEGER NOT NULL,
                                        tx_out_count INTEGER NOT NULL,
                                        lock_time INTEGER NOT NULL,
                                        block_height INTEGER NOT NULL
                                    );
                                    CREATE TABLE IF NOT EXISTS txin (
                                        script_length INTEGER NOT NULL,
                                        signature_script BLOB NOT NULL,
                                        sequence INTEGER NOT NULL,
                                        tx_id BLOB NOT NULL,
                                        txout_id BLOB NOT NULL,
                                        FOREIGN KEY(tx_id) REFERENCES tx(id)
                                    );
                                    CREATE TABLE IF NOT EXISTS txout (
                                        out_index INTEGER NOT NULL,
                                        value INTEGER NOT NULL,
                                        pk_script_length INTEGER NOT NULL,
                                        pk_script BLOB NOT NULL,
                                        tx_id BLOB NOT NULL,
                                        pub_key_hash BLOB,
                                        FOREIGN KEY(tx_id) REFERENCES tx(id)
                                    );
                                    CREATE TABLE IF NOT EXISTS payment (
                                        id BLOB NOT NULL PRIMARY KEY,
                                        direction BLOB NOT NULL,
                                        amount INTEGER NOT NULL,
                                        block_height INTEGER NOT NULL
                                    );
                                    CREATE VIEW IF NOT EXISTS view_utxo AS
                                        SELECT tx.id, txout.pub_key_hash, txout.out_index, txout.value, txout.pk_script, txin.txout_id from tx
                                        LEFT JOIN txout on id = txout.tx_id
                                        LEFT JOIN txin on id = txin.txout_id
                                        WHERE txout_id IS NULL;
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
        statements["addTransaction"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             REPLACE INTO tx
                                                (id, version, flag, tx_in_count, tx_out_count, lock_time, block_height)
                                                VALUES
                                                (?,     ?,     ?,        ?,            ?,          ?,          ?);
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
                                             REPLACE INTO payment
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
                                             SELECT * FROM payment;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["selectTransactionBlockHeight"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             SELECT block_height FROM tx WHERE id == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["updateTransactionBlockHeight"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             UPDATE tx SET block_height = ? WHERE id == ?;
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
            }()
        statements["addTransactionInput"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             INSERT INTO txin
                                                 (script_length, signature_script, sequence, tx_id, txout_id)
                                                 VALUES
                                                 (?,                     ?,           ?,        ?,     ?);
                                             """,
                                             -1,
                                             &statement,
                                             nil)
            }
            return statement
        }()
        statements["addTransactionOutput"] = try {
            var statement: OpaquePointer?
            try execute { sqlite3_prepare_v2(database,
                                             """
                                             INSERT INTO txout
                                                 (out_index, value, pk_script_length, pk_script, tx_id, pub_key_hash)
                                                 VALUES
                                                 (?,           ?,           ?,            ?,        ?,      ?);
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
                                             SELECT * FROM view_utxo WHERE pub_key_hash == ?;
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
                                             SELECT value FROM view_utxo WHERE pub_key_hash == ?;
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
                                             SELECT * FROM view_utxo WHERE pub_key_hash == ?;
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
    }

    deinit {
        for statement in statements.values {
            try! execute { sqlite3_finalize(statement) }
        }
        try! execute { sqlite3_close(database) }
    }

    public func addBlockHeader(_ blockHeader: Block, hash: Data, height: UInt32) throws {
        let statement = statements["addBlockHeader"]
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

    public func addTransaction(_ transaction: Transaction) throws {
        let statement = statements["addTransaction"]
        let hash = transaction.hash
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: transaction.version))) }
        try execute { sqlite3_bind_int(statement, 3, 0) } // Not supported 'flag' currently
        try execute { sqlite3_bind_int64(statement, 4, sqlite3_int64(bitPattern: transaction.txInCount.underlyingValue)) }
        try execute { sqlite3_bind_int64(statement, 5, sqlite3_int64(bitPattern: transaction.txOutCount.underlyingValue)) }
        try execute { sqlite3_bind_int64(statement, 6, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: transaction.lockTime))) }
        try execute { sqlite3_bind_int64(statement, 7, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: transaction.blockHeight))) }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }

        for input in transaction.inputs {
            try addTransactionInput(input, hash: hash)
        }
        for (i, output) in transaction.outputs.enumerated() {
            try addTransactionOutput(index: i, output: output, hash: hash)
        }
    }

    func addPayment(_ payment: Payment) throws {
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

    func selectTransactionBlockHeight(hash: Data) throws -> UInt32? {
        let statement = statements["selectTransactionBlockHeight"]
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        var blockHeight: UInt32?
        while sqlite3_step(statement) == SQLITE_ROW {
            blockHeight = UInt32(sqlite3_column_int64(statement, 0))
        }
        try execute { sqlite3_reset(statement) }
        return blockHeight
    }

    func updateTransactionBlockHeight(blockHeight: UInt32, hash: Data) throws {
        let statement = statements["updateTransactionBlockHeight"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: blockHeight))) }
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 2, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func addTransactionInput(_ input: TransactionInput, hash: Data) throws {
        let statement = statements["addTransactionInput"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: input.scriptLength.underlyingValue)) }
        try execute { input.signatureScript.withUnsafeBytes { sqlite3_bind_blob(statement, 2, $0, Int32(input.signatureScript.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: input.sequence))) }
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try execute { input.previousOutput.hash.withUnsafeBytes { sqlite3_bind_blob(statement, 5, $0, Int32(input.previousOutput.hash.count), SQLITE_TRANSIENT) } }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func addTransactionOutput(index: Int, output: TransactionOutput, hash: Data) throws {
        let statement = statements["addTransactionOutput"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: index))) }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: output.value))) }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(bitPattern: output.scriptLength.underlyingValue)) }
        try execute { output.lockingScript.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(output.lockingScript.count), SQLITE_TRANSIENT) } }
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 5, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        let pubKeyHash = Script.getPublicKeyHash(from: output.lockingScript)
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 6, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
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

    func selectUTXO(pubKeyHash: Data) throws -> [UnspentTransactionOutput] {
        let statement = statements["selectUTXO"]
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }
        var utxos = [UnspentTransactionOutput]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let hash = Data(bytes: sqlite3_column_blob(statement, 0)!, count: 32)
            let index = UInt32(sqlite3_column_int64(statement, 2))
            let value = UInt64(sqlite3_column_int64(statement, 3))
            let scriptLength = Int(sqlite3_column_bytes(statement, 4))
            let script = Data(bytes: sqlite3_column_blob(statement, 4)!, count: scriptLength)
            utxos.append(UnspentTransactionOutput(hash: hash, index: index, value: value, lockingScript: script, pubkeyHash: pubKeyHash))
        }
        try execute { sqlite3_reset(statement) }
        return utxos
    }

    func latestBlockHeader() throws -> Block? {
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
