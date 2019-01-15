//
//  VersionMessage.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/05.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct VersionMessage: Message {
    static let nodeBloomService: UInt64 = 0x04
    static var command: String {
      return "version"
    }
    let version: Int32
    let services: UInt64
    let timestamp: Int64
    let yourAddress: NetworkAddress
    // Fields below require version ≥ 106
    let myAddress: NetworkAddress?
    let nonce: UInt64?
    let userAgent: VarString?
    let startHeight: Int32?
    // Fields below require version ≥ 70001 
    let relay: Bool?

    func serialized() -> Data {
        var data = Data()
        data += version.littleEndian
        data += services.littleEndian
        data += timestamp.littleEndian
        data += yourAddress.serialized()
        data += myAddress?.serialized() ?? Data(count: 26)
        data += nonce?.littleEndian ?? UInt64(0)
        data += userAgent?.serialized() ?? Data()
        data += startHeight?.littleEndian ?? Int32(0)
        data += relay ?? true   // If this value is missing, true is the same meaning
        return data
    }

    static func deserialize(_ data: Data) throws -> VersionMessage {
        guard data.count >= 85 else {
            throw ProtocolError.error("malformed version message, length is \(data.count), should be >= 85")
        }
        let byteStream = ByteStream(data)
        let version = byteStream.read(Int32.self)
        let services = byteStream.read(UInt64.self)
        let timestamp = byteStream.read(Int64.self)
        let yourAddress = NetworkAddress.desirialize(byteStream)
        guard byteStream.availableBytes > 0 else {
            return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: nil, nonce: nil, userAgent: nil, startHeight: nil, relay: nil)
        }
        let myAddress = NetworkAddress.desirialize(byteStream)
        let nonce = byteStream.read(UInt64.self)
        let userAgent = byteStream.read(VarString.self)
        let startHeight = byteStream.read(Int32.self)
        guard byteStream.availableBytes > 0 else {
            return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: myAddress, nonce: nonce, userAgent: userAgent, startHeight: startHeight, relay: nil)
        }
        let relay = byteStream.read(Bool.self)
        return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: myAddress, nonce: nonce, userAgent: userAgent, startHeight: startHeight, relay: relay)
    }
}
