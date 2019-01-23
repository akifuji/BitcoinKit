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

struct Crypto {
    static func sha256(_ data: Data) -> Data {
        return _Hash.sha256(data)
    }

    static func sha256sha256(_ data: Data) -> Data {
        return sha256(sha256(data))
    }

    static func ripemd160(_ data: Data) -> Data {
        return _Hash.ripemd160(data)
    }

    static func sha256ripemd160(_ data: Data) -> Data {
        return ripemd160(sha256(data))
    }

    static func hmacsha512(data: Data, key: Data) -> Data {
        return _Hash.hmacsha512(data, key: key)
    }

    static func sign(_ data: Data, privateKey: PrivateKey) throws -> Data {
        #if BitcoinKitXcode
        return _Crypto.signMessage(data, withPrivateKey: privateKey.data)
        #else
        return try _Crypto.signMessage(data, withPrivateKey: privateKey.data)
        #endif
    }
}
