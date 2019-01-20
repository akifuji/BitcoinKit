//
//  OpCode.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/20.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

enum OpCode: UInt8 {
    case OP_0 = 0x00
    case OP_PUSHDATA1 = 0x4c
    case OP_PUSHDATA2 = 0x4d
    case OP_PUSHDATA4 = 0x4e
    case OP_1NEGATE = 0x4f
    case OP_1 = 0x51
    case OP_16 = 0x60
    case OP_DUP = 0x76
    case OP_EQUAL = 0x87
    case OP_EQUALVERIFY = 0x88
    case OP_HASH160 = 0xa9
    case OP_CHECKSIG = 0xac
}

// swiftlint:disable operator_whitespace
func +(lhs: Data, rhs: OpCode) -> Data {
    return lhs + rhs.rawValue
}

func +=(lhs: inout Data, rhs: OpCode) {
    lhs += lhs + rhs
}
