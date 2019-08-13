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
            return (User.purchasedPro) ? self.emails.count + 1 : 2
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath.section == 0 {
            if tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1 {
                let newEmailCell = tableView.dequeueReusableCell(withIdentifier: "NewEmailCell", for: indexPath) as! NewEmailCell
                newEmailCell.settingsView = self
                newEmailCell.updateLabel()
                self.newEmailCell = newEmailCell
                cell = newEmailCell
            } else {
                let emailCell = tableView.dequeueReusableCell(withIdentifier: "EmailCell", for: indexPath) as! EmailCell
                emailCell.darkMode(on: User.darkMode)
                emailCell.populateCell(row: indexPath.row, viewController: self)
                cell = emailCell
            }
        }
        cell.backgroundColor = (User.darkMode) ? UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1) : .white
        if User.darkMode && cell.selectionStyle != .none {
            let view = UIView()
            view.backgroundColor = .darkGray
            cell.selectedBackgroundView = view
        } else if cell.selectionStyle != .none {
            cell.selectionStyle = .default
            cell.selectedBackgroundView = nil
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.backgroundColor = (User.darkMode) ? .black : .groupTableViewBackground
        return view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.backgroundColor = (User.darkMode) ? .black : .groupTableViewBackground
        return view
    }
}
