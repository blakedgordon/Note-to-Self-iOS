//
//  EmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 7/15/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class EmailCell: UITableViewCell {
    
    @IBOutlet weak var validateSpinner: UIActivityIndicatorView!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    
    weak var viewController: UIViewController?
    var row: Int?
    
    @IBAction func emailValueChanged(_ sender: Any) {
        validateSpinner.stopAnimating()
        validateSpinner.isHidden = true
        validateButton.isHidden = false
        if User.emailsValidated.keys.contains(emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? " ") {
            validateButton.isEnabled = true
            validateButton.isUserInteractionEnabled = false
            validateButton.tintColor = UIColor.green
        } else {
            validateButton.isEnabled = false
        }
    }
    
    @IBAction func validateEmail(_ sender: Any) {
        User.validateRequest(email: User.mainEmail)
        viewController?.presentDarkAlert(title: "Request Sent", message: "Email validation request sent!",
                                         actions: [UIAlertAction(title: "Ok", style: .default)], darkMode: User.darkMode)
    }
    
    @IBAction func clear(_ sender: Any) {
        if let view = viewController as? SettingsTableViewController, let index = row {
            view.emails.remove(at: index)
            view.tableView.reloadData()
        }
    }
    
    func populateCell(row: Int, viewController: SettingsTableViewController) {
        self.row = row
        emailField.text = viewController.emails[row]
        clearButton.isHidden = viewController.emails.count == 1
        self.viewController = viewController
        validateSpinner.startAnimating()
        validateSpinner.isHidden = false
    }
    
    func darkMode(on: Bool) {
        emailField.textColor = (on) ? UIColor.white : UIColor.black
        emailField.keyboardAppearance = (on) ? .dark : .light
        clearButton.tintColor = (on) ? UIColor.lightGray : UIColor.darkGray
    }
}
