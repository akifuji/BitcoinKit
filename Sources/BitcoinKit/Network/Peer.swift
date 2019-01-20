//
//  Peer.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation
import Network

private let protocolVersion: Int32 = 70_015
private let minimumProtocolVersion: Int32 = 70_011 // peers earlier than this protocol version does not support bloom filter

protocol PeerDelegate: class {
    func peerDidHandShake(_ peer: Peer)
    func peer(_ peer: Peer, didReceiveBlockHeaders blockHeaders: [Block])
    func peer(_ peer: Peer, didReceiveMerkleBkock merkleBlock: MerkleBlockMessage)
    func peer(_ peer: Peer, didReceiveGetData inventory: InventoryItem)
    func peer(didReceiveTransaction message: Transaction)
    func peerDidDisconnect(_ peer: Peer)
}

class Peer: NSObject {
    let network: Network
    let host: String
    let connection: NWConnection
    let context = Context()
    class Context {
        var packets = Data()
        var gotVersion = false
        var gotVerack = false
        var sentVersion = false
        var sentVerack = false
        var sentFilter = false
        var currentMerkleBlock: MerkleBlockMessage?
        var currentGotTxNumber: UInt32 = 0  // the number of gotten tx following a merkle block
        var remoteNodeHeight: Int32 = -1
    }
    public weak var delegate: PeerDelegate?

