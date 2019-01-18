//
//  MerkleBlockTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/18.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

// The data is from `BRMerkleBlockTests()` in
// https://github.com/breadwallet/breadwallet-core/blob/master/test.c

class MerkleBlockMessageTests: XCTestCase {
    func testSerialize() {
        // block 10001 filtered to include only transactions 0, 1, 2, and 6
        let payload = Data(hex: "0100000006e533fd1ada86391f3f6c343204b0d278d4aaec1c" +
            "0b20aa27ba0300000000006abbb3eb3d733a9fe18967fd7d4c117e4c" +
            "cbbac5bec4d910d900b3ae0793e77f54241b4d4c86041b4089cc9b0c" +
            "000000084c30b63cfcdc2d35e3329421b9805ef0c6565d35381ca857" +
            "762ea0b3a5a128bbca5065ff9617cbcba45eb23726df6498a9b9cafe" +
            "d4f54cbab9d227b0035ddefbbb15ac1d57d0182aaee61c74743a9c4f" +
            "785895e563909bafec45c9a2b0ff3181d77706be8b1dcc91112eada8" +
            "6d424e2d0a8907c3488b6e44fda5a74a25cbc7d6bb4fa04245f4ac8a" +
            "1a571d5537eac24adca1454d65eda446055479af6c6d4dd3c9ab6584" +
            "48c10b6921b7a4ce3021eb22ed6bb6a7fde1e5bcc4b1db6615c6abc5" +
            "ca042127bfaf9f44ebce29cb29c6df9d05b47f35b2edff4f0064b578" +
            "ab741fa78276222651209fe1a2c4c0fa1c58510aec8b090dd1eb1f82" +
            "f9d261b8273b525b02ff1a")!
        let merkleBlock = MerkleBlockMessage.deserialize(payload)
        XCTAssertEqual(Data(merkleBlock.blockHash.reversed()).hex, "00000000000080b66c911bd5ba14a74260057311eaeb1982802f7010f1a9f090")
        XCTAssertTrue(merkleBlock.isValid())
        XCTAssertEqual(merkleBlock.hashes[0].hex, "4c30b63cfcdc2d35e3329421b9805ef0c6565d35381ca857762ea0b3a5a128bb")
    }
}
