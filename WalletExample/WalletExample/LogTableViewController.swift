//
//  LogTableViewController.swift
//  WalletExample
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 Yenom Inc. All rights reserved.
//

import UIKit

class LogTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(logged(notification:)), name: Notification.Name.Wallet.logged, object: nil)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @objc
    func logged(notification: Notification) {
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Wallet.shared.logs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath)
        let log = Wallet.shared.logs[indexPath.row]
        cell.textLabel?.text = log.message
        cell.detailTextLabel?.text = log.date.description
        return cell
    }
}
