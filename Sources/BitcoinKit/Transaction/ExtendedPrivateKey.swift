//
//  ExtendedPrivateKey.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/23.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation
#if BitcoinKitXcode
import BitcoinKit.Private
#else
import BitcoinKitPrivate
#endif

struct ExtendedPrivatekey {
    let network: Network
    let depth: UInt8
    let fingerprint: UInt32
    let childIndex: UInt32
    let data: Data
    let chainCode: Data

    var privateKey: PrivateKey {
        return PrivateKey(data: data, network: network)
    }

    var extendedPublicKey: ExtendedPublicKey {
        let publicKey = _Key.computePublicKey(fromPrivateKey: data, compression: true)
        return ExtendedPublicKey(network: network, depth: depth, fingerprint: fingerprint, childIndex: childIndex, data: publicKey, chainCode: chainCode)
    }

    init(privateKey: Data, chainCode: Data, network: Network) {
        self.data = privateKey
        self.chainCode = chainCode
        self.network = network
        self.depth = 0
        self.fingerprint = 0
        self.childIndex = 0
    }

    init(seed: Data, network: Network) {
        let hmac = Crypto.hmacsha512(data: seed, key: "Bitcoin seed".data(using: .ascii)!)
        let privateKey = hmac[0..<32]
        let chainCode = hmac[32..<64]
        self.init(privateKey: privateKey, chainCode: chainCode, network: network)
    }

    init(privateKey: Data, chainCode: Data, network: Network, depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
        self.data = privateKey
        self.chainCode = chainCode
        self.network = network
        self.depth = depth
        self.fingerprint = fingerprint
        self.childIndex = childIndex
    }

    func serialized() -> String {
        var data = Data()
        data += network.xprivkey.bigEndian
        data += depth.littleEndian
        data += fingerprint.littleEndian
        data += childIndex.littleEndian
        data += chainCode
        data += UInt8(0)
        data += self.data
        return Base58.encode(data + data.checksum)
    }

    func derived(at index: UInt32, hardened: Bool = true) throws -> ExtendedPrivatekey {
        guard (0x80000000 & index) == 0 else {
            throw DerivationError.error("invalid child index")
        }
        guard let derivedKey = _HDKey(privateKey: data, publicKey: extendedPublicKey.data, chainCode: chainCode, depth: depth, fingerprint: fingerprint, childIndex: childIndex).derived(at: index, hardened: hardened) else {
            throw DerivationError.error("fail to deserialize")
        }
        return ExtendedPrivatekey(privateKey: derivedKey.privateKey!, chainCode: derivedKey.chainCode, network: network, depth: derivedKey.depth, fingerprint: derivedKey.fingerprint, childIndex: derivedKey.childIndex)
    }
}

extension ExtendedPrivatekey: CustomStringConvertible {
    var description: String {
        return serialized()
    }
}

enum DerivationError: Error {
    case error(String)
}
