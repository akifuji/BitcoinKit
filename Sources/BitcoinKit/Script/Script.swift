//
//  Script.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/12.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

public class Script {
    public static func getPublicKeyHash(from script: Data) -> Data {
        guard script.count >= 23 else {
            return Data()
        }
        return script[3..<23]
    }
}
