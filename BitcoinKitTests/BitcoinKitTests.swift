//
//  BitcoinKitTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/06.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class MessageTests: XCTestCase {
    
    func testWIF() {
        let data = Data(hex: "01000000013458a707f8a363f53f74ba2932ae993fdfd56a338ebac2e24c1806a5b8a4a265010000006b483045022100bbc21d57f1e8b797db796bb906ae2757624c1911e58823119946ad15cb673bf102206c56b3b7a8b8127fc68d4d81f8f509aa9fbb821fdbadf24899ee43ae9f2e5b250121036363d5dd76767a09e247e630458b97373b0042581c561e0552871fbd59187aadffffffff02a0860100000000001976a91446c4863357fe4a3d8f6d48232b6dcf7ad8418bb788acd7e9eb00000000001976a9142043b2855e906e1f88e89d6dc7f392c4f7f6f73088ac00000000")!
        let tx = Transaction.deserialize(data)
        print(tx.outputs[0].lockingScript.hex)
//        let data = Data(hex: "0b110907686561646572730000000000d3780200320f23dafdd0070100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038fc5f31f020e7494dffff001d03e4b672000100000006128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000e241352e3bec0a95a6217e10c3abb54adfa05a")
//        let m = MessageHeader.deserialize(data!)!
//        print(m.command)
        //print(m.payload.count)
//        let versionMessage = VersionMessage.deserialize(m.payload)
//        print("got version: \(versionMessage.version), useragent: \(versionMessage.userAgent?.value ?? "")")
    }
    
    func testMerkleBlock() {
        let data = Data(hex: "00000020cd040a576394fb55b653d23ccdf0198ac5304836a06ecc5ca1000000000000001606f146ecbaec691d66ecbb8963b6c98ab0611a868712dbbfaecd1237a625983ee2425cffff001d0a28d6c8260000000ac4c6707a8c029fe5284a62d3c26d9506d1fb1a250c9c28aedd44ce820a8acc3cb99c351d5b8699db2b976d1a22cb9c883c5a3063039eaf376dec604ed317e4e50dbf6dac059bd365cb81b3733f05c0e6fd142408a69d1c30ab78b27c4904681146079e645dd47666ce459072f1713db7c38bf78daf344f35c9ae557f2339961ab72a6fa0c9f46ee20fd2c8ff4651cd07b5d054759ad98abf8f36e368afdfa80c165c8e4db7329208ddc721f2db701151b9a363cb1580d676b782461059219ebbdb9d9761140120e6f1b60ecd5bd1e93f638523f366b88f5b857a587749ec6e6fdb1b636f1fdfd3efb1acd7174821b2c8ece544f5262b2e8cc454b505bb4309104104b3f8838f5afc4415e55fd4f05e311198b6110ca04252124a8c391145948b5ce54876cfced3168165abb6769d04bf09e755b72e7661fa7175c27eba94f2f803d7f106")!
        let m = MerkleBlockMessage.deserialize(data)
        m.isValid()
    }
    
    func txSerialize() {
        let data = Data(hex: "0100000001f3f6a909f8521adb57d898d2985834e632374e770fd9e2b98656f1bf1fdfd427010000006b48304502203a776322ebf8eb8b58cc6ced4f2574f4c73aa664edce0b0022690f2f6f47c521022100b82353305988cb0ebd443089a173ceec93fe4dbfe98d74419ecc84a6a698e31d012103c5c1bc61f60ce3d6223a63cedbece03b12ef9f0068f2f3c4a7e7f06c523c3664ffffffff0260e31600000000001976a914977ae6e32349b99b72196cb62b5ef37329ed81b488ac063d1000000000001976a914f76bc4190f3d8e2315e5c11c59cfc8be9df747e388ac00000000")!
        let tx = Transaction.deserialize(data)
        print(tx.outputs[0].lockingScript.hex)
    }
}



