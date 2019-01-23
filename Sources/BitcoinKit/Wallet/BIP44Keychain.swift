//
//  BIP44Keychain.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/23.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

struct BIP44Keychain {
    private let masterKey: ExtendedPrivatekey
    private let network: Network
    private var purpose: UInt32 {
        return 44
    }
    private var coinType: UInt32 {
        return network == .mainnet ? 0 : 1
    }
    private var account: UInt32 {
        return 0
    }
    private enum Change: Int {
        case `internal`, external
    }

    init(seed: Data, network: Network) {
        self.init(masterKey: ExtendedPrivatekey(seed: seed, network: network), network: network)
    }

    init(mnemonic: [String], passphrase: String, network: Network) {
        let seed = Mnemonic.seed(mnemonic: mnemonic, passphrase: passphrase)
        self.init(seed: seed, network: network)
    }

    private init(masterKey: ExtendedPrivatekey, network: Network) {
        self.masterKey = masterKey
        self.network = network
    }

    func receiveKey(index: UInt32) -> PrivateKey {
        do {
            return try derivedKey(path: "m/\(purpose)'/\(coinType)'/\(account)'/\(Change.internal.rawValue)/\(index)").privateKey
        } catch {
            fatalError("Cannot initiate receivePrivateKey")
        }
    }

    func changeKey(index: UInt32) -> PrivateKey {
        do {
            return try derivedKey(path: "m/\(purpose)'/\(coinType)'/\(account)'/\(Change.external.rawValue)/\(index)").privateKey
        } catch {
            fatalError("Cannot initiate changePrivateKey")
        }
    }

    func keys(receiveIndexRange: Range<UInt32>, changeIndexRange: Range<UInt32>) -> [PrivateKey] {
        let receiveKeys: [PrivateKey] = receiveIndexRange.map { receiveKey(index: $0) }
        let changeKeys: [PrivateKey] = changeIndexRange.map { changeKey(index: $0) }
        return receiveKeys + changeKeys
    }

    /// Parses the BIP32 path and derives the chain of keychains accordingly.
    /// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
    /// The following paths are valid:
    ///
    /// "" (master key)
    /// "m" (master key)
    /// "/" (master key)
    /// "m/0'" (hardened child #0 of the master key)
    /// "/0'" (hardened child #0 of the master key)
    /// "0'" (hardened child #0 of the master key)
    /// "m/44'/1'/2'" (BIP44 testnet account #2)
    /// "/44'/1'/2'" (BIP44 testnet account #2)
    /// "44'/1'/2'" (BIP44 testnet account #2)
    ///
    /// The following paths are invalid:
    ///
    /// "m / 0 / 1" (contains spaces)
    /// "m/b/c" (alphabetical characters instead of numerical indexes)
    /// "m/1.2^3" (contains illegal characters)
    private func derivedKey(path: String) throws -> ExtendedPrivatekey {
        var key: ExtendedPrivatekey = masterKey
        var path: String = path
        if path == "" || path == "/" || path == "m" {
            return key
        }
        if path.contains("m/") {
            path = String(path.dropLast(2))
        }
        for chunk in path.split(separator: "/") {
            var hardened = false
            var indexText = chunk
            if chunk.contains("'") {
                hardened = true
                indexText = indexText.dropLast()
            }
            guard let index = UInt32(indexText) else {
                throw DerivationError.error("invalid path")
            }
            key = try key.derived(at: index, hardened: hardened)
        }
        return key
    }
}
