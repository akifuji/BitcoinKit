//
//  PeerManager.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/08.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public protocol PeerManagerDelegate: class {
    func balanceChanged(_ balance: UInt64)
    func paymentAdded(_ payment: Payment)
    func logged(_ log: PeerLog)
}

public class PeerManager {
    let database: Database
    let network: Network
    let maxConnections: Int
    var peers: [Peer] = []
    var lastBlock: Block?
    var pubkeys: [PublicKey] = []
    var nextCheckpointIndex: Int = 0
    var transactions = [Data: Transaction]()

    public weak var delegate: PeerManagerDelegate?

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
            let dnsSeeds: [String] = network.dnsSeeds
            let peer = Peer(host: dnsSeeds[Int(arc4random_uniform(UInt32(dnsSeeds.count)))], network: network)
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

    public func send(toAddress: String, amount: UInt64) {
        let txBuilder = TransactionBuilder()
        let pubkey = pubkeys[0]
        let utxos = try! database.selectUTXO(pubKeyHash: pubkey.pubkeyHash)
        let utxo = utxos.filter { $0.pubkeyHash == pubkeys[0].pubkeyHash }
        var transaction: Transaction!
        do {
            transaction = try txBuilder.buildTransaction(toAddress: toAddress, changeAddress: pubkey.base58Address, amount: amount, utxos: utxo, keys: [try! PrivateKey(wif: "cQ2BQqKL44d9az7JuUx8b1CSGx5LkQrTM7UQKjYGnrHiMX5nUn5C")])
        } catch TransactionBuilderError.error(let message) {
            print("failt to build tx: \(message)")
        } catch let error {
            print(error.localizedDescription)
        }
        transactions[transaction.txID] = transaction
        let inventory = InventoryMessage(count: 1, inventoryItems: [InventoryItem(type: InventoryItem.ObjectType.transactionMessage.rawValue, hash: transaction.txID)])
        print("txID: \(transaction.txID.hex)")
        for peer in peers {
            peer.sendMessage(inventory)
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
                print("last block hash does not match the prev block.")
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

    func peer(_ peer: Peer, didReceiveMerkleBkock merkleBlock: MerkleBlockMessage) {
        // assume that last block is the second newest one
        guard let lastBlock = lastBlock, lastBlock.blockHash == merkleBlock.prevBlock else {
            peer.log(PeerLog(message: "last block hash does not match the prev block of merkle block", type: .error))
            return
        }
        peer.context.currentMerkleBlock = merkleBlock
    }

    func peer(didReceiveTransaction transaction: Transaction) {
        guard let payment = convertToMyPayment(transaction) else {
            print("transaction is irrelevant")
            return
        }
        if let transactionHeight = try! database.selectTransactionBlockHeight(hash: transaction.hash) {
            guard transactionHeight == Transaction.unconfirmed && transaction.blockHeight != Transaction.unconfirmed else {
                print("already-known transaction. No need to update")
                return
            }
            try! database.updateTransactionBlockHeight(blockHeight: transaction.blockHeight, hash: transaction.hash)
            print("transaction updated")
        } else {
            try! database.addTransaction(transaction)
            try! database.addPayment(payment)
            print("new transaction found")
        }
        delegate?.paymentAdded(payment)
        let balance = try! database.calculateBalance(pubKeyHash: pubkeys[0].pubkeyHash)
        print("balance: \(balance)")
        delegate?.balanceChanged(balance)
    }

    func peer(_ peer: Peer, didReceiveGetData inventory: InventoryItem) {
        for (hash, tx) in transactions where hash == inventory.hash {
            peer.sendMessage(tx)
        }
    }

    private func convertToMyPayment(_ transaction: Transaction) -> Payment? {
        // sum sendAmount if tx input points to UTXO
        var sendAmount: UInt64 = 0
        let utxos = try! database.selectUTXO(pubKeyHash: pubkeys[0].pubkeyHash)
        for transacstionInput in transaction.inputs {
            sendAmount = utxos
                .filter { $0.hash == transacstionInput.previousOutput.hash }
                .reduce(0) { $0 + $1.value }
        }
        // sum receiveAmount if tx output contains my pubkey hash
        let pubKeyHashes = pubkeys.map { $0.pubkeyHash }
        let receiveAmount: UInt64 = transaction.outputs
            .filter { _ in true } // TODO: check whether tx is P2PKH
            .filter { pubKeyHashes.contains(Script.getPublicKeyHash(from: $0.lockingScript)) }
            .reduce(0) { $0 + $1.value }
        // return nil if tx is irrelevant
        guard sendAmount > 0 || receiveAmount > 0 else {
            return nil
        }
        let amount: UInt64 = receiveAmount - sendAmount
        let direction: Payment.Direction = amount > 0 ? .received : .sent
        return Payment(txID: transaction.txID, direction: direction, amount: amount)
    }

    func peer(_ peer: Peer, logged log: PeerLog) {
        delegate?.logged(log)
    }
}