    public init(host: String, network: Network = .testnet) {
        self.host = host
        self.network = network
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(network.port))!, using: .tcp)
    }

    public convenience init(network: Network = .testnet) {
        let dnsSeeds: [String] = network.dnsSeeds
        self.init(host: dnsSeeds[Int(arc4random_uniform(UInt32(dnsSeeds.count)))], network: network)
    }

    public func connect() {
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                self.log("Connection ready")
                self.startConnect()
            case .waiting(let error):
                self.log("Connection waiting: \(error)")
            case .failed(let error):
                self.log("Connection failed: \(error)")
            default:
                break
            }
        }
        readHead()
        log("Connecting: \(host):\(network.port)")
        connection.start(queue: .main)
    }

    private func readHead() {
        connection.receive(minimumIncompleteLength: MessageHeader.length, maximumLength: MessageHeader.length, completion: { [weak self] (data, _, _, error) in
            guard let strongSelf = self else {
                print("self is nil")
                return
            }
            if let error = error {
                strongSelf.log(error.debugDescription)
            }
            guard let _data = data, let messageHeader = MessageHeader.deserialize(_data) else {
                strongSelf.log("failed to deserialize messageHeader: \(String(describing: data?.hex))")
                return
            }
            let command: String = messageHeader.command
            let bodyLength = Int(messageHeader.length)
            if bodyLength > 0 {
                strongSelf.readBody(command: command, bodyLength: bodyLength)
            } else {
                if strongSelf.isSucceeededHandle(command: command, payload: Data()) {
                    strongSelf.readHead()
                } else {
                    strongSelf.disconnect()
                }
            }
        })
    }

    private func readBody(command: String, bodyLength: Int) {
        connection.receive(minimumIncompleteLength: bodyLength, maximumLength: bodyLength, completion: { [weak self] (data, _, _, error) in
            guard let strongSelf = self else {
                print("self is nil")
                return
            }
            if let error = error {
                strongSelf.log(error.debugDescription)
            }
            guard let data = data else {
                strongSelf.log("Data is nil")
                return
            }
            if strongSelf.isSucceeededHandle(command: command, payload: data) {
                strongSelf.readHead()
            } else {
                strongSelf.disconnect()
            }
        })
    }

    private func isSucceeededHandle(command: String, payload: Data) -> Bool {
        // if we receive a non-tx message, merkleblock is done
        if command != Transaction.command, let merkleBlock = context.currentMerkleBlock {
            log("incomplete merkleblock, expected \(merkleBlock.totalTransactions) txs, but got only \(context.currentGotTxNumber)")
            context.currentMerkleBlock = nil
            context.currentGotTxNumber = 0
        }
        do {
            switch command {
            case VersionMessage.command:
                try handleVersionMessage(payload: payload)
            case VerackMessage.command:
                try handleVerackMessage()
            case HeadersMessage.command:
                try handleHeadersMessage(payload: payload)
            case MerkleBlockMessage.command:
                handleMerkleblockMessage(payload: payload)
            case Transaction.command:
                handleTransactionMessage(payload: payload)
            case InventoryMessage.command:
                handleInventoryMessage(payload: payload)
            case GetDataMessage.command:
                handleGetDataMessage(payload: payload)
            case RejectMessage.command:
                handleRejectMessage(payload: payload)
            default:
                log("Other commands: \(command)")
            }
            return true
        } catch PeerError.error(let message) {
            log(message)
            return false
        } catch {
            return false
        }
    }

    private func startConnect() {
        print("start connect")
        if !context.sentVersion {
            sendVersionMessage()
            context.sentVersion = true
        }
    }

    public func disconnect() {
        log("disconnected")
        connection.cancel()
    }

    func sendMessage(_ message: Message) {
        let data = message.combineHeader(network.magic)
        connection.send(content: data, completion: .contentProcessed { [weak self] (sendError) in
            guard let strongSelf = self else {
                print("self is nil")
                return
            }
            if let sendError = sendError {
                strongSelf.log("SendError: \(sendError.debugDescription)")
            }
            strongSelf.log("send \(type(of: message).command) message")
        })
    }

    private func sendVersionMessage() {
        let versionMessage = VersionMessage(version: protocolVersion,
                                     services: 0x00,
                                     timestamp: Int64(Date().timeIntervalSince1970),
                                     yourAddress: NetworkAddress(service: 0x00, address: "::ffff:127.0.0.1", port: UInt16(network.port)),
                                     myAddress: NetworkAddress(service: 0x00, address: "::ffff:127.0.0.1", port: UInt16(network.port)),
                                     nonce: 0,
                                     userAgent: "/BitcoinKit:1.0.2/",
                                     startHeight: 0,
                                     relay: false)
        sendMessage(versionMessage)
    }

    private func sendVerackMessage() {
        let verackMessage = VerackMessage()
        sendMessage(verackMessage)
        context.sentVerack = true
    }

    func sendGetHeadersMessage(blockHash: Data) {
        let getHeadersMessage = GetHeadersMessage(version: UInt32(protocolVersion), hashCount: 1, blockLocatorHashes: blockHash, hashStop: Data(count: 32))
        sendMessage(getHeadersMessage)
    }

    func sendFilterLoadMessage(_ bloomFilter: BloomFilter) {
        let filterLoadMessage = FilterLoadMessage(filter: Data(bloomFilter.filters), hashFuncs: bloomFilter.hashFuncs, tweak: bloomFilter.tweak, flags: 0)
        sendMessage(filterLoadMessage)
        context.sentFilter = true
    }

    func sendGetDataMessage(_ inventoryItems: [InventoryItem]) {
        let getDataMessage = GetDataMessage(count: VarInt(inventoryItems.count), inventoryItems: inventoryItems)
        sendMessage(getDataMessage)
    }

    private func handleVersionMessage(payload: Data) throws {
        let versionMessage = try VersionMessage.deserialize(payload)
        guard versionMessage.version >= minimumProtocolVersion else {
            throw PeerError.error("protocol version \(versionMessage.version) not supported")
        }
        guard versionMessage.services & VersionMessage.nodeBloomService == VersionMessage.nodeBloomService else {
            throw PeerError.error("node doesn't support SPV mode")
        }
        guard let startHeight = versionMessage.startHeight else {
            throw PeerError.error("version message from this node should have startHeight")
        }
        log("got verversion: \(versionMessage.version), useragent: \(versionMessage.userAgent?.value ?? "")")
        context.gotVersion = true
        context.remoteNodeHeight = startHeight
        sendVerackMessage()
    }

    private func handleVerackMessage() throws {
        guard context.gotVersion && !context.gotVerack else {
            throw PeerError.error("got unexpected verack")
        }
        log("got verack. Handshake complete.")
        delegate?.peerDidHandShake(self)
    }

    private func handleHeadersMessage(payload: Data) throws {
        let headersMessage = try HeadersMessage.deserialize(payload)
        log("got \(headersMessage.count) header(s)")
        delegate?.peer(self, didReceiveBlockHeaders: headersMessage.headers)
    }

    private func handleMerkleblockMessage(payload: Data) {
        let merkleBlockMessage = MerkleBlockMessage.deserialize(payload)
        guard merkleBlockMessage.isValid() else {
            print(payload.hex)
            log("malformed merkleblock message")
            return
        }
        guard context.sentFilter else {
            log("got merkleblock message before loading filter")
            return
        }
        log("got merkleblock")
        delegate?.peer(self, didReceiveMerkleBkock: merkleBlockMessage)
    }

    private func handleTransactionMessage(payload: Data) {
        let tx = Transaction.deserialize(payload)
        guard context.sentFilter else {
            log("got tx message before loading filter")
            return
        }
        log("got tx \(payload.hex)")
        if let merkleBlock = context.currentMerkleBlock {
            guard merkleBlock.hashes.contains(tx.hash) else {
                log("tx hash is out of merkle block hashes")
                return
            }
            context.currentGotTxNumber += 1
            if context.currentGotTxNumber == merkleBlock.totalTransactions {
                log("txs following a merkle block has completed")
                context.currentMerkleBlock = nil
                context.currentGotTxNumber = 0
            }
        }
        delegate?.peer(didReceiveTransaction: tx)
    }

    private func handleInventoryMessage(payload: Data) {
        let inventory = InventoryMessage.deserialize(payload)
        guard context.sentFilter else {
            log("got inv message before loading a filter")
            return
        }
        log("got inv with \(inventory.count.underlyingValue) item(s)")
        for item in inventory.inventoryItems {
            let type = InventoryItem.ObjectType(rawValue: item.type) ?? .unknown
            log("got \(type) type inv message")
            switch type {
            case .blockMessage:
                let sendItem = InventoryItem(type: InventoryItem.ObjectType.filteredBlockMessage.rawValue, hash: item.hash)
                sendGetDataMessage([sendItem])
            case .transactionMessage:
                let sendItem = InventoryItem(type: InventoryItem.ObjectType.transactionMessage.rawValue, hash: item.hash)
                sendGetDataMessage([sendItem])
            default:
                break
            }
        }
    }

    private func handleGetDataMessage(payload: Data) {
        let getData = GetDataMessage.deserialize(payload)
        log("got getdata with \(getData.count.underlyingValue) item(s)")
        for inventoryItem in getData.inventoryItems {
            delegate?.peer(self, didReceiveGetData: inventoryItem)
        }
    }

    private func handleRejectMessage(payload: Data) {
        let reject = RejectMessage.deserialize(payload)
        let message = reject.message.description
        let reason = reject.reason.description
        log("rejected \(message): reason: \(reason)")
    }

    private enum PeerError: Error {
        case error(String)
    }

    func log(_ message: String) {
        print("\(message)")
    }
}
