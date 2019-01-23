//
//  PrivateKey.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation
#if BitcoinKitXcode
import BitcoinKit.Private
#else
import BitcoinKitPrivate
#endif

import Foundation

public struct PrivateKey {
    public let data: Data
    public let network: Network
    public let isPublicKeyCompressed: Bool

    public var wif: String {
        var payload: Data = Data([network.privatekey]) + data
        if isPublicKeyCompressed {
            // Add extra byte 0x01 in the end.
            payload += Int8(0x01)
        }
        let checksum: Data = Crypto.sha256sha256(payload).prefix(4)
        return Base58.encode(payload + checksum)
    }

    public var publicKey: PublicKey {
        let data = _Key.computePublicKey(fromPrivateKey: self.data, compression: isPublicKeyCompressed)
        return PublicKey(data: data, network: network)
    }

    public init(data: Data, network: Network = .testnet, isPublicKeyCompressed: Bool = true) {
        self.data = data
        self.network = network
        self.isPublicKeyCompressed = isPublicKeyCompressed
    }

    public init(network: Network = .testnet, isPublicKeyCompressed: Bool = true) {
        self.network = network
        self.isPublicKeyCompressed = isPublicKeyCompressed
        // Validate if vch is greater than or equal to max value
        func validate(_ vch: [UInt8]) -> Bool {
            let max: [UInt8] = [
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
                0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
                0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x40
            ]
            var isZero: Bool = true
            for byte in vch where byte != 0 {
                isZero = false
                break
            }
            if isZero {
                return false
            }
            for (index, byte) in vch.enumerated() {
                if byte < max[index] {
                    return true
                }
                if byte > max[index] {
                    return false
                }
            }
            return true
        }
        let count: Int = 32
        var key = Data(count: count)
        var status: Int32 = 0
        repeat {
            status = key.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0) }
        } while (status != 0 || !validate([UInt8](key)))
        self.data = key
    }

    public init(wif: String) throws {
        guard let decoded = Base58.decode(wif) else {
            throw PrivateKeyError.invalidFormat
        }
        let checksumDropped = decoded.dropLast(4)
        guard checksumDropped.count == (1 + 32) || checksumDropped.count == (1 + 32 + 1) else {
            throw PrivateKeyError.invalidFormat
        }
        // Check the first byte
        switch checksumDropped[0] {
        case Network.mainnet.privatekey:
            network = .mainnet
        case Network.testnet.privatekey:
            network = .testnet
        default:
            throw PrivateKeyError.invalidFormat
        }
        // Checksum checking
        let calculatedChecksum = Crypto.sha256sha256(checksumDropped).prefix(4)
        let originalChecksum = decoded.suffix(4)
        guard calculatedChecksum == originalChecksum else {
            throw PrivateKeyError.invalidFormat
        }
        //If the private key corresponded to a compressed public key, drop the last byte (it should be 0x01)
        isPublicKeyCompressed = (checksumDropped.count == (1 + 32 + 1))
        data = checksumDropped.dropFirst().prefix(32)
    }
}

extension PrivateKey: Equatable {
    // swiftlint:disable operator_whitespace
    public static func ==(lhs: PrivateKey, rhs: PrivateKey) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data && lhs.isPublicKeyCompressed == rhs.isPublicKeyCompressed
    }
}

extension PrivateKey: CustomStringConvertible {
    public var description: String {
        return data.hex
    }
}

public enum PrivateKeyError: Error {
    case invalidFormat
}
