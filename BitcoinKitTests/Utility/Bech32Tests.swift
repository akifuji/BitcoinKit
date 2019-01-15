//
//  Bech32.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class Bech32Tests: XCTestCase {
    
    func testValidChecksum() {
        XCTAssertNotNil(Bech32.bech32_decode("A12UEL5L"))
        XCTAssertNotNil(Bech32.bech32_decode("an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs"))
        XCTAssertNotNil(Bech32.bech32_decode("abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw"))
        XCTAssertNotNil(Bech32.bech32_decode("11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j"))
        XCTAssertNotNil(Bech32.bech32_decode("split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w"))
    }
    
    func testInvalidChecksum() {
        XCTAssertNil(Bech32.bech32_decode("201nwldj5"), "HRP character out of range")
        XCTAssertNil(Bech32.bech32_decode("7f1axkwrx"), "HRP character out of range")
        XCTAssertNil(Bech32.bech32_decode("801eym55h"), "HRP character out of range")
        XCTAssertNil(Bech32.bech32_decode("an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx"), "overall max length exceeded")
        XCTAssertNil(Bech32.bech32_decode("pzry9x0s0muk"), "No separator character")
        XCTAssertNil(Bech32.bech32_decode("1pzry9x0s0muk"), "Empty HRP")
        XCTAssertNil(Bech32.bech32_decode("x1b4n0q5v"), "Invalid data character")
        XCTAssertNil(Bech32.bech32_decode("li1dgmt3"), "Too short checksum")
        XCTAssertNil(Bech32.bech32_decode("de1lg7wtff"), "Invalid character in checksum")
        XCTAssertNil(Bech32.bech32_decode("A1G7SGD8"), "checksum calculated with uppercase form of HRP")
        XCTAssertNil(Bech32.bech32_decode("10a06t8"), "empty HRP")
        XCTAssertNil(Bech32.bech32_decode("1qzzfhee"), "empty HRP")
    }
}

