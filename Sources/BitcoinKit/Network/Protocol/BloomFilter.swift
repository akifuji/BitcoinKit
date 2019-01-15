//
//  BloomFilter.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/09.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct BloomFilter {
    private let maxFilterSize: UInt32 = 36_000
    private let maxHashFuncs: UInt32 = 50

    public var filters: [UInt8]
    public let hashFuncs: UInt32
    public let tweak: UInt32
    public let size: UInt32

    public init(elementCount: Int, falsePositiveRate: Double = 0.0005, randomNonce tweak: UInt32) {
        self.size = max(1, min(UInt32(-1.0 / pow(log(2), 2) * Double(elementCount) * log(falsePositiveRate)), maxFilterSize * 8) / 8)
        filters = [UInt8](repeating: 0, count: Int(size))
        self.hashFuncs = max(1, min(UInt32(Double(size * UInt32(8)) / Double(elementCount) * log(2)), maxHashFuncs))
        self.tweak = tweak
    }

    public mutating func insert(_ data: Data) {
        for i in 0..<hashFuncs {
            let seed = i &* 0xfba4c795 &+ tweak
            let index = Int(MurmurHash.hashValue(data, seed) % (size * 8))
            filters[index >> 3] |= (1 << (7 & index))
        }
    }
}
