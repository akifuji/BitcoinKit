//
//  LogTableViewController.swift
//  WalletExample
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 Yenom Inc. All rights reserved.
//

import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var blockHeightTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(logged(notification:)), name: Notification.Name.Wallet.logged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lastBlockChanged(notification:)), name: Notification.Name.Wallet.lastBlockChanged, object: nil)
        updateBlockHeight()
    }
    
    private func updateBlockHeight() {
        blockHeightTextField.text = "Block Height: \(Wallet.shared.lastCheckedBlockHeight)"
    }
    
    @objc
    func lastBlockChanged(notification: Notification) {
        updateBlockHeight()
    }
    
    @objc
    func logged(notification: Notification) {
        tableView.reloadData()
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: Wallet.shared.logs.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Wallet.shared.logs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath)
        let log = Wallet.shared.logs[indexPath.row]
        cell.textLabel?.text = log.message
        switch log.type {
        case .from:
            cell.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        case .to:
            cell.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        case .other:
            cell.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        case .error:
            cell.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        }
        return cell
    }
}
