//
//  Wallet.swift
//  WalletExample
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 Yenom Inc. All rights reserved.
//

import Foundation
import BitcoinKit
import KeychainAccess

class Wallet: PeerManagerDelegate {
    static let shared = Wallet()
    private let keychain: Keychain = Keychain().synchronizable(false)
    let network: Network = .testnet
    var peerManager: PeerManager!
    var balance: UInt64 = 0
    var payments = [Payment]()
    var logs = [PeerLog]()
    var bip44Keychain: BIP44Keychain {
        return BIP44Keychain(seed: seed, network: network)
    }
    var mnemonic: [String] {
        get {
            if let data = keychain[data: "mnemonic"], let mnemonic = try? JSONDecoder().decode([String].self, from: data) {
                return mnemonic
            } else {
                self.mnemonic = try! Mnemonic.generate(language: .english)
                return self.mnemonic
            }
        }
        set {
            keychain[data: "mnemonic"] = try! JSONEncoder().encode(newValue)
        }
    }
    var seed: Data {
        get {
            if let seed = keychain[data: "seed"] {
                return seed
            } else {
                return Mnemonic.seed(mnemonic: mnemonic)
            }
        }
        set {
            keychain[data: "seed"] = newValue
        }
    }
    private var receiveKeyIndex: UInt32 {
        get {
            return keychain[string: "receiveKeyIndex"].map(UInt32.init) as? UInt32 ?? 0
        }
    }
    private func incrementReceiveKeyIndex() {
        keychain[string: "receiveKeyIndex"] = String(receiveKeyIndex + 1)
    }
    var receiveKey: PrivateKey {
        return bip44Keychain.receiveKey(index: receiveKeyIndex)
    }
    var receivePublicKey: PublicKey {
        return receiveKey.publicKey
    }
    private var changeKeyIndex: UInt32 {
        get {
            return keychain[string: "changeKeyIndex"].map(UInt32.init) as? UInt32 ?? 0
        }
    }
    private func incrementChangeKeyIndex() {
        keychain[string: "changeKeyIndex"] = String(changeKeyIndex + 1)
    }
    var changeKey: PrivateKey {
        return bip44Keychain.changeKey(index: changeKeyIndex)
    }
    var changePublicKey: PublicKey {
        return changeKey.publicKey
    }
    var allKeys: [PrivateKey] {
        return bip44Keychain.keys(receiveIndexRange: 0..<receiveKeyIndex + 1, changeIndexRange: 0..<changeKeyIndex + 1)
    }
    var allPublicKeys: [PublicKey] {
        return allKeys.map { $0.publicKey }
    }
    
    var lastCheckedBlockHeight: UInt32 {
        get {
            return UInt32(UserDefaults.standard.integer(forKey: #function))
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: #function)
        }
    }
    
    private init() {        
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        print("DB Path: \(dbPath)")
        
        let database = try! SQLiteDatabase.default()
        balance = try! database.calculateBalance()
        payments = try! database.payments()
        peerManager = PeerManager(database: database, network: network, pubkeys: allPublicKeys, lastCheckedBlockHeight: lastCheckedBlockHeight)
        peerManager.delegate = self
        peerManager.start()
    }
    
    func balanceChanged(_ balance: UInt64) {
        self.balance = balance
        NotificationCenter.default.post(name: Notification.Name.Wallet.balanceChanged, object: self)
    }
    
    func paymentAdded(_ payment: Payment) {
        payments.append(payment)
        if payment.direction == .sent {
            incrementChangeKeyIndex()
        }
        incrementReceiveKeyIndex()
        peerManager.pubkeys = allPublicKeys
        NotificationCenter.default.post(name: Notification.Name.Wallet.paymentAdded, object: self)
    }
    
    func logged(_ log: PeerLog) {
        logs.append(log)
        NotificationCenter.default.post(name: Notification.Name.Wallet.logged, object: self)
    }
    
    func lastCheckedBlockHeightUpdated(_ height: UInt32) {
        lastCheckedBlockHeight = height
        NotificationCenter.default.post(name: Notification.Name.Wallet.lastBlockChanged, object: self)
    }
}

extension Notification.Name {
    struct Wallet {
        static let balanceChanged = Notification.Name("Wallet.balanceChanged")
        static let paymentAdded = Notification.Name("Wallet.paymentAdded")
        static let logged = Notification.Name("Wallet.logged")
        static let lastBlockChanged = Notification.Name("Wallet.lastBlockChanged")
    }
}
