//
//  LogTableViewController.swift
//  WalletExample
//
//  Created by Akifumi Fujita on 2019/01/21.
//  Copyright © 2019 Yenom Inc. All rights reserved.
//

import UIKit

class LogTableViewController: UITableViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(logged(notification:)), name: Notification.Name.Wallet.logged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationBar.topItem?.title = "Log History"
    }
    
    @objc
    func logged(notification: Notification) {
        tableView.reloadData()
        let indexPath = IndexPath(item: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
