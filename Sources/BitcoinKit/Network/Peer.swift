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
    func peer(_ peer: Peer, didReceiveMerkleBlock merkleBlock: MerkleBlockMessage)
    func peer(_ peer: Peer, didReceiveGetData inventory: InventoryItem)
    func peer(_ peer: Peer, didReceiveTransaction message: Transaction)
    func peerDidDisconnect(_ peer: Peer)
    func peer(_ peer: Peer, logged log: PeerLog)
}

extension PeerDelegate {
    func peer(_ peer: Peer, logged log: PeerLog) {}
}

class Peer: NSObject {
    private let network: Network
    private let host: String
    private let connection: NWConnection
    let context = Context()
    class Context {
        var packets = Data()
        var gotVersion = false
        var gotVerack = false
        var sentVersion = false
        var sentVerack = false
        var sentFilter = false
        var currentMerkleBlock: MerkleBlockMessage?
        var remoteNodeHeight: Int32 = -1
    }
    weak var delegate: PeerDelegate?

    init(host: String, network: Network) {
        self.host = host
        self.network = network
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(network.port))!, using: .tcp)
    }

    func connect() {
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                self.log(PeerLog(message: "connection ready", type: .other))
                self.startConnect()
            case .waiting(let error):
                self.log(PeerLog(message: "connection waiting: \(error)", type: .error))
            case .failed(let error):
                self.log(PeerLog(message: "connection failed: \(error)", type: .error))
            default:
                break
            }
        }
        readHead()
        log(PeerLog(message: "connecting: \(host)", type: .other))
        connection.start(queue: .main)
    }

    private func readHead() {
        connection.receive(minimumIncompleteLength: MessageHeader.length, maximumLength: MessageHeader.length, completion: { [weak self] (data, _, _, error) in
            guard let strongSelf = self else {
                print("self is nil")
                return
            }
            if let error = error {
                strongSelf.log(PeerLog(message: error.debugDescription, type: .error))
            }
            guard let _data = data, let messageHeader = MessageHeader.deserialize(_data) else {
                strongSelf.log(PeerLog(message: "failed to deserialize messageHeader: \(String(describing: data?.hex))", type: .error))
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
                strongSelf.log(PeerLog(message: error.debugDescription, type: .error))
            }
            guard let data = data else {
                strongSelf.log(PeerLog(message: "data is nil", type: .error))
                return
            }
            if strongSelf.isSucceeededHandle(command: command, payload: data) {
                strongSelf.readHead()
            } else {
                strongSelf.disconnect()
            }
        })
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func isSucceeededHandle(command: String, payload: Data) -> Bool {
        // if we receive a non-tx message, merkleblock is done
        if context.currentMerkleBlock != nil && command != Transaction.command {
            context.currentMerkleBlock = nil
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
            case PingMessage.command:
                handlePingMessage(payload: payload)
            case RejectMessage.command:
                handleRejectMessage(payload: payload)
            default:
                log(PeerLog(message: "got \(command) message", type: .from))
            }
            return true
        } catch PeerError.error(let message) {
            log(PeerLog(message: message, type: .error))
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
        log(PeerLog(message: "disconnected", type: .other))
        connection.cancel()
        delegate?.peerDidDisconnect(self)
    }

    func sendMessage(_ message: Message) {
        let data = message.combineHeader(network.magic)
        connection.send(content: data, completion: .contentProcessed { [weak self] (sendError) in
            guard let strongSelf = self else {
                print("self is nil")
                return
            }
            if let sendError = sendError {
                strongSelf.log(PeerLog(message: "fail to send \(type(of: message).command): \(sendError.debugDescription)", type: .error))
            }
            strongSelf.log(PeerLog(message: "send \(type(of: message).command) message", type: .to))
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
        log(PeerLog(message: "got version: \(versionMessage.version) \(versionMessage.userAgent?.value ?? "")", type: .from))
        context.gotVersion = true
        context.remoteNodeHeight = startHeight
        sendVerackMessage()
    }

    private func handleVerackMessage() throws {
        guard context.gotVersion && !context.gotVerack else {
            throw PeerError.error("got unexpected verack")
        }
        log(PeerLog(message: "got verack. Handshake complete.", type: .from))
        delegate?.peerDidHandShake(self)
    }

    private func handleHeadersMessage(payload: Data) throws {
        let headersMessage = try HeadersMessage.deserialize(payload)
        log(PeerLog(message: "got \(headersMessage.count) header(s)", type: .from))
        delegate?.peer(self, didReceiveBlockHeaders: headersMessage.headers)
    }

    private func handleMerkleblockMessage(payload: Data) {
        let merkleBlockMessage = MerkleBlockMessage.deserialize(payload)
        guard merkleBlockMessage.isValid() else {
            print(payload.hex)
            log(PeerLog(message: "malformed merkleblock message", type: .error))
            return
        }
        guard context.sentFilter else {
            log(PeerLog(message: "got merkleblock message before loading filter", type: .from))
            return
        }
        log(PeerLog(message: "got merkleblock", type: .from))
        delegate?.peer(self, didReceiveMerkleBlock: merkleBlockMessage)
    }

    private func handleTransactionMessage(payload: Data) {
        let tx = Transaction.deserialize(payload)
        guard context.sentFilter else {
            log(PeerLog(message: "got tx message before loading filter", type: .error))
            return
        }
        log(PeerLog(message: "got tx, ID: \(tx.txID)", type: .from))
        delegate?.peer(self, didReceiveTransaction: tx)
    }

    private func handleInventoryMessage(payload: Data) {
        let inventory = InventoryMessage.deserialize(payload)
        guard context.sentFilter else {
            log(PeerLog(message: "got inv message before loading a filter", type: .error))
            return
        }
        log(PeerLog(message: "got inv with \(inventory.count.underlyingValue) item(s)", type: .from))
        for item in inventory.inventoryItems {
            let type = InventoryItem.ObjectType(rawValue: item.type) ?? .unknown
            log(PeerLog(message: "got \(type) type inv message", type: .from))
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
        log(PeerLog(message: "got getdata with \(getData.count.underlyingValue) item(s)", type: .from))
        for inventoryItem in getData.inventoryItems {
            delegate?.peer(self, didReceiveGetData: inventoryItem)
        }
    }

    private func handlePingMessage(payload: Data) {
        let ping = PingMessage.deserialize(payload)
        log(PeerLog(message: "got ping message", type: .from))
        let pong = PongMessage(nonce: ping.nonce)
        sendMessage(pong)
    }

    private func handleRejectMessage(payload: Data) {
        let reject = RejectMessage.deserialize(payload)
        let message = reject.message.description
        let reason = reject.reason.description
        log(PeerLog(message: "rejected \(message): reason: \(reason)", type: .error))
    }

    private enum PeerError: Error {
        case error(String)
    }

    func log(_ log: PeerLog) {
        print(log.message)
        delegate?.peer(self, logged: log)
    }
}

public struct PeerLog {
    public let message: String
    public let type: LogType
    public let date = Date()

    public enum LogType {
        case from, to, error, other
    }
}
