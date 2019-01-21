//
//  Wallet.swift
//  WalletExample
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 Yenom Inc. All rights reserved.
//

import Foundation
import BitcoinKit

class Wallet: PeerManagerDelegate {
    
    static let shared = Wallet()
    
    var peerManager: PeerManager!
    var balance: UInt64 = 0
    var payments = [Payment]()
    var logs = [PeerLog]()
    var privateKey: PrivateKey
    var publicKey: PublicKey {
        return privateKey.publicKey
    }
    
    private init() {
        self.privateKey = try! PrivateKey.init(wif: "cQ2BQqKL44d9az7JuUx8b1CSGx5LkQrTM7UQKjYGnrHiMX5nUn5C")
        let database = try! Database.default()
        peerManager = PeerManager(database: database, pubkeys: [publicKey])
        peerManager.delegate = self
        peerManager.start()
    }
    
    func balanceChanged(_ balance: UInt64) {
        self.balance = balance
        NotificationCenter.default.post(name: Notification.Name.Wallet.balanceChanged, object: self)
    }
    
    func paymentAdded(_ payment: Payment) {
        payments.append(payment)
        NotificationCenter.default.post(name: Notification.Name.Wallet.paymentAdded, object: self)
    }
    
    func logged(_ log: PeerLog) {
        logs.append(log)
        NotificationCenter.default.post(name: Notification.Name.Wallet.logged, object: self)
    }
}

extension Notification.Name {
    struct Wallet {
        static let balanceChanged = Notification.Name("Wallet.balanceChanged")
        static let paymentAdded = Notification.Name("Wallet.paymentAdded")
        static let logged = Notification.Name("Wallet.logged")
    }
}
