//
//  KeyTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class KeyTests: XCTestCase {
    
    var testCases: [[Any]]!
    
    override func setUp() {
        super.setUp()
        let path = Bundle(for: type(of: self)).url(forResource: "key_io_valid", withExtension: "json")!
        let data = try! Data(contentsOf: path)
        testCases = try! JSONSerialization.jsonObject(with: data) as! [[Any]]
    }
    
    func testKeyEncoding() {
        for testCase in testCases {
            let base58Encoded = testCase[0] as! String
            let keyData = testCase[1] as! String
            let metadata = testCase[2] as! [String: Any]
            var network: Network!
            switch metadata["chain"] as! String {
            case "main":
                network = Network.mainnet
            case "test", "regtest":
                network = Network.testnet
            default:
                XCTFail("Invalid network found")
            }
            if metadata["isPrivkey"] as! Int == 1 {
                let isPublicKeyCompressed: Bool = (metadata["isCompressed"] as! Int == 1)
                let privateKey = PrivateKey(data: Data(hex: keyData)!, network: network, isPublicKeyCompressed: isPublicKeyCompressed)
                // Test conversion from private key into WIF
                XCTAssertEqual(privateKey.wif, base58Encoded)
                // Test conversion from WIF into private key
                XCTAssertEqual(try! PrivateKey(wif: base58Encoded), privateKey)
            }
        }
    }
}

