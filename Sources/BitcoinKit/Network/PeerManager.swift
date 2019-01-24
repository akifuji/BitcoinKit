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
    func lastCheckedBlockHeightUpdated(_ height: UInt32)
}

public class PeerManager {
    let database: Database
    let network: Network
    let maxConnections: Int
    var peers = [Peer]()
    var lastBlock: Block?
    var lastCheckedBlockHeight: UInt32? // have checked whether any payments exsist to this block
    var pubkeys = [PublicKey]()
    var pubkeyHashes: [Data] {
        return pubkeys.map { $0.pubkeyHash }
    }
    var nextCheckpointIndex: Int = 0
    var txsToBroadcast = [(tx: Transaction, sendAmount: UInt64)]() // save txs to broadcast till getting GetDataMessage from remote node

    public weak var delegate: PeerManagerDelegate?

    public init(database: Database, network: Network = .testnet, maxConnections: Int = 1, pubkeys: [PublicKey] = [], lastCheckedBlockHeight: UInt32?) {
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
        self.lastCheckedBlockHeight = lastCheckedBlockHeight
    }

    public func start() {
        peers.removeAll()
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

    private func loadBloomFilter() {
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

    private func sendGetBlockData(from peer: Peer) {
        guard let lastCheckedBlockHeight = lastCheckedBlockHeight, lastCheckedBlockHeight < peer.context.remoteNodeHeight else {
            return
        }
        let hashes = try! database.selectBlockHashes(from: lastCheckedBlockHeight)
        let inventoryItems: [InventoryItem] = hashes.map { InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: $0) }
        if inventoryItems.count <= GetDataMessage.maximumEntries {
            peer.sendGetDataMessage(inventoryItems)
        } else {
            let maxIndex: Int = inventoryItems.count / GetDataMessage.maximumEntries
            for index in 0...maxIndex {
                let end = index == maxIndex ? inventoryItems.count : (index + 1) * GetDataMessage.maximumEntries
                peer.sendGetDataMessage(Array(inventoryItems[index * GetDataMessage.maximumEntries..<end]))
            }
        }
        self.lastCheckedBlockHeight = UInt32(peer.context.remoteNodeHeight)
        delegate?.lastCheckedBlockHeightUpdated(UInt32(peer.context.remoteNodeHeight))
    }

    public func send(toAddress: String, amount: UInt64, changeAddress: String) {
        let txBuilder = TransactionBuilder()
        let utxos: [UnspentTransactionOutput] = pubkeyHashes
            .map { try! database.selectUTXO(pubKeyHash: $0) }
            .flatMap { $0 }
        var transaction: Transaction!
        do {
            let (utxosToSpend, fee) = try txBuilder.selectUTXOs(from: utxos, targetValue: amount)
            let totalAmount: UInt64 = utxosToSpend.sum()
            let change: UInt64 = totalAmount - amount - fee
            let destinations: [(String, UInt64)] = [(toAddress, amount), (pubkeys[0].base58Address, change)]
            transaction = try txBuilder.buildTransaction(destinations: destinations, utxos: utxos, keys: [try! PrivateKey(wif: "cQ2BQqKL44d9az7JuUx8b1CSGx5LkQrTM7UQKjYGnrHiMX5nUn5C")])
        } catch TransactionBuilderError.error(let message) {
            print("failt to build tx: \(message)")
        } catch let error {
            print(error.localizedDescription)
        }
        txsToBroadcast.append((tx: transaction, sendAmount: amount))
        let inventory = InventoryMessage(count: 1, inventoryItems: [InventoryItem(type: InventoryItem.ObjectType.transactionMessage.rawValue, hash: transaction.txID)])
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
                peer.log(PeerLog(message: "node isn't synced: height is \(remoteNodeHeight)", type: .other))
                peer.disconnect()
                return
            }
            // lastCheckedBlockHeight is nil when initializing wallet for the first time
            // txs need to be checked from that point
            if lastCheckedBlockHeight == nil {
                lastCheckedBlockHeight = UInt32(remoteNodeHeight)
            }
            if lastBlock.height >= remoteNodeHeight {
                loadBloomFilter()
                sendGetBlockData(from: peer)
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
            sendGetBlockData(from: peer)
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
            try! database.addBlockHeader(blockHeader, height: blockHeight)
            lastBlock = blockHeader
            lastBlock!.height = blockHeight
        }
    }

