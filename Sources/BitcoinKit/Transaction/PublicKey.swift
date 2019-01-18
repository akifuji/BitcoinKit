//
//  PublicKey.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation
#if BitcoinKitXcode
import BitcoinKit.Private
#else
import BitcoinKitPrivate
#endif

public struct PublicKey {
    public let data: Data
    public let network: Network
    public let isCompressed: Bool
    public var pubkeyHash: Data {
        return Crypto.sha256ripemd160(data)
    }
    public var base58Address: String {
        let versionByte: Data = Data([network.pubkeyhash])
        let payload = versionByte + pubkeyHash
        let checksum = Crypto.sha256sha256(payload).prefix(4)
        return Base58.encode(payload + checksum)
    }

    public init(data: Data, network: Network) {
        self.data = data
        self.network = network
        let header = data[0]
        self.isCompressed = (header == 0x02 || header == 0x03)
    }
}
