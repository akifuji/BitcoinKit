//
//  TransactionBuilder.swift
//  BitcoinKit
//
//  Created by Akifumi Fujita on 2019/01/19.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import Foundation

class TransactionBuilder {
    let feePerByte: UInt64
    let dustThreshhold: UInt64

    init(feePerByte: UInt64 = 5, dustThreshhold: UInt64 = 3 * 182) {
        self.feePerByte = feePerByte
        self.dustThreshhold = dustThreshhold
    }

    func buildTransaction(toAddress: String, changeAddress: String, amount: UInt64, utxos: [UnspentTransactionOutput], keys: [PrivateKey]) throws -> Transaction {
        // Create outputs
        let (utxosToSpend, fee) = try selectUTXOs(from: utxos, targetValue: amount)
        let totalAmount: UInt64 = utxosToSpend.sum()
        let change: UInt64 = totalAmount - amount - fee
        let destinations: [(String, UInt64)] = [(toAddress, amount), (changeAddress, change)]
        let outputs = destinations.map { (address: String, amount: UInt64) -> TransactionOutput in
            let decoded = Base58.decode(address)
            let pubkeyHash = decoded!.dropLast(4)
            let lockingScript = Script.buildP2PKHLockingScript(pubKeyHash: pubkeyHash)
            return TransactionOutput(value: amount, lockingScript: lockingScript)
        }
        // Create inputs
        var signingInputs = utxos.map { TransactionInput(previousOutput: TransactionOutPoint(hash: $0.hash, index: $0.index), signatureScript: Data(), sequence: UInt32.max)
        }
        // Create signature and sign tx
        for (inputIndex, utxo) in utxosToSpend.enumerated() {
            let keysOfUtxo: [PrivateKey] = keys.filter { $0.publicKey.pubkeyHash == utxo.pubkeyHash }
            guard let key = keysOfUtxo.first else {
                throw TransactionBuilderError.error("key is missing")
            }
            let inputsToSerialize = (0..<signingInputs.count).map { index -> TransactionInput in
                let txInput = signingInputs[index]
                let script = inputIndex == index ? utxo.lockingScript : Data()
                return TransactionInput(previousOutput: txInput.previousOutput, signatureScript: script, sequence: txInput.sequence)
            }
            let txToSerialize = Transaction(version: 1, inputs: inputsToSerialize, outputs: outputs, lockTime: 0)
            let serializedTx = txToSerialize.serialized()
            let sighash = Crypto.sha256sha256(serializedTx + UInt32(0x01))  // 0x01: SIGHASH_ALL
            let signature = try Crypto.sign(sighash, privateKey: key)
            let pubkey = key.publicKey
            // Create unlocking Script
            let sigWithHashType: Data = signature + UInt8(0x01)
            let unlockingScipt = Data(bytes: [UInt8(sigWithHashType.count)]) + sigWithHashType + Data(bytes: [UInt8(pubkey.data.count)]) + pubkey.data
            let txInput = signingInputs[inputIndex]
            signingInputs[inputIndex] = TransactionInput(previousOutput: txInput.previousOutput, signatureScript: unlockingScipt, sequence: txInput.sequence)
        }
        return Transaction(version: 1, inputs: signingInputs, outputs: outputs, lockTime: 0)
    }

    private func selectUTXOs(from utxos: [UnspentTransactionOutput], targetValue: UInt64) throws -> (utxos: [UnspentTransactionOutput], fee: UInt64) {
        // if target value is zero, fee is zero
        guard targetValue > 0 else {
            return ([], 0)
        }

        // definitions for the following calculation
        let doubleTargetValue = targetValue * 2
        let numOutputs = 2
        var numInputs = 2
        var fee: UInt64 {
            return calculateFee(nIn: numInputs, nOut: numOutputs)
        }
        var targetWithFee: UInt64 {
            return targetValue + fee
        }
        var targetWithFeeAndDust: UInt64 {
            return targetWithFee + dustThreshhold
        }
        let sortedUTXOs: [UnspentTransactionOutput] = utxos.sorted(by: { $0.value < $1.value })

        // total values of utxos should be greater than targetValue
        guard !sortedUTXOs.isEmpty && sortedUTXOs.sum() >= targetValue else {
            throw TransactionBuilderError.error("insufficient funds")
        }

        // difference from 2x targetValue
        func distFrom2x(_ value: UInt64) -> UInt64 {
            return UInt64(abs(Int32(value - doubleTargetValue)))
        }

        // 1. find a combination of the fewest outputs that is
        //    (1) bigger than what we need
        //    (2) closer to 2x the amount,
        //    (3) and does not produce dust change
        for nTx in (1...sortedUTXOs.count) {
            let nOutputsSlices = sortedUTXOs.eachSlices(nTx)
            let nOutputsInRange = nOutputsSlices.filter { $0.sum() >= targetWithFeeAndDust }
            if let nOutputs = nOutputsInRange.first {
                return (nOutputs, fee)
            }
        }

        // 2. If not, find a combination of outputs that may produce dust change.
        for nTx in (1...sortedUTXOs.count) {
            let nOutputsSlices = sortedUTXOs.eachSlices(nTx)
            let nOutputsInRange = nOutputsSlices.filter { $0.sum() >= targetWithFee }
            if let nOutputs = nOutputsInRange.first {
                return (nOutputs, fee)
            }
        }

        throw TransactionBuilderError.error("insufficient funds")
    }

    private func calculateFee(nIn: Int, nOut: Int = 2) -> UInt64 {
        var txSize: Int {
            return ((148 * nIn) + (34 * nOut) + 10)
        }
        return UInt64(txSize) * feePerByte
    }
}

enum TransactionBuilderError: Error {
    case error(String)
}

private extension Array {
    // Slice Array
    // [0,1,2,3,4,5,6,7,8,9].eachSlices(3)
    // >
    // [[0, 1, 2], [1, 2, 3], [2, 3, 4], [3, 4, 5], [4, 5, 6], [5, 6, 7], [6, 7, 8], [7, 8, 9]]
    func eachSlices(_ num: Int) -> [[Element]] {
        return (0...count - num).map { self[$0..<$0 + num].map { $0 } }
    }
}
