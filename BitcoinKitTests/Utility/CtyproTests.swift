//
//  CryptoTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class CryptoTests: XCTestCase {
    
    func testSHA256() {
        XCTAssertEqual(Crypto.sha256("".data(using: .ascii)!).hex,  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(Crypto.sha256("abc".data(using: .ascii)!).hex,  "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(Crypto.sha256("message digest".data(using: .ascii)!).hex,  "f7846f55cf23e14eebeab5b4e1550cad5b509e3348fbc4efa3a1413d393cb650")
        XCTAssertEqual(Crypto.sha256("secure hash algorithm".data(using: .ascii)!).hex,  "f30ceb2bb2829e79e4ca9753d35a8ecc00262d164cc077080295381cbd643f0d")
        XCTAssertEqual(Crypto.sha256("SHA256 is considered to be safe".data(using: .ascii)!).hex,  "6819d915c73f4d1e77e4e1b52d1fa0f9cf9beaead3939f15874bd988e2a23630")
        XCTAssertEqual(Crypto.sha256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".data(using: .ascii)!).hex, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        XCTAssertEqual(Crypto.sha256("For this sample, this 63-byte string will be used as input data".data(using: .ascii)!).hex,  "f08a78cbbaee082b052ae0708f32fa1e50c5c421aa772ba5dbb406a2ea6be342")
        XCTAssertEqual(Crypto.sha256("This is exactly 64 bytes long, not counting the terminating byte".data(using: .ascii)!).hex,  "ab64eff7e88e2e46165e29f2bce41826bd4c7b3552f6b382a9e7d3af47c245f8")
        XCTAssertEqual(Crypto.sha256("As Bitcoin relies on 80 byte header hashes, we want to have an example for that.".data(using: .ascii)!).hex,  "7406e8de7d6e4fffc573daef05aefb8806e7790f55eab5576f31349743cca743")
        XCTAssertEqual(Crypto.sha256("".data(using: .ascii)!).hex,  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(Crypto.sha256(String(repeating: "a", count: 1000000).data(using: .ascii)!).hex,  "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
    
    func testRipemd160() {
        XCTAssertEqual(Crypto.ripemd160("".data(using: .ascii)!).hex,  "9c1185a5c5e9fc54612808977ee8f548b2258d31")
        XCTAssertEqual(Crypto.ripemd160("abc".data(using: .ascii)!).hex,  "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc")
        XCTAssertEqual(Crypto.ripemd160("message digest".data(using: .ascii)!).hex,  "5d0689ef49d2fae572b881b123a85ffa21595f36")
        XCTAssertEqual(Crypto.ripemd160("secure hash algorithm".data(using: .ascii)!).hex,  "20397528223b6a5f4cbc2808aba0464e645544f9")
        XCTAssertEqual(Crypto.ripemd160("RIPEMD160 is considered to be safe".data(using: .ascii)!).hex,  "a7d78608c7af8a8e728778e81576870734122b66")
        XCTAssertEqual(Crypto.ripemd160("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".data(using: .ascii)!).hex,  "12a053384a9c0c88e405a06c27dcf49ada62eb2b")
        XCTAssertEqual(Crypto.ripemd160("For this sample, this 63-byte string will be used as input data".data(using: .ascii)!).hex,  "de90dbfee14b63fb5abf27c2ad4a82aaa5f27a11")
        XCTAssertEqual(Crypto.ripemd160("This is exactly 64 bytes long, not counting the terminating byte".data(using: .ascii)!).hex,  "eda31d51d3a623b81e19eb02e24ff65d27d67b37")
        XCTAssertEqual(Crypto.ripemd160(String(repeating: "a", count: 1000000).data(using: .ascii)!).hex,  "52783243c1697bdbe16d37f97f68f08325dc1528")
    }
}
