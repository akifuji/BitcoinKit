//
//  PeerManager.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/08.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public class PeerManager {
    let database: Database
    let network: Network
    let maxConnections: Int
    var peers: [Peer] = []
    var lastBlock: Block?
    var pubkeys: [PublicKey] = []
    var nextCheckpointIndex: Int = 0

    public init(database: Database, network: Network = .testnet, maxConnections: Int = 1, pubkeys: [PublicKey] = []) {
        self.database = database
        self.network = network
        self.maxConnections = maxConnections
        self.pubkeys = pubkeys
        self.lastBlock = try! database.latestBlockHeader()
        if let currentHeight = lastBlock?.height {
            for (index, checkpoint) in network.checkpoints.enumerated() where currentHeight < checkpoint.height {
                self.nextCheckpointIndex = index
                break
            }
        }
    }

    public func start() {
        for _ in peers.count..<maxConnections {
            let peer = Peer(host: network.dnsSeeds[0], network: network)
            peer.delegate = self
            peer.connect()
            peers.append(peer)
        }
    }

    public func stop() {
        for peer in peers {
            peer.disconnect()
        }
    }

    func loadBloomFilter() {
        let tweak = arc4random_uniform(UInt32.max)
        var bloomFilter = BloomFilter(elementCount: pubkeys.count * 2, randomNonce: tweak)
        for pubkey in pubkeys {
            bloomFilter.insert(pubkey.data)
            bloomFilter.insert(pubkey.pubkeyHash)
        }
        for peer in peers {
            peer.sendFilterLoadMessage(bloomFilter)
        }
    }

    func generateGetblock() {
        let hash = Data(Data(hex: "0000000000290f8d9b99569c715ca46f68d408a449b3016192df0be5526bc682")!.reversed())
        let inventory = InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: hash)
        for peer in peers {
            peer.sendGetDataMessage([inventory])
        }
    }
}

extension PeerManager: PeerDelegate {
    func peerDidDisconnect(_ peer: Peer) {
        start()
    }

    func peerDidHandShake(_ peer: Peer) {
        if let lastBlock = lastBlock {
            let remoteNodeHeight = peer.context.remoteNodeHeight
            guard remoteNodeHeight + 10 > lastBlock.height else {
                print("node isn't synced")
                peer.disconnect()
                peerDidDisconnect(peer)
                return
            }
            if lastBlock.height >= remoteNodeHeight {
                loadBloomFilter()
                return
            }
        }
        // start blockchain sync
        peer.sendGetHeadersMessage(blockHash: lastBlock?.blockHash ?? Data(count: 32))
    }

    func peer(_ peer: Peer, didReceiveBlockHeaders blockHeaders: [Block]) {
        if lastBlock == nil || peer.context.remoteNodeHeight > lastBlock!.height + UInt32(blockHeaders.count) {
            guard let lastBlockHeader = blockHeaders.last else {
                print("header message carries zero headers")
                peer.disconnect()
                return
            }
            peer.sendGetHeadersMessage(blockHash: lastBlockHeader.blockHash)
        } else {
            // load bloom filter if we're done syncing
            print("sync done")
            loadBloomFilter()
        }
        for blockHeader in blockHeaders {
            if let lastBlock = lastBlock, lastBlock.blockHash != blockHeader.prevBlock {
                print("block hash does not match the prev block.")
                peer.disconnect()
                return
            }
            let blockHeight = (lastBlock?.height ?? 0) + 1
            if nextCheckpointIndex < network.checkpoints.count {
                let nextCheckpoint = network.checkpoints[nextCheckpointIndex]
                if blockHeight == nextCheckpoint.height {
                    guard blockHeader.blockHash == nextCheckpoint.hash else {
                        print("block hash does not match the checkpoint, height: \(blockHeight), blockhash: \(Data(blockHeader.blockHash.reversed()).hex)")
                        peer.disconnect()
                        return
                    }
                    self.nextCheckpointIndex = nextCheckpointIndex + 1
                }
            }
            try! database.addBlockHeader(blockHeader, hash: blockHeader.blockHash, height: blockHeight)
            lastBlock = blockHeader
            lastBlock!.height = blockHeight
        }
    }

    func peer(didReceiveTransaction transaction: Transaction) {
        guard isMyTransaction(transaction) else {
            print("transaction is irrelevant")
            return
        }
        if let transactionHeight = try! database.selectTransactionBlockHeight(hash: transaction.hash) {
            guard transactionHeight == Transaction.unconfirmed && transaction.blockHeight != Transaction.unconfirmed else {
                print("already-known transaction")
                return
            }
            try! database.updateTransactionBlockHeight(blockHeight: transaction.blockHeight, hash: transaction.hash)
            print("transaction updated")
        } else {
            try! database.addTransaction(transaction)
            print("new transaction found")
        }
        print("balance: \(try! database.calculateBalance(pubKeyHash: pubkeys[0].pubkeyHash))")
    }

    private func isMyTransaction(_ transaction: Transaction) -> Bool {
        // check whether tx represents spending coins
        let utxoHashes = try! database.selectUTXOHashes(pubKeyHash: pubkeys[0].pubkeyHash)
        for transacstionInput in transaction.inputs where utxoHashes.contains(transacstionInput.previousOutput.hash) {
            return true
        }
        // check whether tx represents getting coins
        let pubKeyHashes = pubkeys.map { $0.pubkeyHash }
        for transactionOutput in transaction.outputs {
            // TODO: check whether tx is P2PKH
            let pubKeyHash = Script.getPublicKeyHash(from: transactionOutput.lockingScript)
            if pubKeyHashes.contains(pubKeyHash) {
                return true
            }
        }
        return false
    }
}
