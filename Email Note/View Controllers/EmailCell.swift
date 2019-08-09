//
//  EmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 7/15/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class EmailCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var validateSpinner: UIActivityIndicatorView!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var clearButtonWidth: NSLayoutConstraint!
    
    weak var viewController: SettingsTableViewController?
    var row: Int?
    
    @IBAction func emailValueChanged(_ sender: Any) {
        validateSpinner.stopAnimating()
        validateSpinner.isHidden = true
        validateButton.isHidden = false
        if let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            User.emailsValidated.keys.contains(email) && email != "" {
            validateButton.isEnabled = true
            validateButton.isUserInteractionEnabled = false
            validateButton.tintColor = UIColor.green
        } else {
            validateButton.isEnabled = false
        }
    }
    
    @IBAction func setEmail(_ sender: Any) {
        if let view = viewController, let index = row, let email = emailField.text {
            view.emails[index] = email
            checkEmail()
        }
    }
    
    @IBAction func validateEmail(_ sender: Any) {
        User.validateRequest(email: User.mainEmail)
        viewController?.presentDarkAlert(title: "Request Sent", message: "Email validation request sent!",
                                         actions: [UIAlertAction(title: "Ok", style: .default)], darkMode: User.darkMode)
    }
    
    @IBAction func clear(_ sender: Any) {
        if let index = row {
            viewController?.emails.remove(at: index)
            viewController?.tableView.reloadData()
        }
    }
    
    func populateCell(row: Int, viewController: SettingsTableViewController) {
        self.viewController = viewController
        self.row = row
        
        emailField.text = viewController.emails[row]
        clearButton.isHidden = viewController.emails.count == 1
        clearButtonWidth.constant = (clearButton.isHidden) ? 0 : 22
        
        emailField.delegate = self
        
        checkEmail()
    }
    
    func checkEmail() {
        if let email = viewController?.emails[row ?? 0] {
            validateButton.isHidden = true
            validateSpinner.startAnimating()
            validateSpinner.isHidden = false
            User.isEmailValidated(email) { (valid, verificationEmail) in
                self.validateSpinner.stopAnimating()
                self.validateButton.isHidden = false
                self.validateButton.isEnabled = true
                if email.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    self.validateButton.isEnabled = false
                } else if valid {
                    self.validateButton.isUserInteractionEnabled = false
                    self.validateButton.tintColor = UIColor.green
                } else {
                    self.validateButton.isUserInteractionEnabled = true
                    self.validateButton.tintColor = UIColor.orange
                    if let emailSent = verificationEmail, emailSent {
                        self.viewController?.presentDarkAlert(title: "Request Sent",
                                                         message: "Email validation request sent for this new email!",
                                                         actions: [UIAlertAction(title: "Ok", style: .default)], darkMode: User.darkMode)
                    }
                }
            }
        }
    }
    
    func darkMode(on: Bool) {
        emailField.textColor = (on) ? UIColor.white : UIColor.black
        emailField.keyboardAppearance = (on) ? .dark : .light
        clearButton.tintColor = (on) ? UIColor.lightGray : UIColor.darkGray
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewController?.view.endEditing(true)
        return false
    }
}
