//
//  Network.swift
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

public class Network {
    public static let mainnet: Network = Mainnet()
    public static let testnet: Network = Testnet()
    public var name: String { return "" }
    var privatekeyVersionByte: UInt8 { return 0 }
    // version byte
    public var pubkeyhash: UInt8 { return 0 }
    // Network
    var magic: UInt32 { return 0 }
    public var port: UInt32 { return 0 }
    public var dnsSeeds: [String] { return [] }
    var genesisBlock: Data { return Data() }
    var checkpoints: [Checkpoint] { return [] }

    fileprivate init() {}
}

extension Network: Equatable {
    // swiftlint:disable operator_whitespace
    public static func ==(lhs: Network, rhs: Network) -> Bool {
        return lhs.name == rhs.name
    }
}

struct Checkpoint {
    let height: Int32
    let hash: Data
    let timestamp: UInt32
    let target: UInt32
}

extension Network: CustomStringConvertible {
    public var description: String {
        return name
    }
}

public class Mainnet: Network {
    public override var name: String {
        return "mainnet"
    }
    override public var pubkeyhash: UInt8 {
        return 0x00
    }
    override var privatekeyVersionByte: UInt8 {
        return 0x80
    }
    override var magic: UInt32 {
        return 0xf9beb4d9
    }
    public override var port: UInt32 {
        return 8333
    }
    public override var dnsSeeds: [String] {
        return [
            "seed.bitcoin.sipa.be",         // Pieter Wuille
            "dnsseed.bluematt.me",          // Matt Corallo
            "dnsseed.bitcoin.dashjr.org",   // Luke Dashjr
            "seed.bitcoinstats.com",        // Chris Decker
            "seed.bitnodes.io",             // Addy Yeow
            "seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
            "bitcoin.bloqseeds.net"        // Bloq dead
        ]
    }
    override var genesisBlock: Data {
        return Data(Data(hex: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")!.reversed())
    }
    override var checkpoints: [Checkpoint] {
        return super.checkpoints + [
            Checkpoint(height: 0, hash: Data(Data(hex: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")!.reversed()), timestamp: 1_231_006_505, target: 0x1d00ffff),
            Checkpoint(height: 20_160, hash: Data(Data(hex: "000000000f1aef56190aee63d33a373e6487132d522ff4cd98ccfc96566d461e")!.reversed()), timestamp: 1_248_481_816, target: 0x1d00ffff)
        ]
    }
}

public class Testnet: Network {
    public override var name: String {
        return "testnet"
    }
    override public var pubkeyhash: UInt8 {
        return 0x6f
    }
    override var privatekeyVersionByte: UInt8 {
        return 0xef
    }
    override var magic: UInt32 {
        return 0x0b110907
    }
    public override var port: UInt32 {
        return 18_333
    }
    public override var dnsSeeds: [String] {
        return [
            "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
            "testnet-seed.bitcoin.petertodd.org"    // Peter Todd
        ]
    }
    override var genesisBlock: Data {
        return Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed())
    }
}
