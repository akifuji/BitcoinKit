//
//  HeadersMessageTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/18.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class HeadersMessageTests: XCTestCase {
    func testSerialize1() {
        // The first block after the genesis
        // Block #1 https://blockexplorer.com/block/00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048
        let data = Data(hex: "01" +
            "01000000" +
            "6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000" +
            "982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e" +
            "61bc6649" +
            "ffff001d" +
            "01e36299" +
            "00")!
        let headersMessage = try! HeadersMessage.deserialize(data)
        XCTAssertEqual(headersMessage.count.underlyingValue, 1)
        let header = headersMessage.headers[0]
        XCTAssertEqual(Data(header.blockHash.reversed()).hex, "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048")
        XCTAssertTrue(header.transactions.isEmpty)
        XCTAssertEqual(Data(header.merkleRoot.reversed()).hex, "0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098")
        XCTAssertEqual(headersMessage.serialized().hex, data.hex)
    }
    
    func testSerialize2() {
        let data = Data(hex: "06010000006fe28c0ab6f1b372c1a6a246ae63f74f931e" +
            "8365e15a089c68d6190000000000982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1c" +
            "db606e857233e0e61bc6649ffff001d01e3629900010000004860eb18bf1b1620e37e9490fc8a" +
            "427514416fd75159ab86688e9a8300000000d5fdcc541e25de1c7a5addedf24858b8bb665c9f36" +
            "ef744ee42c316022c90f9bb0bc6649ffff001d08d2bd610001000000bddd99ccfda39da1b108ce1" +
            "a5d70038d0a967bacb68b6b63065f626a0000000044f672226090d85db9a9f2fbfe5f0f9609b387" +
            "af7be5b7fbb7a1767c831c9e995dbe6649ffff001d05e0ed6d00010000004944469562ae1c2c74" +
            "d9a535e00b6f3e40ffbad4f2fda3895501b582000000007a06ea98cd40ba2e3288262b28638cec" +
            "5337c1456aaf5eedc8e9e5a20f062bdf8cc16649ffff001d2bfee0a9000100000085144a84488e" +
            "a88d221c8bd6c059da090e88f8a2c99690ee55dbba4e00000000e11c48fecdd9e72510ca84f023" +
            "370c9a38bf91ac5cae88019bee94d24528526344c36649ffff001d1d03e4770001000000fc33f5" +
            "96f822a0a1951ffdbf2a897b095636ad871707bf5d3162729b00000000379dfb96a5ea8c81700ea4" +
            "ac6b97ae9a9312b2d4301a29580e924ee6761a2520adc46649ffff001d189c4c9700")!
        let headersMessage = try! HeadersMessage.deserialize(data)
        XCTAssertEqual(headersMessage.count.underlyingValue, 6)
        
        // index 0 block is the number 1 block in the block chain
        // https://blockexplorer.com/block/00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048
        let zeroHeaderBlock = headersMessage.headers[0]
        XCTAssertEqual(2573394689, zeroHeaderBlock.nonce)
        
        // index 3 block is the number 4 block in the block chain
        // https://blockexplorer.com/block/000000004ebadb55ee9096c9a2f8880e09da59c0d68b1c228da88e48844a1485
        let thirdHeaderBlock = headersMessage.headers[3]
        XCTAssertEqual(2850094635, thirdHeaderBlock.nonce)
        
        XCTAssertEqual(headersMessage.serialized().hex, data.hex)
    }
}
