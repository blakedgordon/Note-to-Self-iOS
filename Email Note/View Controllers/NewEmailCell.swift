//
//  NewEmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 8/7/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class NewEmailCell: UITableViewCell {
    
    @IBOutlet weak var newEmailButton: UIButton!
    
    weak var settingsView: SettingsTableViewController?
    
    @IBAction func addNewEmailPressed(_ sender: Any) {
        settingsView?.emails.append("")
        settingsView?.tableView?.reloadData()
    }
    
    func updateLabel() {
        newEmailButton.isEnabled = (User.purchasedPro && (settingsView?.emails.count ?? 5) < 5)
    }
    
}
