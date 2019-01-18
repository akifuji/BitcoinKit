//
//  ViewController.swift
//
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import BitcoinKit

class ViewController: UIViewController {
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var destinationAddressTextField: UITextField!
    
//    private var wallet: Wallet?  = Wallet()
    
    var peerManager: PeerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//        print("Docs Path: \(documentsPath)")
//        self.createWalletIfNeeded()
//        self.updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let privkey = try! PrivateKey.init(wif: "cQ2BQqKL44d9az7JuUx8b1CSGx5LkQrTM7UQKjYGnrHiMX5nUn5C")
        let pubkey = privkey.publicKey
        qrCodeImageView.image = generateVisualCode(address: pubkey.base58Address)
        peerManager = PeerManager(database: try! Database.default(), pubkeys: [pubkey])
        peerManager.start()
    }
    
    private func generateVisualCode(address: String) -> UIImage? {
        let parameters: [String : Any] = [
            "inputMessage": address.data(using: .utf8)!,
            "inputCorrectionLevel": "L"
        ]
        let filter = CIFilter(name: "CIQRCodeGenerator", parameters: parameters)
        
        guard let outputImage = filter?.outputImage else {
            return nil
        }
        
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 6, y: 6))
        guard let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
//
//    func createWalletIfNeeded() {
//        if wallet == nil {
//            let privateKey = PrivateKey(network: .testnet)
//            wallet = Wallet(privateKey: privateKey)
//            wallet?.save()
//        }
//    }
//
//    func updateLabels() {
//        qrCodeImageView.image = wallet?.address.qrImage()
//        addressLabel.text = wallet?.address.cashaddr
//        if let balance = wallet?.balance() {
//            balanceLabel.text = "Balance : \(balance) satoshi"
//        }
//    }
//
//    func updateBalance() {
//        wallet?.reloadBalance(completion: { [weak self] (utxos) in
//            DispatchQueue.main.async { self?.updateLabels() }
//        })
//    }
//
//    @IBAction func didTapReloadBalanceButton(_ sender: UIButton) {
//        updateBalance()
//    }
//
//    @IBAction func didTapSendButton(_ sender: UIButton) {
//        guard let addressString = destinationAddressTextField.text else {
//            return
//        }
//
//        do {
//            let address: Address = try AddressFactory.create(addressString)
//            try wallet?.send(to: address, amount: 10000, completion: { [weak self] (response) in
//                print(response ?? "")
//                self?.updateBalance()
//            })
//        } catch {
//            print(error)
//        }
//    }
}

