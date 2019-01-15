//
//  Base58Tests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class Base58Tests: XCTestCase {
    
    var testCases: [[String]]!
    
    override func setUp() {
        super.setUp()
        let path = Bundle(for: type(of: self)).url(forResource: "base58_encode_decode", withExtension: "json")!
        let data = try! Data(contentsOf: path)
        testCases = try! JSONSerialization.jsonObject(with: data) as! [[String]]
    }
    
    func testEncode() {
        for testPair in testCases {
            let original: Data = Data(hex: testPair[0])!
            XCTAssertEqual(Base58.encode(original), testPair[1])
        }
    }
    
    func testDecode() {
        for testPair in testCases {
            let original: String = testPair[1]
            XCTAssertEqual(Base58.decode(original), Data(hex: testPair[0]))
        }
    }
}
