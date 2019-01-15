//
//  UInt256.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/15.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

// swiftlint:disable operator_whitespace

struct UInt256 {
    // e0 is lowest digit (UInt64 value is LittleEndian)
    // e3 is highest digit (UInt64 value is LittleEndian)
    private var e0: UInt64
    private var e1: UInt64
    private var e2: UInt64
    private var e3: UInt64

    static let zero = UInt256()

    var hex: String {
        return "0x" + [e3, e2, e1, e0].map { String(format: "%016lx", $0) }.joined()
    }

    init() {
        (e0, e1, e2, e3) = (0, 0, 0, 0)
    }

    init(_ e0: UInt64, _ e1: UInt64, _ e2: UInt64, _ e3: UInt64) {
        self.e0 = e0
        self.e1 = e1
        self.e2 = e2
        self.e3 = e3
    }

    init(_ value: UInt64) {
        self = UInt256(value, 0, 0, 0)
    }

    init(_ value: UInt32) {
        self = UInt256(UInt64(value))
    }

    // little endian cast
    init?(data: Data) {
        guard data.count == 32 else {
            return nil
        }
        e0 = data[0..<8].to(type: UInt64.self)
        e1 = data[8..<16].to(type: UInt64.self)
        e2 = data[16..<24].to(type: UInt64.self)
        e3 = data[24..<32].to(type: UInt64.self)
    }

    static func >><RHS>(lhs: UInt256, rhs: RHS) -> UInt256 where RHS: UnsignedInteger {
        var value = UInt256()
        let rightShift = rhs % 64
        let mask = bitValue(UInt(rightShift))
        let leftShift = 64 - rightShift
        switch rhs {
        case ..<64:
            value.e3 = lhs.e3 >> rightShift
            value.e2 = (lhs.e2 >> rightShift) + ((lhs.e3 & mask) << leftShift)
            value.e1 = (lhs.e2 >> rightShift) + ((lhs.e2 & mask) << leftShift)
            value.e0 = (lhs.e0 >> rightShift) + ((lhs.e1 & mask) << leftShift)
        case ..<128:
            value.e2 = lhs.e3 >> rightShift
            value.e1 = (lhs.e2 >> rightShift) + ((lhs.e3 & mask) << leftShift)
            value.e0 = (lhs.e1 >> rightShift) + ((lhs.e2 & mask) << leftShift)
        case ..<192:
            value.e1 = lhs.e3 >> rightShift
            value.e0 = (lhs.e2 >> rightShift) + ((lhs.e3 & mask) << leftShift)
        case ..<256:
            value.e0 = lhs.e3 >> rightShift
        default:
            return UInt256.zero
        }
        return value
    }

    static func <<<RHS>(lhs: UInt256, rhs: RHS) -> UInt256 where RHS: UnsignedInteger {
        var value = UInt256()
        let leftShift = rhs % 64
        let rightShift = 64 - leftShift
        switch rhs {
        case ..<64:
            value.e3 = (lhs.e3 << leftShift) + (lhs.e2 >> rightShift)
            value.e2 = (lhs.e2 << leftShift) + (lhs.e1 >> rightShift)
            value.e1 = (lhs.e1 << leftShift) + (lhs.e0 >> rightShift)
            value.e0 = lhs.e0 << leftShift
        case ..<128:
            value.e3 = (lhs.e2 << leftShift) + (lhs.e1 >> rightShift)
            value.e2 = (lhs.e1 << leftShift) + (lhs.e0 >> rightShift)
            value.e1 = lhs.e0 << leftShift
        case ..<192:
            value.e3 = (lhs.e1 << leftShift) + (lhs.e0 >> rightShift)
            value.e2 = lhs.e0 << leftShift
        case ..<256:
            value.e3 = lhs.e0 << leftShift
        default:
            return UInt256.zero
        }
        return value
    }

    private static func bitValue(_ value: UInt) -> UInt64 {
        return (0..<value).reduce(0) { $0 + 1 << $1 }
    }
}

extension UInt256: Equatable {
    static func ==(lhs: UInt256, rhs: UInt256) -> Bool {
        return lhs.e0 == rhs.e0 && lhs.e1 == rhs.e1 && lhs.e2 == rhs.e2 && lhs.e3 == rhs.e3
    }
}

extension UInt256: Comparable {
    static func <(lhs: UInt256, rhs: UInt256) -> Bool {
        if lhs.e3 != rhs.e3 {
            return lhs.e3 < rhs.e3
        } else if lhs.e2 != rhs.e2 {
            return lhs.e2 < rhs.e2
        } else if lhs.e1 != rhs.e1 {
            return lhs.e1 < rhs.e1
        } else if lhs.e0 != rhs.e0 {
            return lhs.e0 < rhs.e0
        }
        // a < a is always false (Irreflexivity)
        return false
    }
}

extension UInt256 {
    init (compact: UInt32) throws {
        let size: UInt32 = compact >> 24
        let target: UInt32 = compact & 0x007fffff
        if target == 0 {
            self = UInt256.zero
        } else {
            guard compact & 0x00800000 == 0 else {
                throw CompactError.error("negative value is not supported")
            }
            guard size <= 0x22 && (target <= 0xff || size <= 0x21) && (target <= 0xffff || size <= 0x20) else {
                throw CompactError.error("compact overflows")
            }
            if size < 3 {
                self = UInt256(target) >> ((3 - size) * 8)
            } else {
                self = UInt256(target) << ((size - 3) * 8)
            }
        }
    }

    enum CompactError: Error {
        case error(String)
    }
}