    func peer(_ peer: Peer, didReceiveMerkleBlock merkleBlock: MerkleBlockMessage) {
        peer.context.currentMerkleBlock = merkleBlock
        if let blockHeight = try! database.selectBlockHeight(hash: merkleBlock.blockHash) {
            peer.context.currentMerkleBlock?.height = blockHeight
        } else if let lastBlock = lastBlock, merkleBlock.prevBlock == lastBlock.blockHash {
            peer.context.currentMerkleBlock?.height = lastBlock.height + 1

        } else {
            peer.log(PeerLog(message: "the prev block of merkle block does not match", type: .error))
            peer.context.currentMerkleBlock = nil
        }
    }

    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction) {
        guard let merkleBlockHeight = peer.context.currentMerkleBlock?.height else {
            return
        }
        var isMyTransaction = false
        // check whether tx contains my utxos
        for input in transaction.inputs where try! database.deleteUTXO(pubkeyHash: input.previousOutput.hash) {
            isMyTransaction = true
        }
        // check whether tx contains new utxos
        var utxos = [UnspentTransactionOutput]()
        for (index, txOutput) in transaction.outputs.enumerated() {
            let lockingScript = txOutput.lockingScript
            guard Script.isP2PKHLockingScript(lockingScript) else {
                continue
            }
            let pubkeyHash = Script.getPublicKeyHash(from: lockingScript)
            guard pubkeyHashes.contains(pubkeyHash) else {
                continue
            }
            let utxo = UnspentTransactionOutput(hash: transaction.hash, index: UInt32(index), value: txOutput.value, lockingScript: lockingScript, pubkeyHash: pubkeyHash, lockTime: transaction.lockTime)
            try! database.addUTXO(utxo: utxo, height: merkleBlockHeight)
            utxos.append(utxo)
            isMyTransaction = true
        }
        guard isMyTransaction else {
            return  // tx is irrelevant
        }
        // check whether tx is known or unknown
        if let height = try! database.selectPaymentHeight(txID: transaction.txID) {
            guard merkleBlockHeight != height else {
                return // exactly same tx is already in DB
            }
            try! database.updatePaymentHeight(txID: transaction.txID, height: merkleBlockHeight)
            peer.log(PeerLog(message: "payment is confirmed", type: .other))
        } else {
            // unknown tx
            let receiveAmount = utxos.reduce(0) { $0 + $1.value }
            let payment = Payment(txID: transaction.txID, direction: .received, amount: receiveAmount, blockHeight: merkleBlockHeight)
            try! database.addPayment(payment)
            delegate?.paymentAdded(payment)
            peer.log(PeerLog(message: "found received tx", type: .other))
        }
    }

    func peer(_ peer: Peer, didReceiveGetData inventory: InventoryItem) {
        guard let objectType = InventoryItem.ObjectType(rawValue: inventory.type) else {
            peer.log(PeerLog(message: "malformed inv message: objecttype cannot be decoded", type: .error))
            return
        }
        switch objectType {
        case .transactionMessage:
            peer.log(PeerLog(message: "object type: transactionMessage, hash: \(inventory.hash.hex)", type: .from))
            for (offset: index, element: (tx: tx, sendAmount: amount)) in txsToBroadcast.enumerated() where tx.txID == inventory.hash {
                peer.sendMessage(tx)
                peer.log(PeerLog(message: "broadcasting txID: \(tx.txID.hex)", type: .to))
                let payment = Payment(txID: tx.txID, direction: .sent, amount: amount)
                try! database.addPayment(payment)
                delegate?.paymentAdded(payment)
                txsToBroadcast.remove(at: index)
            }
        default:
            peer.log(PeerLog(message: "inv object type: non-transactionMessage", type: .from))
        }
    }

    func peer(_ peer: Peer, logged log: PeerLog) {
        delegate?.logged(log)
    }
}
