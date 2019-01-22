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

class WalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var txTableView: UITableView!
    
    let wallet = Wallet.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txTableView.delegate = self
        txTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(balanceChanged(notification:)), name: Notification.Name.Wallet.balanceChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentAdded(notification:)), name: Notification.Name.Wallet.paymentAdded, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        qrCodeImageView.image = generateVisualCode(address: wallet.publicKey.base58Address)
    }
    
    @IBAction func didTapSendButton(_ sender: UIButton) {
        wallet.peerManager.send(toAddress: "mjPAZNeeSid5F9BKt6hYKgfRWrADDtgCVp", amount: 10000)
    }
    
    @objc
    func balanceChanged(notification: Notification) {
        balanceLabel.text = "Balance: \(wallet.balance)"
    }
    
    @objc
    func paymentAdded(notification: Notification) {
        txTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallet.payments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        let payment = wallet.payments[indexPath.row]
        if payment.direction == .sent {
            cell.textLabel?.text = "- \(payment.amount)"
        } else {
            cell.textLabel?.text = "\(payment.amount)"
        }
        cell.detailTextLabel?.text = payment.txID.hex
        return cell
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
}

