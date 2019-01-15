//
//  UInt256Tests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/15.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class UInt256Tests: XCTestCase {
    func testInitFromCompact() {
            XCTAssertEqual(try UInt256(compact: UInt32(0x05009234)).hex, "0x0000000000000000000000000000000000000000000000000000000092340000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x007fffff)).hex, "0x0000000000000000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x017fffff)).hex, "0x000000000000000000000000000000000000000000000000000000000000007f")
            XCTAssertEqual(try UInt256(compact: UInt32(0x027fffff)).hex, "0x0000000000000000000000000000000000000000000000000000000000007fff")
            XCTAssertEqual(try UInt256(compact: UInt32(0x03123456)).hex, "0x0000000000000000000000000000000000000000000000000000000000123456")
            XCTAssertEqual(try UInt256(compact: UInt32(0x037fffff)).hex, "0x00000000000000000000000000000000000000000000000000000000007fffff")
            XCTAssertEqual(try UInt256(compact: UInt32(0x047fffff)).hex, "0x000000000000000000000000000000000000000000000000000000007fffff00")
            XCTAssertEqual(try UInt256(compact: UInt32(0x057fffff)).hex, "0x0000000000000000000000000000000000000000000000000000007fffff0000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x067fffff)).hex, "0x00000000000000000000000000000000000000000000000000007fffff000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x077fffff)).hex, "0x000000000000000000000000000000000000000000000000007fffff00000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x087fffff)).hex, "0x0000000000000000000000000000000000000000000000007fffff0000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x097fffff)).hex, "0x00000000000000000000000000000000000000000000007fffff000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x1d7fffff)).hex, "0x0000007fffff0000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x1e7fffff)).hex, "0x00007fffff000000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x1f7fffff)).hex, "0x007fffff00000000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x207fffff)).hex, "0x7fffff0000000000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x2100ffff)).hex, "0xffff000000000000000000000000000000000000000000000000000000000000")
            XCTAssertEqual(try UInt256(compact: UInt32(0x220000ff)).hex, "0xff00000000000000000000000000000000000000000000000000000000000000")
    }
    
    func testOverflowCompact() {
        do {
            _ = try UInt256(compact: UInt32(0x21010000))
            XCTFail("compact should overflow")
        } catch UInt256.CompactError.error("compact overflows") {
        } catch {
            XCTFail("compact should overflow")
        }
        
        do {
            _ = try UInt256(compact: UInt32(0x23000001))
            XCTFail("compact should overflow")
        } catch UInt256.CompactError.error("compact overflows") {
        } catch {
            XCTFail("compact should overflow")
        }
        
        do {
            _ = try UInt256(compact: UInt32(0xff000001))
            XCTFail("compact should overflow")
        } catch UInt256.CompactError.error("compact overflows") {
        } catch {
            XCTFail("compact should overflow")
        }
    }
    
    func testNegativeCompact() {
        do {
            _ = try UInt256(compact: UInt32(0x008fffff))
            XCTFail("negative value is not supported")
        } catch UInt256.CompactError.error("negative value is not supported") {
        } catch {
            XCTFail("negative value is not supported")
        }
        
        do {
            _ = try UInt256(compact: UInt32(0x009fffff))
            XCTFail("negative value is not supported")
        } catch UInt256.CompactError.error("negative value is not supported") {
        } catch {
            XCTFail("negative value is not supported")
        }
        
        do {
            _ = try UInt256(compact: UInt32(0x00ffffff))
            XCTFail("negative value is not supported")
        } catch UInt256.CompactError.error("negative value is not supported") {
        } catch {
            XCTFail("negative value is not supported")
        }
    }
}
