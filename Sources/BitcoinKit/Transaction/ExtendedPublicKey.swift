//
//  ExtendedPublicKey.swift
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

struct ExtendedPublicKey {
    let network: Network
    let depth: UInt8
    let fingerprint: UInt32
    let childIndex: UInt32
    let data: Data
    let chainCode: Data

    var publicKey: PublicKey {
        return PublicKey(data: data, network: network)
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

    func derived(at index: UInt32) throws -> ExtendedPublicKey {
        guard (0x80000000 & index) == 0 else {
            throw DerivationError.error("invalid child index")
        }
        guard let derivedKey = _HDKey(privateKey: nil, publicKey: data, chainCode: chainCode, depth: depth, fingerprint: fingerprint, childIndex: childIndex).derived(at: index, hardened: true) else {
            throw DerivationError.error("fail to derive")
        }
        return ExtendedPublicKey(network: network, depth: derivedKey.depth, fingerprint: derivedKey.fingerprint, childIndex: derivedKey.childIndex, data: derivedKey.publicKey!, chainCode: derivedKey.chainCode)
    }
}

extension ExtendedPublicKey: CustomStringConvertible {
    var description: String {
        return serialized()
    }
}
