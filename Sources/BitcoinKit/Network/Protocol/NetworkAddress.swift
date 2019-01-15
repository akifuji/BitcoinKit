//
//  NetworkAddress.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/05.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct NetworkAddress {
    public let service: UInt64
    public let address: String
    public let port: UInt16

    public func serialized() -> Data {
        var data = Data()
        data += service.littleEndian
        data += pton(address)
        data += port.bigEndian
        return data
    }

    static func desirialize(_ byteStream: ByteStream) -> NetworkAddress {
        let service = byteStream.read(UInt64.self)
        let address = parseIP(data: byteStream.read(Data.self, count: 16))
        let port = byteStream.read(UInt16.self)
        return NetworkAddress(service: service, address: address, port: port)
    }

    private func pton(_ address: String) -> Data {
        var addr = in6_addr()
        _ = withUnsafeMutablePointer(to: &addr) {
            inet_pton(AF_INET6, address, UnsafeMutablePointer($0))
        }
        var buffer = Data(count: 16)
        _ = buffer.withUnsafeMutableBytes { memcpy($0, &addr, 16) }
        return buffer
    }

    static private func parseIP(data: Data) -> String {
        let address: String = ipv6(from: data)
        if address.hasPrefix("0000:0000:0000:0000:0000:ffff") {
            return "0000:0000:0000:0000:0000:ffff:" + ipv4(from: data)
        } else {
            return address
        }
    }

    static private func ipv4(from data: Data) -> String {
        return Data(data.dropFirst(12)).map { String($0) }.joined(separator: ".")
    }

    static private func ipv6(from data: Data) -> String {
        return stride(from: 0, to: data.count - 1, by: 2).map { Data([data[$0], data[$0 + 1]]).hex }.joined(separator: ":")
    }

}
