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
                                        lock_time INTEGER NOT NULL
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
                                    CREATE VIEW IF NOT EXISTS view_utxo AS
                                        SELECT tx.id, txout.pub_key_hash, txout.out_index, txout.value, txin.txout_id from tx
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
                                                (id, version, flag, tx_in_count, tx_out_count, lock_time)
                                                VALUES
                                                (?,     ?,     ?,        ?,            ?,          ?);
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
                                             SELECT id FROM view_utxo WHERE pub_key_hash == ?;
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

    public func addTransaction(_ transaction: Transaction, hash: Data) throws {
        let statement = statements["addTransaction"]
        try execute { hash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(hash.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: transaction.version))) }
        try execute { sqlite3_bind_int(statement, 3, 0) } // Not supported 'flag' currently
        try execute { sqlite3_bind_int64(statement, 4, sqlite3_int64(bitPattern: transaction.txInCount.underlyingValue)) }
        try execute { sqlite3_bind_int64(statement, 5, sqlite3_int64(bitPattern: transaction.txOutCount.underlyingValue)) }
        try execute { sqlite3_bind_int64(statement, 6, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: transaction.lockTime))) }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }

        for input in transaction.inputs {
            try addTransactionInput(input, txId: hash)
        }
        for (i, output) in transaction.outputs.enumerated() {
            try addTransactionOutput(index: i, output: output, txId: hash)
        }
    }

    public func addTransactionInput(_ input: TransactionInput, txId: Data) throws {
        let statement = statements["addTransactionInput"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: input.scriptLength.underlyingValue)) }
        try execute { input.signatureScript.withUnsafeBytes { sqlite3_bind_blob(statement, 2, $0, Int32(input.signatureScript.count), SQLITE_TRANSIENT) } }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: input.sequence))) }
        try execute { txId.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(txId.count), SQLITE_TRANSIENT) } }
        try execute { input.previousOutput.hash.withUnsafeBytes { sqlite3_bind_blob(statement, 5, $0, Int32(input.previousOutput.hash.count), SQLITE_TRANSIENT) } }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func addTransactionOutput(index: Int, output: TransactionOutput, txId: Data) throws {
        let statement = statements["addTransactionOutput"]
        try execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: index))) }
        try execute { sqlite3_bind_int64(statement, 2, sqlite3_int64(bitPattern: UInt64(truncatingIfNeeded: output.value))) }
        try execute { sqlite3_bind_int64(statement, 3, sqlite3_int64(bitPattern: output.scriptLength.underlyingValue)) }
        try execute { output.lockingScript.withUnsafeBytes { sqlite3_bind_blob(statement, 4, $0, Int32(output.lockingScript.count), SQLITE_TRANSIENT) } }
        try execute { txId.withUnsafeBytes { sqlite3_bind_blob(statement, 5, $0, Int32(txId.count), SQLITE_TRANSIENT) } }
        let pubKeyHash = Script.getPublicKeyHash(from: output.lockingScript)
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 6, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }

        try executeUpdate { sqlite3_step(statement) }
        try execute { sqlite3_reset(statement) }
    }

    public func calculateBalance(pubKeyHash: Data) throws -> Int64 {
        let statement = statements["calculateBalance"]
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }
        var balance: Int64 = 0
        while sqlite3_step(statement) == SQLITE_ROW {
            let value = sqlite3_column_int64(statement, 0)
            balance += value
        }

        try execute { sqlite3_reset(statement) }
        return balance
    }

    public func selectUTXOIDs(pubKeyHash: Data) throws -> [Data] {
        let statement = statements["selectUTXO"]
        try execute { pubKeyHash.withUnsafeBytes { sqlite3_bind_blob(statement, 1, $0, Int32(pubKeyHash.count), SQLITE_TRANSIENT) } }
        var txIDs = [Data]()
        while sqlite3_step(statement) == SQLITE_ROW {
            txIDs.append(Data(bytes: sqlite3_column_blob(statement, 0)!, count: 32))
        }
        try execute { sqlite3_reset(statement) }
        return txIDs
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
