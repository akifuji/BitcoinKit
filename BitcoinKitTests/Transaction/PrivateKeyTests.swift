//
//  PrivateKeyTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class PrivateKeyTests: XCTestCase {
    
    func testWIF() {
        // Mainnet
        do {
            let privateKey = PrivateKey(data: Data(hex: "a7ec27c206a68e33f53d6a35f284c748e0874ca2f0ea56eca6eb7668db0fe805")!, network: .mainnet, isPublicKeyCompressed: false)
            // Test conversion from private key into WIF
            XCTAssertEqual(privateKey.wif, "5K6EwEiKWKNnWGYwbNtrXjA8KKNntvxNKvepNqNeeLpfW7FSG1v")
            // Test conversion from WIF into private key
            XCTAssertEqual(try! PrivateKey(wif: "5K6EwEiKWKNnWGYwbNtrXjA8KKNntvxNKvepNqNeeLpfW7FSG1v"), privateKey)
        }
        // Testnet
        do {
            let privateKey = PrivateKey(data: Data(hex: "a2359719d3dc9f1539c593e477dc9d57b9653a18e7c94299d87a95ed13525eae")!, network: .testnet, isPublicKeyCompressed: false)
            // Test conversion from private key into WIF
            XCTAssertEqual(privateKey.wif, "92pMamV6jNyEq9pDpY4f6nBy9KpV2cfJT4L5zDUYiGqyQHJfF1K")
            // Test conversion from WIF into private key
            XCTAssertEqual(try! PrivateKey(wif: "92pMamV6jNyEq9pDpY4f6nBy9KpV2cfJT4L5zDUYiGqyQHJfF1K"), privateKey)
        }
    }
}
