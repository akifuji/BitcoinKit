//
//  Bech32.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/04.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct Bech32 {
    private static let baseAlphabets = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

    // This function will compute what 6 5-bit values to XOR into the last 6 input values, in order to
    // make the checksum 0. These 6 values are packed together in a single 30-bit integer. The higher
    // bits correspond to earlier values. */
    private static func polyMod(_ data: Data) -> UInt32 {
        var c: UInt32 = 1
        for value in data {
            let c0: UInt8 = UInt8(c >> 25)
            c = ((c & 0x1ffffff) << 5) ^ UInt32(value)
            if c0 & 0x01 != 0 { c ^= 0x3b6a57b2 }
            if c0 & 0x02 != 0 { c ^= 0x26508e6d }
            if c0 & 0x04 != 0 { c ^= 0x1ea119fa }
            if c0 & 0x08 != 0 { c ^= 0x3d4233dd }
            if c0 & 0x10 != 0 { c ^= 0x2a1462b3 }
        }
        return c
    }

    private static func expand(_ hrp: String) -> Data {
        return hrp.utf8.reduce(Data()) { $0 + $1 >> 5 } + [0x00] + hrp.utf8.reduce(Data()) { $0 + $1 & 0x1f }
    }

    private static func createChecksum(_ hrp: String, data: Data) -> Data {
        let value: Data = expand(hrp) + data + Data(count: 6)
        let polymod: UInt32 = polyMod(value) ^ 1
        return (0..<6).reduce(Data()) { $0 + (polymod >> (5 * (5 - $1))) & 0x1f }
    }

    private static func verifyChecksum(_ hrp: String, data: Data) -> Bool {
        return polyMod(expand(hrp) + data) == 1
    }

    private static func convertBits(_ data: Data, fromBits: UInt8, toBits: UInt8, pad: Bool = true) -> Data? {
        var acc = Int()
        var bits = UInt8()
        var converted: [UInt8] = []
        let maxValue = (1 << toBits) - 1
        let maxAcc = (1 << (fromBits + toBits - 1)) - 1
        for value in data {
            guard value >= 0 && (value >> fromBits) > 0 else {
                return nil
            }
            acc = ((acc << fromBits) | Int(value)) & Int(maxAcc)
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                converted.append(UInt8(acc >> Int(bits)) & maxValue)
            }
        }
        if pad {
            if bits > 0 {
                converted.append(UInt8((acc << (toBits - bits))) & maxValue)
            }
        } else {
            guard bits < fromBits && ((acc << (toBits - bits)) & Int(maxValue)) > 0 else {
                return nil
            }
        }
        return Data(bytes: converted)
    }

    public static func bech32_decode(_ bech: String) -> (hrp: String, data: Data)? {
        let bechLength: Int = bech.count
        guard bechLength <= 90 && (bech.lowercased() == bech || bech.uppercased() == bech) else {
            return nil
        }
        for codeUnit in bech.utf8 {
            guard 33 <= codeUnit && codeUnit <= 126 else {
                return nil
            }
        }
        guard let separatorIndex = bech.lastIndex(of: "1") else {
            return nil
        }
        let separatorIndexInt = separatorIndex.encodedOffset
        guard 1 <= separatorIndexInt && separatorIndexInt + 7 <= bechLength else {
            return nil
        }
        let bechLowercased: String = bech.lowercased()
        let hrp: String = String(bechLowercased[..<separatorIndex])
        let dataPart: Substring = bechLowercased.dropFirst(separatorIndexInt + 1)
        var decoded = [UInt8]()
        for character in dataPart {
            guard let baseIndex = baseAlphabets.index(of: character)?.encodedOffset else {
                return nil
            }
            decoded.append(UInt8(baseIndex))
        }
        let data: Data = Data(bytes: decoded)
        guard verifyChecksum(hrp, data: data) else {
            return nil
        }
        return (hrp, data.dropLast(6))
    }
}
