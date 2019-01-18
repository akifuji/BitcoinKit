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
    let height: UInt32
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
            Checkpoint(height: 1, hash: Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed()), timestamp: 1_296_688_602, target: 0x1d00ffff),
            Checkpoint(height: 201_600, hash: Data(Data(hex: "0000000000376bb71314321c45de3015fe958543afcbada242a3b1b072498e38")!.reversed()), timestamp: 1_393_813_869, target: 0x1b602ac0),
            Checkpoint(height: 403_200, hash: Data(Data(hex: "0000000000ef8b05da54711e2106907737741ac0278d59f358303c71d500f3c4")!.reversed()), timestamp: 1_431_821_666, target: 0x1c02346c),
            Checkpoint(height: 604_800, hash: Data(Data(hex: "00000000000008653c7e5c00c703c5a9d53b318837bb1b3586a3d060ce6fff2e")!.reversed()), timestamp: 1_447_484_641, target: 0x1a092a20),
            Checkpoint(height: 806_400, hash: Data(Data(hex: "0000000000000faf114ff29df6dbac969c6b4a3b407cd790d3a12742b50c2398")!.reversed()), timestamp: 1_462_006_183, target: 0x1a34e280),
            Checkpoint(height: 1_008_000, hash: Data(Data(hex: "000000000000390aca616746a9456a0d64c1bd73661fd60a51b5bf1c92bae5a0")!.reversed()), timestamp: 1_476_926_743, target: 0x1a52ccc0),
            Checkpoint(height: 1_209_600, hash: Data(Data(hex: "0000000000000026b4692a26f1651bec8e9d4905640bd8e56056c9a9c53badf8")!.reversed()), timestamp: 1_507_328_506, target: 0x1973e180),
            Checkpoint(height: 1_411_200, hash: Data(Data(hex: "00000000000002d214e1af085eda0a780a8446698ab5c0128b6392e189886114")!.reversed()), timestamp: 1_313_451_894, target: 0x1a094a86),
            Checkpoint(height: 161_280, hash: Data(Data(hex: "00000000000005911fe26209de7ff510a8306475b75ceffd434b68dc31943b99")!.reversed()), timestamp: 1_326_047_176, target: 0x1a0d69d7),
            Checkpoint(height: 181_440, hash: Data(Data(hex: "00000000000000e527fc19df0992d58c12b98ef5a17544696bbba67812ef0e64")!.reversed()), timestamp: 1_337_883_029, target: 0x1a0a8b5f),
            Checkpoint(height: 201_600, hash: Data(Data(hex: "00000000000003a5e28bef30ad31f1f9be706e91ae9dda54179a95c9f9cd9ad0")!.reversed()), timestamp: 1_349_226_660, target: 0x1a057e08),
            Checkpoint(height: 221_760, hash: Data(Data(hex: "00000000000000fc85dd77ea5ed6020f9e333589392560b40908d3264bd1f401")!.reversed()), timestamp: 1_361_148_470, target: 0x1a04985c),
            Checkpoint(height: 241_920, hash: Data(Data(hex: "00000000000000b79f259ad14635739aaf0cc48875874b6aeecc7308267b50fa")!.reversed()), timestamp: 1_371_418_654, target: 0x1a00de15),
            Checkpoint(height: 262_080, hash: Data(Data(hex: "000000000000000aa77be1c33deac6b8d3b7b0757d02ce72fffddc768235d0e2")!.reversed()), timestamp: 1_381_070_552, target: 0x1916b0ca),
            Checkpoint(height: 282_240, hash: Data(Data(hex: "0000000000000000ef9ee7529607286669763763e0c46acfdefd8a2306de5ca8")!.reversed()), timestamp: 1_390_570_126, target: 0x1901f52c),
            Checkpoint(height: 302_400, hash: Data(Data(hex: "0000000000000000472132c4daaf358acaf461ff1c3e96577a74e5ebf91bb170")!.reversed()), timestamp: 1_400_928_750, target: 0x18692842),
            Checkpoint(height: 322_560, hash: Data(Data(hex: "000000000000000002df2dd9d4fe0578392e519610e341dd09025469f101cfa1")!.reversed()), timestamp: 1_411_680_080, target: 0x181fb893),
            Checkpoint(height: 342_720, hash: Data(Data(hex: "00000000000000000f9cfece8494800d3dcbf9583232825da640c8703bcd27e7")!.reversed()), timestamp: 1_423_496_415, target: 0x1818bb87),
            Checkpoint(height: 362_880, hash: Data(Data(hex: "000000000000000014898b8e6538392702ffb9450f904c80ebf9d82b519a77d5")!.reversed()), timestamp: 1_435_475_246, target: 0x1816418e),
            Checkpoint(height: 383_040, hash: Data(Data(hex: "00000000000000000a974fa1a3f84055ad5ef0b2f96328bc96310ce83da801c9")!.reversed()), timestamp: 1_447_236_692, target: 0x1810b289),
            Checkpoint(height: 403_200, hash: Data(Data(hex: "000000000000000000c4272a5c68b4f55e5af734e88ceab09abf73e9ac3b6d01")!.reversed()), timestamp: 1_458_292_068, target: 0x1806a4c3),
            Checkpoint(height: 423_360, hash: Data(Data(hex: "000000000000000001630546cde8482cc183708f076a5e4d6f51cd24518e8f85")!.reversed()), timestamp: 1_470_163_842, target: 0x18057228),
            Checkpoint(height: 443_520, hash: Data(Data(hex: "00000000000000000345d0c7890b2c81ab5139c6e83400e5bed00d23a1f8d239")!.reversed()), timestamp: 1_481_765_313, target: 0x18038b85),
            Checkpoint(height: 463_680, hash: Data(Data(hex: "000000000000000000431a2f4619afe62357cd16589b638bb638f2992058d88e")!.reversed()), timestamp: 1_493_259_601, target: 0x18021b3e),
            Checkpoint(height: 483_840, hash: Data(Data(hex: "0000000000000000008e5d72027ef42ca050a0776b7184c96d0d4b300fa5da9e")!.reversed()), timestamp: 1_504_704_195, target: 0x1801310b),
            Checkpoint(height: 504_000, hash: Data(Data(hex: "0000000000000000006cd44d7a940c79f94c7c272d159ba19feb15891aa1ea54")!.reversed()), timestamp: 1_515_827_554, target: 0x177e578c),
            Checkpoint(height: 524_160, hash: Data(Data(hex: "00000000000000000009d1e9bee76d334347060c6a2985d6cbc5c22e48f14ed2")!.reversed()), timestamp: 1_527_168_053, target: 0x17415a49),
            Checkpoint(height: 544_320, hash: Data(Data(hex: "0000000000000000000a5e9b5e4fbee51f3d53f31f40cd26b8e59ef86acb2ebd")!.reversed()), timestamp: 1_538_639_362, target: 0x1725c191)
            // 564480
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
    override var checkpoints: [Checkpoint] {
        return super.checkpoints + [
            Checkpoint(height: 1, hash: Data(Data(hex: "00000000b873e79784647a6c82962c70d228557d24a747ea4d1b8bbe878e1206")!.reversed()), timestamp: 1_296_688_602, target: 0x1d00ffff),
            Checkpoint(height: 100_800, hash: Data(Data(hex: "0000000000a33112f86f3f7b0aa590cb4949b84c2d9c673e9e303257b3be9000")!.reversed()), timestamp: 1_376_543_922, target: 0x1c00d907),
            Checkpoint(height: 201_600, hash: Data(Data(hex: "0000000000376bb71314321c45de3015fe958543afcbada242a3b1b072498e38")!.reversed()), timestamp: 1_393_813_869, target: 0x1b602ac0),
            Checkpoint(height: 302_400, hash: Data(Data(hex: "0000000000001c93ebe0a7c33426e8edb9755505537ef9303a023f80be29d32d")!.reversed()), timestamp: 1_413_766_239, target: 0x1a33605e),
            Checkpoint(height: 403_200, hash: Data(Data(hex: "0000000000ef8b05da54711e2106907737741ac0278d59f358303c71d500f3c4")!.reversed()), timestamp: 1_431_821_666, target: 0x1c02346c),
            Checkpoint(height: 504_000, hash: Data(Data(hex: "0000000000005d105473c916cd9d16334f017368afea6bcee71629e0fcf2f4f5")!.reversed()), timestamp: 1_436_951_946, target: 0x1b00ab86),
            Checkpoint(height: 604_800, hash: Data(Data(hex: "00000000000008653c7e5c00c703c5a9d53b318837bb1b3586a3d060ce6fff2e")!.reversed()), timestamp: 1_447_484_641, target: 0x1a092a20),
            Checkpoint(height: 705_600, hash: Data(Data(hex: "00000000004ee3bc2e2dd06c31f2d7a9c3e471ec0251924f59f222e5e9c37e12")!.reversed()), timestamp: 1_455_728_685, target: 0x1c0ffff0),
            Checkpoint(height: 806_400, hash: Data(Data(hex: "0000000000000faf114ff29df6dbac969c6b4a3b407cd790d3a12742b50c2398")!.reversed()), timestamp: 1_462_006_183, target: 0x1a34e280),
            Checkpoint(height: 907_200, hash: Data(Data(hex: "0000000000166938e6f172a21fe69fe335e33565539e74bf74eeb00d2022c226")!.reversed()), timestamp: 1_469_705_562, target: 0x1c00ffff),
            Checkpoint(height: 1_008_000, hash: Data(Data(hex: "000000000000390aca616746a9456a0d64c1bd73661fd60a51b5bf1c92bae5a0")!.reversed()), timestamp: 1_476_926_743, target: 0x1a52ccc0),
            Checkpoint(height: 1_209_600, hash: Data(Data(hex: "0000000000000026b4692a26f1651bec8e9d4905640bd8e56056c9a9c53badf8")!.reversed()), timestamp: 1_507_328_506, target: 0x1973e180),
            Checkpoint(height: 1_310_400, hash: Data(Data(hex: "0000000000013b434bbe5668293c92ef26df6d6d4843228e8958f6a3d8101709")!.reversed()), timestamp: 1_527_038_604, target: 0x1b0ffff0),
            Checkpoint(height: 1_411_200, hash: Data(Data(hex: "00000000000000008b3baea0c3de24b9333c169e1543874f4202397f5b8502cb")!.reversed()), timestamp: 1_535_535_770, target: 0x194ac105),
            Checkpoint(height: 1_414_411, hash: Data(Data(hex: "00000000c56f3315d181723908e27559554d4ab6d6e861a744cc142455cd5ad5")!.reversed()), timestamp: 1_537_674_568, target: 0x1d00ffff) // CVE-2018-17144
            // 1512000
        ]
    }
}
