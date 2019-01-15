//
//  Encoding.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct Base58 {
    private static let baseAlphabets: String = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    private static var zeroAlphabet: Character = "1"
    private static var base: Int = 58

    // Allocate enough space in big-endian base58 representation.
    private static func sizeFromByte(size: Int) -> Int {
        // log(256) / log(base), rounded up
        return size * 138 / 100 + 1
    }
    // Allocate enough space in big-endian base256 representation.
    private static func sizeFromBase(size: Int) -> Int {
        // log(base) / log(256), rounded up
        return size * 733 / 1000 + 1
    }

    public static func encode(_ bytes: Data) -> String {
        var bytes: Data = bytes
        // Skip & count leading zeroes.
        var zerosCount: Int = 0
        for byte in bytes {
            guard byte == 0 else {
                break
            }
            zerosCount += 1
        }
        bytes.removeFirst(zerosCount)
        // Process the bytes.
        var length: Int = 0
        let size: Int = sizeFromByte(size: bytes.count)
        var encodedBytes = [UInt8](repeating: 0, count: size)
        for byte in bytes {
            var carry: Int = Int(byte)
            var i: Int = 0
            // Apply "b58 = b58 * 256 + ch".
            for j in (0..<encodedBytes.count).reversed() where carry != 0 || i < length {
                carry += 256 * Int(encodedBytes[j])
                encodedBytes[j] = UInt8(carry % base)
                carry /= base
                i += 1
            }
            assert(carry == 0)
            length = i
        }
        // Skip leading zeroes in base58 result.
        var zerosToRemove = 0
        for byte in encodedBytes {
            if byte != 0 {
                break
            }
            zerosToRemove += 1
        }
        encodedBytes.removeFirst(zerosToRemove)
        // Translate the result into a string.
        var encoededString: String = String(repeating: zeroAlphabet, count: zerosCount)
        encoededString += encodedBytes.map { baseAlphabets[String.Index(encodedOffset: Int($0))] }
        return encoededString
    }

    public static func decode(_ string: String) -> Data? {
        // Skip and count leading '1's.
        var zerosCount: Int = 0
        var length: Int = 0
        for character in string {
            guard character == zeroAlphabet else {
                break
            }
            zerosCount += 1
        }
        // Process the characters.
        let size = sizeFromByte(size: string.lengthOfBytes(using: .utf8) - zerosCount)
        var decodedBytes  = [UInt8](repeating: 0, count: size)
        for character in string {
            // Decode base58 character
            guard let baseIndex = baseAlphabets.index(of: character) else {
                return nil
            }
            var carry: Int = baseIndex.encodedOffset
            var i: Int = 0
            for j in (0..<decodedBytes.count).reversed() where carry != 0 || i < length {
                carry += base * Int(decodedBytes[j])
                decodedBytes[j] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }
            assert(carry == 0)
            length = i
        }
        // Skip leading zeroes in b256.
        var zerosToRemove = 0
        for byte in decodedBytes {
            guard byte == 0 else {
                break
            }
            zerosToRemove += 1
        }
        decodedBytes.removeFirst(zerosToRemove)
        return Data(count: zerosCount) + Data(decodedBytes)
    }
}
