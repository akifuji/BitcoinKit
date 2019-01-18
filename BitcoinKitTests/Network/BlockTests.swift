//
//  BlockTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/18.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class BlockTests: XCTestCase {
    func testSerialize() {
        // https://bitcoin.org/en/developer-reference#block-headers
        let payload = Data(hex: "02000000" +   // Block version: 2
            "b6ff0b1b1680a2862a30ca44d346d9e8910d334beb48ca0c0000000000000000" +    // Hash of previous block's header
            "9d10aa52ee949386ca9385695f04ede270dda20810decd12bc9b048aaab31471" +    // Merkle root
            "24d95a54" +    // Unix time: 1415239972
            "30c31b18" +    // Target: 0x1bc330 * 256**(0x18-3)
            "fe9f0864" +    // Nonce
            "00")!   // Transaction count (0x00)
        
        let block = Block.deserialize(payload)
        XCTAssertEqual(block.version, 2)
        XCTAssertEqual(block.prevBlock.hex, "b6ff0b1b1680a2862a30ca44d346d9e8910d334beb48ca0c0000000000000000")
        XCTAssertEqual(block.merkleRoot.hex, "9d10aa52ee949386ca9385695f04ede270dda20810decd12bc9b048aaab31471")
        XCTAssertEqual(block.timestamp, 1415239972)
        XCTAssertEqual(block.bits, Data(hex: "30c31b18")!.to(type: UInt32.self))
        XCTAssertEqual(block.nonce, Data(hex: "fe9f0864")!.to(type: UInt32.self))
        XCTAssertEqual(block.transactionCount.underlyingValue, 0)
        XCTAssertTrue(block.transactions.isEmpty)
    }
}

