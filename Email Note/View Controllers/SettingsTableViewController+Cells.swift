//
//  SettingsTableViewController+Cells.swift
//  Email Note
//
//  Created by Blake Gordon on 7/15/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import Foundation
import UIKit

extension SettingsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return User.emails.count + 1
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1 {
                return tableView.dequeueReusableCell(withIdentifier: "NewEmailCell", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmailCell", for: indexPath) as! EmailCell
            cell.populateCell(row: indexPath.row, viewController: self)
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
}
