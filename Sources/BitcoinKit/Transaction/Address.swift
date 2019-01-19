//
//  Address.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public protocol Address {
    var network: Network { get }
}

public struct LegacyAddress: Address {
    public let network: Network

    public static func publicKeyHashToAddress(_ hash: Data) -> String {
        let checksum = Crypto.sha256sha256(hash).prefix(4)
        let address = Base58.encode(hash + checksum)
        return address
    }
}
