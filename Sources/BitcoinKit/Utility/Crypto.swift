//
//  Crypto.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/03.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation
#if BitcoinKitXcode
import BitcoinKit.Private
#else
import BitcoinKitPrivate
#endif

public struct Crypto {
    public static func sha256(_ data: Data) -> Data {
        return _Hash.sha256(data)
    }

    public static func sha256sha256(_ data: Data) -> Data {
        return sha256(sha256(data))
    }

    public static func ripemd160(_ data: Data) -> Data {
        return _Hash.ripemd160(data)
    }

    public static func sha256ripemd160(_ data: Data) -> Data {
        return ripemd160(sha256(data))
    }
}
