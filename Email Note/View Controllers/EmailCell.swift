//
//  EmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 7/15/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class EmailCell: UITableViewCell {
    
    @IBOutlet var validateButton: UIButton!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var clearButton: UIButton!
    
    weak var viewController: UIViewController?
    
    @IBAction func emailValueChanged(_ sender: Any) {
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
    
    func populateCell(row: Int, viewController: UIViewController) {
        emailField.text = User.emails[row]
        clearButton.isHidden = User.emails.count == 1
        self.viewController = viewController
    }
    
    func darkMode(on: Bool) {
        emailField.textColor = (on) ? UIColor.white : UIColor.black
        emailField.keyboardAppearance = (on) ? .dark : .light
    }
}
