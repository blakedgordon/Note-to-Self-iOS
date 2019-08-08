//
//  SettingsTableViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit
import SVProgressHUD

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var darkModeLabel: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var upgradeProButton: UIButton!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var remainingEmailsLabel: UILabel!
    
    weak var newEmailCell: NewEmailCell?
    var topHeader: UITableViewHeaderFooterView?
    
    var timer: Timer? = nil
    let numberOfTotalSections = 5
    
    var emails: [String] = User.emails
    
    var productsAvailable: [SKProduct]?
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        let rows = tableView.numberOfRows(inSection: 0)
        var emails: [String] = []
        var invalidEmail = false
        for row in 0..<rows {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? EmailCell
            if let emailCell = cell, let email = emailCell.emailField.text {
                emails.append(email.trimmingCharacters(in: .whitespacesAndNewlines))
                if !User.isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    invalidEmail = true
                }
            }
        }
        
        if !invalidEmail {
            User.emails = emails
            if let subject = subjectTextField.text, subject != "" {
                SecureMail.subject = subject
            }
            view.endEditing(true)
            dismiss(animated: true)
        } else {
            var alertTitle = "Invalid Email"
            var alertMessage = "One or more of the emails you entered was invalid"
            if self.emails.count == 1 {
                alertTitle = "Enter Email"
                alertMessage = "Please enter a valid email address"
            }
            let alertAction = UIAlertAction(title: "Ok", style: .default)
            self.presentDarkAlert(title: alertTitle, message: alertMessage, actions: [alertAction], darkMode: User.darkMode)
        }
    }
    
    @IBAction func darkSwitched(_ sender: UISwitch) {
        view.endEditing(true)
        User.darkMode = sender.isOn
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.75) {
            self.darkMode(on: User.darkMode)
            if let noteView = self.presentingViewController as? NoteViewController {
                noteView.darkMode(on: User.darkMode)
            }
        }
    }
    
    @IBAction func upgradeToProPressed(_ sender: Any) {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        if NoteToSelfPro.proAvailable(products: productsAvailable) {
            NoteToSelfPro.store.buyProduct(
                NoteToSelfPro.getProduct(NoteToSelfPro.proProductKey, products: productsAvailable)!)
        } else {
            self.presentDarkAlert(title: "Unavailable",
                                  message: "Looks like we've hit a snag and we can't seem to purchase this. Please contact support.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            SVProgressHUD.dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    @IBAction func restorePurchasesPressed(_ sender: Any) {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        if productsAvailable?.count ?? 0 > 0 {
            NoteToSelfPro.store.restorePurchases()
        } else {
            self.presentDarkAlert(title: "Unavailable",
                                  message: "Looks like we've hit a snag and we can't seem to restore any purchases. Please contact support.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            SVProgressHUD.dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "EmailCell", bundle: nil), forCellReuseIdentifier: "EmailCell")
        tableView.register(UINib(nibName: "NewEmailCell", bundle: nil), forCellReuseIdentifier: "NewEmailCell")
        
        subjectTextField.delegate = self
        
        emails = User.emails
        
        NoteToSelfPro.validateReceipt()
        upgradeProButton.layer.cornerRadius = 4
        upgradeProButton.setTitle(NoteToSelfPro.proPriceLabel, for: .normal)
        upgradeProButton.updateConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchase),
                                               name: NSNotification.Name(rawValue: NoteToSelfPro.purchaseNotification), object: nil)
    }
    
    @objc func purchase(notification: NSNotification) {
        SVProgressHUD.dismiss()
        let result = notification.object as? String ?? ""
        if result == "success" {
            self.presentDarkAlert(title: "Purchased",
                                  message: "Thanks for purchasing Pro!",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            self.tableView.reloadData()
            darkModeSwitch.isEnabled = true
            self.newEmailCell?.updateLabel()
        } else if result == "expired" {
            self.presentDarkAlert(title: "Expired",
                                  message: "Looks like your Pro subscription expired. Please renew your subscription by upgrading again.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
        } else {
            self.presentDarkAlert(title: "Failure",
                                  message: "Looks like we've hit a snag and we can't seem to purchase this. Please check your network and App Store account.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let header = self.tableView.headerView(forSection: 0) {
            topHeader = header
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subjectTextField.text = SecureMail.subject
        
        User.validatedEmails { (invalidEmails) in
            let rows = self.tableView.numberOfRows(inSection: 0)
            for row in 0..<rows {
                let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? EmailCell
                if let emailCell = cell, let email = emailCell.emailField.text {
                    emailCell.validateSpinner.stopAnimating()
                    emailCell.validateSpinner.isHidden = true
                    emailCell.validateButton.isHidden = false
                    emailCell.validateButton.isEnabled = true
                    if !invalidEmails.contains(email) {
                        emailCell.validateButton.isUserInteractionEnabled = false
                        emailCell.validateButton.tintColor = UIColor.green
                    }
                }
            }
        }
        
        NoteToSelfPro.store.requestProducts { (_, products) in
            self.productsAvailable = products
        }
        
        self.newEmailCell?.updateLabel()
        darkModeSwitch.isEnabled = User.purchasedPro
        darkModeSwitch.isOn = (User.purchasedPro) ? User.darkMode : false
        if !User.purchasedPro {
            if Emails.remainingEmails > 0 {
                var emailText = (Emails.remainingEmails == 1) ? "email" : "emails"
                var remainingTime = (Emails.remainingTime == "00:00:00") ? "24 hours" : Emails.remainingTime
                remainingEmailsLabel.text = "Send \(Emails.remainingEmails) more \(emailText) for the next \(remainingTime)"
                if remainingTime != "24 hours" {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        emailText = (Emails.remainingEmails == 1) ? "email" : "emails"
                        remainingTime = (Emails.remainingTime == "00:00:00") ? "24 hours" : Emails.remainingTime
                        self.remainingEmailsLabel.text = "Send \(Emails.remainingEmails) more \(emailText) for the next \(remainingTime)"
                    }
                }
            } else {
                remainingEmailsLabel.text = "Please wait \(Emails.remainingTime) to send another email"
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.remainingEmailsLabel.text = "Please wait \(Emails.remainingTime) to send another email"
                }
            }
        }
        
        darkMode(on: User.darkMode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = (User.purchasedPro) ? numberOfTotalSections - 1 : numberOfTotalSections
        return sections
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.headerView(forSection: indexPath.section)?.textLabel?.text?.lowercased() == "support" {
            if indexPath.row == 0 {
                if let url = URL(string: "https://notetoselfapp.com#privacy"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 1 {
                if let url = URL(string: "https://notetoselfapp.com/terms.html"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 2 {
                sendEmailButtonTapped()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func darkMode(on: Bool) {
        self.view.backgroundColor = (on) ? UIColor.black : UIColor.groupTableViewBackground
        self.tableView.separatorColor = (on) ? UIColor.black : UIColor.lightGray
        self.navigationController?.navigationBar.barStyle = (on) ? .black : .default
        self.navigationController?.view.backgroundColor = (on) ? UIColor.black : UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes =
            (on) ? [.foregroundColor: UIColor.white] : [.foregroundColor: UIColor.black]
        subjectTextField.textColor = (on) ? UIColor.white : UIColor.black
        darkModeLabel.textColor = (on) ? UIColor.white : UIColor.black
        remainingEmailsLabel.textColor = (on) ? UIColor.white : UIColor.black
        privacyLabel.textColor = (on) ? UIColor.white : UIColor.black
        termsLabel.textColor = (on) ? UIColor.white : UIColor.black
        contactLabel.textColor = (on) ? UIColor.white : UIColor.black
        
        subjectTextField.keyboardAppearance = (on) ? .dark : .light
        
        for i in (0..<tableView.numberOfSections) {
            self.tableView.headerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? UIColor.black :
                UIColor.groupTableViewBackground
            if let header = self.tableView.headerView(forSection: i), i == 0 {
                topHeader = header
            }
            topHeader?.backgroundView?.backgroundColor = (on) ? UIColor.black : UIColor.groupTableViewBackground
            self.tableView.footerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? UIColor.black :
                UIColor.groupTableViewBackground
            for row in 0..<tableView.numberOfRows(inSection: i) {
                self.tableView.cellForRow(at: IndexPath(row: row, section: i))?.backgroundColor =
                    (on) ? UIColor.darkGray : UIColor.white
                if let emailCell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? EmailCell {
                    emailCell.darkMode(on: on)
                }
            }
        }
    }
    
    // FUNCTIONS BELOW RECIEVED FROM STACK OVERFLOW TO SEND AN EMAIL
    func sendEmailButtonTapped() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["Note to Self Support <support@notetoselfapp.com>"])
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                                       didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
    }
    // END
}
