//
//  NewEmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 8/7/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class NewEmailCell: UITableViewCell {
    
    weak var tableView: UITableView?
    
    @IBAction func addNewEmailPressed(_ sender: Any) {
        User.emails.append("")
        tableView?.reloadData()
    }
    
}
